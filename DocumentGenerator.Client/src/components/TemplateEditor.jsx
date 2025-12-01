import './TemplateEditor.css';

export default function TemplateEditor({ value, onChange }) {
  const handleChange = (e) => {
    const newContent = e.target.value;
    onChange(newContent);
  };

  const insertVariable = (varName) => {
    const textarea = document.getElementById('template-code-editor');
    if (!textarea) return;

    const start = textarea.selectionStart;
    const end = textarea.selectionEnd;
    const text = value || '';
    const before = text.substring(0, start);
    const after = text.substring(end, text.length);
    const newContent = `${before}{{${varName}}}${after}`;

    onChange(newContent);

    // Restore focus and cursor position
    setTimeout(() => {
      textarea.focus();
      const newCursorPos = start + varName.length + 4; // 4 for {{}}
      textarea.setSelectionRange(newCursorPos, newCursorPos);
    }, 0);
  };

  return (
    <div className="template-editor">
      <div className="editor-toolbar">
        <span className="text-muted text-sm">Insert Variable:</span>
        <button type="button" onClick={() => insertVariable('title')} className="btn btn-xs btn-secondary">Title</button>
        <button type="button" onClick={() => insertVariable('content')} className="btn btn-xs btn-secondary">Content</button>
        <button type="button" onClick={() => insertVariable('date')} className="btn btn-xs btn-secondary">Date</button>
        <button type="button" onClick={() => insertVariable('items')} className="btn btn-xs btn-secondary">Items Loop</button>
      </div>

      <div className="editor-panes">
        <div className="editor-pane code-pane">
          <div className="pane-header">HTML Source</div>
          <textarea
            id="template-code-editor"
            value={value || ''}
            onChange={handleChange}
            placeholder="<h1>{{title}}</h1>"
            spellCheck="false"
          />
        </div>

        <div className="editor-pane preview-pane">
          <div className="pane-header">Live Preview</div>
          <div className="preview-container">
            <div className="preview-scaler">
              <div className="preview-paper">
                <div
                  className="preview-content"
                  dangerouslySetInnerHTML={{
                    __html: (value || '').replace(/{{(.*?)}}/g, '<span class="var-highlight">$1</span>')
                  }}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
