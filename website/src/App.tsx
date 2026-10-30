import React, { useState, useEffect } from 'react';
import { Navbar } from './components/Navbar';
import { Footer } from './components/Footer';
import { Home } from './pages/Home';
import { Features } from './pages/Features';
import { DownloadPage } from './pages/Download';
import { PrivacyPage } from './pages/Privacy';
import { DocumentationPage } from './pages/Documentation';
import { AboutPage } from './pages/About';
import { ChangelogPage } from './pages/Changelog';

export const App: React.FC = () => {
  const getTabFromHash = (): string => {
    const hash = window.location.hash.replace('#', '').toLowerCase();
    const validTabs = ['home', 'features', 'download', 'privacy', 'docs', 'about', 'changelog'];
    return validTabs.includes(hash) ? hash : 'home';
  };

  const [activeTab, setActiveTabState] = useState<string>(getTabFromHash);

  const setActiveTab = (tab: string) => {
    setActiveTabState(tab);
    window.location.hash = tab === 'home' ? '' : `#${tab}`;
  };

  useEffect(() => {
    const handleHashChange = () => {
      setActiveTabState(getTabFromHash());
    };
    window.addEventListener('hashchange', handleHashChange);
    return () => window.removeEventListener('hashchange', handleHashChange);
  }, []);

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <Navbar activeTab={activeTab} setActiveTab={setActiveTab} />
      
      <main style={{ flexGrow: 1 }}>
        {activeTab === 'home' && <Home setActiveTab={setActiveTab} />}
        {activeTab === 'features' && <Features setActiveTab={setActiveTab} />}
        {activeTab === 'download' && <DownloadPage />}
        {activeTab === 'privacy' && <PrivacyPage />}
        {activeTab === 'docs' && <DocumentationPage />}
        {activeTab === 'about' && <AboutPage />}
        {activeTab === 'changelog' && <ChangelogPage />}
      </main>

      <Footer setActiveTab={setActiveTab} />
    </div>
  );
};

