import React, { useState } from 'react';
import { Download, Check, Copy, Shield, Terminal, AlertCircle, FileCheck, Apple, ExternalLink } from 'lucide-react';
import metadata from '../release-metadata.json';

export const DownloadPage: React.FC = () => {
  const [copiedChecksum, setCopiedChecksum] = useState(false);

  const copyChecksum = () => {
    navigator.clipboard.writeText(metadata.sha256);
    setCopiedChecksum(true);
    setTimeout(() => setCopiedChecksum(false), 2000);
  };

  return (
    <div style={{ padding: '60px 0 80px' }}>
      <div className="container" style={{ maxWidth: '960px' }}>
        {/* Header */}
        <div style={{ textAlign: 'center', marginBottom: '50px' }}>
          <span className="badge badge-cyan" style={{ marginBottom: '14px' }}>Release Portal</span>
          <h1 style={{ fontSize: 'clamp(32px, 4.5vw, 50px)', fontWeight: 800, letterSpacing: '-1px', marginBottom: '16px' }}>
            Download AUTO for macOS
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '17px', maxWidth: '580px', margin: '0 auto', lineHeight: 1.6 }}>
            Install the native companion application. 100% free with no paywalls, accounts, or telemetry.
          </p>
        </div>

        {/* Primary Download Card */}
        <div className="card-glass" style={{
          padding: '40px',
          marginBottom: '40px',
          border: '1px solid rgba(0, 240, 255, 0.35)',
          boxShadow: '0 20px 40px -15px var(--glow-cyan)'
        }}>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: '24px',
            marginBottom: '32px'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
              <img 
                src="./assets/auto_app_icon.png" 
                alt="AUTO App Icon" 
                style={{ width: '80px', height: '80px', borderRadius: '18px', boxShadow: '0 8px 24px rgba(0, 240, 255, 0.3)' }}
              />
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '4px' }}>
                  <h2 style={{ fontSize: '28px', fontWeight: 800 }}>AUTO v{metadata.version}</h2>
                  <span className="badge badge-green">Production Ready</span>
                </div>
                <div style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
                  Build {metadata.buildNumber} • Released {metadata.releaseDate} • {metadata.dmgSize}
                </div>
              </div>
            </div>

            <a 
              href={metadata.downloadPath}
              className="btn-primary" 
              style={{ padding: '16px 36px', fontSize: '16px' }}
            >
              <Download size={20} />
              <span>Download DMG Installer</span>
            </a>
          </div>

          {/* Specs Grid */}
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
            gap: '16px',
            padding: '20px',
            background: 'rgba(10, 14, 26, 0.6)',
            borderRadius: '12px',
            border: '1px solid var(--border-subtle)',
            marginBottom: '28px'
          }}>
            <div>
              <div style={{ fontSize: '11px', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>Compatibility</div>
              <div style={{ fontSize: '14px', fontWeight: 600, color: '#fff', marginTop: '4px' }}>{metadata.minimumMacOSVersion}</div>
            </div>
            <div>
              <div style={{ fontSize: '11px', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>Architecture</div>
              <div style={{ fontSize: '14px', fontWeight: 600, color: '#fff', marginTop: '4px' }}>Apple Silicon & Intel x86_64</div>
            </div>
            <div>
              <div style={{ fontSize: '11px', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>Package Size</div>
              <div style={{ fontSize: '14px', fontWeight: 600, color: '#fff', marginTop: '4px' }}>{metadata.dmgSize} DMG ({metadata.appBundleSize} .app)</div>
            </div>
            <div>
              <div style={{ fontSize: '11px', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>License & Cost</div>
              <div style={{ fontSize: '14px', fontWeight: 600, color: '#4ADE80', marginTop: '4px' }}>100% Free Forever</div>
            </div>
          </div>

          {/* SHA-256 Checksum Box */}
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
              <span style={{ fontSize: '12px', fontWeight: 700, color: 'var(--text-secondary)', display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
                <FileCheck size={14} color="#00F0FF" /> Verified SHA-256 Checksum:
              </span>
              <button 
                onClick={copyChecksum} 
                style={{ fontSize: '11px', color: copiedChecksum ? '#4ADE80' : 'var(--accent-cyan)', display: 'inline-flex', alignItems: 'center', gap: '4px' }}
              >
                {copiedChecksum ? <Check size={12} /> : <Copy size={12} />}
                <span>{copiedChecksum ? 'Copied to Clipboard' : 'Copy Checksum'}</span>
              </button>
            </div>
            <div className="code-block" style={{ fontSize: '12px', color: '#38BDF8', wordBreak: 'break-all' }}>
              {metadata.sha256}
            </div>
          </div>
        </div>

        {/* Step-by-Step Installation Instructions */}
        <div className="card-glass" style={{ padding: '36px', marginBottom: '40px' }}>
          <h3 style={{ fontSize: '20px', fontWeight: 800, marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Apple size={22} color="#00F0FF" /> Standard macOS Installation
          </h3>

          <ol style={{ paddingLeft: '20px', display: 'flex', flexDirection: 'column', gap: '16px', color: 'var(--text-secondary)', fontSize: '14px', lineHeight: 1.6 }}>
            <li>
              <strong style={{ color: '#fff' }}>1. Mount Disk Image:</strong> Double-click the downloaded <code>AUTO-1.0.0.dmg</code> file to mount the disk image.
            </li>
            <li>
              <strong style={{ color: '#fff' }}>2. Install into Applications:</strong> Drag the <strong>AUTO</strong> mascot icon into the <strong>Applications</strong> shortcut folder.
            </li>
            <li>
              <strong style={{ color: '#fff' }}>3. Eject Installer:</strong> Eject the disk image from Finder.
            </li>
            <li>
              <strong style={{ color: '#fff' }}>4. Launch & Configure:</strong> Open <strong>AUTO</strong> from Applications or Spotlight (<code>⌘ Space</code>). Follow the 5-step onboarding wizard to enter your Gemini API key and grant necessary permissions.
            </li>
          </ol>
        </div>

        {/* Gatekeeper Ad-Hoc Notice */}
        <div className="card-glass" style={{
          padding: '28px',
          background: 'rgba(245, 158, 11, 0.05)',
          border: '1px solid rgba(245, 158, 11, 0.3)'
        }}>
          <div style={{ display: 'flex', gap: '16px' }}>
            <AlertCircle size={24} color="#F59E0B" style={{ flexShrink: 0 }} />
            <div>
              <h4 style={{ fontSize: '16px', fontWeight: 700, color: '#F59E0B', marginBottom: '6px' }}>
                First-Launch Gatekeeper Notice (Ad-Hoc Signing)
              </h4>
              <p style={{ fontSize: '13px', color: 'var(--text-secondary)', lineHeight: 1.6, marginBottom: '10px' }}>
                AUTO is an independent open-source desktop companion signed with hardened ad-hoc signatures. On your very first launch, macOS Gatekeeper may prompt: <em>"AUTO cannot be opened because the developer cannot be verified."</em>
              </p>
              <div style={{ fontSize: '13px', color: '#fff', background: 'rgba(0, 0, 0, 0.3)', padding: '10px 14px', borderRadius: '8px' }}>
                <strong>To open on first launch:</strong> Right-click (or Control-click) <code>AUTO.app</code> in your <code>/Applications</code> folder, select <strong>Open</strong>, and click <strong>Open</strong> in the alert dialog. You only need to do this once.
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

