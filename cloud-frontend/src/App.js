import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [count, setCount] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  
  // Dark Mode State (defaults to true if nothing is saved)
  const [darkMode, setDarkMode] = useState(() => {
    const saved = localStorage.getItem('theme');
    return saved ? saved === 'dark' : true;
  });

  // Save preference to localStorage whenever it changes
  useEffect(() => {
    localStorage.setItem('theme', darkMode ? 'dark' : 'light');
    document.body.className = darkMode ? 'dark-theme' : 'light-theme';
  }, [darkMode]);

  useEffect(() => {
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  const saved = localStorage.getItem('theme');
  if (saved === null) {
    setDarkMode(prefersDark);
  }
}, []);

  // Fetch visitor count
  useEffect(() => {
    const apiUrl = 'https://6axn3bk1id.execute-api.us-east-1.amazonaws.com/dev';

    fetch(apiUrl)
      .then(response => response.json())
      .then(data => {
        setCount(data.count);
        setLoading(false);
      })
      .catch(err => {
        console.error('Error fetching count:', err);
        setError(true);
        setLoading(false);
      });
  }, []);

  const toggleTheme = () => {
    setDarkMode(!darkMode);
  };

  return (
    <div className={`App ${darkMode ? 'dark-theme' : 'light-theme'}`}>
      <header className="App-header">
        {/* Theme Toggle Button */}
        <button onClick={toggleTheme} className="theme-toggle">
          {darkMode ? '☀️ Light Mode' : '🌙 Dark Mode'}
        </button>

        <div className="badge">☁️</div>
        <h1>Aladdin Ali</h1>
        <p className="subtitle">
          AWS · Terraform · Serverless <br />
          <span style={{ color: '#a1a1aa', fontSize: '14px' }}>
            Building things that work.
          </span>
        </p>

        <div className="counter-card">
          <div className="counter-label">🌍 Live Visitors</div>
          <div className="counter-number">
            {loading ? '—' : error ? '🚀' : count}
          </div>
        </div>

        <div className="tech-stack">
          <span className="live-dot"></span> Live · S3 · CloudFront · Lambda · API Gateway · DynamoDB
        </div>
      </header>
    </div>
  );
}

export default App;