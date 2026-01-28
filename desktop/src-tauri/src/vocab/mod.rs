//! Vocabulary import module
//!
//! Provides utilities for reading and encoding vocab.db files

use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};
use std::fs;
use std::path::Path;

#[allow(dead_code)]
pub fn read_vocab_db_base64(path: &Path) -> Result<String, String> {
    if !path.exists() {
        return Err("vocab.db file not found".to_string());
    }
    
    let contents = fs::read(path)
        .map_err(|e| format!("Failed to read vocab.db: {}", e))?;
    
    if contents.len() > 6 * 1024 * 1024 {
        return Err("vocab.db file too large (max 6MB)".to_string());
    }
    
    Ok(BASE64.encode(&contents))
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_read_vocab_db_nonexistent() {
        let result = read_vocab_db_base64(Path::new("/nonexistent/path"));
        assert!(result.is_err());
    }
}
