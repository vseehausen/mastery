//! Kindle detection and vocab.db access
//!
//! Supports all Kindle e-reader models:
//! - Older models (pre-2024): Mount as USB mass storage, vocab.db at system/vocabulary/
//! - Newer models (2024+): Use MTP protocol via pure Rust implementation (requires admin privileges)

mod mtp;

use std::path::{Path, PathBuf};
use std::fs;
use std::process::Command;

const VOCAB_DB_FILE: &str = "vocab.db";
const VOCAB_PATH: &str = "system/vocabulary";

fn find_vocab_at_path(base_path: &Path) -> Option<PathBuf> {
    let vocab_path = base_path.join(VOCAB_PATH).join(VOCAB_DB_FILE);
    if vocab_path.exists() {
        return Some(vocab_path);
    }
    None
}

fn find_vocab_on_mounted_volumes() -> Option<PathBuf> {
    #[cfg(target_os = "macos")]
    {
        let volumes_dir = Path::new("/Volumes");
        if !volumes_dir.exists() {
            return None;
        }

        if let Ok(entries) = fs::read_dir(volumes_dir) {
            for entry in entries.flatten() {
                let volume_path = entry.path();
                
                if volume_path.is_symlink() {
                    continue;
                }
                
                if volume_path.is_dir() {
                    if let Some(path) = find_vocab_at_path(&volume_path) {
                        return Some(path);
                    }
                    
                    let internal_storage = volume_path.join("Internal storage");
                    if internal_storage.exists() {
                        if let Some(path) = find_vocab_at_path(&internal_storage) {
                            return Some(path);
                        }
                    }
                }
            }
        }
        None
    }

    #[cfg(not(target_os = "macos"))]
    {
        None
    }
}

#[cfg(target_os = "macos")]
fn is_kindle_mtp_device_present() -> bool {
    let output = Command::new("ioreg")
        .args(["-p", "IOUSB", "-l", "-w", "0"])
        .output();
    
    match output {
        Ok(out) => {
            let stdout = String::from_utf8_lossy(&out.stdout);
            stdout.contains("idVendor\" = 6473") || 
            (stdout.to_lowercase().contains("amazon") && stdout.to_lowercase().contains("kindle"))
        }
        Err(_) => false,
    }
}

#[derive(Debug, Clone, serde::Serialize)]
#[serde(rename_all = "camelCase")]
pub struct KindleStatus {
    pub connected: bool,
    pub connection_type: Option<String>,
}

#[allow(dead_code)]
pub fn is_kindle_connected() -> bool {
    get_kindle_status().connected
}

pub fn get_kindle_status() -> KindleStatus {
    if find_vocab_on_mounted_volumes().is_some() {
        return KindleStatus {
            connected: true,
            connection_type: Some("mounted".to_string()),
        };
    }
    
    #[cfg(target_os = "macos")]
    {
        if is_kindle_mtp_device_present() {
            return KindleStatus {
                connected: true,
                connection_type: Some("mtp".to_string()),
            };
        }
    }
    
    KindleStatus {
        connected: false,
        connection_type: None,
    }
}

pub fn read_vocab_db_content() -> Result<Vec<u8>, String> {
    if let Some(source_path) = find_vocab_on_mounted_volumes() {
        return fs::read(&source_path)
            .map_err(|e| format!("Failed to read vocab.db: {}", e));
    }
    
    #[cfg(target_os = "macos")]
    {
        read_vocab_via_mtp_privileged()
    }
    
    #[cfg(not(target_os = "macos"))]
    {
        Err("Kindle not found. Please connect your Kindle via USB.".to_string())
    }
}

#[cfg(target_os = "macos")]
fn read_vocab_via_mtp_privileged() -> Result<Vec<u8>, String> {
    use std::env::temp_dir;
    
    let temp_path = temp_dir().join("mastery_vocab_temp.db");
    
    let current_exe = std::env::current_exe()
        .map_err(|e| format!("Failed to get current exe: {}", e))?;
    
    let script = format!(
        r#"do shell script "{} --sync-vocab '{}'" with administrator privileges"#,
        current_exe.display(),
        temp_path.display()
    );
    
    let output = Command::new("osascript")
        .arg("-e")
        .arg(&script)
        .output()
        .map_err(|e| format!("Failed to request admin privileges: {}", e))?;
    
    let stderr = String::from_utf8_lossy(&output.stderr);
    
    if !output.status.success() {
        if stderr.contains("User canceled") || stderr.contains("(-128)") {
            return Err("Import cancelled by user".to_string());
        }
        return Err(format!("MTP access failed: {}", stderr.trim()));
    }
    
    if !temp_path.exists() {
        return Err("Failed to read from Kindle via MTP".to_string());
    }
    
    let content = fs::read(&temp_path)
        .map_err(|e| format!("Failed to read temp file: {}", e))?;
    
    let _ = fs::remove_file(&temp_path);
    
    Ok(content)
}

pub fn sync_vocab_db(output_path: &Path) -> Result<u64, String> {
    if let Some(source_path) = find_vocab_on_mounted_volumes() {
        fs::copy(&source_path, output_path)
            .map_err(|e| format!("Failed to copy vocab.db: {}", e))?;
        
        let size = fs::metadata(output_path)
            .map(|m| m.len())
            .unwrap_or(0);
        
        return Ok(size);
    }
    
    #[cfg(target_os = "macos")]
    {
        sync_vocab_via_mtp(output_path)
    }
    
    #[cfg(not(target_os = "macos"))]
    {
        Err("Kindle not found".to_string())
    }
}

#[cfg(target_os = "macos")]
fn sync_vocab_via_mtp(output_path: &Path) -> Result<u64, String> {
    mtp::sync_vocab_via_mtp(output_path)
}

#[allow(dead_code)]
pub fn sync_vocab_with_privileges(output_path: &Path) -> Result<String, String> {
    if let Some(source_path) = find_vocab_on_mounted_volumes() {
        fs::copy(&source_path, output_path)
            .map_err(|e| format!("Failed to copy vocab.db: {}", e))?;
        
        let size = fs::metadata(output_path)
            .map(|m| m.len())
            .unwrap_or(0);
        
        return Ok(format!("Copied from mounted volume ({} bytes)", size));
    }
    
    #[cfg(target_os = "macos")]
    {
        let current_exe = std::env::current_exe()
            .map_err(|e| format!("Failed to get current exe: {}", e))?;
        
        let script = format!(
            r#"do shell script "{} --sync-vocab '{}'" with administrator privileges"#,
            current_exe.display(),
            output_path.display()
        );
        
        let output = Command::new("osascript")
            .arg("-e")
            .arg(&script)
            .output()
            .map_err(|e| format!("Failed to request admin privileges: {}", e))?;
        
        let stdout = String::from_utf8_lossy(&output.stdout);
        let stderr = String::from_utf8_lossy(&output.stderr);
        
        if output.status.success() {
            let stdout_str = stdout.trim();
            for line in stdout_str.lines() {
                if let Some((size_str, msg)) = line.split_once('|') {
                    if let Ok(size) = size_str.trim().parse::<u64>() {
                        return Ok(format!("{} ({} bytes)", msg, size));
                    }
                }
            }
            let size = fs::metadata(output_path).map(|m| m.len()).unwrap_or(0);
            if size > 0 {
                Ok(format!("Downloaded vocab.db ({} bytes)", size))
            } else {
                Err(format!("Sync may have failed. stdout: {}", stdout_str))
            }
        } else {
            if stderr.contains("User canceled") || stderr.contains("(-128)") {
                Err("Sync cancelled by user".to_string())
            } else {
                Err(format!("Sync failed: {}", stderr.trim()))
            }
        }
    }
    
    #[cfg(not(target_os = "macos"))]
    {
        Err("Platform not supported".to_string())
    }
}

pub fn handle_sync_vocab_cli(output_path: &str) {
    let path = Path::new(output_path);
    
    if let Some(parent) = path.parent() {
        if !parent.exists() {
            if let Err(e) = fs::create_dir_all(parent) {
                eprintln!("Failed to create directory: {}", e);
                std::process::exit(1);
            }
        }
    }
    
    match sync_vocab_db(path) {
        Ok(size) => {
            println!("{}|Downloaded via MTP", size);
            std::process::exit(0);
        }
        Err(e) => {
            eprintln!("{}", e);
            std::process::exit(1);
        }
    }
}
