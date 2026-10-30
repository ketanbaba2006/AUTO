import React from 'react';
import { Heart, Sparkles, Terminal, Shield, CheckCircle2 } from 'lucide-react';
import metadata from '../release-metadata.json';

export const AboutPage: React.FC = () => {
  return (
    <div style={{ padding: '60px 0 80px' }}>
      <div className="container" style={{ maxWidth: '880px' }}>
        {/* Header */}
        <div style={{ textAlign: 'center', marginBottom: '50px' }}>
          <img 
            src="./assets/auto_mascot.png" 
            alt="AUTO Mascot" 
            style={{ width: '96px', height: '96px', borderRadius: '24px', marginBottom: '20px', boxShadow: '0 8px 30px rgba(0, 240, 255, 0.4)' }}
          />
          <span className="badge badge-cyan" style={{ marginBottom: '14px' }}>About AUTO</span>
          <h1 style={{ fontSize: 'clamp(32px, 4.5vw, 48px)', fontWeight: 800, letterSpacing: '-1px', marginBottom: '16px' }}>
            {metadata.productName}
          </h1>
          <p style={{ color: 'var(--accent-cyan)', fontSize: '18px', fontWeight: 600 }}>
            {metadata.tagline}
          </p>
        </div>

        {/* Mission & Philosophy Card */}
        <div className="card-glass" style={{ padding: '36px', marginBottom: '32px' }}>
          <h2 style={{ fontSize: '22px', fontWeight: 800, marginBottom: '16px' }}>
            Mission & Product Philosophy
          </h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '15px', lineHeight: 1.7, marginBottom: '16px' }}>
            Modern AI assistants are often trapped behind web tabs, bloated Electron wrappers, or intrusive SaaS subscriptions that monitor every keystroke. 
          </p>
          <p style={{ color: 'var(--text-secondary)', fontSize: '15px', lineHeight: 1.7, marginBottom: '16px' }}>
            <strong>AUTO</strong> was built with a different philosophy: to create an unobtrusive, lightning-fast native macOS desktop companion that respects user privacy, operates without accounts, and gives users full control over when it listens, looks, and assists.
          </p>
        </div>

        {/* Core Commitments Grid */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))',
          gap: '20px',
          marginBottom: '32px'
        }}>
          <div className="card-glass" style={{ padding: '24px' }}>
            <Terminal size={24} color="#00F0FF" style={{ marginBottom: '12px' }} />
            <h3 style={{ fontSize: '17px', fontWeight: 700, marginBottom: '8px' }}>100% Native macOS</h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '13px', lineHeight: 1.6 }}>
              Engineered exclusively in Swift, SwiftUI, AppKit, ScreenCaptureKit, and CoreGraphics. Zero web wrappers, instant startup, and tiny resource footprint.
            </p>
          </div>

          <div className="card-glass" style={{ padding: '24px' }}>
            <Shield size={24} color="#8B5CF6" style={{ marginBottom: '12px' }} />
            <h3 style={{ fontSize: '17px', fontWeight: 700, marginBottom: '8px' }}>100% Free & Private</h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '13px', lineHeight: 1.6 }}>
              No subscriptions, paywalls, premium tiers, or user tracking. All secrets reside in macOS Keychain, and captures exist only in volatile RAM.
            </p>
          </div>

          <div className="card-glass" style={{ padding: '24px' }}>
            <Heart size={24} color="#F43F5E" style={{ marginBottom: '12px' }} />
            <h3 style={{ fontSize: '17px', fontWeight: 700, marginBottom: '8px' }}>Open-Source Spirit</h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '13px', lineHeight: 1.6 }}>
              Inspired by and referencing design patterns from Farza's open-source HeyClicky project, reimagined for production native macOS desktop assistance.
            </p>
          </div>
        </div>

        {/* Acknowledgements Box */}
        <div className="card-glass" style={{ padding: '32px', background: 'rgba(10, 14, 26, 0.5)' }}>
          <h3 style={{ fontSize: '18px', fontWeight: 800, marginBottom: '12px' }}>
            Acknowledgements & Attribution
          </h3>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px', lineHeight: 1.6, marginBottom: '12px' }}>
            We gratefully acknowledge the open-source community:
          </p>
          <ul style={{ paddingLeft: '20px', display: 'flex', flexDirection: 'column', gap: '8px', color: 'var(--text-secondary)', fontSize: '14px' }}>
            <li>
              <strong>HeyClicky:</strong> Interaction concepts and push-to-talk companion design inspired by Farza (<a href="https://github.com/farzaa/clicky" target="_blank" rel="noopener noreferrer" style={{ color: 'var(--accent-cyan)' }}>github.com/farzaa/clicky</a>).
            </li>
            <li>
              <strong>Google DeepMind:</strong> High-performance multimodal intelligence powered by the Google Gemini API.
            </li>
            <li>
              <strong>Apple Engineering:</strong> Native foundation powered by Swift, SwiftUI, ScreenCaptureKit, and AppKit.
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
};

