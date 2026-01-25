//! Highlights storage module for local SQLite database
//!
//! Provides CRUD operations and duplicate detection for highlights.

use super::schema::{Book, Highlight};
use super::Database;
use anyhow::Result;
use chrono::Utc;
use rusqlite::params;
use uuid::Uuid;

impl Database {
    // ============================================
    // Book operations
    // ============================================

    /// Find a book by title and author, or create if not exists
    pub fn find_or_create_book(
        &self,
        user_id: &str,
        title: &str,
        author: Option<&str>,
    ) -> Result<Book> {
        self.with_conn_mut(|conn| {
            // Try to find existing book
            let existing: Option<Book> = conn
                .query_row(
                    "SELECT id, user_id, title, author, asin, language_id, source,
                            created_at, updated_at, deleted_at, version, is_pending_sync, last_synced_at
                     FROM books
                     WHERE user_id = ? AND title = ? AND (author = ? OR (author IS NULL AND ? IS NULL))
                     AND deleted_at IS NULL",
                    params![user_id, title, author, author],
                    |row| {
                        Ok(Book {
                            id: row.get(0)?,
                            user_id: row.get(1)?,
                            title: row.get(2)?,
                            author: row.get(3)?,
                            asin: row.get(4)?,
                            language_id: row.get(5)?,
                            source: row.get(6)?,
                            created_at: row.get::<_, String>(7)?.parse().unwrap_or_else(|_| Utc::now()),
                            updated_at: row.get::<_, String>(8)?.parse().unwrap_or_else(|_| Utc::now()),
                            deleted_at: row.get::<_, Option<String>>(9)?.and_then(|s| s.parse().ok()),
                            version: row.get(10)?,
                            is_pending_sync: row.get::<_, i32>(11)? != 0,
                            last_synced_at: row.get::<_, Option<String>>(12)?.and_then(|s| s.parse().ok()),
                        })
                    },
                )
                .ok();

            if let Some(book) = existing {
                return Ok(book);
            }

            // Create new book
            let book = Book::new(user_id.to_string(), title.to_string(), author.map(String::from));
            let now = Utc::now().to_rfc3339();

            conn.execute(
                "INSERT INTO books (id, user_id, title, author, language_id, source, created_at, updated_at, version, is_pending_sync)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                params![
                    &book.id,
                    &book.user_id,
                    &book.title,
                    &book.author,
                    &book.language_id,
                    &book.source,
                    &now,
                    &now,
                    book.version,
                    book.is_pending_sync as i32,
                ],
            )?;

            Ok(book)
        })
    }

    /// Get a book by ID
    pub fn get_book(&self, book_id: &str) -> Result<Option<Book>> {
        self.with_conn(|conn| {
            let book = conn
                .query_row(
                    "SELECT id, user_id, title, author, asin, language_id, source,
                            created_at, updated_at, deleted_at, version, is_pending_sync, last_synced_at
                     FROM books WHERE id = ?",
                    params![book_id],
                    |row| {
                        Ok(Book {
                            id: row.get(0)?,
                            user_id: row.get(1)?,
                            title: row.get(2)?,
                            author: row.get(3)?,
                            asin: row.get(4)?,
                            language_id: row.get(5)?,
                            source: row.get(6)?,
                            created_at: row.get::<_, String>(7)?.parse().unwrap_or_else(|_| Utc::now()),
                            updated_at: row.get::<_, String>(8)?.parse().unwrap_or_else(|_| Utc::now()),
                            deleted_at: row.get::<_, Option<String>>(9)?.and_then(|s| s.parse().ok()),
                            version: row.get(10)?,
                            is_pending_sync: row.get::<_, i32>(11)? != 0,
                            last_synced_at: row.get::<_, Option<String>>(12)?.and_then(|s| s.parse().ok()),
                        })
                    },
                )
                .ok();
            Ok(book)
        })
    }

    // ============================================
    // Highlight operations
    // ============================================

    /// Check if a highlight exists by content hash (duplicate detection)
    pub fn highlight_exists_by_hash(&self, user_id: &str, content_hash: &str) -> Result<bool> {
        self.with_conn(|conn| {
            let count: i32 = conn.query_row(
                "SELECT COUNT(*) FROM highlights
                 WHERE user_id = ? AND content_hash = ? AND deleted_at IS NULL",
                params![user_id, content_hash],
                |row| row.get(0),
            )?;
            Ok(count > 0)
        })
    }

    /// Create a new highlight
    pub fn create_highlight(&self, highlight: &Highlight) -> Result<()> {
        self.with_conn(|conn| {
            let now = Utc::now().to_rfc3339();
            let kindle_date = highlight.kindle_date.map(|d| d.to_rfc3339());

            conn.execute(
                "INSERT INTO highlights (
                    id, user_id, book_id, content, type, location, page, kindle_date, note,
                    content_hash, created_at, updated_at, version, is_pending_sync
                 ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                params![
                    &highlight.id,
                    &highlight.user_id,
                    &highlight.book_id,
                    &highlight.content,
                    &highlight.highlight_type,
                    &highlight.location,
                    highlight.page,
                    kindle_date,
                    &highlight.note,
                    &highlight.content_hash,
                    &now,
                    &now,
                    highlight.version,
                    highlight.is_pending_sync as i32,
                ],
            )?;
            Ok(())
        })
    }

    /// Get all highlights for a book
    pub fn get_highlights_for_book(&self, book_id: &str) -> Result<Vec<Highlight>> {
        self.with_conn(|conn| {
            let mut stmt = conn.prepare(
                "SELECT id, user_id, book_id, content, type, location, page, kindle_date, note,
                        content_hash, created_at, updated_at, deleted_at, version, is_pending_sync, last_synced_at
                 FROM highlights
                 WHERE book_id = ? AND deleted_at IS NULL
                 ORDER BY page ASC, location ASC",
            )?;

            let highlights = stmt
                .query_map(params![book_id], |row| {
                    Ok(Highlight {
                        id: row.get(0)?,
                        user_id: row.get(1)?,
                        book_id: row.get(2)?,
                        content: row.get(3)?,
                        highlight_type: row.get(4)?,
                        location: row.get(5)?,
                        page: row.get(6)?,
                        kindle_date: row.get::<_, Option<String>>(7)?.and_then(|s| s.parse().ok()),
                        note: row.get(8)?,
                        content_hash: row.get(9)?,
                        created_at: row.get::<_, String>(10)?.parse().unwrap_or_else(|_| Utc::now()),
                        updated_at: row.get::<_, String>(11)?.parse().unwrap_or_else(|_| Utc::now()),
                        deleted_at: row.get::<_, Option<String>>(12)?.and_then(|s| s.parse().ok()),
                        version: row.get(13)?,
                        is_pending_sync: row.get::<_, i32>(14)? != 0,
                        last_synced_at: row.get::<_, Option<String>>(15)?.and_then(|s| s.parse().ok()),
                    })
                })?
                .filter_map(|r| r.ok())
                .collect();

            Ok(highlights)
        })
    }

    /// Get all highlights pending sync
    pub fn get_pending_sync_highlights(&self, user_id: &str) -> Result<Vec<Highlight>> {
        self.with_conn(|conn| {
            let mut stmt = conn.prepare(
                "SELECT id, user_id, book_id, content, type, location, page, kindle_date, note,
                        content_hash, created_at, updated_at, deleted_at, version, is_pending_sync, last_synced_at
                 FROM highlights
                 WHERE user_id = ? AND is_pending_sync = 1",
            )?;

            let highlights = stmt
                .query_map(params![user_id], |row| {
                    Ok(Highlight {
                        id: row.get(0)?,
                        user_id: row.get(1)?,
                        book_id: row.get(2)?,
                        content: row.get(3)?,
                        highlight_type: row.get(4)?,
                        location: row.get(5)?,
                        page: row.get(6)?,
                        kindle_date: row.get::<_, Option<String>>(7)?.and_then(|s| s.parse().ok()),
                        note: row.get(8)?,
                        content_hash: row.get(9)?,
                        created_at: row.get::<_, String>(10)?.parse().unwrap_or_else(|_| Utc::now()),
                        updated_at: row.get::<_, String>(11)?.parse().unwrap_or_else(|_| Utc::now()),
                        deleted_at: row.get::<_, Option<String>>(12)?.and_then(|s| s.parse().ok()),
                        version: row.get(13)?,
                        is_pending_sync: row.get::<_, i32>(14)? != 0,
                        last_synced_at: row.get::<_, Option<String>>(15)?.and_then(|s| s.parse().ok()),
                    })
                })?
                .filter_map(|r| r.ok())
                .collect();

            Ok(highlights)
        })
    }

    /// Mark a highlight as synced
    pub fn mark_highlight_synced(&self, highlight_id: &str) -> Result<()> {
        self.with_conn(|conn| {
            let now = Utc::now().to_rfc3339();
            conn.execute(
                "UPDATE highlights SET is_pending_sync = 0, last_synced_at = ? WHERE id = ?",
                params![now, highlight_id],
            )?;
            Ok(())
        })
    }

    /// Soft delete a highlight
    pub fn soft_delete_highlight(&self, highlight_id: &str) -> Result<()> {
        self.with_conn(|conn| {
            let now = Utc::now().to_rfc3339();
            conn.execute(
                "UPDATE highlights SET deleted_at = ?, updated_at = ?, is_pending_sync = 1 WHERE id = ?",
                params![now, now, highlight_id],
            )?;
            Ok(())
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_and_find_book() {
        let db = Database::in_memory().unwrap();
        let user_id = "test-user";
        let title = "Test Book";
        let author = Some("Test Author");

        // Create book
        let book = db.find_or_create_book(user_id, title, author).unwrap();
        assert_eq!(book.title, title);
        assert_eq!(book.author, author.map(String::from));

        // Find existing book
        let found = db.find_or_create_book(user_id, title, author).unwrap();
        assert_eq!(book.id, found.id);
    }

    #[test]
    fn test_highlight_duplicate_detection() {
        let db = Database::in_memory().unwrap();
        let user_id = "test-user";
        let content_hash = "abc123";

        // Should not exist initially
        assert!(!db.highlight_exists_by_hash(user_id, content_hash).unwrap());

        // Create a highlight
        let book = db.find_or_create_book(user_id, "Book", None).unwrap();
        let highlight = Highlight::new(
            user_id.to_string(),
            book.id.clone(),
            "Content".to_string(),
            "highlight".to_string(),
            content_hash.to_string(),
        );
        db.create_highlight(&highlight).unwrap();

        // Should exist now
        assert!(db.highlight_exists_by_hash(user_id, content_hash).unwrap());
    }
}
