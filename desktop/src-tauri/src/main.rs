// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod kindle;

use kindle::{get_kindle_status, KindleStatus, read_vocab_db_content, handle_sync_vocab_cli};
use tauri::Emitter;

#[tauri::command]
fn check_kindle_status() -> KindleStatus {
    get_kindle_status()
}

#[tauri::command]
fn read_kindle_vocab_db() -> Result<Vec<u8>, String> {
    read_vocab_db_content()
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() >= 3 && args[1] == "--sync-vocab" {
        handle_sync_vocab_cli(&args[2]);
        return;
    }
    
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_deep_link::init())
        .setup(|app| {
            #[cfg(any(target_os = "linux", target_os = "windows", target_os = "macos"))]
            {
                use tauri_plugin_deep_link::DeepLinkExt;
                let handle = app.handle().clone();
                app.deep_link().on_open_url(move |event| {
                    for url in event.urls() {
                        let url_str = url.to_string();
                        if url_str.starts_with("mastery://auth/callback") {
                            let _ = handle.emit("oauth-callback", url_str);
                        }
                    }
                });
            }
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            check_kindle_status,
            read_kindle_vocab_db,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
