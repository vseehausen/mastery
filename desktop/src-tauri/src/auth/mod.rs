//! Authentication module for Supabase Auth integration

use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use anyhow::{Result, Context};
use reqwest::Client;
use chrono::Utc;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthSession {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_at: i64,
    pub user_id: String,
    pub email: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: String,
    pub email: Option<String>,
    pub email_confirmed_at: Option<String>,
    pub created_at: String,
    pub last_sign_in_at: Option<String>,
}

pub struct SupabaseAuth {
    supabase_url: String,
    anon_key: String,
    session_path: PathBuf,
}

impl SupabaseAuth {
    pub fn new(app_data_dir: &Path) -> Self {
        // Use compile-time values (embedded at build), fallback to runtime env
        let supabase_url = option_env!("SUPABASE_URL")
            .map(String::from)
            .or_else(|| std::env::var("SUPABASE_URL").ok())
            .unwrap_or_default();
        let anon_key = option_env!("SUPABASE_ANON_KEY")
            .map(String::from)
            .or_else(|| std::env::var("SUPABASE_ANON_KEY").ok())
            .unwrap_or_default();
        
        let auth_dir = app_data_dir.join("auth");
        std::fs::create_dir_all(&auth_dir).ok();
        
        Self {
            supabase_url,
            anon_key,
            session_path: auth_dir.join("session.json"),
        }
    }
    
    fn is_configured(&self) -> bool {
        !self.supabase_url.is_empty() && !self.anon_key.is_empty()
    }
    
    pub fn load_session(&self) -> Option<AuthSession> {
        if !self.session_path.exists() {
            return None;
        }
        let content = std::fs::read_to_string(&self.session_path).ok()?;
        serde_json::from_str(&content).ok()
    }
    
    pub fn save_session(&self, session: &AuthSession) -> Result<()> {
        let content = serde_json::to_string_pretty(session)?;
        std::fs::write(&self.session_path, content)?;
        Ok(())
    }
    
    pub fn delete_session(&self) -> Result<()> {
        if self.session_path.exists() {
            std::fs::remove_file(&self.session_path)?;
        }
        Ok(())
    }
    
    pub async fn sign_up_with_email(&self, email: &str, password: &str) -> Result<AuthResponse> {
        if !self.is_configured() {
            return Ok(AuthResponse::error("Supabase not configured. Check environment variables."));
        }
        
        let client = Client::new();
        let url = format!("{}/auth/v1/signup", self.supabase_url);
        
        let response = client
            .post(&url)
            .header("apikey", &self.anon_key)
            .header("Content-Type", "application/json")
            .json(&serde_json::json!({
                "email": email,
                "password": password
            }))
            .send()
            .await
            .map_err(|e| anyhow::anyhow!("Network error: {}", e))?;
        
        let status = response.status();
        let body: serde_json::Value = response.json().await.unwrap_or_default();
        
        if status.is_success() {
            if let Some(session) = body.get("session")
                .and_then(|s| serde_json::from_value::<SupabaseSession>(s.clone()).ok()) 
            {
                let auth_session = AuthSession::from_supabase(session);
                self.save_session(&auth_session).ok();
                return Ok(AuthResponse::success(auth_session));
            }
            Ok(AuthResponse::error("Email confirmation required"))
        } else {
            Ok(AuthResponse::error(&extract_error_message(&body, "Signup failed")))
        }
    }
    
    pub async fn sign_in_with_email(&self, email: &str, password: &str) -> Result<AuthResponse> {
        if !self.is_configured() {
            return Ok(AuthResponse::error("Supabase not configured. Check environment variables."));
        }
        
        let client = Client::new();
        let url = format!("{}/auth/v1/token?grant_type=password", self.supabase_url);
        
        let response = client
            .post(&url)
            .header("apikey", &self.anon_key)
            .header("Content-Type", "application/json")
            .json(&serde_json::json!({
                "email": email,
                "password": password
            }))
            .send()
            .await
            .map_err(|e| anyhow::anyhow!("Network error: {}", e))?;
        
        let status = response.status();
        let body: serde_json::Value = response.json().await.unwrap_or_default();
        
        if status.is_success() {
            let session = serde_json::from_value::<SupabaseSession>(body)
                .map_err(|e| anyhow::anyhow!("Failed to parse session: {}", e))?;
            
            let auth_session = AuthSession::from_supabase(session);
            self.save_session(&auth_session).ok();
            Ok(AuthResponse::success(auth_session))
        } else {
            Ok(AuthResponse::error(&extract_error_message(&body, "Sign in failed")))
        }
    }
    
    pub fn sign_out(&self) -> Result<()> {
        self.delete_session()
    }
    
    pub fn get_current_user(&self) -> Option<User> {
        let session = self.load_session()?;
        Some(User {
            id: session.user_id,
            email: session.email,
            email_confirmed_at: None,
            created_at: Utc::now().to_rfc3339(),
            last_sign_in_at: None,
        })
    }

    pub fn get_oauth_url(&self, provider: &str) -> Result<OAuthUrlResponse> {
        if !self.is_configured() {
            return Ok(OAuthUrlResponse {
                url: None,
                error: Some("Supabase not configured".to_string()),
            });
        }

        let redirect_url = urlencoding::encode("mastery://auth/callback");
        let url = format!(
            "{}/auth/v1/authorize?provider={}&redirect_to={}",
            self.supabase_url, provider, redirect_url
        );

        Ok(OAuthUrlResponse {
            url: Some(url),
            error: None,
        })
    }

    pub async fn handle_oauth_callback(&self, callback_url: &str) -> Result<AuthResponse> {
        let parsed = url::Url::parse(callback_url)
            .context("Failed to parse callback URL")?;

        let fragment = parsed.fragment().unwrap_or("");
        let params: std::collections::HashMap<String, String> = fragment
            .split('&')
            .filter_map(|pair| {
                let mut parts = pair.splitn(2, '=');
                Some((parts.next()?.to_string(), parts.next()?.to_string()))
            })
            .collect();

        // Check for error
        if let Some(error) = params.get("error") {
            let error_desc = params.get("error_description")
                .map(|s| urlencoding::decode(s).unwrap_or_default().into_owned())
                .unwrap_or_else(|| error.clone());
            return Ok(AuthResponse::error(&error_desc));
        }

        // Extract tokens from fragment
        let access_token = params.get("access_token").cloned();
        let refresh_token = params.get("refresh_token").cloned();
        let expires_at = params.get("expires_at")
            .and_then(|s| s.parse::<i64>().ok())
            .unwrap_or(0);

        if let (Some(access_token), Some(refresh_token)) = (access_token, refresh_token) {
            let user = self.get_user_from_token(&access_token).await?;
            let auth_session = AuthSession {
                access_token,
                refresh_token,
                expires_at,
                user_id: user.id.clone(),
                email: user.email.clone(),
            };
            self.save_session(&auth_session).ok();
            return Ok(AuthResponse::success(auth_session));
        }

        // Try exchange code if no tokens in fragment
        let code_from_query = parsed.query_pairs()
            .find(|(k, _)| k == "code")
            .map(|(_, v)| v.into_owned());
        if let Some(code) = params.get("code").cloned().or(code_from_query) {
            return self.exchange_code_for_session(&code).await;
        }

        Ok(AuthResponse::error("No tokens found in callback"))
    }

    async fn exchange_code_for_session(&self, code: &str) -> Result<AuthResponse> {
        let client = Client::new();
        let url = format!("{}/auth/v1/token?grant_type=pkce", self.supabase_url);

        let response = client
            .post(&url)
            .header("apikey", &self.anon_key)
            .header("Content-Type", "application/json")
            .json(&serde_json::json!({
                "auth_code": code,
                "code_verifier": ""
            }))
            .send()
            .await;

        match response {
            Ok(resp) if resp.status().is_success() => {
                let body: serde_json::Value = resp.json().await.unwrap_or_default();
                if let Ok(session) = serde_json::from_value::<SupabaseSession>(body) {
                    let auth_session = AuthSession::from_supabase(session);
                    self.save_session(&auth_session).ok();
                    return Ok(AuthResponse::success(auth_session));
                }
                Ok(AuthResponse::error("Failed to parse session"))
            }
            Ok(_) => Ok(AuthResponse::error("Failed to exchange code")),
            Err(e) => Ok(AuthResponse::error(&format!("Network error: {}", e))),
        }
    }

    async fn get_user_from_token(&self, access_token: &str) -> Result<User> {
        let client = Client::new();
        let url = format!("{}/auth/v1/user", self.supabase_url);

        let response = client
            .get(&url)
            .header("apikey", &self.anon_key)
            .header("Authorization", format!("Bearer {}", access_token))
            .send()
            .await?;

        let body: serde_json::Value = response.json().await?;

        Ok(User {
            id: body.get("id").and_then(|v| v.as_str()).unwrap_or("").to_string(),
            email: body.get("email").and_then(|v| v.as_str()).map(String::from),
            email_confirmed_at: body.get("email_confirmed_at").and_then(|v| v.as_str()).map(String::from),
            created_at: body.get("created_at").and_then(|v| v.as_str()).unwrap_or("").to_string(),
            last_sign_in_at: body.get("last_sign_in_at").and_then(|v| v.as_str()).map(String::from),
        })
    }
}

impl AuthSession {
    fn from_supabase(session: SupabaseSession) -> Self {
        Self {
            access_token: session.access_token,
            refresh_token: session.refresh_token,
            expires_at: session.expires_at,
            user_id: session.user.id,
            email: session.user.email,
        }
    }
}

impl AuthResponse {
    fn success(session: AuthSession) -> Self {
        Self { success: true, session: Some(session), error: None }
    }
    
    fn error(msg: &str) -> Self {
        Self { success: false, session: None, error: Some(msg.to_string()) }
    }
}

fn extract_error_message(body: &serde_json::Value, default: &str) -> String {
    body.get("error_description")
        .or_else(|| body.get("msg"))
        .or_else(|| body.get("error"))
        .and_then(|m| m.as_str())
        .unwrap_or(default)
        .to_string()
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OAuthUrlResponse {
    pub url: Option<String>,
    pub error: Option<String>,
}

#[derive(Debug, Deserialize)]
struct SupabaseSession {
    access_token: String,
    refresh_token: String,
    expires_at: i64,
    user: SupabaseUser,
}

#[derive(Debug, Deserialize)]
struct SupabaseUser {
    id: String,
    email: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AuthResponse {
    pub success: bool,
    pub session: Option<AuthSession>,
    pub error: Option<String>,
}
