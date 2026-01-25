//! Database schema definitions and data models
//!
//! Matches the mobile Drift schema for consistency.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Book entity representing a Kindle book
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Book {
    pub id: String,
    pub user_id: String,
    pub title: String,
    pub author: Option<String>,
    pub asin: Option<String>,
    pub language_id: String,
    pub source: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub deleted_at: Option<DateTime<Utc>>,
    pub version: i32,
    pub is_pending_sync: bool,
    pub last_synced_at: Option<DateTime<Utc>>,
}

impl Book {
    /// Create a new book with generated ID
    pub fn new(user_id: String, title: String, author: Option<String>) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4().to_string(),
            user_id,
            title,
            author,
            asin: None,
            language_id: "en".to_string(),
            source: "kindle".to_string(),
            created_at: now,
            updated_at: now,
            deleted_at: None,
            version: 1,
            is_pending_sync: true,
            last_synced_at: None,
        }
    }
}

/// Highlight entity representing a Kindle highlight or note
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Highlight {
    pub id: String,
    pub user_id: String,
    pub book_id: String,
    pub content: String,
    #[serde(rename = "type")]
    pub highlight_type: String,
    pub location: Option<String>,
    pub page: Option<i32>,
    pub kindle_date: Option<DateTime<Utc>>,
    pub note: Option<String>,
    pub content_hash: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub deleted_at: Option<DateTime<Utc>>,
    pub version: i32,
    pub is_pending_sync: bool,
    pub last_synced_at: Option<DateTime<Utc>>,
}

impl Highlight {
    /// Create a new highlight with generated ID
    pub fn new(
        user_id: String,
        book_id: String,
        content: String,
        highlight_type: String,
        content_hash: String,
    ) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4().to_string(),
            user_id,
            book_id,
            content,
            highlight_type,
            location: None,
            page: None,
            kindle_date: None,
            note: None,
            content_hash,
            created_at: now,
            updated_at: now,
            deleted_at: None,
            version: 1,
            is_pending_sync: true,
            last_synced_at: None,
        }
    }

    /// Set location metadata
    pub fn with_location(mut self, location: String) -> Self {
        self.location = Some(location);
        self
    }

    /// Set page number
    pub fn with_page(mut self, page: i32) -> Self {
        self.page = Some(page);
        self
    }

    /// Set Kindle date
    pub fn with_kindle_date(mut self, date: DateTime<Utc>) -> Self {
        self.kindle_date = Some(date);
        self
    }

    /// Set note
    pub fn with_note(mut self, note: String) -> Self {
        self.note = Some(note);
        self
    }
}

/// Import session record
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportSession {
    pub id: String,
    pub user_id: String,
    pub source: String,
    pub filename: Option<String>,
    pub device_name: Option<String>,
    pub total_found: i32,
    pub imported: i32,
    pub skipped: i32,
    pub errors: i32,
    pub error_details: Option<String>,
    pub started_at: DateTime<Utc>,
    pub completed_at: Option<DateTime<Utc>>,
}

impl ImportSession {
    /// Create a new import session
    pub fn new(user_id: String, source: String) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            user_id,
            source,
            filename: None,
            device_name: None,
            total_found: 0,
            imported: 0,
            skipped: 0,
            errors: 0,
            error_details: None,
            started_at: Utc::now(),
            completed_at: None,
        }
    }
}

/// Sync outbox entry for pending sync operations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncOutboxEntry {
    pub id: String,
    pub entity_table: String,
    pub record_id: String,
    pub operation: String,
    pub payload: String,
    pub created_at: DateTime<Utc>,
    pub retry_count: i32,
    pub last_error: Option<String>,
}

impl SyncOutboxEntry {
    /// Create a new sync outbox entry
    pub fn new(
        entity_table: String,
        record_id: String,
        operation: String,
        payload: String,
    ) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            entity_table,
            record_id,
            operation,
            payload,
            created_at: Utc::now(),
            retry_count: 0,
            last_error: None,
        }
    }
}

/// User preference key-value pair
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Preference {
    pub key: String,
    pub value: String,
    pub updated_at: DateTime<Utc>,
}

/// Sync state tracking
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncState {
    pub last_synced_at: Option<DateTime<Utc>>,
    pub last_sync_token: Option<String>,
}
