//! Vocabulary import module
//!
//! Handles importing vocabulary from Kindle's vocab.db

use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};
use uuid::Uuid;

fn get_parse_vocab_url() -> String {
    // Use compile-time value if available, fallback to runtime env
    let base_url = option_env!("SUPABASE_URL")
        .map(String::from)
        .or_else(|| std::env::var("SUPABASE_URL").ok())
        .unwrap_or_else(|| "https://vfeovvfpivbqeziwinwz.supabase.co".to_string());
    format!("{}/functions/v1/parse-vocab", base_url)
}

pub fn get_auth_token_from_env() -> Option<String> {
    // Use compile-time anon key, fallback to runtime env
    // Note: For authenticated requests, use user's session token instead
    option_env!("SUPABASE_ANON_KEY")
        .map(String::from)
        .or_else(|| std::env::var("SUPABASE_ANON_KEY").ok())
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

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub(crate) struct ImportHistory {
    sessions: Vec<ImportSession>,
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

fn get_history_path(app_data_dir: &Path) -> PathBuf {
    app_data_dir.join("import_history.json")
}

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

fn save_import_history(app_data_dir: &Path, history: &ImportHistory) -> Result<(), String> {
    let path = get_history_path(app_data_dir);
    let contents = serde_json::to_string_pretty(history)
        .map_err(|e| format!("Failed to serialize history: {}", e))?;
    fs::write(&path, contents)
        .map_err(|e| format!("Failed to write history: {}", e))?;
    Ok(())
}

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
    
    history.sessions.insert(0, session.clone());
    
    if history.sessions.len() > 50 {
        history.sessions.truncate(50);
    }
    
    save_import_history(app_data_dir, &history)?;
    
    Ok(session)
}

pub fn get_import_sessions(app_data_dir: &Path) -> Vec<ImportSession> {
    load_import_history(app_data_dir).sessions
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
    app_data_dir: Option<&Path>,
) -> Result<ImportResult, String> {
    let parsed = parse_vocab_on_server(base64_content, auth_token).await?;
    
    let result = ImportResult {
        total_parsed: parsed.total_parsed,
        imported: parsed.imported,
        skipped: parsed.skipped,
        books: parsed.books,
        error: parsed.errors.map(|e| e.join("; ")),
    };
    
    if let Some(dir) = app_data_dir {
        let _ = record_import_session(dir, &result);
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
