import { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { templateService } from '../services/templateService';
import Navbar from '../components/Navbar';
import TemplateEditor from '../components/TemplateEditor';
import VisualBuilder from '../components/VisualBuilder';
import './TemplatesPage.css'; // Reusing styles for now

export default function TemplateForm() {
    const { id } = useParams();
    const navigate = useNavigate();
    const isEditing = !!id;

    const [formData, setFormData] = useState({ name: '', content: '' });
    const [loading, setLoading] = useState(isEditing);
    const [submitting, setSubmitting] = useState(false);
    const [error, setError] = useState('');
    const [editorMode, setEditorMode] = useState('visual'); // 'visual' or 'code'

    useEffect(() => {
        const loadTemplate = async () => {
            try {
                const data = await templateService.getById(id);
                setFormData({ name: data.name, content: data.content });
            } catch (err) {
                setError('Failed to load template');
                console.error(err);
            } finally {
                setLoading(false);
            }
        };

        if (isEditing) {
            setLoading(true);
            loadTemplate();
        } else {
            setFormData({ name: '', content: '' });
            setLoading(false);
        }
    }, [id, isEditing]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSubmitting(true);
        setError('');

        try {
            if (isEditing) {
                await templateService.update(id, formData);
            } else {
                await templateService.create(formData);
            }
            navigate('/templates');
        } catch (err) {
            setError(err.response?.data?.message || `Failed to ${isEditing ? 'update' : 'create'} template`);
        } finally {
            setSubmitting(false);
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
                <div className="page-header mb-lg">
                    <h1 className="mb-sm">{isEditing ? 'Edit Template' : 'Create New Template'}</h1>
                    <p className="text-muted mb-0">
                        {isEditing ? 'Update your existing template' : 'Design a new document template'}
                    </p>
                </div>

                {error && <div className="alert alert-error mb-md">{error}</div>}

                <div className="card">
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
                                placeholder="e.g., Invoice Template"
                                className="form-control"
                            />
                        </div>

                        <div className="editor-container">
                            <div className="editor-header">
                                <label className="mb-0">Template Content</label>
                                <div className="mode-toggle">
                                    <button
                                        type="button"
                                        className={`mode-toggle-btn ${editorMode === 'visual' ? 'active' : ''}`}
                                        onClick={() => setEditorMode('visual')}
                                    >
                                        <span className="icon">🎨</span> Visual Builder
                                    </button>
                                    <button
                                        type="button"
                                        className={`mode-toggle-btn ${editorMode === 'code' ? 'active' : ''}`}
                                        onClick={() => setEditorMode('code')}
                                    >
                                        <span className="icon">💻</span> Code Editor
                                    </button>
                                </div>
                            </div>

                            {editorMode === 'visual' ? (
                                <div className="visual-builder-wrapper">
                                    <VisualBuilder
                                        initialContent={formData.content}
                                        onChange={(newContent) =>
                                            setFormData({ ...formData, content: newContent })
                                        }
                                    />
                                </div>
                            ) : (
                                <TemplateEditor
                                    value={formData.content}
                                    onChange={(newContent) =>
                                        setFormData({ ...formData, content: newContent })
                                    }
                                />
                            )}
                        </div>

                        <div className="flex gap-sm mt-lg">
                            <button
                                type="submit"
                                className="btn btn-primary"
                                disabled={submitting}
                            >
                                {submitting ? 'Saving...' : (isEditing ? 'Update Template' : 'Create Template')}
                            </button>
                            <button
                                type="button"
                                className="btn btn-secondary"
                                onClick={() => navigate('/templates')}
                                disabled={submitting}
                            >
                                Cancel
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
}
