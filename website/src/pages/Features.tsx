import React from 'react';
import { Sparkles, Network, Mic, Monitor, MousePointer, ListTodo, Brain, Shield, AlertTriangle, Cpu } from 'lucide-react';
import metadata from '../release-metadata.json';

interface FeaturesProps {
  setActiveTab: (tab: string) => void;
}

export const Features: React.FC<FeaturesProps> = ({ setActiveTab }) => {
  const featureList = [
    {
      icon: Sparkles,
      color: 'var(--accent-cyan)',
      title: 'Google Gemini Multimodal AI',
      category: 'PRIMARY AI ENGINE',
      desc: 'Harnesses Google DeepMind Gemini models for high-speed streaming generation, complex reasoning, and multimodal visual screenshot analysis. Configurable model selection, token tracking, and 403/429 error mapping.',
      details: ['Dynamic model discovery', 'Streaming response chunks', 'Spatial point token extraction', 'Encrypted Keychain storage']
    },
    {
      icon: Network,
      color: 'var(--accent-purple)',
      title: 'Optional OmniRoute Gateway',
      category: 'UNIVERSAL GATEWAY',
      desc: 'Connect alternative remote or local models (such as Ollama, LM Studio, or custom OpenAI-compatible proxies) without changing workflows. If OmniRoute is offline, AUTO automatically falls back to Gemini.',
      details: ['Local model support (100% offline)', 'Custom endpoint profiles', 'Automatic fallback to Gemini', 'Zero mandatory setup']
    },
    {
      icon: Mic,
      color: '#38BDF8',
      title: 'Global Hold-Control Push-to-Talk',
      category: 'VOICE CONVERSATION',
      desc: 'Hold the Control key anywhere on macOS to speak. Releasing the key stops recording and initiates immediate AI processing. Features real-time voice activity detection (RMS) and instant speech interruption.',
      details: ['Global CGEvent modifier tap', 'Real-time audio metering', 'Apple Speech STT engine', 'Instant speech interruption']
    },
    {
      icon: Monitor,
      color: '#A855F7',
      title: 'Screen & Multi-Monitor Intelligence',
      category: 'VISUAL REASONING',
      desc: 'Built on Apple ScreenCaptureKit. AUTO understands visible application windows, negative coordinate spaces, and multi-display arrangements. Captures are held in volatile RAM only during inference and destroyed immediately.',
      details: ['Full display & window capture', 'Negative coordinate normalization', 'Retina display downsampling', 'Zero permanent screenshot storage']
    },
    {
      icon: MousePointer,
      color: '#F43F5E',
      title: 'Permission-Based Cursor Guidance',
      category: 'DESKTOP AUTOMATION',
      desc: 'Inspects active window UI trees via macOS Accessibility APIs (AXUIElement). Locates controls with natural language fuzzy scoring, plans smooth Bezier cursor trajectories, and executes clicks, typing, and hotkeys.',
      details: ['Three-tier risk rating', 'Mandatory high-risk modal approval', '<10ms local Emergency Stop', 'Hardware failsafe button release']
    },
    {
      icon: ListTodo,
      color: '#F59E0B',
      title: 'Autonomous Multi-Step Task Planning',
      category: 'AGENT ENGINE',
      desc: 'Decomposes complex requests into structured plans with explicit step dependencies. Features a 16+ tool catalog across 6 domains, state verification after each step, and sandboxed local file organization.',
      details: ['Step dependency ordering', 'Post-action outcome verification', 'Sandboxed user file access', 'System directory defense']
    },
    {
      icon: Brain,
      color: '#10B981',
      title: 'Private Local Persistent Memory',
      category: 'MEMORY & COMPACTION',
      desc: 'Remembers user preferences, project context, and frequent instructions locally at ~/Library/Application Support/AUTO/agent_memory.json. Automatically scans and rejects passwords, API keys, and credentials.',
      details: ['5 partitioned categories', 'Relevance ranking & prompt injection', 'Credential security scanner', 'Multi-turn conversation compaction']
    },
    {
      icon: Shield,
      color: '#6366F1',
      title: 'Defense-in-Depth Privacy Hub',
      category: 'SECURITY & PRIVACY',
      desc: 'Transparent disclosure of what executes locally vs. what uses remote AI APIs. Unified permissions manager for Microphone, Speech, Screen Recording, and Accessibility, plus single-click granular memory purging.',
      details: ['Zero analytics or telemetry', 'Local vs. remote disclosure', 'Granular data clearance', 'Hardware Keychain secrets']
    }
  ];

  return (
    <div style={{ padding: '60px 0 80px' }}>
      <div className="container">
        {/* Header */}
        <div style={{ textAlign: 'center', marginBottom: '60px' }}>
          <span className="badge badge-cyan" style={{ marginBottom: '14px' }}>Feature Specifications</span>
          <h1 style={{ fontSize: 'clamp(32px, 4.5vw, 52px)', fontWeight: 800, letterSpacing: '-1px', marginBottom: '18px' }}>
            Complete Companion Intelligence
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '17px', maxWidth: '640px', margin: '0 auto', lineHeight: 1.6 }}>
            Every capability in AUTO is engineered natively in Swift for macOS 14+ Sonoma and Sequoia. No web wrappers, no Electron, and no hidden subscriptions.
          </p>
        </div>

        {/* Feature Grid */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))',
          gap: '24px'
        }}>
          {featureList.map((item, idx) => {
            const Icon = item.icon;
            return (
              <div key={idx} className="card-glass" style={{ padding: '32px', display: 'flex', flexDirection: 'column' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
                  <div style={{
                    width: '46px',
                    height: '46px',
                    borderRadius: '12px',
                    background: 'rgba(255, 255, 255, 0.05)',
                    border: '1px solid var(--border-subtle)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: item.color
                  }}>
                    <Icon size={24} />
                  </div>
                  <span style={{ fontSize: '11px', fontWeight: 700, letterSpacing: '0.8px', color: item.color }}>
                    {item.category}
                  </span>
                </div>

                <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '12px' }}>
                  {item.title}
                </h3>

                <p style={{ color: 'var(--text-secondary)', fontSize: '14px', lineHeight: 1.6, marginBottom: '20px', flexGrow: 1 }}>
                  {item.desc}
                </p>

                <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: '16px' }}>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                    {item.details.map((detail, dIdx) => (
                      <div key={dIdx} style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <span style={{ width: '4px', height: '4px', borderRadius: '50%', background: item.color }} />
                        <span>{detail}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Bottom Bar */}
        <div style={{ textAlign: 'center', marginTop: '60px' }}>
          <button onClick={() => setActiveTab('download')} className="btn-primary" style={{ padding: '14px 30px' }}>
            <span>Download AUTO v{metadata.version} (macOS 14.0+)</span>
          </button>
        </div>
      </div>
    </div>
  );
};

