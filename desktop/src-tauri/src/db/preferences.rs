//! User preferences storage module
//!
//! Key-value store for user settings like auto-sync toggle.

use super::Database;
use anyhow::Result;
use chrono::Utc;
use rusqlite::params;

/// Known preference keys
pub mod keys {
    /// Whether to auto-import when Kindle is connected
    pub const AUTO_IMPORT_ENABLED: &str = "auto_import_enabled";

    /// Last import timestamp
    pub const LAST_IMPORT_AT: &str = "last_import_at";

    /// User's Supabase access token (encrypted in production)
    pub const ACCESS_TOKEN: &str = "access_token";

    /// User's Supabase refresh token (encrypted in production)
    pub const REFRESH_TOKEN: &str = "refresh_token";

    /// Token expiry timestamp
    pub const TOKEN_EXPIRES_AT: &str = "token_expires_at";

    /// User ID from Supabase auth
    pub const USER_ID: &str = "user_id";

    /// User email
    pub const USER_EMAIL: &str = "user_email";
}

impl Database {
    /// Get a preference value by key
    pub fn get_preference(&self, key: &str) -> Result<Option<String>> {
        self.with_conn(|conn| {
            let value = conn
                .query_row(
                    "SELECT value FROM preferences WHERE key = ?",
                    params![key],
                    |row| row.get(0),
                )
                .ok();
            Ok(value)
        })
    }

    /// Set a preference value
    pub fn set_preference(&self, key: &str, value: &str) -> Result<()> {
        self.with_conn(|conn| {
            let now = Utc::now().to_rfc3339();
            conn.execute(
                "INSERT OR REPLACE INTO preferences (key, value, updated_at) VALUES (?, ?, ?)",
                params![key, value, now],
            )?;
            Ok(())
        })
    }

    /// Delete a preference
    pub fn delete_preference(&self, key: &str) -> Result<()> {
        self.with_conn(|conn| {
            conn.execute("DELETE FROM preferences WHERE key = ?", params![key])?;
            Ok(())
        })
    }

    /// Get boolean preference (defaults to false if not set)
    pub fn get_bool_preference(&self, key: &str) -> Result<bool> {
        let value = self.get_preference(key)?;
        Ok(value.map(|v| v == "true" || v == "1").unwrap_or(false))
    }

    /// Set boolean preference
    pub fn set_bool_preference(&self, key: &str, value: bool) -> Result<()> {
        self.set_preference(key, if value { "true" } else { "false" })
    }

    /// Check if auto-import is enabled
    pub fn is_auto_import_enabled(&self) -> Result<bool> {
        self.get_bool_preference(keys::AUTO_IMPORT_ENABLED)
    }

    /// Set auto-import enabled state
    pub fn set_auto_import_enabled(&self, enabled: bool) -> Result<()> {
        self.set_bool_preference(keys::AUTO_IMPORT_ENABLED, enabled)
    }

    /// Store auth tokens
    pub fn store_auth_tokens(
        &self,
        access_token: &str,
        refresh_token: &str,
        expires_at: i64,
        user_id: &str,
        email: Option<&str>,
    ) -> Result<()> {
        self.set_preference(keys::ACCESS_TOKEN, access_token)?;
        self.set_preference(keys::REFRESH_TOKEN, refresh_token)?;
        self.set_preference(keys::TOKEN_EXPIRES_AT, &expires_at.to_string())?;
        self.set_preference(keys::USER_ID, user_id)?;
        if let Some(email) = email {
            self.set_preference(keys::USER_EMAIL, email)?;
        }
        Ok(())
    }

    /// Clear auth tokens (sign out)
    pub fn clear_auth_tokens(&self) -> Result<()> {
        self.delete_preference(keys::ACCESS_TOKEN)?;
        self.delete_preference(keys::REFRESH_TOKEN)?;
        self.delete_preference(keys::TOKEN_EXPIRES_AT)?;
        self.delete_preference(keys::USER_ID)?;
        self.delete_preference(keys::USER_EMAIL)?;
        Ok(())
    }

    /// Get stored user ID
    pub fn get_user_id(&self) -> Result<Option<String>> {
        self.get_preference(keys::USER_ID)
    }

    /// Get sync state
    pub fn get_sync_state(&self) -> Result<(Option<String>, Option<String>)> {
        self.with_conn(|conn| {
            let result = conn
                .query_row(
                    "SELECT last_synced_at, last_sync_token FROM sync_state WHERE id = 1",
                    [],
                    |row| Ok((row.get(0)?, row.get(1)?)),
                )
                .ok();
            Ok(result.unwrap_or((None, None)))
        })
    }

    /// Update sync state
    pub fn update_sync_state(&self, last_synced_at: &str, token: Option<&str>) -> Result<()> {
        self.with_conn(|conn| {
            conn.execute(
                "UPDATE sync_state SET last_synced_at = ?, last_sync_token = ? WHERE id = 1",
                params![last_synced_at, token],
            )?;
            Ok(())
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_set_get_preference() {
        let db = Database::in_memory().unwrap();

        db.set_preference("test_key", "test_value").unwrap();
        let value = db.get_preference("test_key").unwrap();
        assert_eq!(value, Some("test_value".to_string()));
    }

    #[test]
    fn test_bool_preference() {
        let db = Database::in_memory().unwrap();

        // Default is false
        assert!(!db.get_bool_preference("flag").unwrap());

        // Set to true
        db.set_bool_preference("flag", true).unwrap();
        assert!(db.get_bool_preference("flag").unwrap());

        // Set to false
        db.set_bool_preference("flag", false).unwrap();
        assert!(!db.get_bool_preference("flag").unwrap());
    }

    #[test]
    fn test_auto_import_preference() {
        let db = Database::in_memory().unwrap();

        // Default is false
        assert!(!db.is_auto_import_enabled().unwrap());

        // Enable
        db.set_auto_import_enabled(true).unwrap();
        assert!(db.is_auto_import_enabled().unwrap());
    }
}
