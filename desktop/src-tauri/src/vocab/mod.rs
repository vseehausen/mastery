//! Vocabulary import module
//!
//! Handles importing vocabulary from Kindle's vocab.db

use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;

fn get_parse_vocab_url() -> String {
    // Use compile-time value if available, fallback to runtime env
    let base_url = option_env!("SUPABASE_URL")
        .map(String::from)
        .or_else(|| std::env::var("SUPABASE_URL").ok())
        .unwrap_or_else(|| "https://vfeovvfpivbqeziwinwz.supabase.co".to_string());
    format!("{}/functions/v1/parse-vocab", base_url)
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ParseVocabResponse {
    pub total_parsed: i32,
    pub imported: i32,
    pub skipped: i32,
    pub books: i32,
    pub errors: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportResult {
    pub total_parsed: i32,
    pub imported: i32,
    pub skipped: i32,
    pub books: i32,
    pub error: Option<String>,
}

/// Database row from import_sessions table
#[derive(Debug, Clone, Deserialize)]
struct ImportSessionRow {
    id: String,
    started_at: Option<String>,
    #[allow(dead_code)]
    completed_at: Option<String>,
    #[allow(dead_code)]
    source: Option<String>,
    total_found: Option<i32>,
    imported: Option<i32>,
    skipped: Option<i32>,
    errors: Option<i32>,
}

/// Transformed import session for frontend
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportSession {
    pub id: String,
    pub timestamp: String,
    pub total_parsed: i32,
    pub imported: i32,
    pub skipped: i32,
    pub books: i32,
    pub status: String,
    pub error: Option<String>,
}

impl From<ImportSessionRow> for ImportSession {
    fn from(row: ImportSessionRow) -> Self {
        let has_errors = row.errors.unwrap_or(0) > 0;
        ImportSession {
            id: row.id,
            timestamp: row.started_at.unwrap_or_default(),
            total_parsed: row.total_found.unwrap_or(0),
            imported: row.imported.unwrap_or(0),
            skipped: row.skipped.unwrap_or(0),
            books: 0, // Not tracked in current schema
            status: if has_errors { "error".to_string() } else { "success".to_string() },
            error: if has_errors { Some(format!("{} errors", row.errors.unwrap_or(0))) } else { None },
        }
    }
}

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

fn get_dev_user_id() -> Option<String> {
    std::env::var("DEV_USER_ID").ok()
}

fn get_dev_secret() -> Option<String> {
    std::env::var("DEV_SECRET").ok()
}

pub async fn parse_vocab_on_server(
    base64_content: &str,
    auth_token: &str,
) -> Result<ParseVocabResponse, String> {
    let url = get_parse_vocab_url();
    let client = reqwest::Client::new();
    
    let body = if let Some(user_id) = get_dev_user_id() {
        serde_json::json!({
            "file": base64_content,
            "userId": user_id
        })
    } else {
        serde_json::json!({
            "file": base64_content
        })
    };
    
    let mut request = client
        .post(&url)
        .header("Authorization", format!("Bearer {}", auth_token))
        .header("Content-Type", "application/json");
    
    if let Some(dev_secret) = get_dev_secret() {
        request = request.header("X-Dev-Secret", dev_secret);
    }
    
    let response = request
        .json(&body)
        .send()
        .await
        .map_err(|e| format!("Network error: {}", e))?;
    
    let status = response.status();
    
    if !status.is_success() {
        let error_text = response.text().await.unwrap_or_default();
        return Err(format!("Server error {}: {}", status, error_text));
    }
    
    response
        .json()
        .await
        .map_err(|e| format!("Failed to parse response: {}", e))
}

fn get_supabase_url() -> String {
    option_env!("SUPABASE_URL")
        .map(String::from)
        .or_else(|| std::env::var("SUPABASE_URL").ok())
        .unwrap_or_else(|| "https://vfeovvfpivbqeziwinwz.supabase.co".to_string())
}

fn get_anon_key() -> String {
    option_env!("SUPABASE_ANON_KEY")
        .map(String::from)
        .or_else(|| std::env::var("SUPABASE_ANON_KEY").ok())
        .unwrap_or_default()
}

/// Fetch import sessions directly from Supabase database via PostgREST.
/// RLS ensures only the authenticated user's sessions are returned.
pub async fn fetch_import_sessions(auth_token: &str) -> Result<Vec<ImportSession>, String> {
    let url = format!(
        "{}/rest/v1/import_sessions?order=started_at.desc&limit=50",
        get_supabase_url()
    );
    let client = reqwest::Client::new();
    
    let response = client
        .get(&url)
        .header("Authorization", format!("Bearer {}", auth_token))
        .header("apikey", get_anon_key())
        .send()
        .await
        .map_err(|e| format!("Network error: {}", e))?;
    
    if !response.status().is_success() {
        let error_text = response.text().await.unwrap_or_default();
        return Err(format!("Failed to fetch import sessions: {}", error_text));
    }
    
    let rows: Vec<ImportSessionRow> = response
        .json()
        .await
        .map_err(|e| format!("Failed to parse response: {}", e))?;
    
    Ok(rows.into_iter().map(ImportSession::from).collect())
}

#[allow(dead_code)]
pub async fn import_vocabulary(
    vocab_db_path: &Path,
    auth_token: &str,
    app_data_dir: Option<&Path>,
) -> Result<ImportResult, String> {
    let base64_content = read_vocab_db_base64(vocab_db_path)?;
    import_vocabulary_base64(&base64_content, auth_token, app_data_dir).await
}

pub async fn import_vocabulary_from_bytes(
    vocab_data: &[u8],
    auth_token: &str,
    app_data_dir: Option<&Path>,
) -> Result<ImportResult, String> {
    let base64_content = BASE64.encode(vocab_data);
    import_vocabulary_base64(&base64_content, auth_token, app_data_dir).await
}

async fn import_vocabulary_base64(
    base64_content: &str,
    auth_token: &str,
    _app_data_dir: Option<&Path>,
) -> Result<ImportResult, String> {
    let parsed = parse_vocab_on_server(base64_content, auth_token).await?;
    
    Ok(ImportResult {
        total_parsed: parsed.total_parsed,
        imported: parsed.imported,
        skipped: parsed.skipped,
        books: parsed.books,
        error: parsed.errors.map(|e| e.join("; ")),
    })
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
