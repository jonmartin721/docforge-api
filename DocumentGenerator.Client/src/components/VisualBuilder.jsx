
import React, { useState, useEffect } from 'react';
import {
  DndContext,
  DragOverlay,
  useSensor,
  useSensors,
  PointerSensor,
  KeyboardSensor,
  // closestCenter // Removed as per instruction
} from '@dnd-kit/core';
import {
  sortableKeyboardCoordinates,
  rectSortingStrategy,
  SortableContext,
  verticalListSortingStrategy,
  useSortable,
  arrayMove
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import {
  Type,
  Heading1,
  Table,
  Image as ImageIcon,
  GripVertical,
  Trash2,
  LayoutGrid,
  Minus,
  Quote,
  List,
  PenTool,
  Columns,
  FileText,
  MousePointer2
} from 'lucide-react';
import './VisualBuilder.css';

// --- Block Components ---

const BlockWrapper = ({ block, isSelected, onClick, onDelete, onChange, layoutMode }) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging
  } = useSortable({ id: block.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
    position: layoutMode === 'canvas' ? 'absolute' : 'relative',
    left: layoutMode === 'canvas' ? (block.x || 0) + 'px' : 'auto',
    top: layoutMode === 'canvas' ? (block.y || 0) + 'px' : 'auto',
    width: layoutMode === 'canvas' ? (block.w ? block.w + 'px' : 'auto') : '100%',
    zIndex: isSelected ? 10 : 1
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`vb-block-wrapper ${isSelected ? 'selected' : ''}`}
      onClick={(e) => {
        e.stopPropagation();
        onClick();
      }}
    >
      <div className="vb-block-actions">
        <div {...attributes} {...listeners} className="vb-drag-handle">
          <GripVertical size={16} />
        </div>
        <button className="vb-delete-btn" onClick={(e) => {
          e.stopPropagation();
          onDelete();
        }}>
          <Trash2 size={16} />
        </button>
      </div>
      <div className="vb-block-content">
        <BlockContent block={block} onChange={onChange} />
      </div>
    </div>
  );
};

// --- Main Component ---

const TOOLS = [
  { type: 'heading', label: 'Header', icon: Heading1 },
  { type: 'text', label: 'Text', icon: Type },
  { type: 'image', label: 'Image', icon: ImageIcon },
  { type: 'divider', label: 'Divider', icon: Minus },
  { type: 'spacer', label: 'Spacer', icon: GripVertical }, // Reusing GripVertical as icon for spacer
  { type: 'quote', label: 'Quote', icon: Quote },
  { type: 'list', label: 'List', icon: List },
  { type: 'signature', label: 'Signature', icon: PenTool },
  { type: '2-col-text', label: '2 Columns', icon: Columns },
  { type: 'invoice-grid', label: 'Invoice Grid', icon: LayoutGrid },
  { type: 'items-table', label: 'Items Table', icon: Table },
];

const PRESETS = {
  invoice: [
    { id: '1', type: 'heading', content: 'INVOICE' },
    { id: '2', type: 'invoice-grid', from: 'My Company\n123 Business Rd\nCity, State 12345', to: 'Client Name\n456 Client St\nCity, State 67890' },
    { id: '3', type: 'items-table' },
    { id: '4', type: 'text', content: 'Thank you for your business!' }
  ],
  contract: [
    { id: '1', type: 'heading', content: 'SERVICE AGREEMENT' },
    { id: '2', type: 'text', content: 'This Agreement is made between My Company ("Provider") and {{clientName}} ("Client").' },
    { id: '3', type: 'divider' },
    { id: '4', type: 'heading', content: '1. Services' },
    { id: '5', type: 'text', content: 'Provider agrees to perform the following services:\n\n- Service A\n- Service B' },
    { id: '6', type: 'heading', content: '2. Payment' },
    { id: '7', type: 'text', content: 'Client agrees to pay {{amount}} upon completion.' },
    { id: '8', type: 'spacer' },
    { id: '9', type: '2-col-text', left: 'Signed (Provider):', right: 'Signed (Client):' },
    { id: '10', type: 'signature' }
  ],
  letter: [
    { id: '1', type: 'image', url: 'https://via.placeholder.com/150x50?text=LOGO', width: '150px', align: 'left' },
    { id: '2', type: 'text', content: '123 Business Rd\nCity, State 12345\n\n{{currentDate}}' },
    { id: '3', type: 'text', content: 'Dear {{recipientName}},' },
    { id: '4', type: 'text', content: 'Write your letter content here...' },
    { id: '5', type: 'text', content: 'Sincerely,\n\nYour Name' },
    { id: '6', type: 'signature' }
  ]
};

export default function VisualBuilder({ initialContent, onChange }) {
  const [blocks, setBlocks] = useState([]);
  const [selectedBlockId, setSelectedBlockId] = useState(null);
  const [layoutMode, setLayoutMode] = useState('document'); // 'document' | 'canvas'

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  // Load initial content
  useEffect(() => {
    if (initialContent) {
      // Try to parse existing blocks
      const parsed = parseBlocksFromHtml(initialContent);
      if (parsed) {
        setBlocks(parsed.blocks);
        if (parsed.layoutMode) setLayoutMode(parsed.layoutMode);
        return; // Successfully loaded blocks
      }
    }
    // Default start if no blocks found
    if (!initialContent) {
        loadPreset('invoice');
    }
  }, []);

  const loadPreset = (presetName) => {
    if (blocks.length > 0 && !confirm('This will replace your current template. Continue?')) return;

    const preset = PRESETS[presetName].map(b => ({
      ...b,
      id: Math.random().toString(36).substr(2, 9),
      // Default coordinates for fixed mode if switched
      x: 50,
      y: 50 + (Math.random() * 200)
    }));
    setBlocks(preset);
  };

  // Update parent whenever blocks change
  useEffect(() => {
    const html = generateHtml(blocks, layoutMode);
    onChange(html);
  }, [blocks, layoutMode]);

  const handleDragStart = (event) => {
    // setActiveDragId(event.active.id); // Not used in the new snippet
  };

  const handleDragEnd = (event) => {
    const { active, over, delta } = event;

    if (!over) return;

    // Handle dropping a new tool
    if (active.data.current?.isTool) {
      const type = active.data.current.type;
      const newBlock = createBlock(type);

        if (layoutMode === 'canvas') {
        // For this iteration, let's place it at a default visible spot
        // A more advanced implementation would calculate drop coordinates relative to the canvas.
        newBlock.x = 50;
        newBlock.y = 50 + (blocks.length * 20); // Simple stacking for new items
        setBlocks([...blocks, newBlock]);
      } else {
        // Flow mode: insert at index
        setBlocks((items) => {
          const overIndex = items.findIndex(b => b.id === over.id);
          const newBlocks = [...items];
          newBlocks.splice(overIndex >= 0 ? overIndex + 1 : items.length, 0, newBlock);
          return newBlocks;
        });
      }
      return;
    }

    // Handle moving existing blocks
    if (layoutMode === 'canvas') {
      setBlocks(items => items.map(block => {
        if (block.id === active.id) {
          return {
            ...block,
            x: (block.x || 0) + delta.x,
            y: (block.y || 0) + delta.y
          };
        }
        return block;
      }));
    } else {
      // Flow mode sorting
      if (active.id !== over.id) {
        setBlocks((items) => {
          const oldIndex = items.findIndex((item) => item.id === active.id);
          const newIndex = items.findIndex((item) => item.id === over.id);
          return arrayMove(items, oldIndex, newIndex);
        });
      }
    }
  };

  const createBlock = (type) => {
    const id = Math.random().toString(36).substr(2, 9);
    switch (type) {
      case 'heading': return { id, type, content: 'New Heading' };
      case 'text': return { id, type, content: 'Click to edit text...' };
      case 'image': return { id, type, url: 'https://via.placeholder.com/300x200', width: '100%', align: 'center' };
      case 'divider': return { id, type };
      case 'spacer': return { id, type, height: '50px' };
      case 'quote': return { id, type, content: 'Insert quote here...' };
      case 'list': return { id, type, items: ['Item 1', 'Item 2', 'Item 3'], listType: 'ul' };
      case 'signature': return { id, type };
      case '2-col-text': return { id, type, left: 'Left column content...', right: 'Right column content...' };
      case 'invoice-grid': return { id, type, from: 'From:\nMy Company\nAddress', to: 'To:\n{{customerName}}\nAddress' };
      case 'items-table': return { id, type };
      default: return { id, type };
    }
  };

  const updateBlock = (id, updates) => {
    setBlocks(blocks.map(b => b.id === id ? { ...b, ...updates } : b));
  };

  const deleteBlock = (id) => {
    setBlocks(blocks.filter(b => b.id !== id));
    if (selectedBlockId === id) setSelectedBlockId(null);
  };

  return (
    <DndContext
      sensors={sensors}
      // collisionDetection={closestCenter} // Removed as per instruction
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
    >
      <div className="visual-builder">
        <div className="vb-sidebar">
          <div className="vb-sidebar-header">Presets</div>
          <div className="vb-presets">
            <button className="btn btn-xs btn-secondary w-full mb-xs" onClick={() => loadPreset('invoice')}>Invoice</button>
            <button className="btn btn-xs btn-secondary w-full mb-xs" onClick={() => loadPreset('contract')}>Contract</button>
            <button className="btn btn-xs btn-secondary w-full mb-xs" onClick={() => loadPreset('letter')}>Letter</button>
          </div>
          <div className="vb-sidebar-header mt-md">Tools</div>
          <div className="vb-tools">
            {TOOLS.map(tool => (
              <DraggableTool key={tool.type} tool={tool} />
            ))}
          </div>
        </div>

        <div className="vb-main">
          <div className="vb-toolbar">
            <div className="flex-between">
              <div className="text-sm text-muted">
                {layoutMode === 'document' 
                  ? 'Items stack automatically (like a document)' 
                  : 'Place items anywhere (like a canvas)'}
              </div>
              <div className="btn-group">
                <button
                  className={`btn btn-xs ${layoutMode === 'document' ? 'btn-primary' : 'btn-secondary'}`}
                  onClick={() => setLayoutMode('document')}
                  title="Items stack automatically"
                >
                  <FileText size={14} style={{ marginRight: '4px' }} />
                  Document
                </button>
                <button
                  className={`btn btn-xs ${layoutMode === 'canvas' ? 'btn-primary' : 'btn-secondary'}`}
                  onClick={() => setLayoutMode('canvas')}
                  title="Place items anywhere"
                >
                  <MousePointer2 size={14} style={{ marginRight: '4px' }} />
                  Canvas
                </button>
              </div>
            </div>
          </div>

          <div className="vb-canvas-wrapper">
            <div className={`vb-canvas ${layoutMode === 'canvas' ? 'vb-canvas-fixed' : ''}`}>
              <SortableContext
                items={blocks.map(b => b.id)}
                strategy={layoutMode === 'canvas' ? rectSortingStrategy : verticalListSortingStrategy}
              >
                <div
                  id="canvas"
                  className="vb-drop-area"
                  style={layoutMode === 'canvas' ? { position: 'relative', height: '100%', minHeight: '297mm' } : {}}
                >
                  {blocks.length === 0 && (
                    <div className="vb-placeholder">
                      Drop items here
                    </div>
                  )}
                  {blocks.map((block) => (
                    <BlockWrapper
                      key={block.id}
                      block={block}
                      isSelected={selectedBlockId === block.id}
                      onClick={() => setSelectedBlockId(block.id)}
                      onDelete={() => deleteBlock(block.id)}
                      onChange={(updates) => updateBlock(block.id, updates)}
                      layoutMode={layoutMode}
                    />
                  ))}
                </div>
              </SortableContext>
            </div>
            <DragOverlay>
              {/* Optional: Custom drag preview */}
              {/* {activeDragId ? (
                <div className="vb-tool-overlay">
                  Dragging...
                </div>
              ) : null} */}
            </DragOverlay>
          </div>
        </div>
      </div>
    </DndContext>
  );
}

function DraggableTool({ tool }) {
  const { attributes, listeners, setNodeRef, transform } = useSortable({
    id: `tool-${tool.type}`,
    data: {
      isTool: true,
      type: tool.type,
    }
  });

  const style = transform ? {
    transform: CSS.Transform.toString(transform),
  } : undefined;

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...listeners}
      {...attributes}
      className="vb-tool"
    >
      <tool.icon size={24} />
      <span>{tool.label}</span>
    </div>
  );
}

function BlockContent({ block, onChange }) {
  switch (block.type) {
    case 'heading':
      return (
        <div className="vb-block-header">
          <input
            value={block.content}
            onChange={(e) => onChange({ content: e.target.value })}
            placeholder="Heading"
          />
        </div>
      );
    case 'text':
      return (
        <div className="vb-block-text">
          <textarea
            value={block.content}
            onChange={(e) => onChange({ content: e.target.value })}
            placeholder="Enter text..."
          />
        </div>
      );
    case 'image':
      return (
        <div className="vb-block-image">
          <div className="flex gap-sm mb-sm">
            <input 
              className="flex-1"
              value={block.url} 
              onChange={(e) => onChange({ url: e.target.value })}
              placeholder="Image URL"
            />
            <input 
              style={{ width: '80px' }}
              value={block.width} 
              onChange={(e) => onChange({ width: e.target.value })}
              placeholder="Width"
            />
            <select 
              value={block.align} 
              onChange={(e) => onChange({ align: e.target.value })}
            >
              <option value="left">Left</option>
              <option value="center">Center</option>
              <option value="right">Right</option>
            </select>
          </div>
          <div style={{ textAlign: block.align }}>
            <img src={block.url} style={{ maxWidth: '100%', width: block.width, maxHeight: '100px', objectFit: 'contain' }} alt="Preview" />
          </div>
        </div>
      );
    case 'divider':
      return <hr style={{ border: 0, borderTop: '1px solid #ccc', margin: '1rem 0' }} />;
    case 'spacer':
      return (
        <div className="vb-block-spacer flex-center text-muted text-sm" style={{ height: block.height || '50px', background: '#f8f9fa', border: '1px dashed #dee2e6' }}>
          Spacer: <input value={block.height} onChange={(e) => onChange({ height: e.target.value })} style={{ width: '60px', marginLeft: '5px', padding: '2px' }} />
        </div>
      );
    case 'quote':
      return (
        <blockquote style={{ borderLeft: '4px solid #ccc', margin: '0 10px', padding: '0.5em 10px' }}>
          <textarea 
            value={block.content} 
            onChange={(e) => onChange({ content: e.target.value })}
            placeholder="Quote text..."
            style={{ width: '100%', border: 'none', background: 'transparent', fontStyle: 'italic' }}
          />
        </blockquote>
      );
    case 'list':
      return (
        <div className="vb-block-list">
          <div className="flex-between mb-sm">
            <select 
              value={block.listType} 
              onChange={(e) => onChange({ listType: e.target.value })}
              className="text-sm p-1"
            >
              <option value="ul">Bulleted</option>
              <option value="ol">Numbered</option>
            </select>
            <button className="btn btn-xs btn-secondary" onClick={() => onChange({ items: [...block.items, 'New Item'] })}>+ Item</button>
          </div>
          {block.listType === 'ol' ? (
            <ol className="pl-lg">
              {block.items.map((item, i) => (
                <li key={i} className="mb-xs">
                  <div className="flex gap-xs">
                    <input 
                      value={item} 
                      onChange={(e) => {
                        const newItems = [...block.items];
                        newItems[i] = e.target.value;
                        onChange({ items: newItems });
                      }}
                      className="flex-1 p-1 border rounded"
                    />
                    <button className="btn btn-xs btn-danger" onClick={() => {
                      const newItems = block.items.filter((_, idx) => idx !== i);
                      onChange({ items: newItems });
                    }}>×</button>
                  </div>
                </li>
              ))}
            </ol>
          ) : (
            <ul className="pl-lg">
              {block.items.map((item, i) => (
                <li key={i} className="mb-xs">
                  <div className="flex gap-xs">
                    <input 
                      value={item} 
                      onChange={(e) => {
                        const newItems = [...block.items];
                        newItems[i] = e.target.value;
                        onChange({ items: newItems });
                      }}
                      className="flex-1 p-1 border rounded"
                    />
                    <button className="btn btn-xs btn-danger" onClick={() => {
                      const newItems = block.items.filter((_, idx) => idx !== i);
                      onChange({ items: newItems });
                    }}>×</button>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>
      );
    case 'signature':
      return (
        <div style={{ marginTop: '1rem', borderTop: '1px solid #000', width: '200px', paddingTop: '0.5rem' }}>
          Signature
        </div>
      );
    case '2-col-text':
      return (
        <div className="flex gap-lg">
          <div className="flex-1">
            <textarea 
              value={block.left} 
              onChange={(e) => onChange({ left: e.target.value })}
              placeholder="Left column..."
              rows={3}
              style={{ width: '100%', border: '1px dashed #eee', padding: '5px' }}
            />
          </div>
          <div className="flex-1">
            <textarea 
              value={block.right} 
              onChange={(e) => onChange({ right: e.target.value })}
              placeholder="Right column..."
              rows={3}
              style={{ width: '100%', border: '1px dashed #eee', padding: '5px' }}
            />
          </div>
        </div>
      );
    case 'invoice-grid':
      return (
        <div className="flex-between gap-lg">
          <div className="vb-block-text flex-1">
            <textarea 
              value={block.from} 
              onChange={(e) => onChange({ from: e.target.value })}
              placeholder="From details..."
              rows={3}
            />
          </div>
          <div className="vb-block-text flex-1 text-right">
            <textarea 
              value={block.to} 
              onChange={(e) => onChange({ to: e.target.value })}
              placeholder="To details..."
              rows={3}
              style={{ textAlign: 'right' }}
            />
          </div>
        </div>
      );
    case 'items-table':
      return (
        <div>
          <table className="vb-block-table">
            <thead>
              <tr>
                <th>Item</th>
                <th style={{ textAlign: 'right' }}>Price</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>{'{'}{'{'}name{'}'}{'}'}</td>
                <td style={{ textAlign: 'right' }}>{'{'}{'{'}price{'}'}{'}'}</td>
              </tr>
              <tr>
                <td colSpan={2} className="text-center text-muted text-sm">
                  (Repeats for each item)
                </td>
              </tr>
            </tbody>
          </table>
          <div className="text-right mt-md font-bold">
            Total: {'{'}{'{'}total{'}'}{'}'}
          </div>
        </div>
      );
    default:
      return <div>Unknown Block</div>;
  }
}

// --- Helper Functions ---

function generateHtml(blocks, layoutMode = 'flow') {
  const blocksData = JSON.stringify({ blocks, layoutMode });
  const hiddenComment = `<!-- VISUAL_BLOCKS:${blocksData}-->`;

  let contentHtml = '';
  
  if (layoutMode === 'canvas') {
    const itemsHtml = blocks.map(block => {
      const innerHtml = getBlockHtml(block);
      return `<div style="position: absolute; left: ${block.x || 0}px; top: ${block.y || 0}px; width: ${block.w ? block.w + 'px' : 'auto'};">${innerHtml}</div>`;
    }).join('\n');
    
    contentHtml = `<div style="position: relative; width: 210mm; height: 297mm;">\n${itemsHtml}\n</div>`;
  } else {
    contentHtml = blocks.map(getBlockHtml).join('\n');
  }

  return `${contentHtml}\n${hiddenComment}`;
}

function getBlockHtml(block) {
    switch (block.type) {
        case 'heading':
          return `<h1>${block.content}</h1>`;
        case 'text':
          return `<p>${block.content.replace(/\n/g, '<br>')}</p>`;
        case 'image':
          return `<div style="text-align: ${block.align}; margin-bottom: 1rem;"><img src="${block.url}" style="max-width: 100%; width: ${block.width};" alt="Image" /></div>`;
        case 'divider':
          return `<hr style="border: 0; border-top: 1px solid #ccc; margin: 2rem 0;" />`;
        case 'spacer':
          return `<div style="height: ${block.height || '50px'};"></div>`;
        case 'quote':
          return `<blockquote style="border-left: 4px solid #ccc; margin: 1.5em 10px; padding: 0.5em 10px; font-style: italic;">${block.content}</blockquote>`;
        case 'list':
          const tag = block.listType === 'ol' ? 'ol' : 'ul';
          const itemsHtml = block.items.map(item => `<li>${item}</li>`).join('');
          return `<${tag}>${itemsHtml}</${tag}>`;
        case 'signature':
          return `<div style="margin-top: 3rem; border-top: 1px solid #000; width: 200px; padding-top: 0.5rem;">Signature</div>`;
        case '2-col-text':
          return `<div style="display: flex; gap: 2rem; margin-bottom: 1rem;">
<div style="flex: 1;">${block.left.replace(/\n/g, '<br>')}</div>
<div style="flex: 1;">${block.right.replace(/\n/g, '<br>')}</div>
</div>`;
        case 'invoice-grid':
          return `
<div style="display: flex; justify-content: space-between; margin-bottom: 2rem;">
  <div>${block.from.replace(/\n/g, '<br>')}</div>
  <div>${block.to.replace(/\n/g, '<br>')}</div>
</div>`;
        case 'items-table':
          return `
<table style="width: 100%; border-collapse: collapse; margin-bottom: 2rem;">
  <thead>
    <tr style="background: #f3f4f6;">
      <th style="padding: 0.5rem; text-align: left;">Item</th>
      <th style="padding: 0.5rem; text-align: right;">Price</th>
    </tr>
  </thead>
  <tbody>
    {{#each items}}
    <tr>
      <td style="padding: 0.5rem; border-bottom: 1px solid #eee;">{{name}}</td>
      <td style="padding: 0.5rem; border-bottom: 1px solid #eee; text-align: right;">{{price}}</td>
    </tr>
    {{/each}}
  </tbody>
</table>
<div style="text-align: right; font-size: 1.25rem; font-weight: bold;">
  Total: {{total}}
</div>`;
        default: return '';
      }
}

function parseBlocksFromHtml(html) {
  const match = html.match(/<!-- VISUAL_BLOCKS:(.*?)-->/);
  if (match && match[1]) {
    try {
      const parsed = JSON.parse(match[1]);
      // Handle legacy format (array) vs new format (object)
      if (Array.isArray(parsed)) {
        return { blocks: parsed, layoutMode: 'document' };
      }
      // Map legacy modes to new ones
      if (parsed.layoutMode === 'flow') parsed.layoutMode = 'document';
      if (parsed.layoutMode === 'fixed') parsed.layoutMode = 'canvas';
      
      return parsed;
    } catch (e) {
      console.error("Failed to parse blocks", e);
    }
  }
  return null;
}

