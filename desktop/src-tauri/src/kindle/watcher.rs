//! Kindle device watcher with polling loop
//!
//! Monitors for Kindle device connection/disconnection events.

use super::detection::is_kindle_connected;
use super::mount::{find_kindle_mount, get_clippings_metadata, ClippingsMetadata};
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::mpsc;
use tokio::time::interval;

/// Default polling interval in milliseconds
const DEFAULT_POLL_INTERVAL_MS: u64 = 2000;

/// Events emitted by the Kindle watcher
#[derive(Debug, Clone)]
pub enum KindleEvent {
    /// Kindle device connected
    Connected {
        mount_point: PathBuf,
        metadata: ClippingsMetadata,
    },
    /// Kindle device disconnected
    Disconnected,
    /// Clippings file was modified
    ClippingsModified {
        mount_point: PathBuf,
        metadata: ClippingsMetadata,
    },
}

/// State tracked by the watcher
#[derive(Debug, Clone)]
struct WatcherState {
    is_connected: bool,
    mount_point: Option<PathBuf>,
    last_modified: Option<std::time::SystemTime>,
}

impl Default for WatcherState {
    fn default() -> Self {
        Self {
            is_connected: false,
            mount_point: None,
            last_modified: None,
        }
    }
}

/// Kindle device watcher
pub struct KindleWatcher {
    running: Arc<AtomicBool>,
    poll_interval: Duration,
}

impl KindleWatcher {
    /// Create a new watcher with default settings
    pub fn new() -> Self {
        Self {
            running: Arc::new(AtomicBool::new(false)),
            poll_interval: Duration::from_millis(DEFAULT_POLL_INTERVAL_MS),
        }
    }

    /// Create a watcher with custom poll interval
    pub fn with_interval(poll_interval_ms: u64) -> Self {
        Self {
            running: Arc::new(AtomicBool::new(false)),
            poll_interval: Duration::from_millis(poll_interval_ms),
        }
    }

    /// Start watching for Kindle events
    ///
    /// Returns a receiver for events and a handle to stop the watcher.
    pub fn start(&self) -> (mpsc::Receiver<KindleEvent>, WatcherHandle) {
        let (tx, rx) = mpsc::channel(32);
        let running = self.running.clone();
        let poll_interval = self.poll_interval;

        running.store(true, Ordering::SeqCst);

        let handle_running = running.clone();
        tokio::spawn(async move {
            Self::watch_loop(tx, running, poll_interval).await;
        });

        let handle = WatcherHandle {
            running: handle_running,
        };

        (rx, handle)
    }

    /// Internal watch loop
    async fn watch_loop(
        tx: mpsc::Sender<KindleEvent>,
        running: Arc<AtomicBool>,
        poll_interval: Duration,
    ) {
        let mut state = WatcherState::default();
        let mut ticker = interval(poll_interval);

        while running.load(Ordering::SeqCst) {
            ticker.tick().await;

            if let Some(event) = Self::check_for_changes(&mut state) {
                if tx.send(event).await.is_err() {
                    // Receiver dropped, stop watching
                    break;
                }
            }
        }
    }

    /// Check for device/file changes
    fn check_for_changes(state: &mut WatcherState) -> Option<KindleEvent> {
        let is_connected = is_kindle_connected();

        // Check for connection state change
        if is_connected != state.is_connected {
            state.is_connected = is_connected;

            if is_connected {
                // Device connected - try to find mount point
                if let Ok(mount_point) = find_kindle_mount() {
                    let metadata = get_clippings_metadata(&mount_point).ok()?;
                    state.mount_point = Some(mount_point.clone());
                    state.last_modified = metadata.modified;
                    return Some(KindleEvent::Connected {
                        mount_point,
                        metadata,
                    });
                }
            } else {
                // Device disconnected
                state.mount_point = None;
                state.last_modified = None;
                return Some(KindleEvent::Disconnected);
            }
        }

        // Check for file modification (only if connected)
        if let Some(ref mount_point) = state.mount_point {
            if let Ok(metadata) = get_clippings_metadata(mount_point) {
                if metadata.modified != state.last_modified {
                    state.last_modified = metadata.modified;
                    return Some(KindleEvent::ClippingsModified {
                        mount_point: mount_point.clone(),
                        metadata,
                    });
                }
            }
        }

        None
    }

    /// Check if the watcher is currently running
    pub fn is_running(&self) -> bool {
        self.running.load(Ordering::SeqCst)
    }
}

impl Default for KindleWatcher {
    fn default() -> Self {
        Self::new()
    }
}

/// Handle to control a running watcher
pub struct WatcherHandle {
    running: Arc<AtomicBool>,
}

impl WatcherHandle {
    /// Stop the watcher
    pub fn stop(&self) {
        self.running.store(false, Ordering::SeqCst);
    }

    /// Check if still running
    pub fn is_running(&self) -> bool {
        self.running.load(Ordering::SeqCst)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_watcher_creation() {
        let watcher = KindleWatcher::new();
        assert!(!watcher.is_running());
    }

    #[test]
    fn test_custom_interval() {
        let watcher = KindleWatcher::with_interval(5000);
        assert_eq!(watcher.poll_interval, Duration::from_millis(5000));
    }

    #[test]
    fn test_watcher_state_default() {
        let state = WatcherState::default();
        assert!(!state.is_connected);
        assert!(state.mount_point.is_none());
        assert!(state.last_modified.is_none());
    }
}
