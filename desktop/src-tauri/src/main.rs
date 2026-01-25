// Mastery Desktop Agent
// Handles automatic Kindle device detection and highlight import

#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod db;
mod kindle;
mod sync;

use db::Database;
use kindle::{find_kindle_mount, is_kindle_connected, read_clippings, parse_clippings, generate_content_hash};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tauri::State;
use tokio::sync::Mutex;

/// Application state shared across commands
struct AppState {
    db: Arc<Mutex<Option<Database>>>,
    monitoring: Arc<std::sync::atomic::AtomicBool>,
}

/// Kindle device status
#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct KindleStatus {
    connected: bool,
    mount_point: Option<String>,
    clippings_size: Option<u64>,
}

/// Import result from manual trigger
#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct ImportResult {
    total_found: usize,
    imported: usize,
    skipped: usize,
    errors: usize,
}

/// Get current Kindle device status
#[tauri::command]
async fn get_kindle_status() -> Result<KindleStatus, String> {
    let connected = is_kindle_connected();

    if !connected {
        return Ok(KindleStatus {
            connected: false,
            mount_point: None,
            clippings_size: None,
        });
    }

    let mount_point = find_kindle_mount().ok();
    let clippings_size = mount_point.as_ref().and_then(|mp| {
        kindle::get_clippings_metadata(mp).ok().map(|m| m.size)
    });

    Ok(KindleStatus {
        connected,
        mount_point: mount_point.map(|p| p.to_string_lossy().to_string()),
        clippings_size,
    })
}

/// Start monitoring for Kindle device connection
#[tauri::command]
async fn start_monitoring(state: State<'_, AppState>) -> Result<(), String> {
    state.monitoring.store(true, std::sync::atomic::Ordering::SeqCst);
    Ok(())
}

/// Stop monitoring for Kindle device connection
#[tauri::command]
async fn stop_monitoring(state: State<'_, AppState>) -> Result<(), String> {
    state.monitoring.store(false, std::sync::atomic::Ordering::SeqCst);
    Ok(())
}

/// Manually trigger import from connected Kindle
#[tauri::command]
async fn trigger_import(state: State<'_, AppState>) -> Result<ImportResult, String> {
    // Check if Kindle is connected
    if !is_kindle_connected() {
        return Err("Kindle not connected".to_string());
    }

    // Find mount point
    let mount_point = find_kindle_mount().map_err(|e| e.to_string())?;

    // Read clippings
    let content = read_clippings(&mount_point).map_err(|e| e.to_string())?;

    // Parse clippings
    let parsed = parse_clippings(&content).map_err(|e| e.to_string())?;
    let total_found = parsed.len();

    // Get database
    let db_guard = state.db.lock().await;
    let db = db_guard.as_ref().ok_or("Database not initialized")?;

    // Get user ID from preferences
    let user_id = db.get_user_id()
        .map_err(|e| e.to_string())?
        .ok_or("Not logged in")?;

    let mut imported = 0;
    let mut skipped = 0;
    let mut errors = 0;

    for highlight in parsed {
        // Generate content hash
        let content_hash = generate_content_hash(&highlight.book_title, &highlight.content);

        // Check for duplicate
        match db.highlight_exists_by_hash(&user_id, &content_hash) {
            Ok(true) => {
                skipped += 1;
                continue;
            }
            Ok(false) => {}
            Err(_) => {
                errors += 1;
                continue;
            }
        }

        // Find or create book
        let book = match db.find_or_create_book(&user_id, &highlight.book_title, highlight.author.as_deref()) {
            Ok(b) => b,
            Err(_) => {
                errors += 1;
                continue;
            }
        };

        // Create highlight
        let db_highlight = db::Highlight::new(
            user_id.clone(),
            book.id.clone(),
            highlight.content.clone(),
            format!("{:?}", highlight.highlight_type).to_lowercase(),
            content_hash,
        );

        match db.create_highlight(&db_highlight) {
            Ok(()) => imported += 1,
            Err(_) => errors += 1,
        }
    }

    Ok(ImportResult {
        total_found,
        imported,
        skipped,
        errors,
    })
}

/// Get auto-import setting
#[tauri::command]
async fn get_auto_import_enabled(state: State<'_, AppState>) -> Result<bool, String> {
    let db_guard = state.db.lock().await;
    let db = db_guard.as_ref().ok_or("Database not initialized")?;
    db.is_auto_import_enabled().map_err(|e| e.to_string())
}

/// Set auto-import setting
#[tauri::command]
async fn set_auto_import_enabled(state: State<'_, AppState>, enabled: bool) -> Result<(), String> {
    let db_guard = state.db.lock().await;
    let db = db_guard.as_ref().ok_or("Database not initialized")?;
    db.set_auto_import_enabled(enabled).map_err(|e| e.to_string())
}

fn main() {
    // Initialize database
    let db_path = db::default_db_path();
    let db = match Database::new(db_path) {
        Ok(d) => Some(d),
        Err(e) => {
            eprintln!("Failed to initialize database: {}", e);
            None
        }
    };

    let state = AppState {
        db: Arc::new(Mutex::new(db)),
        monitoring: Arc::new(std::sync::atomic::AtomicBool::new(false)),
    };

    let result = tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .manage(state)
        .invoke_handler(tauri::generate_handler![
            get_kindle_status,
            start_monitoring,
            stop_monitoring,
            trigger_import,
            get_auto_import_enabled,
            set_auto_import_enabled,
        ])
        .run(tauri::generate_context!());

    if let Err(e) = result {
        eprintln!("Tauri error: {}", e);
        std::process::exit(1);
    }
}
