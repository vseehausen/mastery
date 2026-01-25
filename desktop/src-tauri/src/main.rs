// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod kindle;

use kindle::{is_kindle_connected, get_clippings_info as get_clippings_info_impl};

/// Get current Kindle connection status
#[tauri::command]
fn get_kindle_status() -> bool {
    is_kindle_connected()
}

/// Get clippings file information (path and size in bytes)
#[tauri::command]
fn get_clippings_info() -> Result<(String, u64), String> {
    get_clippings_info_impl()
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![get_kindle_status])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
