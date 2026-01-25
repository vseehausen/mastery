//! Sync module for synchronizing data with Supabase
//!
//! Handles authentication, pushing local changes, and pulling remote updates.

mod auth;
mod push;

pub use auth::*;
pub use push::*;

use anyhow::Result;
use serde::{Deserialize, Serialize};

/// Supabase configuration
#[derive(Debug, Clone)]
pub struct SupabaseConfig {
    pub url: String,
    pub anon_key: String,
}

impl SupabaseConfig {
    /// Create config from environment variables
    pub fn from_env() -> Result<Self> {
        Ok(Self {
            url: std::env::var("SUPABASE_URL")
                .unwrap_or_else(|_| "http://localhost:54321".to_string()),
            anon_key: std::env::var("SUPABASE_ANON_KEY")
                .unwrap_or_else(|_| "".to_string()),
        })
    }
}

/// Sync result summary
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncResult {
    pub pushed: i32,
    pub pulled: i32,
    pub errors: Vec<String>,
}

impl SyncResult {
    pub fn empty() -> Self {
        Self {
            pushed: 0,
            pulled: 0,
            errors: Vec::new(),
        }
    }

    pub fn is_success(&self) -> bool {
        self.errors.is_empty()
    }
}
