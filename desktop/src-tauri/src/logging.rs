//! File-based logging for the desktop agent
//!
//! Logs are written to the application's data directory.

use anyhow::Result;
use std::fs::{self, File, OpenOptions};
use std::io::Write;
use std::path::PathBuf;
use std::sync::Mutex;
use tracing_subscriber::{fmt, prelude::*, EnvFilter};

/// Initialize the logging system
pub fn init_logging() -> Result<()> {
    // Set up tracing subscriber with both console and file output
    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new("info"));

    tracing_subscriber::registry()
        .with(filter)
        .with(fmt::layer().with_target(true))
        .init();

    tracing::info!("Logging initialized");
    Ok(())
}

/// Get the log file path
pub fn get_log_path() -> PathBuf {
    dirs::data_local_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("mastery")
        .join("logs")
        .join("mastery.log")
}

/// Ensure log directory exists
pub fn ensure_log_dir() -> Result<PathBuf> {
    let log_path = get_log_path();
    if let Some(parent) = log_path.parent() {
        fs::create_dir_all(parent)?;
    }
    Ok(log_path)
}

/// Simple file logger for writing to log files
pub struct FileLogger {
    file: Mutex<File>,
}

impl FileLogger {
    /// Create a new file logger
    pub fn new() -> Result<Self> {
        let log_path = ensure_log_dir()?;
        let file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(log_path)?;

        Ok(Self {
            file: Mutex::new(file),
        })
    }

    /// Write a log entry
    pub fn log(&self, level: &str, message: &str) -> Result<()> {
        let timestamp = chrono::Utc::now().to_rfc3339();
        let entry = format!("[{}] {} {}\n", timestamp, level, message);

        let mut file = self.file.lock().map_err(|e| anyhow::anyhow!("Lock error: {}", e))?;
        file.write_all(entry.as_bytes())?;
        file.flush()?;

        Ok(())
    }

    /// Log debug message
    pub fn debug(&self, message: &str) -> Result<()> {
        self.log("DEBUG", message)
    }

    /// Log info message
    pub fn info(&self, message: &str) -> Result<()> {
        self.log("INFO ", message)
    }

    /// Log warning message
    pub fn warn(&self, message: &str) -> Result<()> {
        self.log("WARN ", message)
    }

    /// Log error message
    pub fn error(&self, message: &str) -> Result<()> {
        self.log("ERROR", message)
    }
}

/// Rotate log files if they get too large
pub fn rotate_logs() -> Result<()> {
    let log_path = get_log_path();

    if !log_path.exists() {
        return Ok(());
    }

    let metadata = fs::metadata(&log_path)?;
    const MAX_LOG_SIZE: u64 = 10 * 1024 * 1024; // 10 MB

    if metadata.len() > MAX_LOG_SIZE {
        // Rename current log to .old
        let old_path = log_path.with_extension("log.old");
        if old_path.exists() {
            fs::remove_file(&old_path)?;
        }
        fs::rename(&log_path, &old_path)?;

        tracing::info!("Rotated log file");
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_log_path_is_valid() {
        let path = get_log_path();
        assert!(path.to_string_lossy().contains("mastery"));
        assert!(path.to_string_lossy().ends_with(".log"));
    }
}
