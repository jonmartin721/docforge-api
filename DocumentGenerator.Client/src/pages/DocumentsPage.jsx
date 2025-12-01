import { useState, useEffect } from 'react';
import { documentService } from '../services/documentService';
import Navbar from '../components/Navbar';
import Modal from '../components/Modal';
import { formatDateTime } from '../utils/dateUtils';
import './DocumentsPage.css';

// Extract first few key-value pairs from metadata for preview
function getMetadataPreview(metadataStr, maxItems = 3) {
  if (!metadataStr) return null;
  try {
    const data = JSON.parse(metadataStr);
    if (typeof data !== 'object' || data === null) return null;

    const entries = Object.entries(data)
      .filter(([, v]) => typeof v === 'string' || typeof v === 'number')
      .slice(0, maxItems)
      .map(([key, value]) => ({
        key: key.charAt(0).toUpperCase() + key.slice(1).replace(/([A-Z])/g, ' $1'),
        value: String(value).length > 30 ? String(value).slice(0, 30) + '...' : String(value)
      }));

    return entries.length > 0 ? entries : null;
  } catch {
    return null;
  }
}

export default function DocumentsPage() {
  const [documents, setDocuments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [deleteModal, setDeleteModal] = useState({ isOpen: false, docId: null });

  useEffect(() => {
    loadDocuments();
  }, []);

  const loadDocuments = async () => {
    try {
      const data = await documentService.getAll();
      setDocuments(data);
    } catch (err) {
      console.error(err);
      // TODO: Integrate a dedicated error tracking service (e.g., Sentry) for production
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
      console.error(err);
      setError('Failed to download document');
    }
  };

  const handleView = async (id) => {
    try {
      const blob = await documentService.download(id);
      const url = window.URL.createObjectURL(blob);
      window.open(url, '_blank');
      // Note: We can't revoke the URL immediately if we want it to persist in the new tab
      // The browser will clean it up when the document is unloaded
    } catch (err) {
      console.error(err);
      setError('Failed to view document');
    }
  };

  const confirmDelete = (id) => {
    setDeleteModal({ isOpen: true, docId: id });
  };

  const handleDelete = async () => {
    try {
      await documentService.delete(deleteModal.docId);
      setDeleteModal({ isOpen: false, docId: null });
      await loadDocuments();
    } catch (err) {
      console.error(err);
      setError('Failed to delete document');
      setDeleteModal({ isOpen: false, docId: null });
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
            {documents.map((doc) => {
              const metadataPreview = getMetadataPreview(doc.metadata);
              return (
                <div key={doc.id} className="document-card card">
                  <div className="document-icon">📄</div>
                  <div className="document-info">
                    <h3 className="mb-xs">{doc.fileName}</h3>
                    <div className="document-meta mb-sm">
                      <span className="template-badge">{doc.templateName}</span>
                      <span className="text-muted">
                        {formatDateTime(doc.generatedAt)}
                      </span>
                    </div>
                    {metadataPreview && (
                      <div className="document-data-preview">
                        {metadataPreview.map((item, i) => (
                          <span key={i} className="data-tag">
                            <span className="data-key">{item.key}:</span> {item.value}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                  <div className="document-actions flex gap-sm">
                    <button
                      onClick={() => handleView(doc.id)}
                      className="btn btn-secondary btn-sm"
                    >
                      View
                    </button>
                    <button
                      onClick={() => handleDownload(doc.id, doc.fileName)}
                      className="btn btn-primary btn-sm"
                    >
                      Download
                    </button>
                    <button
                      onClick={() => confirmDelete(doc.id)}
                      className="btn btn-danger btn-sm"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      <Modal
        isOpen={deleteModal.isOpen}
        onClose={() => setDeleteModal({ isOpen: false, docId: null })}
        title="Delete Document"
        type="danger"
        footer={
          <>
            <button
              className="btn btn-secondary"
              onClick={() => setDeleteModal({ isOpen: false, docId: null })}
            >
              Cancel
            </button>
            <button
              className="btn btn-danger"
              onClick={handleDelete}
            >
              Delete
            </button>
          </>
        }
      >
        <p>Are you sure you want to delete this document? This action cannot be undone.</p>
      </Modal>
    </div>
  );
}
