import React from 'react';
import { BookOpen, Key, Mic, Monitor, MousePointer, Brain, Wrench, Shield, AlertTriangle, FileCode } from 'lucide-react';

export const DocumentationPage: React.FC = () => {
  const docSections = [
    {
      title: 'Getting Started',
      icon: BookOpen,
      color: '#00F0FF',
      items: [
        { name: 'Installation Guide', path: 'docs/INSTALLATION.md', desc: 'System requirements, DMG mounting, Gatekeeper ad-hoc opening, and building from source.' },
        { name: 'Voice & Push-to-Talk Setup', path: 'docs/VOICE_SETUP.md', desc: 'Global Hold-Control shortcut, microphone device selection, and instant speech interruption.' },
        { name: 'Gemini Configuration', path: 'docs/GEMINI_SETUP.md', desc: 'Google AI Studio API key setup, Keychain storage, and dynamic model discovery.' },
        { name: 'OmniRoute Gateway Setup', path: 'docs/OMNIROUTE_SETUP.md', desc: 'Optional local model connection (Ollama, LM Studio) and OpenAI-compatible endpoints.' }
      ]
    },
    {
      title: 'Visual Intelligence & Automation',
      icon: Monitor,
      color: '#8B5CF6',
      items: [
        { name: 'Screen Intelligence & Multi-Display', path: 'docs/SCREEN_INTELLIGENCE.md', desc: 'ScreenCaptureKit integration, window discovery, and negative virtual coordinates.' },
        { name: 'Cursor Intelligence & Element Matching', path: 'docs/CURSOR_INTELLIGENCE.md', desc: 'Accessibility tree inspection (AXUIElement), fuzzy scoring, and Bezier trajectories.' },
        { name: 'Automation Safety & Failsafes', path: 'docs/AUTOMATION_SAFETY.md', desc: 'Three-tier risk rating, high-risk modal confirmation, and <10ms Emergency Stop.' },
        { name: 'Accessibility Permissions', path: 'docs/ACCESSIBILITY_PERMISSIONS.md', desc: 'TCC authorization, preflight checks, and reduced capability mode.' }
      ]
    },
    {
      title: 'Agent, Memory & Operations',
      icon: Brain,
      color: '#10B981',
      items: [
        { name: 'Autonomous Task Planning', path: 'docs/TASK_PLANNING.md', desc: 'Multi-step instruction decomposition, step dependencies, and state verification.' },
        { name: 'Local Persistent Memory', path: 'docs/MEMORY_SYSTEM.md', desc: 'JSON persistence, relevance scoring, and sensitive credential filtering.' },
        { name: 'Modular Tool Execution Registry', path: 'docs/TOOL_EXECUTION.md', desc: 'Catalog of 16+ tools across 6 functional domains and async dispatching.' },
        { name: 'Sandboxed Local File Operations', path: 'docs/LOCAL_FILE_ACCESS.md', desc: 'Safe operations on Desktop/Downloads/Documents with system folder isolation.' }
      ]
    },
    {
      title: 'Operations & Troubleshooting',
      icon: Wrench,
      color: '#F59E0B',
      items: [
        { name: 'Troubleshooting & Diagnostics', path: 'docs/TROUBLESHOOTING.md', desc: 'Diagnostic steps for permissions, audio metering, blank screen captures, and 429 quotas.' },
        { name: 'Known Limitations & Constraints', path: 'docs/KNOWN_LIMITATIONS.md', desc: 'Secure Input mode, DRM media playback, and non-standard web canvas limits.' },
        { name: 'Release & Packaging Guide', path: 'docs/RELEASE_GUIDE.md', desc: 'Packaging script, ad-hoc codesigning, and Apple Developer ID notarization.' },
        { name: 'System Architecture Reference', path: 'docs/ARCHITECTURE.md', desc: 'Comprehensive component diagram and directory structure across all 7 fragments.' }
      ]
    }
  ];

  return (
    <div style={{ padding: '60px 0 80px' }}>
      <div className="container" style={{ maxWidth: '1000px' }}>
        {/* Header */}
        <div style={{ textAlign: 'center', marginBottom: '50px' }}>
          <span className="badge badge-purple" style={{ marginBottom: '14px' }}>Engineering Knowledge Base</span>
          <h1 style={{ fontSize: 'clamp(32px, 4.5vw, 50px)', fontWeight: 800, letterSpacing: '-1px', marginBottom: '16px' }}>
            Technical Documentation
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '17px', maxWidth: '600px', margin: '0 auto', lineHeight: 1.6 }}>
            Comprehensive architectural specifications, configuration guides, and security references matching the exact implementation.
          </p>
        </div>

        {/* Documentation Sections */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '36px' }}>
          {docSections.map((section, sIdx) => {
            const SectionIcon = section.icon;
            return (
              <div key={sIdx} className="card-glass" style={{ padding: '32px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '20px' }}>
                  <SectionIcon size={22} color={section.color} />
                  <h2 style={{ fontSize: '20px', fontWeight: 800 }}>{section.title}</h2>
                </div>

                <div style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
                  gap: '16px'
                }}>
                  {section.items.map((item, iIdx) => (
                    <div key={iIdx} style={{
                      padding: '18px',
                      background: 'rgba(10, 14, 26, 0.5)',
                      borderRadius: '10px',
                      border: '1px solid var(--border-subtle)'
                    }}>
                      <div style={{ fontSize: '15px', fontWeight: 700, color: '#fff', marginBottom: '6px' }}>
                        {item.name}
                      </div>
                      <p style={{ color: 'var(--text-secondary)', fontSize: '13px', lineHeight: 1.5, marginBottom: '10px' }}>
                        {item.desc}
                      </p>
                      <div style={{ fontSize: '11px', color: 'var(--accent-cyan)', fontFamily: 'var(--font-mono)' }}>
                        {item.path}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

