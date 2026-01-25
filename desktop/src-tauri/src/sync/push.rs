//! Sync push module for pushing local changes to Supabase
//!
//! Handles pushing pending highlights and books to the cloud.

use super::auth::SupabaseAuth;
use super::SyncResult;
use crate::db::{Database, Highlight, Book};
use anyhow::Result;
use serde::{Deserialize, Serialize};

/// Request body for sync push
#[derive(Debug, Serialize)]
struct SyncPushRequest {
    highlights: Vec<HighlightPayload>,
    books: Vec<BookPayload>,
}

/// Highlight payload for sync
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct HighlightPayload {
    id: String,
    book_id: String,
    content: String,
    #[serde(rename = "type")]
    highlight_type: String,
    location: Option<String>,
    page: Option<i32>,
    kindle_date: Option<String>,
    note: Option<String>,
    content_hash: String,
    version: i32,
}

/// Book payload for sync
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct BookPayload {
    id: String,
    title: String,
    author: Option<String>,
    asin: Option<String>,
    language_id: String,
    source: String,
    version: i32,
}

/// Response from sync push
#[derive(Debug, Deserialize)]
struct SyncPushResponse {
    synced: i32,
    errors: Vec<String>,
}

/// Push pending changes to Supabase
pub async fn push_changes(db: &Database, auth: &SupabaseAuth) -> Result<SyncResult> {
    let user_id = auth.get_user_id().await
        .ok_or_else(|| anyhow::anyhow!("Not authenticated"))?;

    // Get pending highlights
    let pending_highlights = db.get_pending_sync_highlights(&user_id)?;

    if pending_highlights.is_empty() {
        return Ok(SyncResult::empty());
    }

    // Convert to payloads
    let highlight_payloads: Vec<HighlightPayload> = pending_highlights
        .iter()
        .map(|h| HighlightPayload {
            id: h.id.clone(),
            book_id: h.book_id.clone(),
            content: h.content.clone(),
            highlight_type: h.highlight_type.clone(),
            location: h.location.clone(),
            page: h.page,
            kindle_date: h.kindle_date.map(|d| d.to_rfc3339()),
            note: h.note.clone(),
            content_hash: h.content_hash.clone(),
            version: h.version,
        })
        .collect();

    // Build request
    let request = SyncPushRequest {
        highlights: highlight_payloads,
        books: Vec::new(), // Books are synced separately
    };

    // Call sync/push Edge Function
    let response: SyncPushResponse = auth
        .call_function("sync/push", reqwest::Method::POST, Some(&request))
        .await?;

    // Mark synced highlights
    for highlight in &pending_highlights {
        if !response.errors.iter().any(|e| e.contains(&highlight.id)) {
            db.mark_highlight_synced(&highlight.id)?;
        }
    }

    Ok(SyncResult {
        pushed: response.synced,
        pulled: 0,
        errors: response.errors,
    })
}

/// Push a single highlight immediately
pub async fn push_highlight(db: &Database, auth: &SupabaseAuth, highlight: &Highlight) -> Result<()> {
    let payload = HighlightPayload {
        id: highlight.id.clone(),
        book_id: highlight.book_id.clone(),
        content: highlight.content.clone(),
        highlight_type: highlight.highlight_type.clone(),
        location: highlight.location.clone(),
        page: highlight.page,
        kindle_date: highlight.kindle_date.map(|d| d.to_rfc3339()),
        note: highlight.note.clone(),
        content_hash: highlight.content_hash.clone(),
        version: highlight.version,
    };

    let request = SyncPushRequest {
        highlights: vec![payload],
        books: Vec::new(),
    };

    let _response: SyncPushResponse = auth
        .call_function("sync/push", reqwest::Method::POST, Some(&request))
        .await?;

    db.mark_highlight_synced(&highlight.id)?;

    Ok(())
}

/// Push a book to sync
pub async fn push_book(auth: &SupabaseAuth, book: &Book) -> Result<()> {
    let payload = BookPayload {
        id: book.id.clone(),
        title: book.title.clone(),
        author: book.author.clone(),
        asin: book.asin.clone(),
        language_id: book.language_id.clone(),
        source: book.source.clone(),
        version: book.version,
    };

    let request = SyncPushRequest {
        highlights: Vec::new(),
        books: vec![payload],
    };

    let _response: SyncPushResponse = auth
        .call_function("sync/push", reqwest::Method::POST, Some(&request))
        .await?;

    Ok(())
}
