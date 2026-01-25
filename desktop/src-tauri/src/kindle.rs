// Simple Kindle detection and file access

use std::path::Path;

const CLIPPINGS_PATH: &str = "/Volumes/Kindle/documents/My Clippings.txt";

/// Check if a Kindle device is currently connected and accessible
pub fn is_kindle_connected() -> bool {
    #[cfg(target_os = "macos")]
    {
        Path::new(CLIPPINGS_PATH).exists()
    }

    #[cfg(not(target_os = "macos"))]
    {
        // TODO: Add support for other platforms
        false
    }
}

/// Get clippings file information (path and size)
pub fn get_clippings_info() -> Result<(String, u64), String> {
    #[cfg(target_os = "macos")]
    {
        let path = Path::new(CLIPPINGS_PATH);
        if !path.exists() {
            return Err("Clippings file not found".to_string());
        }

        let metadata = std::fs::metadata(path)
            .map_err(|e| format!("Failed to read file metadata: {}", e))?;

        Ok((
            CLIPPINGS_PATH.to_string(),
            metadata.len(),
        ))
    }

    #[cfg(not(target_os = "macos"))]
    {
        Err("Platform not supported".to_string())
    }
}
