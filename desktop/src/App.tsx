/**
 * Main app layout for Mastery Desktop Agent
 */

import React, { useState } from 'react';
import { KindleStatus } from './components/KindleStatus';
import { Settings } from './components/Settings';
import type { ImportResult } from './api/kindle';
import './App.css';

type Tab = 'status' | 'settings';

export function App(): JSX.Element {
  const [activeTab, setActiveTab] = useState<Tab>('status');
  const [importCount, setImportCount] = useState(0);

  const handleImportComplete = (result: ImportResult): void => {
    if (result.imported > 0) {
      setImportCount((prev) => prev + result.imported);
    }
  };

  return (
    <div className="app">
      <header className="app-header">
        <div className="logo">
          <span className="logo-icon">📚</span>
          <h1>Mastery</h1>
        </div>
        {importCount > 0 && (
          <div className="import-badge">
            {importCount} imported this session
          </div>
        )}
      </header>

      <nav className="app-nav">
        <button
          className={`nav-button ${activeTab === 'status' ? 'active' : ''}`}
          onClick={() => setActiveTab('status')}
        >
          <span className="nav-icon">📱</span>
          Status
        </button>
        <button
          className={`nav-button ${activeTab === 'settings' ? 'active' : ''}`}
          onClick={() => setActiveTab('settings')}
        >
          <span className="nav-icon">⚙️</span>
          Settings
        </button>
      </nav>

      <main className="app-content">
        {activeTab === 'status' && (
          <KindleStatus onImportComplete={handleImportComplete} />
        )}
        {activeTab === 'settings' && <Settings />}
      </main>

      <footer className="app-footer">
        <p>Connect your Kindle to import highlights automatically</p>
      </footer>
    </div>
  );
}

export default App;
