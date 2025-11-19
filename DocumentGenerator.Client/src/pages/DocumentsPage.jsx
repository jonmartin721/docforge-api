import { useState, useEffect } from 'react';
import { documentService } from '../services/documentService';
import Navbar from '../components/Navbar';
import './DocumentsPage.css';

export default function DocumentsPage() {
  const [documents, setDocuments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadDocuments();
  }, []);

  const loadDocuments = async () => {
    try {
      const data = await documentService.getAll();
      setDocuments(data);
    } catch (err) {
      setError('Failed to load documents');
    } finally {
      setLoading(false);
    }
  };

  const handleDownload = async (id, fileName) => {
    try {
      const blob = await documentService.download(id);
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = fileName || 'document.pdf';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
    } catch (err) {
      setError('Failed to download document');
    }
  };

  const handleDelete = async (id) => {
    if (!confirm('Are you sure you want to delete this document?')) return;
    try {
      await documentService.delete(id);
      await loadDocuments();
    } catch (err) {
      setError('Failed to delete document');
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
        <div className="page-header">
          <h1 className="mb-sm">Generated Documents</h1>
          <p className="text-muted mb-0">View and download your generated PDFs</p>
        </div>

        {error && <div className="alert alert-error">{error}</div>}

        {documents.length === 0 ? (
          <div className="card empty-state">
            <p className="text-muted">No documents yet. Generate your first document from a template!</p>
          </div>
        ) : (
          <div className="documents-list">
            {documents.map((doc) => (
              <div key={doc.id} className="document-card card">
                <div className="document-icon">📄</div>
                <div className="document-info">
                  <h3 className="mb-sm">{doc.fileName}</h3>
                  <div className="document-meta">
                    <span className="text-muted">
                      Generated {new Date(doc.createdAt).toLocaleDateString()}
                    </span>
                    <span className="text-muted">•</span>
                    <span className="text-muted">{doc.templateName}</span>
                  </div>
                </div>
                <div className="document-actions flex gap-sm">
                  <button
                    onClick={() => handleDownload(doc.id, doc.fileName)}
                    className="btn btn-primary btn-sm"
                  >
                    Download
                  </button>
                  <button
                    onClick={() => handleDelete(doc.id)}
                    className="btn btn-danger btn-sm"
                  >
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
