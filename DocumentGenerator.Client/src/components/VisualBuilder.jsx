import { useState, useRef, useEffect, useCallback } from 'react';
import './VisualBuilder.css';
import Modal from './Modal';

const SNAP_THRESHOLD = 8; // pixels
const DEFAULT_WIDTH = 300;
const DEFAULT_HEIGHT = 40;

export default function VisualBuilder({ initialContent, onChange }) {
  const [blocks, setBlocks] = useState(() => parseContent(initialContent));
  const [selectedBlockId, setSelectedBlockId] = useState(null);
  const [draggedElementType, setDraggedElementType] = useState(null);
  const [clearModalOpen, setClearModalOpen] = useState(false);

  // Dragging state
  const [dragging, setDragging] = useState(null); // { blockId, startX, startY, offsetX, offsetY }
  const [dragPreview, setDragPreview] = useState(null); // { x, y } - current drag position
  const [snapLines, setSnapLines] = useState({ horizontal: [], vertical: [] });

  const canvasRef = useRef(null);

  // Derive selectedBlock from blocks array
  const selectedBlock = selectedBlockId ? blocks.find(b => b.id === selectedBlockId) : null;

  const updateBlocks = useCallback((newBlocks) => {
    setBlocks(newBlocks);
    onChange(blocksToHtml(newBlocks));
  }, [onChange]);

  const addBlock = useCallback((type, position = null) => {
    const canvasRect = canvasRef.current?.getBoundingClientRect();
    const defaultPos = position || {
      x: 20,
      y: blocks.length > 0
        ? Math.max(...blocks.map(b => b.position.y + b.size.height)) + 16
        : 20
    };

    const newBlock = {
      id: `block-${generateUUID()}`,
      type,
      content: getDefaultContent(type),
      styles: { textAlign: 'left' },
      position: defaultPos,
      size: {
        width: type === 'divider' ? (canvasRect?.width - 40 || 560) : DEFAULT_WIDTH,
        height: type === 'divider' ? 4 : DEFAULT_HEIGHT
      }
    };
    updateBlocks([...blocks, newBlock]);
    return newBlock;
  }, [blocks, updateBlocks]);

  const updateBlockPosition = useCallback((id, position) => {
    const newBlocks = blocks.map(b =>
      b.id === id ? { ...b, position } : b
    );
    updateBlocks(newBlocks);
  }, [blocks, updateBlocks]);

  const updateBlockContent = (id, content) => {
    const newBlocks = blocks.map(b =>
      b.id === id ? { ...b, content } : b
    );
    updateBlocks(newBlocks);
  };

  const updateBlockStyle = (id, styleName, value) => {
    const block = blocks.find(b => b.id === id);

    // For tables, apply text-align to all cells
    if (block?.type === 'table' && styleName === 'textAlign') {
      const parser = new DOMParser();
      const doc = parser.parseFromString(block.content, 'text/html');
      const cells = doc.querySelectorAll('th, td');
      cells.forEach(cell => {
        cell.style.textAlign = value;
      });
      const table = doc.querySelector('table');
      if (table) {
        const newBlocks = blocks.map(b =>
          b.id === id ? { ...b, content: table.outerHTML, styles: { ...b.styles, [styleName]: value } } : b
        );
        updateBlocks(newBlocks);
        return;
      }
    }

    const newBlocks = blocks.map(b =>
      b.id === id ? { ...b, styles: { ...b.styles, [styleName]: value } } : b
    );
    updateBlocks(newBlocks);
  };

  // Table manipulation functions
  const getTableInfo = (block) => {
    if (block?.type !== 'table') return null;
    const parser = new DOMParser();
    const doc = parser.parseFromString(block.content, 'text/html');
    const table = doc.querySelector('table');
    if (!table) return null;

    const rows = table.querySelectorAll('tr');
    const cols = rows[0]?.querySelectorAll('th, td').length || 0;
    return { rows: rows.length, cols };
  };

  const addTableColumn = (id) => {
    const block = blocks.find(b => b.id === id);
    if (block?.type !== 'table') return;

    const parser = new DOMParser();
    const doc = parser.parseFromString(block.content, 'text/html');
    const rows = doc.querySelectorAll('tr');

    rows.forEach(row => {
      const isHeader = row.closest('thead') !== null;
      const cell = document.createElement(isHeader ? 'th' : 'td');
      cell.textContent = isHeader ? 'Header' : 'Cell';
      cell.style.textAlign = block.styles.textAlign || 'left';
      row.appendChild(cell);
    });

    const table = doc.querySelector('table');
    if (table) {
      updateBlockContent(id, table.outerHTML);
    }
  };

  const removeTableColumn = (id) => {
    const block = blocks.find(b => b.id === id);
    if (block?.type !== 'table') return;

    const parser = new DOMParser();
    const doc = parser.parseFromString(block.content, 'text/html');
    const rows = doc.querySelectorAll('tr');

    rows.forEach(row => {
      const cells = row.querySelectorAll('th, td');
      if (cells.length > 1) {
        cells[cells.length - 1].remove();
      }
    });

    const table = doc.querySelector('table');
    if (table) {
      updateBlockContent(id, table.outerHTML);
    }
  };

  const addTableRow = (id) => {
    const block = blocks.find(b => b.id === id);
    if (block?.type !== 'table') return;

    const parser = new DOMParser();
    const doc = parser.parseFromString(block.content, 'text/html');
    const tbody = doc.querySelector('tbody') || doc.querySelector('table');
    const firstRow = doc.querySelector('tr');
    const colCount = firstRow?.querySelectorAll('th, td').length || 2;

    const newRow = document.createElement('tr');
    for (let i = 0; i < colCount; i++) {
      const cell = document.createElement('td');
      cell.textContent = 'Cell';
      cell.style.textAlign = block.styles.textAlign || 'left';
      newRow.appendChild(cell);
    }
    tbody.appendChild(newRow);

    const table = doc.querySelector('table');
    if (table) {
      updateBlockContent(id, table.outerHTML);
    }
  };

  const removeTableRow = (id) => {
    const block = blocks.find(b => b.id === id);
    if (block?.type !== 'table') return;

    const parser = new DOMParser();
    const doc = parser.parseFromString(block.content, 'text/html');
    const tbody = doc.querySelector('tbody');
    const rows = tbody?.querySelectorAll('tr');

    if (rows && rows.length > 1) {
      rows[rows.length - 1].remove();
    }

    const table = doc.querySelector('table');
    if (table) {
      updateBlockContent(id, table.outerHTML);
    }
  };

  const updateBlockSize = useCallback((id, size) => {
    const newBlocks = blocks.map(b =>
      b.id === id ? { ...b, size: { ...b.size, ...size } } : b
    );
    updateBlocks(newBlocks);
  }, [blocks, updateBlocks]);

  const deleteBlock = (id) => {
    const newBlocks = blocks.filter(b => b.id !== id);
    updateBlocks(newBlocks);
    if (selectedBlockId === id) setSelectedBlockId(null);
  };

  // Calculate snap lines from other blocks
  const calculateSnapLines = useCallback((draggedId, currentPos, currentSize) => {
    const horizontal = [];
    const vertical = [];
    const canvas = canvasRef.current;
    if (!canvas) return { horizontal, vertical };

    const canvasRect = canvas.getBoundingClientRect();
    const canvasWidth = canvasRect.width;
    const canvasHeight = canvasRect.height;

    // Canvas edge snap points
    const canvasSnapPoints = {
      left: 20, // margin
      right: canvasWidth - 20,
      centerX: canvasWidth / 2,
      top: 20,
      bottom: canvasHeight - 20,
      centerY: canvasHeight / 2
    };

    // Current block edges
    const currentLeft = currentPos.x;
    const currentRight = currentPos.x + currentSize.width;
    const currentCenterX = currentPos.x + currentSize.width / 2;
    const currentTop = currentPos.y;
    const currentBottom = currentPos.y + currentSize.height;
    const currentCenterY = currentPos.y + currentSize.height / 2;

    // Check canvas snaps
    if (Math.abs(currentLeft - canvasSnapPoints.left) < SNAP_THRESHOLD) {
      vertical.push({ position: canvasSnapPoints.left, type: 'canvas' });
    }
    if (Math.abs(currentRight - canvasSnapPoints.right) < SNAP_THRESHOLD) {
      vertical.push({ position: canvasSnapPoints.right, type: 'canvas' });
    }
    if (Math.abs(currentCenterX - canvasSnapPoints.centerX) < SNAP_THRESHOLD) {
      vertical.push({ position: canvasSnapPoints.centerX, type: 'center' });
    }
    if (Math.abs(currentTop - canvasSnapPoints.top) < SNAP_THRESHOLD) {
      horizontal.push({ position: canvasSnapPoints.top, type: 'canvas' });
    }

    // Check other blocks for snap points
    blocks.forEach(block => {
      if (block.id === draggedId) return;

      const blockLeft = block.position.x;
      const blockRight = block.position.x + block.size.width;
      const blockCenterX = block.position.x + block.size.width / 2;
      const blockTop = block.position.y;
      const blockBottom = block.position.y + block.size.height;
      const blockCenterY = block.position.y + block.size.height / 2;

      // Vertical snaps (x-axis alignment)
      if (Math.abs(currentLeft - blockLeft) < SNAP_THRESHOLD) {
        vertical.push({ position: blockLeft, type: 'edge' });
      }
      if (Math.abs(currentLeft - blockRight) < SNAP_THRESHOLD) {
        vertical.push({ position: blockRight, type: 'edge' });
      }
      if (Math.abs(currentRight - blockLeft) < SNAP_THRESHOLD) {
        vertical.push({ position: blockLeft, type: 'edge' });
      }
      if (Math.abs(currentRight - blockRight) < SNAP_THRESHOLD) {
        vertical.push({ position: blockRight, type: 'edge' });
      }
      if (Math.abs(currentCenterX - blockCenterX) < SNAP_THRESHOLD) {
        vertical.push({ position: blockCenterX, type: 'center' });
      }

      // Horizontal snaps (y-axis alignment)
      if (Math.abs(currentTop - blockTop) < SNAP_THRESHOLD) {
        horizontal.push({ position: blockTop, type: 'edge' });
      }
      if (Math.abs(currentTop - blockBottom) < SNAP_THRESHOLD) {
        horizontal.push({ position: blockBottom, type: 'edge' });
      }
      if (Math.abs(currentBottom - blockTop) < SNAP_THRESHOLD) {
        horizontal.push({ position: blockTop, type: 'edge' });
      }
      if (Math.abs(currentBottom - blockBottom) < SNAP_THRESHOLD) {
        horizontal.push({ position: blockBottom, type: 'edge' });
      }
      if (Math.abs(currentCenterY - blockCenterY) < SNAP_THRESHOLD) {
        horizontal.push({ position: blockCenterY, type: 'center' });
      }
    });

    return { horizontal, vertical };
  }, [blocks]);

  // Apply snapping to position
  const applySnap = useCallback((pos, size, draggedId) => {
    const snapped = { ...pos };
    const lines = calculateSnapLines(draggedId, pos, size);

    // Apply vertical snaps
    for (const snap of lines.vertical) {
      const leftDiff = Math.abs(pos.x - snap.position);
      const rightDiff = Math.abs(pos.x + size.width - snap.position);
      const centerDiff = Math.abs(pos.x + size.width / 2 - snap.position);

      if (leftDiff < SNAP_THRESHOLD) {
        snapped.x = snap.position;
        break;
      } else if (rightDiff < SNAP_THRESHOLD) {
        snapped.x = snap.position - size.width;
        break;
      } else if (centerDiff < SNAP_THRESHOLD) {
        snapped.x = snap.position - size.width / 2;
        break;
      }
    }

    // Apply horizontal snaps
    for (const snap of lines.horizontal) {
      const topDiff = Math.abs(pos.y - snap.position);
      const bottomDiff = Math.abs(pos.y + size.height - snap.position);
      const centerDiff = Math.abs(pos.y + size.height / 2 - snap.position);

      if (topDiff < SNAP_THRESHOLD) {
        snapped.y = snap.position;
        break;
      } else if (bottomDiff < SNAP_THRESHOLD) {
        snapped.y = snap.position - size.height;
        break;
      } else if (centerDiff < SNAP_THRESHOLD) {
        snapped.y = snap.position - size.height / 2;
        break;
      }
    }

    return { snapped, lines };
  }, [calculateSnapLines]);

  // Mouse handlers for dragging blocks
  const handleBlockMouseDown = (e, block) => {
    if (e.target.closest('.delete-btn') || e.target.closest('.resize-handle')) return;
    e.preventDefault();

    const canvasRect = canvasRef.current.getBoundingClientRect();
    setDragging({
      blockId: block.id,
      startX: block.position.x,
      startY: block.position.y,
      offsetX: e.clientX - canvasRect.left - block.position.x,
      offsetY: e.clientY - canvasRect.top - block.position.y
    });
    setSelectedBlockId(block.id);
  };

  useEffect(() => {
    if (!dragging) return;

    const handleMouseMove = (e) => {
      const canvasRect = canvasRef.current.getBoundingClientRect();
      const block = blocks.find(b => b.id === dragging.blockId);
      if (!block) return;

      const rawX = e.clientX - canvasRect.left - dragging.offsetX;
      const rawY = e.clientY - canvasRect.top - dragging.offsetY;

      // Constrain to canvas bounds
      const constrainedX = Math.max(0, Math.min(rawX, canvasRect.width - block.size.width));
      const constrainedY = Math.max(0, rawY);

      const { snapped, lines } = applySnap(
        { x: constrainedX, y: constrainedY },
        block.size,
        block.id
      );

      setDragPreview(snapped);
      setSnapLines(lines);
    };

    const handleMouseUp = () => {
      if (dragPreview) {
        updateBlockPosition(dragging.blockId, dragPreview);
      }
      setDragging(null);
      setDragPreview(null);
      setSnapLines({ horizontal: [], vertical: [] });
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);

    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  }, [dragging, dragPreview, blocks, applySnap, updateBlockPosition]);

  // Sidebar element drag handlers (for new elements)
  const handleElementDragStart = (e, type) => {
    setDraggedElementType(type);
    e.dataTransfer.effectAllowed = 'copy';
    e.dataTransfer.setData('elementType', type);
  };

  const handleElementDragEnd = () => {
    setDraggedElementType(null);
    setDragPreview(null);
    setSnapLines({ horizontal: [], vertical: [] });
  };

  const handleCanvasDragOver = (e) => {
    e.preventDefault();
    if (!draggedElementType || !canvasRef.current) return;

    const canvasRect = canvasRef.current.getBoundingClientRect();
    const x = e.clientX - canvasRect.left - DEFAULT_WIDTH / 2;
    const y = e.clientY - canvasRect.top - DEFAULT_HEIGHT / 2;

    // Constrain to canvas
    const constrainedX = Math.max(0, Math.min(x, canvasRect.width - DEFAULT_WIDTH));
    const constrainedY = Math.max(0, y);

    // Calculate snap lines for preview
    const size = { width: DEFAULT_WIDTH, height: DEFAULT_HEIGHT };
    const { snapped, lines } = applySnap({ x: constrainedX, y: constrainedY }, size, null);

    setDragPreview(snapped);
    setSnapLines(lines);
  };

  const handleCanvasDragLeave = (e) => {
    // Only clear if actually leaving the canvas (not entering a child)
    if (!canvasRef.current?.contains(e.relatedTarget)) {
      setDragPreview(null);
      setSnapLines({ horizontal: [], vertical: [] });
    }
  };

  const handleCanvasDrop = (e) => {
    e.preventDefault();
    const type = e.dataTransfer.getData('elementType');
    if (!type || !canvasRef.current) return;

    // Use the snapped preview position if available
    const position = dragPreview || (() => {
      const canvasRect = canvasRef.current.getBoundingClientRect();
      const x = e.clientX - canvasRect.left - DEFAULT_WIDTH / 2;
      const y = e.clientY - canvasRect.top - DEFAULT_HEIGHT / 2;
      return {
        x: Math.max(0, Math.min(x, canvasRect.width - DEFAULT_WIDTH)),
        y: Math.max(0, y)
      };
    })();

    addBlock(type, position);
    setDraggedElementType(null);
    setDragPreview(null);
    setSnapLines({ horizontal: [], vertical: [] });
  };

  const handleClear = () => {
    setClearModalOpen(true);
  };

  const confirmClear = () => {
    updateBlocks([]);
    setSelectedBlockId(null);
    setClearModalOpen(false);
  };

  const handleCanvasClick = (e) => {
    if (e.target === canvasRef.current) {
      setSelectedBlockId(null);
    }
  };

  // Resize handler
  const handleResizeMouseDown = (e, block) => {
    e.preventDefault();
    e.stopPropagation();

    const startX = e.clientX;
    const startY = e.clientY;
    const startWidth = block.size.width;
    const startHeight = block.size.height;

    const handleMouseMove = (moveEvent) => {
      const deltaX = moveEvent.clientX - startX;
      const deltaY = moveEvent.clientY - startY;
      updateBlockSize(block.id, {
        width: Math.max(100, startWidth + deltaX),
        height: Math.max(24, startHeight + deltaY)
      });
    };

    const handleMouseUp = () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);
  };

  return (
    <div className="visual-builder">
      <div className="vb-sidebar">
        <div className="vb-sidebar-header">
          Elements
        </div>
        <div className="vb-elements">
          {[
            { type: 'heading1', icon: 'H1', label: 'Heading 1' },
            { type: 'heading2', icon: 'H2', label: 'Heading 2' },
            { type: 'heading3', icon: 'H3', label: 'Heading 3' },
            { type: 'text', icon: '¶', label: 'Text' },
            { type: 'list', icon: '≣', label: 'List' },
            { type: 'table', icon: '▦', label: 'Table' },
            { type: 'divider', icon: '—', label: 'Divider' },
          ].map(({ type, icon, label }) => (
            <div
              key={type}
              className={`vb-element ${draggedElementType === type ? 'dragging' : ''}`}
              draggable
              onDragStart={(e) => handleElementDragStart(e, type)}
              onDragEnd={handleElementDragEnd}
              onClick={() => addBlock(type)}
            >
              <span className="vb-element-icon">{icon}</span>
              <span className="vb-element-label">{label}</span>
            </div>
          ))}
        </div>

        <div className="vb-sidebar-footer">
          <button type="button" className="btn btn-danger w-full" onClick={handleClear}>
            Clear All
          </button>
        </div>
      </div>

      <div className="vb-workspace">
        <div
          ref={canvasRef}
          className={`vb-canvas ${draggedElementType ? 'drag-active' : ''}`}
          onDragOver={handleCanvasDragOver}
          onDragLeave={handleCanvasDragLeave}
          onDrop={handleCanvasDrop}
          onClick={handleCanvasClick}
        >
          {blocks.length === 0 && !draggedElementType && (
            <div className="vb-empty-state">
              <p>Drag elements here or click to add</p>
            </div>
          )}

          {/* Ghost preview for new element being dragged */}
          {draggedElementType && dragPreview && (
            <div
              className="vb-block-ghost"
              style={{
                left: dragPreview.x,
                top: dragPreview.y,
                width: DEFAULT_WIDTH,
                height: DEFAULT_HEIGHT
              }}
            />
          )}

          {/* Snap guide lines */}
          {snapLines.vertical.map((line, i) => (
            <div
              key={`v-${i}`}
              className={`vb-snap-line vertical ${line.type}`}
              style={{ left: line.position }}
            />
          ))}
          {snapLines.horizontal.map((line, i) => (
            <div
              key={`h-${i}`}
              className={`vb-snap-line horizontal ${line.type}`}
              style={{ top: line.position }}
            />
          ))}

          {/* Blocks */}
          {blocks.map((block) => {
            const isDragging = dragging?.blockId === block.id;
            const position = isDragging && dragPreview ? dragPreview : block.position;

            return (
              <div
                key={block.id}
                className={`vb-block ${selectedBlock?.id === block.id ? 'selected' : ''} ${isDragging ? 'dragging' : ''}`}
                style={{
                  left: position.x,
                  top: position.y,
                  width: block.size.width,
                  minHeight: block.size.height
                }}
                onMouseDown={(e) => handleBlockMouseDown(e, block)}
                onClick={(e) => {
                  e.stopPropagation();
                  setSelectedBlockId(block.id);
                }}
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
                    ×
                  </button>
                </div>

                {block.type === 'divider' ? (
                  <hr style={block.styles} />
                ) : block.type === 'table' ? (
                  <div
                    className="vb-content vb-table-wrapper"
                    contentEditable
                    suppressContentEditableWarning
                    style={block.styles}
                    onBlur={(e) => {
                      const table = e.target.querySelector('table');
                      if (table) {
                        updateBlockContent(block.id, table.outerHTML);
                      }
                    }}
                    onMouseDown={(e) => e.stopPropagation()}
                    dangerouslySetInnerHTML={{ __html: block.content }}
                  />
                ) : (
                  <div
                    contentEditable
                    suppressContentEditableWarning
                    style={block.styles}
                    className={`vb-content vb-${block.type}`}
                    onBlur={(e) => updateBlockContent(block.id, e.target.innerHTML)}
                    onMouseDown={(e) => e.stopPropagation()}
                    dangerouslySetInnerHTML={{ __html: block.content }}
                  />
                )}

                {/* Resize handle */}
                <div
                  className="resize-handle"
                  onMouseDown={(e) => handleResizeMouseDown(e, block)}
                />
              </div>
            );
          })}
        </div>

        {selectedBlock && (
          <div className="vb-properties">
            <h4>Properties</h4>

            <div className="prop-group">
              <label>Position</label>
              <div className="prop-row">
                <div className="prop-field">
                  <span>X</span>
                  <input
                    type="number"
                    value={Math.round(selectedBlock.position.x)}
                    onChange={(e) => updateBlockPosition(selectedBlock.id, {
                      ...selectedBlock.position,
                      x: parseInt(e.target.value) || 0
                    })}
                  />
                </div>
                <div className="prop-field">
                  <span>Y</span>
                  <input
                    type="number"
                    value={Math.round(selectedBlock.position.y)}
                    onChange={(e) => updateBlockPosition(selectedBlock.id, {
                      ...selectedBlock.position,
                      y: parseInt(e.target.value) || 0
                    })}
                  />
                </div>
              </div>
            </div>

            <div className="prop-group">
              <label>Size</label>
              <div className="prop-row">
                <div className="prop-field">
                  <span>W</span>
                  <input
                    type="number"
                    value={Math.round(selectedBlock.size.width)}
                    onChange={(e) => updateBlockSize(selectedBlock.id, {
                      width: parseInt(e.target.value) || 100
                    })}
                  />
                </div>
                <div className="prop-field">
                  <span>H</span>
                  <input
                    type="number"
                    value={Math.round(selectedBlock.size.height)}
                    onChange={(e) => updateBlockSize(selectedBlock.id, {
                      height: parseInt(e.target.value) || 24
                    })}
                  />
                </div>
              </div>
            </div>

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

            {selectedBlock.type === 'table' && (
              <>
                <div className="prop-group">
                  <label>Columns</label>
                  <div className="table-controls">
                    <button
                      type="button"
                      className="btn btn-sm btn-secondary"
                      onClick={() => removeTableColumn(selectedBlock.id)}
                      disabled={getTableInfo(selectedBlock)?.cols <= 1}
                    >
                      − Remove
                    </button>
                    <span className="table-count">{getTableInfo(selectedBlock)?.cols || 0}</span>
                    <button
                      type="button"
                      className="btn btn-sm btn-secondary"
                      onClick={() => addTableColumn(selectedBlock.id)}
                    >
                      + Add
                    </button>
                  </div>
                </div>

                <div className="prop-group">
                  <label>Rows</label>
                  <div className="table-controls">
                    <button
                      type="button"
                      className="btn btn-sm btn-secondary"
                      onClick={() => removeTableRow(selectedBlock.id)}
                      disabled={getTableInfo(selectedBlock)?.rows <= 2}
                    >
                      − Remove
                    </button>
                    <span className="table-count">{(getTableInfo(selectedBlock)?.rows || 1) - 1}</span>
                    <button
                      type="button"
                      className="btn btn-sm btn-secondary"
                      onClick={() => addTableRow(selectedBlock.id)}
                    >
                      + Add
                    </button>
                  </div>
                </div>
              </>
            )}
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

  let yOffset = 20;
  return Array.from(div.children).map((el) => {
    const type = getElementType(el);

    // For tables, store the full outerHTML since our table rendering expects it
    let content;
    if (type === 'table') {
      // Clone the element and remove positioning styles for the stored content
      const clone = el.cloneNode(true);
      clone.style.position = '';
      clone.style.left = '';
      clone.style.top = '';
      clone.style.width = '';
      content = clone.outerHTML;
    } else {
      content = el.innerHTML;
    }

    const block = {
      id: `block-${generateUUID()}`,
      type,
      content,
      styles: getElementStyles(el),
      position: {
        x: parseInt(el.style.left) || 20,
        y: parseInt(el.style.top) || yOffset
      },
      size: {
        width: parseInt(el.style.width) || DEFAULT_WIDTH,
        height: parseInt(el.style.height) || DEFAULT_HEIGHT
      }
    };
    yOffset += block.size.height + 16;
    return block;
  });
}

function generateUUID() {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (char) {
    const randomValue = Math.random() * 16 | 0;
    const hexValue = char === 'x' ? randomValue : (randomValue & 0x3 | 0x8);
    return hexValue.toString(16);
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

// Convert blocks back to HTML (preserves position as inline styles)
function blocksToHtml(currentBlocks) {
  return currentBlocks.map(block => {
    const styles = {
      ...block.styles,
      position: 'absolute',
      left: `${block.position.x}px`,
      top: `${block.position.y}px`,
      width: `${block.size.width}px`
    };

    const styleString = Object.entries(styles)
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
      case 'table': {
        // Table content already includes <table> tags, just add positioning styles
        // Use case-insensitive regex and trim whitespace to handle various formats
        const trimmedContent = block.content.trim();
        const tableMatch = trimmedContent.match(/^<table([^>]*)>/i);
        if (tableMatch) {
          const existingAttrs = tableMatch[1];
          const newTableOpen = existingAttrs.includes('style=')
            ? `<table${existingAttrs.replace(/style="([^"]*)"/, `style="$1; ${styleString}"`)}>`
            : `<table${existingAttrs}${styleAttr}>`;
          return trimmedContent.replace(/^<table[^>]*>/i, newTableOpen);
        }
        // Content doesn't have table wrapper (shouldn't happen, but handle gracefully)
        return `<table${styleAttr}>${trimmedContent}</table>`;
      }
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
    case 'table': return '<table><thead><tr><th>Header 1</th><th>Header 2</th></tr></thead><tbody><tr><td>Cell 1</td><td>Cell 2</td></tr></tbody></table>';
    case 'divider': return '';
    default: return '';
  }
};
