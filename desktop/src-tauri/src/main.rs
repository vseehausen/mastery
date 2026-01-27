// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod kindle;
mod vocab;
mod auth;

use kindle::{get_kindle_status, KindleStatus, read_vocab_db_content, handle_sync_vocab_cli};
use vocab::ImportResult;
use auth::{AuthResponse, User, OAuthUrlResponse};
use std::sync::Mutex;
use tauri::{Manager, Emitter};

fn load_env() {
    // 1. Check near the executable (for bundled app)
    if let Ok(exe_path) = std::env::current_exe() {
        // On macOS, exe is at Mastery.app/Contents/MacOS/desktop
        // Check Mastery.app/Contents/Resources/.env
        if let Some(exe_dir) = exe_path.parent() {
            let resources_env = exe_dir.parent()
                .map(|p| p.join("Resources").join(".env"));
            if let Some(env_path) = resources_env {
                if env_path.exists() && dotenvy::from_path(&env_path).is_ok() {
                    return;
                }
            }
            // Also check next to executable
            let exe_env = exe_dir.join(".env");
            if exe_env.exists() && dotenvy::from_path(&exe_env).is_ok() {
                return;
            }
        }
    }

    // 2. Check project root (for dev mode)
    let project_root = std::env::current_dir()
        .ok()
        .and_then(|d| {
            let mut path = d;
            while path.file_name().map(|n| n != "mastery").unwrap_or(false) {
                if let Some(parent) = path.parent() {
                    path = parent.to_path_buf();
                } else {
                    break;
                }
            }
            Some(path)
        });
    
    if let Some(root) = project_root {
        let root_env = root.join(".env");
        if root_env.exists() && dotenvy::from_path(&root_env).is_ok() {
            return;
        }
    }
    
    // 3. Walk up from current directory
    let mut current_dir = std::env::current_dir().ok();
    while let Some(dir) = current_dir {
        let env_path = dir.join(".env");
        if env_path.exists() && dotenvy::from_path(&env_path).is_ok() {
            return;
        }
        current_dir = dir.parent().map(|p| p.to_path_buf());
    }
    
    // 4. Default dotenv behavior
    let _ = dotenvy::dotenv();
}

#[tauri::command]
fn check_kindle_status() -> KindleStatus {
    get_kindle_status()
}

#[tauri::command]
async fn import_from_kindle(app: tauri::AppHandle) -> Result<ImportResult, String> {
    let token = vocab::get_auth_token_from_env()
        .ok_or_else(|| "No auth token found in environment".to_string())?;
    
    let vocab_data = read_vocab_db_content()?;
    
    let data_dir = app.path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app data dir: {}", e))?;
    
    std::fs::create_dir_all(&data_dir).map_err(|e| e.to_string())?;
    
    vocab::import_vocabulary_from_bytes(&vocab_data, &token, Some(&data_dir)).await
}

#[tauri::command]
fn get_import_history(app: tauri::AppHandle) -> Vec<vocab::ImportSession> {
    let data_dir = match app.path().app_data_dir() {
        Ok(dir) => dir,
        Err(_) => return Vec::new(),
    };
    vocab::get_import_sessions(&data_dir)
}

#[tauri::command]
async fn auth_sign_up_with_email(
    app: tauri::AppHandle,
    email: String,
    password: String,
) -> Result<AuthResponse, String> {
    let data_dir = app.path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app data dir: {}", e))?;
    
    let auth = auth::SupabaseAuth::new(&data_dir);
    auth.sign_up_with_email(&email, &password)
        .await
        .map_err(|e| e.to_string())
}

#[tauri::command]
async fn auth_sign_in_with_email(
    app: tauri::AppHandle,
    email: String,
    password: String,
) -> Result<AuthResponse, String> {
    let data_dir = app.path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app data dir: {}", e))?;
    
    let auth = auth::SupabaseAuth::new(&data_dir);
    auth.sign_in_with_email(&email, &password)
        .await
        .map_err(|e| e.to_string())
}

#[tauri::command]
fn auth_sign_out(app: tauri::AppHandle) -> Result<(), String> {
    let data_dir = app.path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app data dir: {}", e))?;
    
    let auth = auth::SupabaseAuth::new(&data_dir);
    auth.sign_out().map_err(|e| e.to_string())
}

#[tauri::command]
fn auth_get_session(app: tauri::AppHandle) -> Option<auth::AuthSession> {
    let data_dir = app.path().app_data_dir().ok()?;
    let auth = auth::SupabaseAuth::new(&data_dir);
    auth.load_session()
}

#[tauri::command]
fn auth_get_current_user(app: tauri::AppHandle) -> Option<User> {
    let data_dir = app.path().app_data_dir().ok()?;
    let auth = auth::SupabaseAuth::new(&data_dir);
    auth.get_current_user()
}

#[tauri::command]
fn auth_get_oauth_url(app: tauri::AppHandle, provider: String) -> Result<OAuthUrlResponse, String> {
    let data_dir = app.path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app data dir: {}", e))?;
    
    let auth = auth::SupabaseAuth::new(&data_dir);
    auth.get_oauth_url(&provider).map_err(|e| e.to_string())
}

#[tauri::command]
async fn auth_handle_oauth_callback(
    app: tauri::AppHandle,
    callback_url: String,
) -> Result<AuthResponse, String> {
    let data_dir = app.path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app data dir: {}", e))?;
    
    let auth = auth::SupabaseAuth::new(&data_dir);
    auth.handle_oauth_callback(&callback_url)
        .await
        .map_err(|e| e.to_string())
}

struct OAuthCallbackState(Mutex<Option<String>>);

fn main() {
    load_env();
    
    let args: Vec<String> = std::env::args().collect();
    if args.len() >= 3 && args[1] == "--sync-vocab" {
        handle_sync_vocab_cli(&args[2]);
        return;
    }
    
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_deep_link::init())
        .manage(OAuthCallbackState(Mutex::new(None)))
        .setup(|app| {
            #[cfg(any(target_os = "linux", target_os = "windows", target_os = "macos"))]
            {
                use tauri_plugin_deep_link::DeepLinkExt;
                let handle = app.handle().clone();
                app.deep_link().on_open_url(move |event| {
                    for url in event.urls() {
                        let url_str = url.to_string();
                        if url_str.starts_with("mastery://auth/callback") {
                            if let Some(state) = handle.try_state::<OAuthCallbackState>() {
                                *state.0.lock().unwrap() = Some(url_str.clone());
                            }
                            let _ = handle.emit("oauth-callback", url_str);
                        }
                    }
                });
            }
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            check_kindle_status,
            import_from_kindle,
            get_import_history,
            auth_sign_up_with_email,
            auth_sign_in_with_email,
            auth_sign_out,
            auth_get_session,
            auth_get_current_user,
            auth_get_oauth_url,
            auth_handle_oauth_callback,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
