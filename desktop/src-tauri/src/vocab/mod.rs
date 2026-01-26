//! Vocabulary import module
//!
//! Handles importing vocabulary from Kindle's vocab.db by:
//! 1. Reading the local vocab.db file
//! 2. Sending to server for parsing
//! 3. Returning parsed vocabulary entries

use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};
use uuid::Uuid;

/// Get the parse-vocab function URL from environment or use default
fn get_parse_vocab_url() -> String {
    if let Ok(url) = std::env::var("SUPABASE_URL") {
        format!("{}/functions/v1/parse-vocab", url)
    } else {
        "https://vfeovvfpivbqeziwinwz.supabase.co/functions/v1/parse-vocab".to_string()
    }
}

/// Get auth token from environment (service role key for dev, user JWT for production)
pub fn get_auth_token_from_env() -> Option<String> {
    // Try service role key first (for development)
    if let Ok(key) = std::env::var("SUPABASE_SERVICE_ROLE_KEY") {
        if key != "your-service-role-key" {
            return Some(key);
        }
    }
    // Fall back to anon key
    std::env::var("SUPABASE_ANON_KEY").ok()
}

/// Response from parse-vocab Edge Function
#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ParseVocabResponse {
    pub total_parsed: i32,
    pub imported: i32,
    pub skipped: i32,
    pub books: i32,
    pub errors: Option<Vec<String>>,
}

/// Result of vocabulary import
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportResult {
    pub total_parsed: i32,
    pub imported: i32,
    pub skipped: i32,
    pub books: i32,
    pub error: Option<String>,
}

/// Import session record
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

/// Import history storage
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
struct ImportHistory {
    sessions: Vec<ImportSession>,
}

fn log(msg: &str) {
    eprintln!("[vocab] {}", msg);
}

/// Read vocab.db file and encode as base64
#[allow(dead_code)]
pub fn read_vocab_db_base64(path: &Path) -> Result<String, String> {
    log(&format!("Reading vocab.db from: {}", path.display()));
    
    if !path.exists() {
        return Err("vocab.db file not found".to_string());
    }
    
    let contents = fs::read(path)
        .map_err(|e| format!("Failed to read vocab.db: {}", e))?;
    
    log(&format!("Read {} bytes", contents.len()));
    
    // Check file size (max 6MB for Edge Function)
    if contents.len() > 6 * 1024 * 1024 {
        return Err("vocab.db file too large (max 6MB)".to_string());
    }
    
    Ok(BASE64.encode(&contents))
}

/// Get test user ID for development
fn get_dev_user_id() -> Option<String> {
    std::env::var("DEV_USER_ID").ok()
}

/// Get dev secret for development testing
fn get_dev_secret() -> Option<String> {
    std::env::var("DEV_SECRET").ok()
}

/// Send vocab.db to server for parsing
pub async fn parse_vocab_on_server(
    base64_content: &str,
    auth_token: &str,
) -> Result<ParseVocabResponse, String> {
    let url = get_parse_vocab_url();
    log(&format!("Sending vocab.db to server: {}", url));
    
    let client = reqwest::Client::new();
    
    // Build request body - include userId for dev testing
    let body = if let Some(user_id) = get_dev_user_id() {
        log(&format!("Using dev user ID: {}", user_id));
        serde_json::json!({
            "file": base64_content,
            "userId": user_id
        })
    } else {
        serde_json::json!({
            "file": base64_content
        })
    };
    
    // Build request with optional dev secret header
    let mut request = client
        .post(&url)
        .header("Authorization", format!("Bearer {}", auth_token))
        .header("Content-Type", "application/json");
    
    if let Some(dev_secret) = get_dev_secret() {
        log("Adding X-Dev-Secret header for dev mode");
        request = request.header("X-Dev-Secret", dev_secret);
    }
    
    let response = request
        .json(&body)
        .send()
        .await
        .map_err(|e| format!("Network error: {}", e))?;
    
    let status = response.status();
    log(&format!("Server response status: {}", status));
    
    if !status.is_success() {
        let error_text = response.text().await.unwrap_or_default();
        return Err(format!("Server error {}: {}", status, error_text));
    }
    
    let result: ParseVocabResponse = response
        .json()
        .await
        .map_err(|e| format!("Failed to parse response: {}", e))?;
    
    log(&format!("Parsed {} vocabulary entries", result.total_parsed));
    
    Ok(result)
}

/// Get the path to import history file
fn get_history_path(app_data_dir: &Path) -> PathBuf {
    app_data_dir.join("import_history.json")
}

/// Load import history from file
pub fn load_import_history(app_data_dir: &Path) -> ImportHistory {
    let path = get_history_path(app_data_dir);
    if path.exists() {
        if let Ok(contents) = fs::read_to_string(&path) {
            if let Ok(history) = serde_json::from_str(&contents) {
                return history;
            }
        }
    }
    ImportHistory::default()
}

/// Save import history to file
fn save_import_history(app_data_dir: &Path, history: &ImportHistory) -> Result<(), String> {
    let path = get_history_path(app_data_dir);
    let contents = serde_json::to_string_pretty(history)
        .map_err(|e| format!("Failed to serialize history: {}", e))?;
    fs::write(&path, contents)
        .map_err(|e| format!("Failed to write history: {}", e))?;
    Ok(())
}

/// Record an import session
pub fn record_import_session(
    app_data_dir: &Path,
    result: &ImportResult,
) -> Result<ImportSession, String> {
    let mut history = load_import_history(app_data_dir);
    
    let session = ImportSession {
        id: Uuid::new_v4().to_string(),
        timestamp: Utc::now().to_rfc3339(),
        total_parsed: result.total_parsed,
        imported: result.imported,
        skipped: result.skipped,
        books: result.books,
        status: if result.error.is_some() { "error".to_string() } else { "success".to_string() },
        error: result.error.clone(),
    };
    
    // Add to history (newest first)
    history.sessions.insert(0, session.clone());
    
    // Keep only last 50 sessions
    if history.sessions.len() > 50 {
        history.sessions.truncate(50);
    }
    
    save_import_history(app_data_dir, &history)?;
    
    Ok(session)
}

/// Get import history (most recent first)
pub fn get_import_sessions(app_data_dir: &Path) -> Vec<ImportSession> {
    load_import_history(app_data_dir).sessions
}

/// Import vocabulary from vocab.db file path
#[allow(dead_code)]
pub async fn import_vocabulary(
    vocab_db_path: &Path,
    auth_token: &str,
    app_data_dir: Option<&Path>,
) -> Result<ImportResult, String> {
    let base64_content = read_vocab_db_base64(vocab_db_path)?;
    import_vocabulary_base64(&base64_content, auth_token, app_data_dir).await
}

/// Import vocabulary from raw bytes (no file needed)
pub async fn import_vocabulary_from_bytes(
    vocab_data: &[u8],
    auth_token: &str,
    app_data_dir: Option<&Path>,
) -> Result<ImportResult, String> {
    log(&format!("Encoding {} bytes as base64", vocab_data.len()));
    let base64_content = BASE64.encode(vocab_data);
    import_vocabulary_base64(&base64_content, auth_token, app_data_dir).await
}

/// Import vocabulary from base64-encoded content
async fn import_vocabulary_base64(
    base64_content: &str,
    auth_token: &str,
    app_data_dir: Option<&Path>,
) -> Result<ImportResult, String> {
    // Parse on server and store directly in database
    let parsed = parse_vocab_on_server(base64_content, auth_token).await?;
    
    let result = ImportResult {
        total_parsed: parsed.total_parsed,
        imported: parsed.imported,
        skipped: parsed.skipped,
        books: parsed.books,
        error: parsed.errors.map(|e| e.join("; ")),
    };
    
    // Record import session if app_data_dir provided
    if let Some(dir) = app_data_dir {
        if let Err(e) = record_import_session(dir, &result) {
            log(&format!("Failed to record import session: {}", e));
        }
    }
    
    Ok(result)
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
