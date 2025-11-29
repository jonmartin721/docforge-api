import { useState } from 'react';
import './VisualBuilder.css';
import Modal from './Modal';

export default function VisualBuilder({ initialContent, onChange }) {
  const [blocks, setBlocks] = useState(() => parseContent(initialContent));
  const [selectedBlock, setSelectedBlock] = useState(null);
  const [draggedBlock, setDraggedBlock] = useState(null);
  const [clearModalOpen, setClearModalOpen] = useState(false);

  const updateBlocks = (newBlocks) => {
    setBlocks(newBlocks);
    onChange(blocksToHtml(newBlocks));
  };

  const addBlock = (type) => {
    const newBlock = {
      id: `block-${crypto.randomUUID()}`,
      type,
      content: getDefaultContent(type),
      styles: { textAlign: 'left' }
    };
    updateBlocks([...blocks, newBlock]);
  };

  const updateBlockContent = (id, content) => {
    const newBlocks = blocks.map(b =>
      b.id === id ? { ...b, content } : b
    );
    updateBlocks(newBlocks);
  };

  const updateBlockStyle = (id, styleName, value) => {
    const newBlocks = blocks.map(b =>
      b.id === id ? { ...b, styles: { ...b.styles, [styleName]: value } } : b
    );
    updateBlocks(newBlocks);
  };

  const deleteBlock = (id) => {
    const newBlocks = blocks.filter(b => b.id !== id);
    updateBlocks(newBlocks);
    if (selectedBlock?.id === id) setSelectedBlock(null);
  };

  const moveBlock = (fromIndex, toIndex) => {
    if (toIndex < 0 || toIndex >= blocks.length) return;
    const newBlocks = [...blocks];
    const [moved] = newBlocks.splice(fromIndex, 1);
    newBlocks.splice(toIndex, 0, moved);
    updateBlocks(newBlocks);
  };

  const handleDragStart = (e, index) => {
    setDraggedBlock(index);
    e.dataTransfer.effectAllowed = 'move';
  };

  const handleDragOver = (e, index) => {
    e.preventDefault();
    if (draggedBlock === null || draggedBlock === index) return;
    moveBlock(draggedBlock, index);
    setDraggedBlock(index);
  };

  const handleDragEnd = () => {
    setDraggedBlock(null);
  };

  const handleClear = () => {
    setClearModalOpen(true);
  };

  const confirmClear = () => {
    updateBlocks([]);
    setSelectedBlock(null);
    setClearModalOpen(false);
  };

  return (
    <div className="visual-builder">
      <div className="vb-sidebar">
        <div className="vb-sidebar-header">
          Tools
        </div>
        <div className="vb-tools">
          <button type="button" className="vb-tool" onClick={() => addBlock('heading1')}>
            <span className="vb-tool-icon">H1</span>
            <span className="vb-tool-label">Heading 1</span>
          </button>
          <button type="button" className="vb-tool" onClick={() => addBlock('heading2')}>
            <span className="vb-tool-icon">H2</span>
            <span className="vb-tool-label">Heading 2</span>
          </button>
          <button type="button" className="vb-tool" onClick={() => addBlock('heading3')}>
            <span className="vb-tool-icon">H3</span>
            <span className="vb-tool-label">Heading 3</span>
          </button>
          <button type="button" className="vb-tool" onClick={() => addBlock('text')}>
            <span className="vb-tool-icon">¶</span>
            <span className="vb-tool-label">Text</span>
          </button>
          <button type="button" className="vb-tool" onClick={() => addBlock('list')}>
            <span className="vb-tool-icon">≣</span>
            <span className="vb-tool-label">List</span>
          </button>
          <button type="button" className="vb-tool" onClick={() => addBlock('table')}>
            <span className="vb-tool-icon">▦</span>
            <span className="vb-tool-label">Table</span>
          </button>
          <button type="button" className="vb-tool" onClick={() => addBlock('divider')}>
            <span className="vb-tool-icon">—</span>
            <span className="vb-tool-label">Divider</span>
          </button>
        </div>

        <div className="vb-sidebar-footer">
          <button type="button" className="btn btn-danger w-full" onClick={handleClear}>
            Clear All
          </button>
        </div>
      </div>

      <div className="vb-workspace">
        <div className="vb-canvas">
          {blocks.length === 0 ? (
            <div className="vb-empty-state">
              <p>Click tools above to add content blocks</p>
            </div>
          ) : (
            blocks.map((block, index) => (
              <div
                key={block.id}
                className={`vb-block ${selectedBlock?.id === block.id ? 'selected' : ''} ${draggedBlock === index ? 'dragging' : ''}`}
                onClick={() => setSelectedBlock(block)}
                draggable
                onDragStart={(e) => handleDragStart(e, index)}
                onDragOver={(e) => handleDragOver(e, index)}
                onDragEnd={handleDragEnd}
              >
                <div className="vb-block-actions">
                  <span className="drag-handle">⋮⋮</span>
                  <button
                    type="button"
                    className="delete-btn"
                    onClick={(e) => {
                      e.stopPropagation();
                      deleteBlock(block.id);
                    }}
                  >
                    &times;
                  </button>
                </div>

                {block.type === 'divider' ? (
                  <hr style={block.styles} />
                ) : (
                  <div
                    contentEditable
                    suppressContentEditableWarning
                    style={block.styles}
                    className={`vb-content vb-${block.type}`}
                    onBlur={(e) => updateBlockContent(block.id, e.target.innerHTML)}
                    dangerouslySetInnerHTML={{ __html: block.content }}
                  />
                )}
              </div>
            ))
          )}
        </div>

        {selectedBlock && (
          <div className="vb-properties">
            <h4>Properties</h4>
            <div className="prop-group">
              <label>Text Align</label>
              <div className="btn-group">
                <button
                  type="button"
                  className={selectedBlock.styles.textAlign === 'left' ? 'active' : ''}
                  onClick={() => updateBlockStyle(selectedBlock.id, 'textAlign', 'left')}
                >
                  Left
                </button>
                <button
                  type="button"
                  className={selectedBlock.styles.textAlign === 'center' ? 'active' : ''}
                  onClick={() => updateBlockStyle(selectedBlock.id, 'textAlign', 'center')}
                >
                  Center
                </button>
                <button
                  type="button"
                  className={selectedBlock.styles.textAlign === 'right' ? 'active' : ''}
                  onClick={() => updateBlockStyle(selectedBlock.id, 'textAlign', 'right')}
                >
                  Right
                </button>
              </div>
            </div>

            <div className="prop-group">
              <label>Color</label>
              <input
                type="color"
                value={selectedBlock.styles.color === 'inherit' ? '#000000' : selectedBlock.styles.color}
                onChange={(e) => updateBlockStyle(selectedBlock.id, 'color', e.target.value)}
              />
            </div>
          </div>
        )}
      </div>

      <Modal
        isOpen={clearModalOpen}
        onClose={() => setClearModalOpen(false)}
        title="Clear All Content"
        type="danger"
        footer={
          <>
            <button
              className="btn btn-secondary"
              onClick={() => setClearModalOpen(false)}
            >
              Cancel
            </button>
            <button
              className="btn btn-danger"
              onClick={confirmClear}
            >
              Clear All
            </button>
          </>
        }
      >
        <p>Are you sure you want to clear all content? This action cannot be undone.</p>
      </Modal>
    </div>
  );
}

// Helper to parse HTML content into blocks
function parseContent(html) {
  if (!html) return [];
  const div = document.createElement('div');
  div.innerHTML = html;

  return Array.from(div.children).map((el, index) => {
    const type = getElementType(el);
    return {
      id: `block-${index}-${crypto.randomUUID()}`,
      type,
      content: el.innerHTML,
      styles: getElementStyles(el)
    };
  });
}

function getElementType(el) {
  const tag = el.tagName.toLowerCase();
  if (tag === 'h1') return 'heading1';
  if (tag === 'h2') return 'heading2';
  if (tag === 'h3') return 'heading3';
  if (tag === 'p') return 'text';
  if (tag === 'ul') return 'list';
  if (tag === 'table') return 'table';
  if (tag === 'hr') return 'divider';
  return 'text';
}

function getElementStyles(el) {
  return {
    textAlign: el.style.textAlign || 'left',
    color: el.style.color || 'inherit',
    fontSize: el.style.fontSize || '',
    fontWeight: el.style.fontWeight || '',
    backgroundColor: el.style.backgroundColor || 'transparent'
  };
}

// Convert blocks back to HTML
function blocksToHtml(currentBlocks) {
  return currentBlocks.map(block => {
    const styleString = Object.entries(block.styles)
      .filter(([, value]) => value && value !== 'inherit' && value !== 'transparent')
      .map(([key, value]) => `${key.replace(/[A-Z]/g, m => `-${m.toLowerCase()}`)}: ${value}`)
      .join('; ');

    const styleAttr = styleString ? ` style="${styleString}"` : '';

    switch (block.type) {
      case 'heading1': return `<h1${styleAttr}>${block.content}</h1>`;
      case 'heading2': return `<h2${styleAttr}>${block.content}</h2>`;
      case 'heading3': return `<h3${styleAttr}>${block.content}</h3>`;
      case 'text': return `<p${styleAttr}>${block.content}</p>`;
      case 'list': return `<ul${styleAttr}>${block.content}</ul>`;
      case 'table': return `<table${styleAttr}>${block.content}</table>`;
      case 'divider': return `<hr${styleAttr} />`;
      default: return `<div${styleAttr}>${block.content}</div>`;
    }
  }).join('\n');
}

const getDefaultContent = (type) => {
  switch (type) {
    case 'heading1': return 'Heading 1';
    case 'heading2': return 'Heading 2';
    case 'heading3': return 'Heading 3';
    case 'text': return 'Enter your text here...';
    case 'list': return '<li>List item 1</li><li>List item 2</li>';
    case 'table': return '<thead><tr><th>Header 1</th><th>Header 2</th></tr></thead><tbody><tr><td>Cell 1</td><td>Cell 2</td></tr></tbody>';
    case 'divider': return '';
    default: return '';
  }
};
