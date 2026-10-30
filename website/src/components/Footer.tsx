import React from 'react';
import { Shield, Sparkles, Terminal, Heart } from 'lucide-react';
import metadata from '../release-metadata.json';

interface FooterProps {
  setActiveTab: (tab: string) => void;
}

export const Footer: React.FC<FooterProps> = ({ setActiveTab }) => {
  return (
    <footer style={{
      background: 'var(--bg-surface)',
      borderTop: '1px solid var(--border-subtle)',
      padding: '60px 0 30px',
      marginTop: '80px'
    }}>
      <div className="container">
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
          gap: '40px',
          marginBottom: '50px'
        }}>
          {/* Brand Col */}
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '14px' }}>
              <img 
                src="./assets/auto_mascot_64.png" 
                alt="AUTO Mascot" 
                style={{ width: '32px', height: '32px', borderRadius: '8px' }}
              />
              <span style={{ fontSize: '20px', fontWeight: 800 }} className="gradient-text-cyan">
                {metadata.productName}
              </span>
            </div>
            <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '16px', lineHeight: 1.6 }}>
              {metadata.tagline} Engineered strictly in native Swift, SwiftUI, AppKit, ScreenCaptureKit, and CoreGraphics.
            </p>
            <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
              <span className="badge badge-green">100% Free Forever</span>
              <span className="badge badge-cyan">Zero Telemetry</span>
            </div>
          </div>

          {/* Navigation Col */}
          <div>
            <h4 style={{ color: '#fff', fontSize: '14px', fontWeight: 700, marginBottom: '16px', textTransform: 'uppercase', letterSpacing: '1px' }}>
              Product & Download
            </h4>
            <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '14px', color: 'var(--text-secondary)' }}>
              <li><a href="#features" onClick={() => setActiveTab('features')}>Features Overview</a></li>
              <li><a href="#download" onClick={() => setActiveTab('download')}>Download macOS App (DMG)</a></li>
              <li><a href="#changelog" onClick={() => setActiveTab('changelog')}>Version 1.0.0 Changelog</a></li>
              <li><a href="#privacy" onClick={() => setActiveTab('privacy')}>Privacy & Stewardship</a></li>
            </ul>
          </div>

          {/* Docs & Architecture Col */}
          <div>
            <h4 style={{ color: '#fff', fontSize: '14px', fontWeight: 700, marginBottom: '16px', textTransform: 'uppercase', letterSpacing: '1px' }}>
              Documentation
            </h4>
            <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '14px', color: 'var(--text-secondary)' }}>
              <li><a href="#docs" onClick={() => setActiveTab('docs')}>Installation Guide</a></li>
              <li><a href="#docs" onClick={() => setActiveTab('docs')}>Push-to-Talk Voice Setup</a></li>
              <li><a href="#docs" onClick={() => setActiveTab('docs')}>Screen Intelligence</a></li>
              <li><a href="#docs" onClick={() => setActiveTab('docs')}>Automation Safety & Failsafes</a></li>
              <li><a href="#docs" onClick={() => setActiveTab('docs')}>Troubleshooting & FAQs</a></li>
            </ul>
          </div>

          {/* Open Source Col */}
          <div>
            <h4 style={{ color: '#fff', fontSize: '14px', fontWeight: 700, marginBottom: '16px', textTransform: 'uppercase', letterSpacing: '1px' }}>
              Open Source & Credits
            </h4>
            <p style={{ color: 'var(--text-secondary)', fontSize: '13px', lineHeight: 1.6, marginBottom: '12px' }}>
              Inspired by and referencing design patterns from the open-source <strong>HeyClicky</strong> project by Farza.
            </p>
            <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
              Primary AI: Google Gemini<br />
              Optional Gateway: OmniRoute
            </div>
          </div>
        </div>

        <div style={{
          borderTop: '1px solid var(--border-subtle)',
          paddingTop: '24px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '12px',
          fontSize: '13px',
          color: 'var(--text-muted)'
        }}>
          <div>
            © 2026 AUTO. Free native macOS desktop companion.
          </div>
          <div style={{ display: 'flex', gap: '18px' }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
              <Shield size={14} color="#00F0FF" /> Local Keychain Encryption
            </span>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
              <Terminal size={14} color="#8B5CF6" /> 100% Native Swift
            </span>
          </div>
        </div>
      </div>
    </footer>
  );
};

