import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { templateService } from '../services/templateService';
import Navbar from '../components/Navbar';
import Modal from '../components/Modal';
import { formatDate } from '../utils/dateUtils';
import './TemplatesPage.css';

export default function TemplatesPage() {
  const [templates, setTemplates] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [deleteModal, setDeleteModal] = useState({ isOpen: false, templateId: null });

  useEffect(() => {
    loadTemplates();
  }, []);

  const loadTemplates = async () => {
    try {
      const data = await templateService.getAll();
      setTemplates(data);
    } catch (err) {
      setError('Failed to load templates');
    } finally {
      setLoading(false);
    }
  };



  const confirmDelete = (id) => {
    setDeleteModal({ isOpen: true, templateId: id });
  };

  const handleDelete = async () => {
    try {
      await templateService.delete(deleteModal.templateId);

      // Update local state immediately
      setTemplates(templates.filter(t => t.id !== deleteModal.templateId));
      setDeleteModal({ isOpen: false, templateId: null });

      // Reload to ensure consistency (optional, but good practice)
      // await loadTemplates(); 
    } catch (err) {
      console.error('Delete error:', err);
      setError(err.response?.data?.message || 'Failed to delete template');
      setDeleteModal({ isOpen: false, templateId: null });
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
        <div className="page-header flex-between mb-lg">
          <div>
            <h1 className="mb-sm">Templates</h1>
            <p className="text-muted mb-0">Manage your document templates</p>
          </div>
          <Link
            to="/templates/new"
            className="btn btn-primary"
          >
            + New Template
          </Link>
        </div>

        {error && <div className="alert alert-error">{error}</div>}



        <div className="templates-grid">
          {templates.length === 0 ? (
            <div className="empty-state card">
              <p className="text-muted">No templates yet. Create your first template!</p>
            </div>
          ) : (
            templates.map((template) => (
              <div key={template.id} className="template-card card">
                <div className="template-header">
                  <h3 className="mb-sm">{template.name}</h3>
                  <span className="template-date text-muted">
                    {formatDate(template.createdAt)}
                  </span>
                </div>
                <div className="template-preview-wrapper">
                  <div className="template-preview-scale">
                    <div
                      className="template-preview-content"
                      dangerouslySetInnerHTML={{
                        __html: (template.content || '')
                          .replace(/{{(.*?)}}/g, '<span class="var-placeholder">$1</span>')
                      }}
                    />
                  </div>
                </div>
                <div className="template-actions flex gap-sm">
                  <Link
                    to={`/generate/${template.id}`}
                    className="btn btn-primary btn-sm"
                  >
                    Generate Doc
                  </Link>
                  <Link
                    to={`/templates/${template.id}/edit`}
                    className="btn btn-secondary btn-sm"
                  >
                    Edit
                  </Link>
                  <button
                    onClick={() => confirmDelete(template.id)}
                    className="btn btn-danger btn-sm"
                  >
                    Delete
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      <Modal
        isOpen={deleteModal.isOpen}
        onClose={() => setDeleteModal({ isOpen: false, templateId: null })}
        title="Delete Template"
        type="danger"
        footer={
          <>
            <button
              className="btn btn-secondary"
              onClick={() => setDeleteModal({ isOpen: false, templateId: null })}
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
        <p>Are you sure you want to delete this template? This action cannot be undone.</p>
      </Modal>
    </div>
  );
}
