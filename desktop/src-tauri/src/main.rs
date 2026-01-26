// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod kindle;
mod vocab;

use kindle::{get_kindle_status, KindleStatus, read_vocab_db_content, handle_sync_vocab_cli};
use vocab::ImportResult;

/// Load .env file from project root (for development)
fn load_env() {
    let mut current_dir = std::env::current_dir().ok();
    
    while let Some(dir) = current_dir {
        let env_path = dir.join(".env");
        if env_path.exists() {
            if dotenvy::from_path(&env_path).is_ok() {
                eprintln!("[main] Loaded .env from: {}", env_path.display());
                return;
            }
        }
        current_dir = dir.parent().map(|p| p.to_path_buf());
    }
    
    let _ = dotenvy::dotenv();
}

/// Check Kindle connection status (for polling)
#[tauri::command]
fn check_kindle_status() -> KindleStatus {
    get_kindle_status()
}

/// Import vocabulary directly from Kindle
/// Single step: reads from Kindle → uploads to server → returns results
#[tauri::command]
async fn import_from_kindle(app: tauri::AppHandle) -> Result<ImportResult, String> {
    use tauri::Manager;
    
    eprintln!("[main] import_from_kindle called");
    
    // Get auth token from environment
    let token = vocab::get_auth_token_from_env()
        .ok_or_else(|| "No auth token found in environment".to_string())?;
    
    eprintln!("[main] Using auth token: {}...", &token[..token.len().min(20)]);
    
    // Read vocab.db directly from Kindle
    eprintln!("[main] Reading vocab.db from Kindle...");
    let vocab_data = read_vocab_db_content()?;
    eprintln!("[main] Read {} bytes from Kindle", vocab_data.len());
    
    // Get app data dir for recording import history
    let data_dir = app.path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app data dir: {}", e))?;
    
    std::fs::create_dir_all(&data_dir)
        .map_err(|e| e.to_string())?;
    
    // Upload to server for parsing
    vocab::import_vocabulary_from_bytes(&vocab_data, &token, Some(&data_dir)).await
}

/// Get import history
#[tauri::command]
fn get_import_history(app: tauri::AppHandle) -> Vec<vocab::ImportSession> {
    use tauri::Manager;
    
    let data_dir = match app.path().app_data_dir() {
        Ok(dir) => dir,
        Err(_) => return Vec::new(),
    };
    
    vocab::get_import_sessions(&data_dir)
}

fn main() {
    load_env();
    
    // Check for CLI sync mode (called with admin privileges for MTP)
    let args: Vec<String> = std::env::args().collect();
    if args.len() >= 3 && args[1] == "--sync-vocab" {
        handle_sync_vocab_cli(&args[2]);
        return;
    }
    
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            check_kindle_status,
            import_from_kindle,
            get_import_history,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
