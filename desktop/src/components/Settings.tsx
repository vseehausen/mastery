/**
 * Settings component with auto-sync toggle
 */

import React, { useEffect, useState } from 'react';
import { getAutoImportEnabled, setAutoImportEnabled } from '../api/kindle';

interface SettingsProps {
  onSettingsChange?: () => void;
}

export function Settings({ onSettingsChange }: SettingsProps): JSX.Element {
  const [autoImport, setAutoImport] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const loadSettings = async (): Promise<void> => {
      try {
        const enabled = await getAutoImportEnabled();
        setAutoImport(enabled);
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed to load settings');
      } finally {
        setLoading(false);
      }
    };

    loadSettings();
  }, []);

  const handleAutoImportChange = async (enabled: boolean): Promise<void> => {
    setSaving(true);
    setError(null);
    try {
      await setAutoImportEnabled(enabled);
      setAutoImport(enabled);
      onSettingsChange?.();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to save setting');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="settings loading">
        <div className="spinner" />
        <span>Loading settings...</span>
      </div>
    );
  }

  return (
    <div className="settings">
      <h3>Settings</h3>

      <div className="setting-item">
        <label className="toggle-label">
          <input
            type="checkbox"
            checked={autoImport}
            onChange={(e) => handleAutoImportChange(e.target.checked)}
            disabled={saving}
          />
          <span className="toggle-slider" />
          <span className="toggle-text">
            Auto-import when Kindle is connected
          </span>
        </label>
        <p className="setting-description">
          Automatically import new highlights when you connect your Kindle device.
        </p>
      </div>

      {error && (
        <div className="error-message">
          <span className="error-icon">⚠️</span>
          {error}
        </div>
      )}

      <div className="settings-info">
        <h4>About</h4>
        <p>Mastery Desktop Agent v0.1.0</p>
        <p className="hint">
          This app runs in the background and monitors for Kindle device connections.
        </p>
      </div>
    </div>
  );
}

export default Settings;
