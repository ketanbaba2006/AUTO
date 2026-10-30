import React, { useState } from 'react';
import { Download, Sparkles, Shield, FileText, Info, History, Menu, X } from 'lucide-react';
import metadata from '../release-metadata.json';

interface NavbarProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

export const Navbar: React.FC<NavbarProps> = ({ activeTab, setActiveTab }) => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const navItems = [
    { id: 'home', label: 'Home' },
    { id: 'features', label: 'Features' },
    { id: 'download', label: 'Download', badge: `v${metadata.version}` },
    { id: 'privacy', label: 'Privacy' },
    { id: 'docs', label: 'Docs' },
    { id: 'about', label: 'About' },
    { id: 'changelog', label: 'Changelog' }
  ];

  const handleNavClick = (id: string) => {
    setActiveTab(id);
    setMobileMenuOpen(false);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return (
    <header style={{
      position: 'sticky',
      top: 0,
      zIndex: 50,
      background: 'rgba(10, 14, 26, 0.85)',
      backdropFilter: 'blur(16px)',
      borderBottom: '1px solid var(--border-subtle)'
    }}>
      <div className="container" style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        height: '70px'
      }}>
        {/* Brand */}
        <div 
          onClick={() => handleNavClick('home')}
          style={{ display: 'flex', alignItems: 'center', gap: '12px', cursor: 'pointer' }}
        >
          <img 
            src="./assets/auto_mascot_64.png" 
            alt="AUTO Mascot" 
            style={{ width: '36px', height: '36px', borderRadius: '10px' }}
          />
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ fontSize: '20px', fontWeight: 800, letterSpacing: '-0.5px' }} className="gradient-text-cyan">
                {metadata.productName}
              </span>
              <span className="badge badge-purple" style={{ fontSize: '10px', padding: '2px 6px' }}>
                macOS Native
              </span>
            </div>
            <div style={{ fontSize: '10px', color: 'var(--text-muted)', lineHeight: 1 }}>
              {metadata.tagline}
            </div>
          </div>
        </div>

        {/* Desktop Nav */}
        <nav style={{ display: 'flex', alignItems: 'center', gap: '6px' }} className="desktop-nav">
          {navItems.map((item) => (
            <button
              key={item.id}
              onClick={() => handleNavClick(item.id)}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '8px 14px',
                borderRadius: '8px',
                fontSize: '14px',
                fontWeight: activeTab === item.id ? 700 : 500,
                color: activeTab === item.id ? 'var(--accent-cyan)' : 'var(--text-secondary)',
                background: activeTab === item.id ? 'rgba(0, 240, 255, 0.08)' : 'transparent',
                transition: 'all 0.15s ease'
              }}
            >
              {item.label}
              {item.badge && (
                <span className="badge badge-cyan" style={{ fontSize: '10px', padding: '2px 6px' }}>
                  {item.badge}
                </span>
              )}
            </button>
          ))}
        </nav>

        {/* CTA Button */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <button 
            onClick={() => handleNavClick('download')}
            className="btn-primary" 
            style={{ padding: '8px 18px', fontSize: '13px' }}
          >
            <Download size={15} />
            <span>Download</span>
          </button>

          {/* Mobile hamburger */}
          <button 
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            style={{ display: 'none', color: '#fff' }}
            className="mobile-hamburger"
          >
            {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>
      </div>

      {/* Mobile Drawer */}
      {mobileMenuOpen && (
        <div style={{
          background: 'var(--bg-surface)',
          borderBottom: '1px solid var(--border-subtle)',
          padding: '16px 24px'
        }}>
          {navItems.map((item) => (
            <button
              key={item.id}
              onClick={() => handleNavClick(item.id)}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                width: '100%',
                padding: '12px 0',
                fontSize: '15px',
                fontWeight: activeTab === item.id ? 700 : 500,
                color: activeTab === item.id ? 'var(--accent-cyan)' : 'var(--text-primary)',
                borderBottom: '1px solid rgba(255, 255, 255, 0.04)'
              }}
            >
              <span>{item.label}</span>
              {item.badge && <span className="badge badge-cyan">{item.badge}</span>}
            </button>
          ))}
        </div>
      )}
    </header>
  );
};

