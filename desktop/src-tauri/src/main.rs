// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod kindle;

use kindle::{is_kindle_connected, get_clippings_info as get_clippings_info_impl, read_clippings as read_clippings_impl, count_clippings as count_clippings_impl};

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

/// Read the entire clippings file content
#[tauri::command]
fn read_clippings() -> Result<String, String> {
    read_clippings_impl()
}

/// Count highlights in clippings content
#[tauri::command]
fn count_clippings(content: String) -> usize {
    count_clippings_impl(&content)
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            get_kindle_status,
            get_clippings_info,
            read_clippings,
            count_clippings
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
