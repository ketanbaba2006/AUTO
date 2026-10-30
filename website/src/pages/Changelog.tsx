import React from 'react';
import { Tag, Calendar, CheckCircle2, Package } from 'lucide-react';
import metadata from '../release-metadata.json';

export const ChangelogPage: React.FC = () => {
  return (
    <div style={{ padding: '60px 0 80px' }}>
      <div className="container" style={{ maxWidth: '840px' }}>
        {/* Header */}
        <div style={{ textAlign: 'center', marginBottom: '50px' }}>
          <span className="badge badge-cyan" style={{ marginBottom: '14px' }}>Release History</span>
          <h1 style={{ fontSize: 'clamp(32px, 4.5vw, 48px)', fontWeight: 800, letterSpacing: '-1px', marginBottom: '16px' }}>
            AUTO Changelog
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '17px', maxWidth: '580px', margin: '0 auto', lineHeight: 1.6 }}>
            Track every release, technical enhancement, and security update to the AUTO macOS desktop companion.
          </p>
        </div>

        {/* Release Entry v1.0.0 */}
        <div className="card-glass" style={{ padding: '36px', borderLeft: '4px solid var(--accent-cyan)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '12px', marginBottom: '20px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <span style={{ fontSize: '24px', fontWeight: 800 }}>v{metadata.version}</span>
              <span className="badge badge-green">Production Stable</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', color: 'var(--text-muted)' }}>
              <Calendar size={14} />
              <span>{metadata.releaseDate}</span>
            </div>
          </div>

          <p style={{ color: 'var(--text-secondary)', fontSize: '15px', lineHeight: 1.6, marginBottom: '24px' }}>
            Official public release of <strong>AUTO</strong>, delivering the completed architecture across all 7 development fragments with 84 passing automated unit and integration tests.
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            {/* Section 1 */}
            <div>
              <h4 style={{ fontSize: '16px', fontWeight: 700, color: '#fff', marginBottom: '8px' }}>
                1. Native Foundation & Floating Panel (Fragment 1)
              </h4>
              <ul style={{ paddingLeft: '20px', fontSize: '14px', color: 'var(--text-secondary)', display: 'flex', flexDirection: 'column', gap: '4px' }}>
                <li>Menu bar resident accessory with custom vector icon and native context menus.</li>
                <li>Floating borderless Companion Panel with live indicators and audio waveforms.</li>
                <li>Transparent multi-monitor overlay windows for spatial targeting reticles.</li>
                <li>Hardware power, sleep/wake, and display reconnection lifecycle management.</li>
              </ul>
            </div>

            {/* Section 2 */}
            <div>
              <h4 style={{ fontSize: '16px', fontWeight: 700, color: '#fff', marginBottom: '8px' }}>
                2. AI Infrastructure & Model Discovery (Fragment 2)
              </h4>
              <ul style={{ paddingLeft: '20px', fontSize: '14px', color: 'var(--text-secondary)', display: 'flex', flexDirection: 'column', gap: '4px' }}>
                <li>Google Gemini API integration with streaming responses and token tracking.</li>
                <li>Hybrid AI Architecture with 13 local Swift execution services and Zero-Screenshot privacy gating.</li>
                <li>Dynamic task-based AI routing rules with automatic fallback to Gemini.</li>
                <li>Hardware-backed encryption for all provider keys via macOS Keychain.</li>
              </ul>
            </div>

            {/* Section 3 */}
            <div>
              <h4 style={{ fontSize: '16px', fontWeight: 700, color: '#fff', marginBottom: '8px' }}>
                3. Live Push-to-Talk Voice Conversations (Fragment 3)
              </h4>
              <ul style={{ paddingLeft: '20px', fontSize: '14px', color: 'var(--text-secondary)', display: 'flex', flexDirection: 'column', gap: '4px' }}>
                <li>Global Hold-Control push-to-talk shortcut using low-level CGEvent taps.</li>
                <li>Real-time AVAudioEngine capture with Voice Activity Detection (RMS energy).</li>
                <li>Apple Speech on-device and cloud transcription (SFSpeechRecognizer).</li>
                <li>Natural speech output via AVSpeechSynthesizer with instant speech interruption.</li>
              </ul>
            </div>

            {/* Section 4 */}
            <div>
              <h4 style={{ fontSize: '16px', fontWeight: 700, color: '#fff', marginBottom: '8px' }}>
                4. Visual Screen Intelligence (Fragment 4)
              </h4>
              <ul style={{ paddingLeft: '20px', fontSize: '14px', color: 'var(--text-secondary)', display: 'flex', flexDirection: 'column', gap: '4px' }}>
                <li>ScreenCaptureKit capture across multi-monitor negative coordinate spaces.</li>
                <li>Window inspection, window-specific capture, and display arrangement mapping.</li>
                <li>Ephemeral in-memory image processing with Retina downsampling and JPEG encoding.</li>
              </ul>
            </div>

            {/* Section 5 */}
            <div>
              <h4 style={{ fontSize: '16px', fontWeight: 700, color: '#fff', marginBottom: '8px' }}>
                5. Desktop Automation & Safety Gating (Fragment 5)
              </h4>
              <ul style={{ paddingLeft: '20px', fontSize: '14px', color: 'var(--text-secondary)', display: 'flex', flexDirection: 'column', gap: '4px' }}>
                <li>Accessibility element hierarchy traversal via macOS AXUIElement APIs.</li>
                <li>Natural language control matching with fuzzy scoring and ambiguity detection.</li>
                <li>Smooth Bezier cursor guidance, hardware clicks, typing, and keyboard shortcuts.</li>
                <li>Three-tier risk rating with mandatory modal approval for destructive actions.</li>
                <li>Triple-channel Emergency Stop (&lt;10ms latency) via Voice, UI button, or Escape.</li>
              </ul>
            </div>

            {/* Section 6 */}
            <div>
              <h4 style={{ fontSize: '16px', fontWeight: 700, color: '#fff', marginBottom: '8px' }}>
                6. Autonomous Agent & Local Memory (Fragment 6)
              </h4>
              <ul style={{ paddingLeft: '20px', fontSize: '14px', color: 'var(--text-secondary)', display: 'flex', flexDirection: 'column', gap: '4px' }}>
                <li>Multi-step task planner with explicit step dependency resolution.</li>
                <li>Modular tool registry with 16+ built-in tools across 6 functional domains.</li>
                <li>Sandboxed local file operations on Desktop, Downloads, and Documents.</li>
                <li>Private persistent JSON memory (agent_memory.json) with credential rejection.</li>
                <li>Multi-turn conversation summarization to avoid token overflow.</li>
              </ul>
            </div>

            {/* Section 7 */}
            <div>
              <h4 style={{ fontSize: '16px', fontWeight: 700, color: '#fff', marginBottom: '8px' }}>
                7. Integration, Security & Packaging (Fragment 7)
              </h4>
              <ul style={{ paddingLeft: '20px', fontSize: '14px', color: 'var(--text-secondary)', display: 'flex', flexDirection: 'column', gap: '4px' }}>
                <li>Swift 6 @MainActor concurrency hardening across all subsystems.</li>
                <li>Unified Permissions Hub in Settings and 5-step onboarding wizard.</li>
                <li>Dedicated Privacy section with local vs. remote disclosures and granular purging.</li>
                <li>Packaging script producing signed AUTO.app (16 MB) and AUTO-1.0.0.dmg (11 MB).</li>
                <li>84 automated unit and integration tests passing with 100% success.</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

