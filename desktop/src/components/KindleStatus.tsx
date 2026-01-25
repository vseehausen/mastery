/**
 * Kindle status display component
 */

import React, { useEffect, useState } from 'react';
import {
  getKindleStatus,
  triggerImport,
  formatFileSize,
  KindleStatus as KindleStatusType,
  ImportResult,
} from '../api/kindle';

interface KindleStatusProps {
  onImportComplete?: (result: ImportResult) => void;
}

export function KindleStatus({ onImportComplete }: KindleStatusProps): JSX.Element {
  const [status, setStatus] = useState<KindleStatusType | null>(null);
  const [loading, setLoading] = useState(true);
  const [importing, setImporting] = useState(false);
  const [lastResult, setLastResult] = useState<ImportResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Poll for status updates
  useEffect(() => {
    const fetchStatus = async (): Promise<void> => {
      try {
        const newStatus = await getKindleStatus();
        setStatus(newStatus);
        setError(null);
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed to get status');
      } finally {
        setLoading(false);
      }
    };

    fetchStatus();
    const interval = setInterval(fetchStatus, 2000);
    return () => clearInterval(interval);
  }, []);

  const handleImport = async (): Promise<void> => {
    setImporting(true);
    setError(null);
    try {
      const result = await triggerImport();
      setLastResult(result);
      onImportComplete?.(result);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Import failed');
    } finally {
      setImporting(false);
    }
  };

  if (loading) {
    return (
      <div className="kindle-status loading">
        <div className="spinner" />
        <span>Checking for Kindle...</span>
      </div>
    );
  }

  return (
    <div className="kindle-status">
      <div className="status-header">
        <div className={`status-indicator ${status?.connected ? 'connected' : 'disconnected'}`} />
        <h3>{status?.connected ? 'Kindle Connected' : 'Kindle Not Connected'}</h3>
      </div>

      {status?.connected && (
        <div className="status-details">
          {status.mountPoint && (
            <p className="mount-point">
              <strong>Location:</strong> {status.mountPoint}
            </p>
          )}
          {status.clippingsSize !== null && (
            <p className="file-size">
              <strong>Clippings file:</strong> {formatFileSize(status.clippingsSize)}
            </p>
          )}

          <button
            className="import-button"
            onClick={handleImport}
            disabled={importing}
          >
            {importing ? 'Importing...' : 'Import Now'}
          </button>
        </div>
      )}

      {!status?.connected && (
        <div className="status-details">
          <p className="hint">Connect your Kindle via USB to import highlights.</p>
        </div>
      )}

      {error && (
        <div className="error-message">
          <span className="error-icon">⚠️</span>
          {error}
        </div>
      )}

      {lastResult && (
        <div className="import-result">
          <h4>Last Import</h4>
          <ul>
            <li><strong>Found:</strong> {lastResult.totalFound}</li>
            <li><strong>Imported:</strong> {lastResult.imported}</li>
            <li><strong>Skipped (duplicates):</strong> {lastResult.skipped}</li>
            {lastResult.errors > 0 && (
              <li className="errors"><strong>Errors:</strong> {lastResult.errors}</li>
            )}
          </ul>
        </div>
      )}
    </div>
  );
}

export default KindleStatus;
