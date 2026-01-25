// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod kindle;

use kindle::{is_kindle_connected, sync_vocab_with_privileges, handle_sync_vocab_cli};

/// Get current Kindle connection status
#[tauri::command]
fn get_kindle_status() -> bool {
    is_kindle_connected()
}

/// Sync vocab.db from Kindle to app data directory
#[tauri::command]
async fn sync_kindle_vocab(app: tauri::AppHandle) -> Result<String, String> {
    use tauri::Manager;
    
    eprintln!("[main] sync_kindle_vocab called");
    
    let data_dir = app.path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app data dir: {}", e))?;
    
    eprintln!("[main] App data dir: {}", data_dir.display());
    
    std::fs::create_dir_all(&data_dir)
        .map_err(|e| e.to_string())?;
    
    let output_path = data_dir.join("vocab.db");
    eprintln!("[main] Output path: {}", output_path.display());
    
    sync_vocab_with_privileges(&output_path)
}

/// Get path to synced vocab.db if it exists
#[tauri::command]
fn get_vocab_db_path(app: tauri::AppHandle) -> Result<String, String> {
    use tauri::Manager;
    
    let data_dir = app.path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app data dir: {}", e))?;
    
    let vocab_path = data_dir.join("vocab.db");
    
    if vocab_path.exists() {
        Ok(vocab_path.to_string_lossy().to_string())
    } else {
        Err("vocab.db not synced yet".to_string())
    }
}

fn main() {
    // Check for CLI sync mode (called with admin privileges)
    let args: Vec<String> = std::env::args().collect();
    if args.len() >= 3 && args[1] == "--sync-vocab" {
        handle_sync_vocab_cli(&args[2]);
        return;
    }
    
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            get_kindle_status,
            sync_kindle_vocab,
            get_vocab_db_path
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
