import React from 'react';
import { Download, Sparkles, Mic, Monitor, MousePointer, Shield, Brain, ArrowRight, CheckCircle2, Terminal } from 'lucide-react';
import metadata from '../release-metadata.json';

interface HomeProps {
  setActiveTab: (tab: string) => void;
}

export const Home: React.FC<HomeProps> = ({ setActiveTab }) => {
  return (
    <div>
      {/* Hero Section */}
      <section style={{ padding: '80px 0 60px', position: 'relative' }}>
        <div className="container">
          <div className="hero-grid" style={{
            display: 'grid',
            gridTemplateColumns: '1.2fr 0.8fr',
            gap: '60px',
            alignItems: 'center'
          }}>
            {/* Left Content */}
            <div>
              <div style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', marginBottom: '20px' }}>
                <span className="badge badge-cyan">
                  <Sparkles size={13} /> Official Release v{metadata.version}
                </span>
                <span className="badge badge-purple">macOS Sonoma & Sequoia</span>
              </div>

              <h1 style={{
                fontSize: 'clamp(40px, 5.5vw, 64px)',
                fontWeight: 800,
                lineHeight: 1.1,
                letterSpacing: '-1.5px',
                marginBottom: '20px'
              }}>
                Your Mac.<br />
                <span className="gradient-text">Your AI Companion.</span>
              </h1>

              <p style={{
                fontSize: '18px',
                color: 'var(--text-secondary)',
                lineHeight: 1.6,
                marginBottom: '32px',
                maxWidth: '560px'
              }}>
                Meet <strong>AUTO</strong>, your personal AI desktop companion that understands your screen, listens to your voice via push-to-talk, and safely helps you get things done.
              </p>

              <div className="hero-buttons" style={{ display: 'flex', gap: '16px', flexWrap: 'wrap', marginBottom: '40px' }}>
                <button onClick={() => setActiveTab('download')} className="btn-primary">
                  <Download size={18} />
                  <span>Download for macOS (DMG)</span>
                </button>
                <button onClick={() => setActiveTab('features')} className="btn-secondary">
                  <span>Explore Features</span>
                  <ArrowRight size={16} />
                </button>
              </div>

              {/* Guarantees row */}
              <div style={{
                display: 'flex',
                gap: '24px',
                flexWrap: 'wrap',
                fontSize: '13px',
                color: 'var(--text-muted)'
              }}>
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
                  <CheckCircle2 size={16} color="#00F0FF" /> 100% Free Forever
                </span>
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
                  <CheckCircle2 size={16} color="#00F0FF" /> Zero Telemetry & Private
                </span>
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
                  <CheckCircle2 size={16} color="#00F0FF" /> Hardware Keychain Security
                </span>
              </div>
            </div>

            {/* Right Hero Mascot Artwork */}
            <div style={{ display: 'flex', justifyContent: 'center' }}>
              <div style={{ position: 'relative' }}>
                <div style={{
                  position: 'absolute',
                  inset: '-20px',
                  background: 'radial-gradient(circle, rgba(0,240,255,0.25) 0%, rgba(139,92,246,0.15) 50%, transparent 70%)',
                  filter: 'blur(30px)',
                  zIndex: 0
                }} />
                <img 
                  src="./assets/auto_mascot.png" 
                  alt="AUTO Mascot Robot" 
                  className="mascot-glow"
                  style={{
                    width: '320px',
                    maxWidth: '100%',
                    height: 'auto',
                    borderRadius: '32px',
                    position: 'relative',
                    zIndex: 1,
                    border: '2px solid rgba(0, 240, 255, 0.4)'
                  }}
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Verified Stats Bar */}
      <section style={{
        background: 'var(--bg-surface)',
        borderTop: '1px solid var(--border-subtle)',
        borderBottom: '1px solid var(--border-subtle)',
        padding: '24px 0'
      }}>
        <div className="container">
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
            gap: '24px',
            textAlign: 'center'
          }}>
            <div>
              <div style={{ fontSize: '26px', fontWeight: 800, color: 'var(--accent-cyan)' }}>84 / 84</div>
              <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>Automated Tests Passing</div>
            </div>
            <div>
              <div style={{ fontSize: '26px', fontWeight: 800, color: '#fff' }}>&lt; 10 ms</div>
              <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>Emergency Stop Latency</div>
            </div>
            <div>
              <div style={{ fontSize: '26px', fontWeight: 800, color: 'var(--accent-purple)' }}>0 MB</div>
              <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>Screen Caching (RAM-Only)</div>
            </div>
            <div>
              <div style={{ fontSize: '26px', fontWeight: 800, color: '#4ADE80' }}>$0.00</div>
              <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>No Subscriptions or Paywalls</div>
            </div>
          </div>
        </div>
      </section>

      {/* Core Highlights */}
      <section style={{ padding: '80px 0' }}>
        <div className="container">
          <div style={{ textAlign: 'center', marginBottom: '50px' }}>
            <span className="badge badge-cyan" style={{ marginBottom: '12px' }}>Core Capabilities</span>
            <h2 style={{ fontSize: '36px', fontWeight: 800, letterSpacing: '-0.5px', marginBottom: '16px' }}>
              Designed Exclusively for Native macOS
            </h2>
            <p style={{ color: 'var(--text-secondary)', fontSize: '16px', maxWidth: '600px', margin: '0 auto' }}>
              Unlike electron or web wrappers, AUTO leverages deep Apple APIs to deliver instant responsiveness and zero memory bloat.
            </p>
          </div>

          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
            gap: '24px'
          }}>
            {/* Feature 1 */}
            <div className="card-glass" style={{ padding: '32px' }}>
              <div style={{
                width: '48px',
                height: '48px',
                borderRadius: '12px',
                background: 'rgba(0, 240, 255, 0.12)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                marginBottom: '20px',
                color: 'var(--accent-cyan)'
              }}>
                <Mic size={24} />
              </div>
              <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '12px' }}>
                Hold-Control Push-to-Talk
              </h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '14px', lineHeight: 1.6, marginBottom: '16px' }}>
                Hold the <code>Control</code> key anywhere on macOS to speak naturally. AUTO streams speech recognition in real-time, responds through natural voice, and can be interrupted mid-sentence anytime.
              </p>
              <div style={{ fontSize: '12px', color: 'var(--accent-cyan)', fontWeight: 600 }}>
                Global CGEvent Tap • AVSpeechSynthesizer
              </div>
            </div>

            {/* Feature 2 */}
            <div className="card-glass" style={{ padding: '32px' }}>
              <div style={{
                width: '48px',
                height: '48px',
                borderRadius: '12px',
                background: 'rgba(139, 92, 246, 0.12)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                marginBottom: '20px',
                color: 'var(--accent-purple)'
              }}>
                <Monitor size={24} />
              </div>
              <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '12px' }}>
                Multi-Monitor Screen Vision
              </h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '14px', lineHeight: 1.6, marginBottom: '16px' }}>
                Powered by native ScreenCaptureKit. Ask questions about anything visible on your monitors. Screenshots exist in volatile RAM only during inference and are destroyed immediately.
              </p>
              <div style={{ fontSize: '12px', color: 'var(--accent-purple)', fontWeight: 600 }}>
                ScreenCaptureKit • Negative Virtual Coordinates
              </div>
            </div>

            {/* Feature 3 */}
            <div className="card-glass" style={{ padding: '32px' }}>
              <div style={{
                width: '48px',
                height: '48px',
                borderRadius: '12px',
                background: 'rgba(0, 102, 255, 0.12)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                marginBottom: '20px',
                color: '#60A5FA'
              }}>
                <MousePointer size={24} />
              </div>
              <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '12px' }}>
                Safe Desktop Automation
              </h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '14px', lineHeight: 1.6, marginBottom: '16px' }}>
                Inspects UI controls using macOS Accessibility (AXUIElement). Traverses buttons, menus, and fields with Bezier cursor guidance. High-risk actions require single-click user confirmation.
              </p>
              <div style={{ fontSize: '12px', color: '#60A5FA', fontWeight: 600 }}>
                Three-Tier Safety Gating • Instant Emergency Stop
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* How It Works Section (Section 13) */}
      <section style={{
        background: 'var(--bg-surface)',
        borderTop: '1px solid var(--border-subtle)',
        borderBottom: '1px solid var(--border-subtle)',
        padding: '80px 0'
      }}>
        <div className="container">
          <div style={{ textAlign: 'center', marginBottom: '50px' }}>
            <span className="badge badge-purple" style={{ marginBottom: '12px' }}>Workflow</span>
            <h2 style={{ fontSize: '36px', fontWeight: 800, letterSpacing: '-0.5px', marginBottom: '16px' }}>
              How AUTO Works in 8 Simple Steps
            </h2>
            <p style={{ color: 'var(--text-secondary)', fontSize: '16px', maxWidth: '600px', margin: '0 auto' }}>
              From initial download to automated desktop assistance in under two minutes.
            </p>
          </div>

          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
            gap: '20px'
          }}>
            {[
              { step: '1', title: 'Download AUTO', desc: 'Get the verified AUTO-1.0.0.dmg package.' },
              { step: '2', title: 'Install Application', desc: 'Drag AUTO into your macOS /Applications folder.' },
              { step: '3', title: 'Configure Gemini', desc: 'Save your Google Gemini API key to macOS Keychain.' },
              { step: '4', title: 'Optional OmniRoute', desc: 'Optionally connect local models (Ollama, LM Studio).' },
              { step: '5', title: 'Grant Permissions', desc: 'Allow Accessibility, Mic, and Screen Recording.' },
              { step: '6', title: 'Hold Control to Talk', desc: 'Press and hold ⌃ to speak naturally anytime.' },
              { step: '7', title: 'Ask for Assistance', desc: 'Ask about screen content, files, or multi-step tasks.' },
              { step: '8', title: 'Approve Actions', desc: 'Review and confirm consequential actions safely.' }
            ].map((item) => (
              <div key={item.step} className="card-glass" style={{ padding: '24px' }}>
                <div style={{
                  fontSize: '28px',
                  fontWeight: 800,
                  color: 'var(--accent-cyan)',
                  marginBottom: '10px'
                }}>
                  0{item.step}
                </div>
                <h4 style={{ fontSize: '16px', fontWeight: 700, marginBottom: '8px' }}>{item.title}</h4>
                <p style={{ color: 'var(--text-secondary)', fontSize: '13px', lineHeight: 1.5 }}>{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Box */}
      <section style={{ padding: '80px 0 20px' }}>
        <div className="container">
          <div className="card-glass" style={{
            padding: '50px 30px',
            textAlign: 'center',
            background: 'linear-gradient(135deg, rgba(22, 31, 54, 0.9) 0%, rgba(10, 14, 26, 0.95) 100%)',
            border: '1px solid rgba(0, 240, 255, 0.3)',
            boxShadow: '0 20px 50px -20px var(--glow-cyan)'
          }}>
            <h2 style={{ fontSize: '36px', fontWeight: 800, marginBottom: '16px' }}>
              Experience Your Personal macOS AI Companion
            </h2>
            <p style={{ color: 'var(--text-secondary)', fontSize: '16px', maxWidth: '580px', margin: '0 auto 32px', lineHeight: 1.6 }}>
              Native Swift engineering, zero telemetry, local memory, and hardware Keychain security. 100% free with no paywalls.
            </p>
            <button onClick={() => setActiveTab('download')} className="btn-primary" style={{ padding: '14px 32px', fontSize: '16px' }}>
              <Download size={20} />
              <span>Download AUTO v{metadata.version} (DMG)</span>
            </button>
          </div>
        </div>
      </section>
    </div>
  );
};

