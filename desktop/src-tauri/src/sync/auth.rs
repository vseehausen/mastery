//! Supabase authentication helper for JWT handling
//!
//! Manages access tokens, refresh tokens, and authenticated API requests.

use anyhow::{anyhow, Result};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::RwLock;

/// Auth session containing tokens and user info
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthSession {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_at: i64,
    pub user_id: String,
    pub email: Option<String>,
}

impl AuthSession {
    /// Check if the access token has expired
    pub fn is_expired(&self) -> bool {
        let now = chrono::Utc::now().timestamp();
        // Consider expired if within 60 seconds of expiry
        now >= self.expires_at - 60
    }
}

/// Auth response from Supabase
#[derive(Debug, Deserialize)]
struct SupabaseAuthResponse {
    access_token: String,
    refresh_token: String,
    expires_in: i64,
    user: SupabaseUser,
}

#[derive(Debug, Deserialize)]
struct SupabaseUser {
    id: String,
    email: Option<String>,
}

/// Supabase auth helper for managing authentication
pub struct SupabaseAuth {
    client: Client,
    base_url: String,
    anon_key: String,
    session: Arc<RwLock<Option<AuthSession>>>,
}

impl SupabaseAuth {
    /// Create a new auth helper
    pub fn new(base_url: String, anon_key: String) -> Self {
        Self {
            client: Client::new(),
            base_url,
            anon_key,
            session: Arc::new(RwLock::new(None)),
        }
    }

    /// Sign in with email and password
    pub async fn sign_in(&self, email: &str, password: &str) -> Result<AuthSession> {
        let response = self
            .client
            .post(format!("{}/auth/v1/token?grant_type=password", self.base_url))
            .header("apikey", &self.anon_key)
            .header("Content-Type", "application/json")
            .json(&serde_json::json!({
                "email": email,
                "password": password
            }))
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await.unwrap_or_default();
            return Err(anyhow!("Sign in failed: {}", error_text));
        }

        let auth_response: SupabaseAuthResponse = response.json().await?;
        let now = chrono::Utc::now().timestamp();

        let session = AuthSession {
            access_token: auth_response.access_token,
            refresh_token: auth_response.refresh_token,
            expires_at: now + auth_response.expires_in,
            user_id: auth_response.user.id,
            email: auth_response.user.email,
        };

        // Store session
        let mut stored = self.session.write().await;
        *stored = Some(session.clone());

        Ok(session)
    }

    /// Refresh the access token
    pub async fn refresh_token(&self) -> Result<AuthSession> {
        let current_session = self.session.read().await;
        let refresh_token = current_session
            .as_ref()
            .map(|s| s.refresh_token.clone())
            .ok_or_else(|| anyhow!("No session to refresh"))?;
        drop(current_session);

        let response = self
            .client
            .post(format!("{}/auth/v1/token?grant_type=refresh_token", self.base_url))
            .header("apikey", &self.anon_key)
            .header("Content-Type", "application/json")
            .json(&serde_json::json!({
                "refresh_token": refresh_token
            }))
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await.unwrap_or_default();
            return Err(anyhow!("Token refresh failed: {}", error_text));
        }

        let auth_response: SupabaseAuthResponse = response.json().await?;
        let now = chrono::Utc::now().timestamp();

        let session = AuthSession {
            access_token: auth_response.access_token,
            refresh_token: auth_response.refresh_token,
            expires_at: now + auth_response.expires_in,
            user_id: auth_response.user.id,
            email: auth_response.user.email,
        };

        // Update stored session
        let mut stored = self.session.write().await;
        *stored = Some(session.clone());

        Ok(session)
    }

    /// Get a valid access token, refreshing if necessary
    pub async fn get_valid_token(&self) -> Result<String> {
        let session = self.session.read().await;

        if let Some(ref s) = *session {
            if !s.is_expired() {
                return Ok(s.access_token.clone());
            }
        }
        drop(session);

        // Need to refresh
        let new_session = self.refresh_token().await?;
        Ok(new_session.access_token)
    }

    /// Get current session if exists
    pub async fn get_session(&self) -> Option<AuthSession> {
        self.session.read().await.clone()
    }

    /// Get current user ID if authenticated
    pub async fn get_user_id(&self) -> Option<String> {
        self.session.read().await.as_ref().map(|s| s.user_id.clone())
    }

    /// Check if user is authenticated
    pub async fn is_authenticated(&self) -> bool {
        self.session.read().await.is_some()
    }

    /// Sign out and clear session
    pub async fn sign_out(&self) {
        let mut session = self.session.write().await;
        *session = None;
    }

    /// Set session from stored data (e.g., loaded from keychain)
    pub async fn set_session(&self, session: AuthSession) {
        let mut stored = self.session.write().await;
        *stored = Some(session);
    }

    /// Make an authenticated request to a Supabase Edge Function
    pub async fn call_function<T: Serialize, R: for<'de> Deserialize<'de>>(
        &self,
        function_name: &str,
        method: reqwest::Method,
        body: Option<&T>,
    ) -> Result<R> {
        let token = self.get_valid_token().await?;

        let url = format!("{}/functions/v1/{}", self.base_url, function_name);
        let mut request = self
            .client
            .request(method, &url)
            .header("Authorization", format!("Bearer {}", token))
            .header("apikey", &self.anon_key);

        if let Some(body) = body {
            request = request.json(body);
        }

        let response = request.send().await?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_default();
            return Err(anyhow!("Function call failed ({}): {}", status, error_text));
        }

        let result: R = response.json().await?;
        Ok(result)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_session_expiry() {
        let now = chrono::Utc::now().timestamp();

        let expired_session = AuthSession {
            access_token: "token".to_string(),
            refresh_token: "refresh".to_string(),
            expires_at: now - 100,
            user_id: "user".to_string(),
            email: None,
        };
        assert!(expired_session.is_expired());

        let valid_session = AuthSession {
            access_token: "token".to_string(),
            refresh_token: "refresh".to_string(),
            expires_at: now + 3600,
            user_id: "user".to_string(),
            email: None,
        };
        assert!(!valid_session.is_expired());
    }
}
