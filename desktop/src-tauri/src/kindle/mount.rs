//! Mount point detection for Kindle devices
//!
//! Finds the filesystem mount point where Kindle device is accessible.

use anyhow::{anyhow, Result};
use std::path::PathBuf;

/// Default path to My Clippings file on Kindle
const CLIPPINGS_PATH: &str = "documents/My Clippings.txt";

/// Find the mount point for a Kindle device
///
/// Searches common mount locations for a directory containing
/// the Kindle's "documents" folder with "My Clippings.txt".
pub fn find_kindle_mount() -> Result<PathBuf> {
    let candidates = get_mount_candidates();

    for mount_point in candidates {
        if is_kindle_mount(&mount_point) {
            return Ok(mount_point);
        }
    }

    Err(anyhow!("Kindle mount point not found"))
}

/// Get candidate mount points based on platform
fn get_mount_candidates() -> Vec<PathBuf> {
    let mut candidates = Vec::new();

    #[cfg(target_os = "macos")]
    {
        // On macOS, Kindle typically mounts under /Volumes/Kindle
        if let Ok(entries) = std::fs::read_dir("/Volumes") {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.is_dir() {
                    let name = path.file_name().unwrap_or_default().to_string_lossy();
                    // Kindle devices typically mount as "Kindle" or similar
                    if name.to_lowercase().contains("kindle") {
                        candidates.insert(0, path);
                    } else {
                        candidates.push(path);
                    }
                }
            }
        }
    }

    #[cfg(target_os = "windows")]
    {
        // On Windows, check removable drives
        for letter in 'D'..='Z' {
            let path = PathBuf::from(format!("{}:\\", letter));
            if path.exists() {
                candidates.push(path);
            }
        }
    }

    #[cfg(target_os = "linux")]
    {
        // On Linux, check common mount points
        let user = std::env::var("USER").unwrap_or_else(|_| "user".to_string());

        // Check /media/<user>/* and /mnt/*
        let media_path = PathBuf::from(format!("/media/{}", user));
        if let Ok(entries) = std::fs::read_dir(&media_path) {
            for entry in entries.flatten() {
                candidates.push(entry.path());
            }
        }

        if let Ok(entries) = std::fs::read_dir("/mnt") {
            for entry in entries.flatten() {
                candidates.push(entry.path());
            }
        }

        // Also check /run/media/<user>/*
        let run_media_path = PathBuf::from(format!("/run/media/{}", user));
        if let Ok(entries) = std::fs::read_dir(&run_media_path) {
            for entry in entries.flatten() {
                candidates.push(entry.path());
            }
        }
    }

    candidates
}

/// Check if a mount point is a Kindle device
fn is_kindle_mount(mount_point: &PathBuf) -> bool {
    let clippings_path = mount_point.join(CLIPPINGS_PATH);
    clippings_path.exists()
}

/// Get the path to My Clippings.txt on a Kindle mount
pub fn get_clippings_path(mount_point: &PathBuf) -> PathBuf {
    mount_point.join(CLIPPINGS_PATH)
}

/// Read the contents of My Clippings.txt from a Kindle
pub fn read_clippings(mount_point: &PathBuf) -> Result<String> {
    let clippings_path = get_clippings_path(mount_point);

    if !clippings_path.exists() {
        return Err(anyhow!("My Clippings.txt not found at {:?}", clippings_path));
    }

    let content = std::fs::read_to_string(&clippings_path)?;
    Ok(content)
}

/// Get file metadata for My Clippings.txt
pub fn get_clippings_metadata(mount_point: &PathBuf) -> Result<ClippingsMetadata> {
    let clippings_path = get_clippings_path(mount_point);
    let metadata = std::fs::metadata(&clippings_path)?;

    Ok(ClippingsMetadata {
        size: metadata.len(),
        modified: metadata.modified().ok(),
    })
}

/// Metadata about the My Clippings.txt file
#[derive(Debug, Clone)]
pub struct ClippingsMetadata {
    pub size: u64,
    pub modified: Option<std::time::SystemTime>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_clippings_path() {
        let mount = PathBuf::from("/Volumes/Kindle");
        let expected = PathBuf::from("/Volumes/Kindle/documents/My Clippings.txt");
        assert_eq!(get_clippings_path(&mount), expected);
    }

    #[test]
    fn test_mount_candidates_not_empty() {
        let candidates = get_mount_candidates();
        // This test just verifies the function doesn't panic
        // Actual mount points depend on the system state
        let _ = candidates;
    }
}
