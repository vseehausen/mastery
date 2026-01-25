//! Kindle detection and vocab.db sync
//!
//! Supports all Kindle e-reader models:
//! - Older models (pre-2024): Mount as USB mass storage, vocab.db at system/vocabulary/
//! - Newer models (2024+): Use MTP protocol via libmtp-rs (requires admin privileges)
//!
//! The vocab.db file is a SQLite database containing vocabulary lookups made on the Kindle.

use std::path::{Path, PathBuf};
use std::fs;
use std::process::Command;

const VOCAB_DB_FILE: &str = "vocab.db";
const VOCAB_PATH: &str = "system/vocabulary";

fn log(msg: &str) {
    eprintln!("[kindle] {}", msg);
}

/// Check if vocab.db exists at a given base path
fn find_vocab_at_path(base_path: &Path) -> Option<PathBuf> {
    let vocab_path = base_path.join(VOCAB_PATH).join(VOCAB_DB_FILE);
    log(&format!("Checking path: {}", vocab_path.display()));
    if vocab_path.exists() {
        log(&format!("Found vocab.db at: {}", vocab_path.display()));
        return Some(vocab_path);
    }
    None
}

/// Find vocab.db by searching mounted volumes
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
                    // Check standard Kindle mount
                    if let Some(path) = find_vocab_at_path(&volume_path) {
                        return Some(path);
                    }
                    
                    // MacDroid "Internal storage" mount
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

/// Check if any Amazon/Kindle MTP device is connected using macOS ioreg
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

/// Check if a Kindle device is connected
pub fn is_kindle_connected() -> bool {
    // Check mounted volumes first (older Kindles or MacDroid)
    if find_vocab_on_mounted_volumes().is_some() {
        return true;
    }
    
    // Check for MTP device presence
    #[cfg(target_os = "macos")]
    {
        is_kindle_mtp_device_present()
    }
    
    #[cfg(not(target_os = "macos"))]
    {
        false
    }
}

/// Sync vocab.db from Kindle to the specified output path.
/// For MTP devices, this requires admin privileges and will prompt for password.
pub fn sync_vocab_db(output_path: &Path) -> Result<u64, String> {
    // First try mounted volumes (no special privileges needed)
    if let Some(source_path) = find_vocab_on_mounted_volumes() {
        fs::copy(&source_path, output_path)
            .map_err(|e| format!("Failed to copy vocab.db: {}", e))?;
        
        let size = fs::metadata(output_path)
            .map(|m| m.len())
            .unwrap_or(0);
        
        return Ok(size);
    }
    
    // Try MTP access (requires admin privileges)
    #[cfg(target_os = "macos")]
    {
        sync_vocab_via_mtp(output_path)
    }
    
    #[cfg(not(target_os = "macos"))]
    {
        Err("Kindle not found".to_string())
    }
}

/// Sync vocab.db via MTP using libmtp-rs
/// This requires admin privileges to detach the kernel driver
#[cfg(target_os = "macos")]
fn sync_vocab_via_mtp(output_path: &Path) -> Result<u64, String> {
    use libmtp_rs::device::raw::detect_raw_devices;
    use libmtp_rs::device::{MtpDevice, StorageSort};
    use libmtp_rs::object::filetypes::Filetype;
    use libmtp_rs::object::Object;
    use libmtp_rs::storage::Parent;

    log("Starting MTP sync...");
    log(&format!("Output path: {}", output_path.display()));

    // Detect devices
    log("Detecting MTP devices...");
    let raw_devices = detect_raw_devices()
        .map_err(|e| format!("Failed to detect MTP devices: {:?}. Try running with admin privileges.", e))?;

    log(&format!("Found {} raw devices", raw_devices.len()));
    
    if raw_devices.is_empty() {
        return Err("No Kindle found via MTP. Make sure it's connected.".to_string());
    }

    let raw_device = raw_devices.into_iter().next().unwrap();
    log(&format!("Using device: VID={:#06x} PID={:#06x}", 
        raw_device.device_entry().vendor_id,
        raw_device.device_entry().product_id));
    
    // Open device
    log("Opening device (uncached)...");
    let mut device: MtpDevice = raw_device.open_uncached()
        .ok_or("Failed to open Kindle. It may require admin privileges or be in use.")?;
    log("Device opened successfully");

    // Update storage
    log("Updating storage info...");
    device.update_storage(StorageSort::ByFreeSpace)
        .map_err(|e| format!("Failed to access storage: {:?}", e))?;

    let storage_pool = device.storage_pool();
    let storage_count = storage_pool.iter().count();
    log(&format!("Found {} storage(s)", storage_count));

    // Track result to return after forgetting device
    let mut result: Result<u64, String> = Err("vocab.db not found on Kindle".to_string());

    // Navigate to system/vocabulary/vocab.db
    'outer: for (storage_id, storage) in storage_pool.iter() {
        log(&format!("Scanning storage {}: {:?}", storage_id, storage.description()));
        
        let root_items = storage.files_and_folders(Parent::Root);
        let root_count = root_items.len();
        log(&format!("  Root has {} items", root_count));
        
        for item in root_items {
            let name = item.name().to_lowercase();
            log(&format!("  - {} (type: {:?})", item.name(), item.ftype()));
            
            if name == "system" && matches!(item.ftype(), Filetype::Folder) {
                log("  Found 'system' folder, scanning...");
                let system_items = storage.files_and_folders(Parent::Folder(item.id()));
                
                for sys_item in system_items {
                    log(&format!("    - {} (type: {:?})", sys_item.name(), sys_item.ftype()));
                    
                    if sys_item.name().to_lowercase() == "vocabulary" && matches!(sys_item.ftype(), Filetype::Folder) {
                        log("    Found 'vocabulary' folder, scanning...");
                        let vocab_items = storage.files_and_folders(Parent::Folder(sys_item.id()));
                        
                        for vocab_item in vocab_items {
                            log(&format!("      - {} (size: {} bytes)", vocab_item.name(), vocab_item.size()));
                            
                            if vocab_item.name().to_lowercase() == "vocab.db" {
                                log(&format!("      Found vocab.db! Size on device: {} bytes", vocab_item.size()));
                                log(&format!("      Downloading to: {}", output_path.display()));
                                
                                let output_str = output_path.to_string_lossy().to_string();
                                match storage.get_file_to_path(vocab_item.id(), output_str) {
                                    Ok(()) => {
                                        let size = fs::metadata(output_path)
                                            .map(|m| m.len())
                                            .unwrap_or(0);
                                        log(&format!("      Download complete! Local size: {} bytes", size));
                                        result = Ok(size);
                                    }
                                    Err(e) => {
                                        result = Err(format!("Failed to download vocab.db: {:?}", e));
                                    }
                                }
                                break 'outer;
                            }
                        }
                    }
                }
            }
        }
    }

    // Prevent device drop from closing session (which disconnects Kindle)
    // The subprocess will exit anyway, so leaking is fine
    drop(storage_pool);
    log("Leaking MTP device to keep Kindle connected...");
    std::mem::forget(device);

    if result.is_err() {
        log("ERROR: vocab.db not found after scanning all storage");
    }
    result
}

/// Sync vocab.db with admin privileges using osascript
/// This prompts the user for their password once
pub fn sync_vocab_with_privileges(output_path: &Path) -> Result<String, String> {
    log("sync_vocab_with_privileges called");
    log(&format!("Output path: {}", output_path.display()));
    
    // First try without privileges (mounted volumes)
    log("Checking mounted volumes first...");
    if let Some(source_path) = find_vocab_on_mounted_volumes() {
        log(&format!("Found on mounted volume: {}", source_path.display()));
        fs::copy(&source_path, output_path)
            .map_err(|e| format!("Failed to copy vocab.db: {}", e))?;
        
        let size = fs::metadata(output_path)
            .map(|m| m.len())
            .unwrap_or(0);
        
        return Ok(format!("Copied from mounted volume ({} bytes)", size));
    }
    
    log("Not found on mounted volumes, trying MTP with admin privileges...");
    
    // Need MTP access with admin privileges
    #[cfg(target_os = "macos")]
    {
        let current_exe = std::env::current_exe()
            .map_err(|e| format!("Failed to get current exe: {}", e))?;
        
        log(&format!("Current exe: {}", current_exe.display()));
        
        let script = format!(
            r#"do shell script "{} --sync-vocab '{}'" with administrator privileges"#,
            current_exe.display(),
            output_path.display()
        );
        
        log("Executing osascript for admin privileges...");
        
        let output = Command::new("osascript")
            .arg("-e")
            .arg(&script)
            .output()
            .map_err(|e| format!("Failed to request admin privileges: {}", e))?;
        
        let stdout = String::from_utf8_lossy(&output.stdout);
        let stderr = String::from_utf8_lossy(&output.stderr);
        
        log(&format!("osascript exit code: {:?}", output.status.code()));
        log(&format!("osascript stdout: {}", stdout.trim()));
        log(&format!("osascript stderr: {}", stderr.trim()));
        
        if output.status.success() {
            // stdout contains "SIZE|MESSAGE" format, but libmtp also prints device info
            // Find the line with our format (contains |)
            let stdout_str = stdout.trim();
            for line in stdout_str.lines() {
                if let Some((size_str, msg)) = line.split_once('|') {
                    if let Ok(size) = size_str.trim().parse::<u64>() {
                        return Ok(format!("{} ({} bytes)", msg, size));
                    }
                }
            }
            // Fallback: check if file exists and get size
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
                Err(format!("Sync failed: stdout={}, stderr={}", stdout.trim(), stderr.trim()))
            }
        }
    }
    
    #[cfg(not(target_os = "macos"))]
    {
        Err("Platform not supported".to_string())
    }
}

/// Handle --sync-vocab CLI argument (called with admin privileges)
pub fn handle_sync_vocab_cli(output_path: &str) {
    log("=== CLI sync mode (with admin privileges) ===");
    log(&format!("Output path: {}", output_path));
    
    let path = Path::new(output_path);
    
    // Create parent directory if needed
    if let Some(parent) = path.parent() {
        if !parent.exists() {
            log(&format!("Creating directory: {}", parent.display()));
            if let Err(e) = fs::create_dir_all(parent) {
                log(&format!("Failed to create directory: {}", e));
                eprintln!("Failed to create directory: {}", e);
                std::process::exit(1);
            }
        }
    }
    
    match sync_vocab_db(path) {
        Ok(size) => {
            log(&format!("Sync successful! Size: {} bytes", size));
            // Output "SIZE|MESSAGE" format for parent to parse
            println!("{}|Downloaded via MTP", size);
            std::process::exit(0);
        }
        Err(e) => {
            log(&format!("Sync failed: {}", e));
            eprintln!("{}", e);
            std::process::exit(1);
        }
    }
}
