//! Tests for Kindle detection and mount functions
//!
//! Note: Some tests require actual Kindle hardware or mock filesystem setup.

#[cfg(test)]
mod tests {
    use super::super::*;

    mod detection_tests {
        use super::*;

        #[test]
        fn test_kindle_vendor_id_constant() {
            // Kindle devices have vendor ID 0x1949 (Amazon)
            assert_eq!(detection::KINDLE_VENDOR_ID, 0x1949);
        }

        #[test]
        fn test_kindle_product_ids_not_empty() {
            // Verify that we have known Kindle product IDs
            assert!(!detection::KINDLE_PRODUCT_IDS.is_empty());
            assert!(detection::KINDLE_PRODUCT_IDS.contains(&0x0002)); // Kindle 2
        }

        #[test]
        fn test_is_kindle_device() {
            // Test with valid Kindle IDs
            assert!(detection::is_kindle_device(0x1949, 0x0002)); // Amazon Vendor ID with Kindle 2 product ID
            assert!(detection::is_kindle_device(0x1949, 0x000C)); // Kindle Paperwhite
            // Test with invalid vendor ID
            assert!(!detection::is_kindle_device(0x0000, 0x0002));
            // Test with invalid product ID
            assert!(!detection::is_kindle_device(0x1949, 0x9999));
        }
    }

    mod mount_tests {
        use super::*;
        use std::path::PathBuf;

        #[test]
        fn test_clippings_path_construction() {
            let mount = PathBuf::from("/Volumes/Kindle");
            let clippings_path = mount::get_clippings_path(&mount);

            assert!(clippings_path.to_string_lossy().contains("documents"));
            assert!(clippings_path.to_string_lossy().contains("My Clippings.txt"));
        }

        #[test]
        fn test_clippings_path_different_mounts() {
            // macOS style
            let mac_mount = PathBuf::from("/Volumes/Kindle");
            let mac_path = mount::get_clippings_path(&mac_mount);
            assert_eq!(
                mac_path.to_string_lossy(),
                "/Volumes/Kindle/documents/My Clippings.txt"
            );

            // Windows style
            let win_mount = PathBuf::from("E:\\");
            let win_path = mount::get_clippings_path(&win_mount);
            assert!(win_path.to_string_lossy().contains("documents"));
        }
    }

    mod parser_tests {
        use super::*;

        #[test]
        fn test_parse_empty_content() {
            let result = parse_clippings("").unwrap();
            assert!(result.is_empty());
        }

        #[test]
        fn test_parse_single_highlight() {
            let content = r#"Test Book (Test Author)
- Your Highlight on page 10 | Location 100-105 | Added on Monday, January 20, 2026 10:00:00 AM

This is the highlight content.
=========="#;

            let result = parse_clippings(content).unwrap();
            assert_eq!(result.len(), 1);
            assert_eq!(result[0].book_title, "Test Book");
            assert_eq!(result[0].author, Some("Test Author".to_string()));
            assert_eq!(result[0].content, "This is the highlight content.");
            assert_eq!(result[0].highlight_type, HighlightType::Highlight);
            assert_eq!(result[0].page, Some(10));
        }

        #[test]
        fn test_parse_note_type() {
            let content = r#"Test Book (Author)
- Your Note on page 5 | Location 50 | Added on Monday, January 20, 2026 10:00:00 AM

This is a note.
=========="#;

            let result = parse_clippings(content).unwrap();
            assert_eq!(result.len(), 1);
            assert_eq!(result[0].highlight_type, HighlightType::Note);
        }

        #[test]
        fn test_parse_book_without_author() {
            let content = r#"Unknown Book
- Your Highlight on page 1 | Location 10 | Added on Monday, January 20, 2026 10:00:00 AM

Content
=========="#;

            let result = parse_clippings(content).unwrap();
            assert_eq!(result.len(), 1);
            assert_eq!(result[0].book_title, "Unknown Book");
            assert!(result[0].author.is_none());
        }

        #[test]
        fn test_parse_multiple_entries() {
            let content = r#"Book One (Author One)
- Your Highlight on page 1 | Location 10 | Added on Monday, January 20, 2026 10:00:00 AM

Content one
==========
Book Two (Author Two)
- Your Highlight on page 2 | Location 20 | Added on Monday, January 20, 2026 10:01:00 AM

Content two
==========
Book Three (Author Three)
- Your Note on page 3 | Location 30 | Added on Monday, January 20, 2026 10:02:00 AM

Note three
=========="#;

            let result = parse_clippings(content).unwrap();
            assert_eq!(result.len(), 3);
            assert_eq!(result[0].book_title, "Book One");
            assert_eq!(result[1].book_title, "Book Two");
            assert_eq!(result[2].book_title, "Book Three");
        }

        #[test]
        fn test_parse_multiline_content() {
            let content = r#"Test Book (Author)
- Your Highlight on page 10 | Location 100 | Added on Monday, January 20, 2026 10:00:00 AM

This is line one.
This is line two.
This is line three.
=========="#;

            let result = parse_clippings(content).unwrap();
            assert_eq!(result.len(), 1);
            assert!(result[0].content.contains("line one"));
            assert!(result[0].content.contains("line two"));
            assert!(result[0].content.contains("line three"));
        }

        #[test]
        fn test_parse_skips_empty_content() {
            let content = r#"Test Book (Author)
- Your Highlight on page 10 | Location 100 | Added on Monday, January 20, 2026 10:00:00 AM

==========
Book Two (Author)
- Your Highlight on page 20 | Location 200 | Added on Monday, January 20, 2026 10:01:00 AM

Valid content
=========="#;

            let result = parse_clippings(content).unwrap();
            // First entry should be skipped (empty content)
            assert_eq!(result.len(), 1);
            assert_eq!(result[0].book_title, "Book Two");
        }
    }

    mod content_hash_tests {
        use super::*;

        #[test]
        fn test_content_hash_deterministic() {
            let hash1 = generate_content_hash("Book", "Content");
            let hash2 = generate_content_hash("Book", "Content");
            assert_eq!(hash1, hash2);
        }

        #[test]
        fn test_content_hash_different_content() {
            let hash1 = generate_content_hash("Book", "Content A");
            let hash2 = generate_content_hash("Book", "Content B");
            assert_ne!(hash1, hash2);
        }

        #[test]
        fn test_content_hash_different_books() {
            let hash1 = generate_content_hash("Book A", "Content");
            let hash2 = generate_content_hash("Book B", "Content");
            assert_ne!(hash1, hash2);
        }

        #[test]
        fn test_content_hash_is_hex() {
            let hash = generate_content_hash("Book", "Content");
            assert!(hash.chars().all(|c| c.is_ascii_hexdigit()));
            assert_eq!(hash.len(), 64); // SHA-256 produces 64 hex characters
        }
    }

    mod watcher_tests {
        use super::*;

        #[test]
        fn test_watcher_creation() {
            let watcher = watcher::KindleWatcher::new();
            assert!(!watcher.is_running());
        }

        #[test]
        fn test_watcher_custom_interval() {
            let watcher = watcher::KindleWatcher::with_interval(5000);
            assert!(!watcher.is_running());
        }
    }
}
