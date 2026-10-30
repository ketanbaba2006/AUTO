import React from 'react';
import { Shield, Lock, EyeOff, Server, HardDrive, Key, CheckCircle2, AlertTriangle, Trash2 } from 'lucide-react';
import metadata from '../release-metadata.json';

export const PrivacyPage: React.FC = () => {
  return (
    <div style={{ padding: '60px 0 80px' }}>
      <div className="container" style={{ maxWidth: '960px' }}>
        {/* Header */}
        <div style={{ textAlign: 'center', marginBottom: '50px' }}>
          <span className="badge badge-cyan" style={{ marginBottom: '14px' }}>Privacy & Data Stewardship</span>
          <h1 style={{ fontSize: 'clamp(32px, 4.5vw, 50px)', fontWeight: 800, letterSpacing: '-1px', marginBottom: '16px' }}>
            Transparent Privacy Policy
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '17px', maxWidth: '620px', margin: '0 auto', lineHeight: 1.6 }}>
            AUTO operates on a local-first architecture. We never collect analytics, track usage, or store your private data on remote servers.
          </p>
        </div>

        {/* Local vs Remote Disclosure Table */}
        <div className="card-glass" style={{ padding: '36px', marginBottom: '40px' }}>
          <h2 style={{ fontSize: '22px', fontWeight: 800, marginBottom: '8px' }}>
            Local Processing vs. Remote AI Disclosure
          </h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '24px', lineHeight: 1.6 }}>
            In full engineering transparency, here is the exact architectural boundary between local operations on your Mac and network calls to AI providers:
          </p>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '14px', textAlign: 'left' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-subtle)', color: 'var(--text-muted)' }}>
                  <th style={{ padding: '12px 16px', fontWeight: 700 }}>Operation</th>
                  <th style={{ padding: '12px 16px', fontWeight: 700 }}>Location</th>
                  <th style={{ padding: '12px 16px', fontWeight: 700 }}>Network Transmission</th>
                  <th style={{ padding: '12px 16px', fontWeight: 700 }}>Persistence</th>
                </tr>
              </thead>
              <tbody>
                <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                  <td style={{ padding: '14px 16px', fontWeight: 600 }}>Push-to-Talk (Hold Control)</td>
                  <td style={{ padding: '14px 16px', color: '#4ADE80' }}>100% Local (Mac)</td>
                  <td style={{ padding: '14px 16px', color: 'var(--text-muted)' }}>None</td>
                  <td style={{ padding: '14px 16px' }}>Ephemeral RAM</td>
                </tr>
                <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                  <td style={{ padding: '14px 16px', fontWeight: 600 }}>Audio Metering & VAD</td>
                  <td style={{ padding: '14px 16px', color: '#4ADE80' }}>100% Local (Mac)</td>
                  <td style={{ padding: '14px 16px', color: 'var(--text-muted)' }}>None</td>
                  <td style={{ padding: '14px 16px' }}>Ephemeral RAM</td>
                </tr>
                <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                  <td style={{ padding: '14px 16px', fontWeight: 600 }}>Screen Coordinate Mapping</td>
                  <td style={{ padding: '14px 16px', color: '#4ADE80' }}>100% Local (Mac)</td>
                  <td style={{ padding: '14px 16px', color: 'var(--text-muted)' }}>None</td>
                  <td style={{ padding: '14px 16px' }}>Ephemeral RAM</td>
                </tr>
                <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                  <td style={{ padding: '14px 16px', fontWeight: 600 }}>Cursor Guidance & Clicks</td>
                  <td style={{ padding: '14px 16px', color: '#4ADE80' }}>100% Local (Mac)</td>
                  <td style={{ padding: '14px 16px', color: 'var(--text-muted)' }}>None</td>
                  <td style={{ padding: '14px 16px' }}>Ephemeral RAM</td>
                </tr>
                <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                  <td style={{ padding: '14px 16px', fontWeight: 600 }}>Local Memory Storage</td>
                  <td style={{ padding: '14px 16px', color: '#4ADE80' }}>100% Local (Mac)</td>
                  <td style={{ padding: '14px 16px', color: 'var(--text-muted)' }}>None</td>
                  <td style={{ padding: '14px 16px' }}>Local JSON file</td>
                </tr>
                <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                  <td style={{ padding: '14px 16px', fontWeight: 600 }}>Emergency Stop Interrupt</td>
                  <td style={{ padding: '14px 16px', color: '#4ADE80' }}>100% Local (Mac)</td>
                  <td style={{ padding: '14px 16px', color: 'var(--text-muted)' }}>None</td>
                  <td style={{ padding: '14px 16px' }}>Zero delay (&lt;10ms)</td>
                </tr>
                <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                  <td style={{ padding: '14px 16px', fontWeight: 600 }}>Gemini Cloud AI Reasoning</td>
                  <td style={{ padding: '14px 16px', color: 'var(--accent-cyan)' }}>Google DeepMind</td>
                  <td style={{ padding: '14px 16px', color: 'var(--accent-cyan)' }}>TLS 1.3 HTTPS</td>
                  <td style={{ padding: '14px 16px' }}>Per Google AI Studio policy</td>
                </tr>
                <tr>
                  <td style={{ padding: '14px 16px', fontWeight: 600 }}>Apple Vision OCR & Execution</td>
                  <td style={{ padding: '14px 16px', color: '#4ADE80' }}>Local Machine (Apple Silicon)</td>
                  <td style={{ padding: '14px 16px', color: '#4ADE80' }}>In-Memory IPC</td>
                  <td style={{ padding: '14px 16px' }}>100% Local & Offline</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        {/* Ephemeral Architecture Cards */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
          gap: '24px',
          marginBottom: '40px'
        }}>
          <div className="card-glass" style={{ padding: '28px' }}>
            <EyeOff size={24} color="#00F0FF" style={{ marginBottom: '16px' }} />
            <h3 style={{ fontSize: '18px', fontWeight: 700, marginBottom: '10px' }}>
              Ephemeral Screen Capture
            </h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '14px', lineHeight: 1.6 }}>
              Screen snapshots are taken exclusively when you explicitly ask a screen-related question. Images exist in volatile RAM (<code>CVPixelBuffer</code>) only during inference and are destroyed immediately. No screenshots are saved to disk.
            </p>
          </div>

          <div className="card-glass" style={{ padding: '28px' }}>
            <Key size={24} color="#8B5CF6" style={{ marginBottom: '16px' }} />
            <h3 style={{ fontSize: '18px', fontWeight: 700, marginBottom: '10px' }}>
              Hardware Keychain Security
            </h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '14px', lineHeight: 1.6 }}>
              Your Google Gemini API key is encrypted via macOS Keychain Services (<code>kSecClassGenericPassword</code>). Keys are never stored in plaintext, never written to preferences, and never printed to logs.
            </p>
          </div>

          <div className="card-glass" style={{ padding: '28px' }}>
            <Lock size={24} color="#10B981" style={{ marginBottom: '16px' }} />
            <h3 style={{ fontSize: '18px', fontWeight: 700, marginBottom: '10px' }}>
              Sensitive Credential Rejection
            </h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '14px', lineHeight: 1.6 }}>
              AUTO's local memory engine actively scans all stored content. Attempts to store passwords, bearer tokens, private keys, API secrets, or credit card numbers are rejected to prevent credential leakage.
            </p>
          </div>
        </div>

        {/* User Privacy Controls */}
        <div className="card-glass" style={{ padding: '36px' }}>
          <h3 style={{ fontSize: '20px', fontWeight: 800, marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Trash2 size={22} color="#F43F5E" /> Granular User Data Controls
          </h3>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '20px', lineHeight: 1.6 }}>
            You maintain 100% control over all data stored by AUTO. Within <strong>Settings -&gt; Privacy</strong>, you can:
          </p>

          <ul style={{ paddingLeft: '20px', display: 'flex', flexDirection: 'column', gap: '10px', color: 'var(--text-secondary)', fontSize: '14px' }}>
            <li><strong>Clear Chat History:</strong> Purges all conversation exchanges from memory.</li>
            <li><strong>Clear Local Memory:</strong> Deletes all stored user preferences and project notes from <code>agent_memory.json</code>.</li>
            <li><strong>Clear Task History:</strong> Purges the record of past automation actions.</li>
            <li><strong>Master Purge:</strong> Wipes all Keychain secrets, local memory, preferences, and cached session data in a single click.</li>
          </ul>
        </div>
      </div>
    </div>
  );
};

