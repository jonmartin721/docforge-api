import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { templateService } from '../services/templateService';
import { documentService } from '../services/documentService';
import Navbar from '../components/Navbar';
import './GeneratePage.css';

export default function GeneratePage() {
  const { templateId } = useParams();
  const navigate = useNavigate();
  const [template, setTemplate] = useState(null);
  const [jsonData, setJsonData] = useState('{\n  \n}');
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [count, setCount] = useState(1);
  const [customCount, setCustomCount] = useState(false);

  useEffect(() => {
    const loadTemplate = async () => {
      try {
        const data = await templateService.getById(templateId);
        setTemplate(data);

        // Extract variables from template
        const variables = [...data.content.matchAll(/\{\{(\w+)\}\}/g)].map(m => m[1]);
        const uniqueVars = [...new Set(variables)];

        if (uniqueVars.length > 0) {
          const sampleData = {};
          uniqueVars.forEach(v => {
            sampleData[v] = '';
          });
          setJsonData(JSON.stringify(sampleData, null, 2));
        } else {
          setJsonData('{\n  \n}');
        }
      } catch (err) {
        console.error(err);
        setError('Failed to load template');
      } finally {
        setLoading(false);
      }
    };

    if (templateId) {
      setLoading(true);
      loadTemplate();
    }
  }, [templateId]);

  const handleGenerate = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setGenerating(true);

    try {
      const parsedData = JSON.parse(jsonData);
      const numCopies = Math.max(1, Math.min(100, count)); // Clamp between 1-100

      if (numCopies === 1) {
        await documentService.generate(templateId, parsedData);
        setSuccess('Document generated successfully! Redirecting...');
      } else {
        // Create array of identical data items for batch
        const dataItems = Array(numCopies).fill(parsedData);
        const result = await documentService.generateBatch(templateId, dataItems);
        setSuccess(`${result.successCount} document${result.successCount !== 1 ? 's' : ''} generated successfully! Redirecting...`);
      }

      setTimeout(() => {
        navigate(`/documents`);
      }, 1500);
    } catch (err) {
      if (err instanceof SyntaxError) {
        setError('Invalid JSON format');
      } else {
        setError(err.response?.data?.message || 'Failed to generate document');
      }
    } finally {
      setGenerating(false);
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

  if (!template) {
    return (
      <div>
        <Navbar />
        <div className="container" style={{ paddingTop: 'var(--space-2xl)' }}>
          <div className="alert alert-error">Template not found</div>
        </div>
      </div>
    );
  }

  return (
    <div>
      <Navbar />
      <div className="container" style={{ paddingTop: 'var(--space-2xl)' }}>
        <h1 className="mb-md">Generate Document</h1>
        <p className="text-muted mb-lg">Using template: {template.name}</p>

        {error && <div className="alert alert-error">{error}</div>}
        {success && <div className="alert alert-success">{success}</div>}

        <div className="generate-layout">
          <div className="card">
            <h3 className="mb-md">Template Preview</h3>
            <pre className="template-code">{template.content}</pre>
          </div>

          <div className="card">
            <h3 className="mb-md">Data (JSON)</h3>
            <form onSubmit={handleGenerate}>
              <div className="form-group">
                <textarea
                  value={jsonData}
                  onChange={(e) => setJsonData(e.target.value)}
                  rows={15}
                  placeholder="Enter JSON data..."
                  style={{ fontFamily: 'Monaco, monospace' }}
                />
              </div>
              <div className="generate-actions">
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={generating}
                >
                  {generating ? 'Generating...' : '📄 Generate PDF'}
                </button>
{customCount ? (
                  <div className="custom-count-input">
                    <input
                      type="number"
                      min="1"
                      max="100"
                      value={count}
                      onChange={(e) => setCount(Math.max(1, Math.min(100, parseInt(e.target.value) || 1)))}
                      disabled={generating}
                      autoFocus
                    />
                    <span>copies</span>
                    <button
                      type="button"
                      className="custom-count-close"
                      onClick={() => {
                        setCustomCount(false);
                        if (![1, 5, 10, 25, 50, 100].includes(count)) {
                          setCount(1);
                        }
                      }}
                      disabled={generating}
                    >
                      ×
                    </button>
                  </div>
                ) : (
                  <select
                    className="copies-select"
                    value={[1, 5, 10, 25, 50, 100].includes(count) ? count : 'custom'}
                    onChange={(e) => {
                      if (e.target.value === 'custom') {
                        setCustomCount(true);
                      } else {
                        setCount(parseInt(e.target.value));
                      }
                    }}
                    disabled={generating}
                  >
                    <option value={1}>1 copy</option>
                    <option value={5}>5 copies</option>
                    <option value={10}>10 copies</option>
                    <option value={25}>25 copies</option>
                    <option value={50}>50 copies</option>
                    <option value={100}>100 copies</option>
                    <option value="custom">Custom...</option>
                  </select>
                )}
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}
