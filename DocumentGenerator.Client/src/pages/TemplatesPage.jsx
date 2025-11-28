import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { templateService } from '../services/templateService';
import Navbar from '../components/Navbar';
import TemplateEditor from '../components/TemplateEditor';
import VisualBuilder from '../components/VisualBuilder';
import Modal from '../components/Modal';
import './TemplatesPage.css';

export default function TemplatesPage() {
  const [templates, setTemplates] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({ name: '', content: '' });
  const [submitting, setSubmitting] = useState(false);
  const [editorMode, setEditorMode] = useState('visual'); // 'visual' or 'code'
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

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await templateService.create(formData);
      setFormData({ name: '', content: '' });
      setShowForm(false);
      await loadTemplates();
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to create template');
    } finally {
      setSubmitting(false);
    }
  };

  const confirmDelete = (id) => {
    setDeleteModal({ isOpen: true, templateId: id });
  };

  const handleDelete = async () => {
    try {
      await templateService.delete(deleteModal.templateId);
      setDeleteModal({ isOpen: false, templateId: null });
      await loadTemplates();
    } catch (err) {
      setError('Failed to delete template');
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
          <button
            className="btn btn-primary"
            onClick={() => setShowForm(!showForm)}
          >
            {showForm ? 'Cancel' : '+ New Template'}
          </button>
        </div>

        {error && <div className="alert alert-error">{error}</div>}

        {showForm && (
          <div className="card mb-lg">
            <h3 className="mb-md">Create New Template</h3>
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label htmlFor="name">Template Name</label>
                <input
                  id="name"
                  type="text"
                  value={formData.name}
                  onChange={(e) =>
                    setFormData({ ...formData, name: e.target.value })
                  }
                  required
                  placeholder="Invoice Template"
                />
              </div>
              <div className="form-group">
                <div className="flex-between mb-sm">
                  <label className="mb-0">Template Content</label>
                  <div className="btn-group">
                    <button
                      type="button"
                      className={`btn btn-sm ${editorMode === 'visual' ? 'btn-primary' : 'btn-secondary'}`}
                      onClick={() => setEditorMode('visual')}
                    >
                      Visual Builder
                    </button>
                    <button
                      type="button"
                      className={`btn btn-sm ${editorMode === 'code' ? 'btn-primary' : 'btn-secondary'}`}
                      onClick={() => setEditorMode('code')}
                    >
                      Code Editor
                    </button>
                  </div>
                </div>

                {editorMode === 'visual' ? (
                  <VisualBuilder
                    initialContent={formData.content}
                    onChange={(newContent) =>
                      setFormData({ ...formData, content: newContent })
                    }
                  />
                ) : (
                  <TemplateEditor
                    initialContent={formData.content}
                    onChange={(newContent) =>
                      setFormData({ ...formData, content: newContent })
                    }
                  />
                )}
              </div>
              <button
                type="submit"
                className="btn btn-primary"
                disabled={submitting}
              >
                {submitting ? 'Creating...' : 'Create Template'}
              </button>
            </form>
          </div>
        )}

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
                    {new Date(template.createdAt).toLocaleDateString()}
                  </span>
                </div>
                <div className="template-preview-wrapper">
                  <div className="template-preview-scale">
                    <div
                      className="template-preview-content"
                      dangerouslySetInnerHTML={{
                        __html: template.content
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
