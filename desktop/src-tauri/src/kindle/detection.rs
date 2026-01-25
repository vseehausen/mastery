// USB device detection for Kindle devices

use anyhow::Result;

/// Kindle USB vendor/product IDs
pub const KINDLE_VENDOR_ID: u16 = 0x1949; // Amazon

/// Known Kindle product IDs
pub const KINDLE_PRODUCT_IDS: &[u16] = &[
    0x0002, // Kindle 2
    0x0004, // Kindle DX
    0x0006, // Kindle 3
    0x0008, // Kindle 4
    0x000A, // Kindle Touch
    0x000C, // Kindle Paperwhite
    0x000E, // Kindle Paperwhite 2
    0x0010, // Kindle Voyage
    0x0012, // Kindle Paperwhite 3
    0x0324, // Kindle Oasis
    0x0326, // Kindle Paperwhite 4
    0x0328, // Kindle 10th Gen
    0x032A, // Kindle Paperwhite 5
];

/// Check if a connected USB device is a Kindle
pub fn is_kindle_device(vendor_id: u16, product_id: u16) -> bool {
    vendor_id == KINDLE_VENDOR_ID && KINDLE_PRODUCT_IDS.contains(&product_id)
}

/// Check if a Kindle device is currently connected and accessible
pub fn is_kindle_connected() -> bool {
    find_clippings_file().ok().flatten().is_some()
}

/// Find clippings file path on mounted Kindle
pub fn find_clippings_file() -> Result<Option<std::path::PathBuf>> {
    // TODO: Implement platform-specific mount point detection
    // macOS: /Volumes/Kindle/documents/My Clippings.txt
    // Windows: D:\documents\My Clippings.txt (drive letter varies)
    // Linux: /media/$USER/Kindle/documents/My Clippings.txt

    #[cfg(target_os = "macos")]
    {
        let path = std::path::PathBuf::from("/Volumes/Kindle/documents/My Clippings.txt");
        if path.exists() {
            return Ok(Some(path));
        }
    }

    Ok(None)
}
