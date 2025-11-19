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
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    loadTemplate();
  }, [templateId]);

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
      }
    } catch (err) {
      setError('Failed to load template');
    } finally {
      setLoading(false);
    }
  };

  const handleGenerate = async (e) => {
    e.preventDefault();
    setError('');
    setGenerating(true);

    try {
      const parsedData = JSON.parse(jsonData);
      const doc = await documentService.generate(templateId, parsedData);
      setSuccess(true);
      
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
        {success && (
          <div className="alert alert-success">
            Document generated successfully! Redirecting...
          </div>
        )}

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
              <button
                type="submit"
                className="btn btn-primary"
                disabled={generating}
              >
                {generating ? 'Generating...' : '📄 Generate PDF'}
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}
