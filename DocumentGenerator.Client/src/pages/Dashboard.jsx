import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { templateService } from '../services/templateService';
import { documentService } from '../services/documentService';
import Navbar from '../components/Navbar';
import { formatDateTime } from '../utils/dateUtils';
import './Dashboard.css';

// Extract first few key-value pairs from metadata for preview
function getMetadataPreview(metadataStr, maxItems = 2) {
  if (!metadataStr) return null;
  try {
    const data = JSON.parse(metadataStr);
    if (typeof data !== 'object' || data === null) return null;

    const entries = Object.entries(data)
      .filter(([, v]) => typeof v === 'string' || typeof v === 'number')
      .slice(0, maxItems)
      .map(([key, value]) => ({
        key: key.charAt(0).toUpperCase() + key.slice(1).replace(/([A-Z])/g, ' $1'),
        value: String(value).length > 20 ? String(value).slice(0, 20) + '...' : String(value)
      }));

    return entries.length > 0 ? entries : null;
  } catch {
    return null;
  }
}

export default function Dashboard() {
  const [stats, setStats] = useState({
    templates: 0,
    documents: 0,
    recentDocs: [],
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboard();
  }, []);

  const loadDashboard = async () => {
    try {
      const [templates, documents] = await Promise.all([
        templateService.getAll(),
        documentService.getAll(),
      ]);

      setStats({
        templates: templates.length,
        documents: documents.length,
        recentDocs: documents.slice(0, 5),
      });
    } catch (err) {
      console.error('Failed to load dashboard', err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div>
        <Navbar />
        <div className="container" style={{ paddingTop: 'var(--space-2xl)' }}>
          <div className="flex-center">
            <div className="spinner"></div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div>
      <Navbar />
      <div className="container" style={{ paddingTop: 'var(--space-2xl)' }}>
        <div className="dashboard-header">
          <h1 className="mb-sm">Dashboard</h1>
          <p className="text-muted mb-0">Welcome to DocForge</p>
        </div>

        <div className="stats-grid">
          <Link to="/templates" className="stat-card card">
            <div className="stat-icon">📝</div>
            <div className="stat-content">
              <h2>{stats.templates}</h2>
              <p className="text-muted">Templates</p>
            </div>
          </Link>

          <Link to="/documents" className="stat-card card">
            <div className="stat-icon">📄</div>
            <div className="stat-content">
              <h2>{stats.documents}</h2>
              <p className="text-muted">Documents</p>
            </div>
          </Link>
        </div>

        <div className="card">
          <div className="flex-between mb-md">
            <h3>Recent Documents</h3>
            <Link to="/documents" className="btn btn-sm btn-secondary">
              View All
            </Link>
          </div>

          {stats.recentDocs.length === 0 ? (
            <p className="text-muted text-center">No documents yet</p>
          ) : (
            <div className="recent-list">
              {stats.recentDocs.map((doc) => {
                const metadataPreview = getMetadataPreview(doc.metadata);
                return (
                  <div key={doc.id} className="recent-item">
                    <span className="recent-icon">📄</span>
                    <div className="recent-info">
                      <div className="recent-name">{doc.fileName}</div>
                      <div className="recent-meta">
                        <span className="recent-template">{doc.templateName}</span>
                        <span className="text-muted">
                          {formatDateTime(doc.generatedAt)}
                        </span>
                      </div>
                      {metadataPreview && (
                        <div className="recent-data">
                          {metadataPreview.map((item, i) => (
                            <span key={i} className="recent-data-item">
                              {item.key}: {item.value}
                            </span>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        <div className="quick-actions card">
          <h3 className="mb-md">Quick Actions</h3>
          <div className="actions-grid">
            <Link to="/templates" className="action-btn">
              <span className="action-icon">➕</span>
              <span>Create Template</span>
            </Link>
            <Link to="/templates" className="action-btn">
              <span className="action-icon">📄</span>
              <span>Generate Document</span>
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
