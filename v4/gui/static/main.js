/* ──────────────────────────────────────────────────────────────────────────
   HakPak4 Script Builder – main.js
   Manages:
     • Loading installed tools from /api/tools  (mirrors CLI state.json)
     • Use-case based automatic command generation from /api/tool/profile
     • Managing the canvas (ordered list of script blocks)
     • Inline block editing via the right-hand editor panel
     • Script generation via /api/script/build
     • Secure git-clone via /api/gitclone
   ────────────────────────────────────────────────────────────────────────── */

'use strict';

// ── State ─────────────────────────────────────────────────────────────────────
let _tools         = {};     // { name → tool metadata }
let _profileCache  = {};     // { toolName → use_cases[] }
let _blocks        = [];     // ordered array of block objects
let _selected      = null;   // currently selected block id
let _nextId        = 1;
let _showInstalled = false;  // sidebar filter
let _groupFilter   = 'all';
let _advisorPlan   = null;
let _lastFocused   = null;   // last focused input/textarea in editor panel
let _pendingAdvisorRun = false; // re-run advisor after Ollama install
let _scriptTested  = false;  // true once test passes on current canvas
let _scriptPassed  = false;  // last test result
let _edges       = [];          // [{id, fromId, toId, pipe:{type,varName,code}}]
let _pan         = {x:40,y:40}; // canvas world pan offset
let _zoom        = 1.0;          // canvas world zoom level
let _connectMode = false;        // click-to-connect mode active
let _connectFrom = null;         // source block id when connecting
let _nextCol     = 0;            // auto-placement grid column
let _nextRow     = 0;            // auto-placement grid row

// ── Init ──────────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', async () => {
  await Promise.all([loadTools(), loadRepos()]);
  bindEvents();
  bindCanvasPan();

  // Grid toggle — default on
  const canvas = document.getElementById('canvas');
  const chkGrid = document.getElementById('chk-grid');
  if (canvas && chkGrid) {
    chkGrid.addEventListener('change', function() {
      canvas.classList.toggle('grid-on', chkGrid.checked);
      if (chkGrid.checked) {
        _applyWorldTransform();
      } else {
        canvas.style.backgroundSize = '';
        canvas.style.backgroundPosition = '';
      }
    });
  }
});

// ── API helpers ───────────────────────────────────────────────────────────────
async function api(path, opts = {}) {
  const res = await fetch(path, {
    headers: { 'Content-Type': 'application/json' },
    ...opts,
  });
  return res.json();
}

// ── Tool loading ──────────────────────────────────────────────────────────────
async function loadTools() {
  try {
    const data = await api('/api/tools');
    _tools = data.tools || {};
  } catch {
    _tools = {};
  }
  ensureToolFilterControl();
  populateGroupFilter();
  renderSidebar();
}

function ensureToolFilterControl() {
  if (document.getElementById('tool-group-filter')) return;

  const filters = document.querySelector('.tool-filters');
  if (!filters) return;

  const label = document.createElement('label');
  label.className = 'tool-filter-title';
  label.setAttribute('for', 'tool-group-filter');
  label.textContent = 'Type';

  const select = document.createElement('select');
  select.id = 'tool-group-filter';
  select.className = 'tool-group-filter';
  select.innerHTML = '<option value="all">All Types</option>';

  const search = document.getElementById('tool-search');
  if (search) {
    filters.insertBefore(label, search);
    filters.insertBefore(select, search);
  } else {
    filters.appendChild(label);
    filters.appendChild(select);
  }
}

function populateGroupFilter() {
  const el = document.getElementById('tool-group-filter');
  if (!el) return;

  const previous = _groupFilter;
  const groups = Array.from(new Set(
    Object.values(_tools)
      .map(t => t.tool_group || 'Other')
      .filter(Boolean)
  )).sort();

  el.innerHTML = '<option value="all">All Types</option>' +
    groups.map(group => '<option value="' + esc(group) + '">' + esc(group) + '</option>').join('');

  el.value = groups.includes(previous) ? previous : 'all';
  _groupFilter = el.value;
}

async function loadRepos() {
  try {
    const data = await api('/api/repos');
    renderRepos(data.repos || {});
  } catch {
    renderRepos({});
  }
}

// ── Profile loading ───────────────────────────────────────────────────────────
async function fetchProfile(toolName) {
  if (!toolName) return [];
  if (_profileCache[toolName] !== undefined) return _profileCache[toolName];
  try {
    const data = await api('/api/tool/profile/' + encodeURIComponent(toolName));
    _profileCache[toolName] = data.use_cases || [];
  } catch {
    _profileCache[toolName] = [];
  }
  return _profileCache[toolName];
}

// ── Sidebar rendering ─────────────────────────────────────────────────────────
function renderSidebar() {
  const search  = document.getElementById('tool-search').value.toLowerCase();
  const listEl  = document.getElementById('tool-list');
  listEl.innerHTML = '';

  let visible = Object.values(_tools).filter(t => {
    if (_showInstalled && !t.installed) return false;
    if (_groupFilter !== 'all' && (t.tool_group || 'Other') !== _groupFilter) return false;
    if (search) {
      const haystack = (t.name + ' ' + (t.tags || []).join(' ') + ' ' + t.description + ' ' + (t.tool_group || '')).toLowerCase();
      if (!haystack.includes(search)) return false;
    }
    return true;
  });

  // Group by YAML tool group/category
  const groups = {};
  for (const t of visible) {
    const cat = t.tool_group || 'Other';
    (groups[cat] = groups[cat] || []).push(t);
  }

  const sorted = Object.keys(groups).sort();

  if (sorted.length === 0) {
    listEl.innerHTML = '<div style="padding:12px;color:var(--text-muted);font-size:12px;">No tools found.</div>';
    return;
  }

  for (const cat of sorted) {
    const label = document.createElement('div');
    label.className = 'tool-category-label';
    label.textContent = cat;
    listEl.appendChild(label);

    for (const t of groups[cat].sort((a, b) => a.name.localeCompare(b.name))) {
      listEl.appendChild(makeToolItem(t));
    }
  }
}

function makeToolItem(t) {
  const el = document.createElement('div');
  el.className = 'tool-item ' + (t.installed ? 'installed' : 'uninstalled');
  el.dataset.name = t.name;

  const badge = t.has_profile
    ? '<span class="tool-profile-badge" title="Auto-command generation available">&#10022;</span>'
    : '';

  el.innerHTML =
    '<div class="tool-dot"></div>' +
    '<div style="flex:1;min-width:0;">' +
      '<div class="tool-name">' + esc(t.name) + badge + '</div>' +
      '<div class="tool-meta-row">' +
        '<span class="tool-group-pill">' + esc(t.tool_group || 'Other') + '</span>' +
        '<span class="tool-tags">' + esc((t.tags || []).slice(0, 3).join(' \xB7 ')) + '</span>' +
      '</div>' +
      '<div class="tool-desc">' + esc(shortText(t.description || '', 84)) + '</div>' +
    '</div>';

  el.addEventListener('click', () => addToolBlock(t));
  return el;
}

function renderRepos(repos) {
  const el = document.getElementById('repo-list');
  el.innerHTML = '';
  const entries = Object.entries(repos);
  if (!entries.length) {
    el.innerHTML = '<div style="font-size:11px;color:var(--text-muted);padding:4px 4px 0;">No repos cloned yet.</div>';
    return;
  }
  for (const [name, meta] of entries) {
    const div = document.createElement('div');
    div.className = 'repo-item';
    const riskClass = 'risk-' + (meta.risk || 'INFO');
    div.innerHTML =
      '<div class="repo-item-name">' + esc(name) + '</div>' +
      '<div class="repo-item-meta">' +
        '<span class="' + riskClass + '">' + esc(meta.risk || 'INFO') + '</span>' +
        ' \xB7 ' + (meta.findings || 0) + ' finding(s)' +
        (meta.exists ? '' : ' \xB7 <span style="color:var(--red)">missing</span>') +
      '</div>';
    el.appendChild(div);
  }
}

function shortText(text, maxLen) {
  text = String(text || '');
  return text.length > maxLen ? text.slice(0, maxLen - 1) + '\u2026' : text;
}

// ── Block factory ─────────────────────────────────────────────────────────────
function makeBlock(type, defaults) {
  defaults = defaults || {};
  const id = 'blk-' + (_nextId++);
  // Auto-place on a 3-column grid; caller can override via defaults.x/y
  const col = _nextCol, row = _nextRow;
  _nextCol++; if (_nextCol >= 3) { _nextCol = 0; _nextRow++; }
  const base = {
    id: id, type: type,
    x: 80 + col * 240,
    y: 80 + row * 160,
  };
  const templates = {
    tool:    { tool: '', args: '', use_case: '', _params: {}, capture: false, output_var: '' },
    raw:     { code: '' },
    comment: { text: '' },
    var:     { name: '', value: '' },
    if:      { condition: '[ $? -eq 0 ]', then: 'echo "success"', else: '' },
    for:     { var: 'item', in: '"$@"', do: 'echo "$item"' },
    python:  { code: 'print("hello from Python")', capture: false, output_var: '' },
  };
  return Object.assign(base, templates[type] || {}, defaults);
}

function addToolBlock(t) {
  const blk = makeBlock('tool', { tool: t.name, _desc: t.description });
  pushBlock(blk);
}

function addBlock(type) {
  pushBlock(makeBlock(type));
}

function pushBlock(blk) {
  _blocks.push(blk);
  renderCanvas();
  selectBlock(blk.id);
  updateEmpty();
}

// ── Canvas rendering ──────────────────────────────────────────────────────────
function renderCanvas() {
  const world = document.getElementById('canvas-world');
  if (!world) return;
  world.querySelectorAll('.block').forEach(function(e) { e.remove(); });
  renderEdges();
  for (const blk of _blocks) {
    const el = makeBlockEl(blk);
    el.style.left = blk.x + 'px';
    el.style.top  = blk.y + 'px';
    world.appendChild(el);
  }
  updateEmpty();
}

function updateEmpty() {
  const empty = document.getElementById('canvas-empty');
  if (empty) empty.style.display = _blocks.length ? 'none' : '';
}

function makeBlockEl(blk) {
  const el = document.createElement('div');
  el.className = 'block block-type-' + blk.type;
  el.dataset.id = blk.id;
  if (_selected   === blk.id) el.classList.add('selected');
  if (_connectFrom === blk.id) el.classList.add('connect-source');

  el.innerHTML =
    '<div class="block-handle"></div>' +
    '<div class="block-inner">' +
      '<div style="flex:1;min-width:0;">' +
        '<div class="block-label">' + blockTypeLabel(blk) + '</div>' +
        '<div class="block-preview">' + blockPreview(blk) + '</div>' +
      '</div>' +
      '<div class="block-actions">' +
        '<button class="block-btn danger" data-action="del" title="Remove">\u2715</button>' +
      '</div>' +
    '</div>';

  // Mouse drag + select (replaces HTML5 drag API)
  el.addEventListener('mousedown', function(e) {
    if (e.target.closest('.block-btn, textarea, input, select, button')) return;

    if (_connectMode) {
      e.preventDefault(); e.stopPropagation();
      handleConnectClick(blk.id);
      return;
    }

    selectBlock(blk.id);
    e.preventDefault(); e.stopPropagation();

    const startX = e.clientX / _zoom - blk.x;
    const startY = e.clientY / _zoom - blk.y;
    el.classList.add('dragging');
    el.style.zIndex = 50;

    function onMove(ev) {
      blk.x = ev.clientX / _zoom - startX;
      blk.y = ev.clientY / _zoom - startY;
      el.style.left = blk.x + 'px';
      el.style.top  = blk.y + 'px';
      renderEdges();
    }
    function onUp() {
      el.classList.remove('dragging');
      el.style.zIndex = '';
      document.removeEventListener('mousemove', onMove);
      document.removeEventListener('mouseup',   onUp);
    }
    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup',   onUp);
  });

  el.querySelectorAll('.block-btn').forEach(function(btn) {
    btn.addEventListener('click', function(e) {
      e.stopPropagation();
      if (btn.dataset.action === 'del') {
        const idx = _blocks.findIndex(function(b) { return b.id === blk.id; });
        if (idx >= 0) _blocks.splice(idx, 1);
        _edges = _edges.filter(function(ed) { return ed.fromId !== blk.id && ed.toId !== blk.id; });
        if (_selected === blk.id) { _selected = null; renderEditor(null); }
        renderCanvas();
      }
    });
  });

  return el;
}

// ── Edge / connection rendering ───────────────────────────────────────────────
function renderEdges() {
  const svg = document.getElementById('canvas-svg');
  if (!svg) return;
  svg.innerHTML =
    '<defs>' +
      '<marker id="mk-arrow" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">' +
        '<polygon points="0 0,10 3.5,0 7" fill="var(--accent)" />' +
      '</marker>' +
    '</defs>';

  _edges.forEach(function(edge) {
    const from = _blocks.find(function(b) { return b.id === edge.fromId; });
    const to   = _blocks.find(function(b) { return b.id === edge.toId; });
    if (!from || !to) return;

    // Use actual DOM dimensions for edge anchors
    const fromEl = document.querySelector('.block[data-id="' + edge.fromId + '"]');
    const toEl   = document.querySelector('.block[data-id="' + edge.toId   + '"]');
    const fw = fromEl ? fromEl.offsetWidth  : 140;
    const fh = fromEl ? fromEl.offsetHeight : 36;
    const th = toEl   ? toEl.offsetHeight   : 36;
    const fx = from.x + fw, fy = from.y + fh / 2;
    const tx = to.x,        ty = to.y   + th / 2;
    const dx = Math.abs(tx - fx);
    const d  = 'M ' + fx + ' ' + fy +
               ' C ' + (fx + dx * 0.5) + ' ' + fy + ',' +
                       (tx - dx * 0.5) + ' ' + ty + ',' +
                        tx + ' ' + ty;

    // Fat transparent hit-path for click-to-delete
    const hit = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    hit.setAttribute('d', d);
    hit.setAttribute('stroke', 'rgba(0,0,0,0)');
    hit.setAttribute('stroke-width', '16');
    hit.setAttribute('fill', 'none');
    hit.style.cursor = 'pointer';
    hit.style.pointerEvents = 'stroke';
    (function(eid) {
      hit.addEventListener('click', function(ev) {
        ev.stopPropagation();
        _edges = _edges.filter(function(e) { return e.id !== eid; });
        renderEdges();
      });
    })(edge.id);

    // Visible path
    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', d);
    path.setAttribute('stroke', 'var(--accent)');
    path.setAttribute('stroke-width', '2');
    path.setAttribute('fill', 'none');
    path.setAttribute('marker-end', 'url(#mk-arrow)');
    path.style.pointerEvents = 'none';

    svg.appendChild(path);
    svg.appendChild(hit);
  });
}

function handleConnectClick(blockId) {
  if (!_connectFrom) {
    _connectFrom = blockId;
    renderCanvas();
    const hint = document.getElementById('connect-mode-hint');
    if (hint) hint.textContent = 'Source selected — now click the target block (Esc to cancel)';
  } else {
    const fromId = _connectFrom;
    _connectFrom = null;
    if (blockId !== fromId) {
      const dup = _edges.some(function(e) { return e.fromId === fromId && e.toId === blockId; });
      if (!dup) {
        const edge = {
          id: 'edge-' + (_nextId++),
          fromId: fromId,
          toId: blockId,
          pipe: { type: 'pipe', varName: '', code: '' }
        };
        edge.pipe.code = _defaultEdgeCode(edge);
        _edges.push(edge);
        renderCanvas();
        openEdgeModal(edge.id);
      }
    }
    const hint = document.getElementById('connect-mode-hint');
    if (hint) hint.textContent = 'Click a source block, then a target block';
    renderCanvas();
  }
}

// ── Edge modal ────────────────────────────────────────────────────────────────
function _blockLabel(id) {
  const b = _blocks.find(function(b) { return b.id === id; });
  if (!b) return id;
  if (b.type === 'tool') return b.tool || 'tool';
  if (b.type === 'var')  return b.name || 'var';
  return b.type;
}

function _defaultEdgeCode(edge) {
  const p = edge.pipe;
  const fromLabel = _blockLabel(edge.fromId);
  switch (p.type) {
    case 'pipe':
      return '# pipe: stdout of "' + fromLabel + '" feeds into next block stdin\n';
    case 'var': {
      const v = p.varName || 'OUTPUT';
      return v + '=$(# captured output from "' + fromLabel + '")\n';
    }
    case 'conditional':
      return '# conditional: only continue if "' + fromLabel + '" exits 0\n' +
             '[ $? -eq 0 ] || { echo "Skipping next step"; exit 1; }\n';
    case 'custom':
      return '# custom bridge between "' + fromLabel + '" and next block\n';
    default:
      return '';
  }
}

function _edgeDesc(type, varName) {
  switch (type) {
    case 'pipe':
      return 'Stdout from the source block is piped into the stdin of the destination block.';
    case 'var':
      return 'Output from the source block is captured into $' + (varName || 'OUTPUT') + ' and made available to the destination block.';
    case 'conditional':
      return 'The destination block only runs if the source block exits with code 0 (success).';
    case 'custom':
      return 'Custom bash code is injected between the two blocks. Write any logic you need.';
    default:
      return '';
  }
}

function openEdgeModal(edgeId) {
  const edge = _edges.find(function(e) { return e.id === edgeId; });
  if (!edge) return;
  if (!edge.pipe) edge.pipe = { type: 'pipe', name: '', notes: '', varName: '', code: '' };

  const fromLabel = _blockLabel(edge.fromId);
  const toLabel   = _blockLabel(edge.toId);

  document.getElementById('edge-modal-title').textContent = 'Connection: ' + fromLabel + ' → ' + toLabel;
  document.getElementById('edge-flow-label').textContent   = '"' + fromLabel + '"  →  "' + toLabel + '"';

  const typeSelect = document.getElementById('edge-type-select');
  const varGroup   = document.getElementById('edge-var-group');
  const varInput   = document.getElementById('edge-var-name');
  const codeArea   = document.getElementById('edge-code');
  const descEl     = document.getElementById('edge-desc');
  const nameInput  = document.getElementById('edge-name');
  const notesArea  = document.getElementById('edge-notes');

  typeSelect.value = edge.pipe.type    || 'pipe';
  varInput.value   = edge.pipe.varName || '';
  codeArea.value   = edge.pipe.code    || _defaultEdgeCode(edge);
  nameInput.value  = edge.pipe.name    || '';
  notesArea.value  = edge.pipe.notes   || '';
  descEl.textContent = _edgeDesc(typeSelect.value, varInput.value);
  varGroup.style.display = typeSelect.value === 'var' ? '' : 'none';

  function onTypeChange() {
    const t = typeSelect.value;
    varGroup.style.display = t === 'var' ? '' : 'none';
    edge.pipe.type = t;
    codeArea.value = _defaultEdgeCode(edge);
    descEl.textContent = _edgeDesc(t, varInput.value);
  }
  function onVarChange() {
    edge.pipe.varName = varInput.value;
    codeArea.value = _defaultEdgeCode(edge);
    descEl.textContent = _edgeDesc(typeSelect.value, varInput.value);
  }

  typeSelect.onchange = onTypeChange;
  varInput.oninput    = onVarChange;

  document.getElementById('btn-edge-save').onclick = function() {
    edge.pipe.type    = typeSelect.value;
    edge.pipe.varName = varInput.value;
    edge.pipe.code    = codeArea.value;
    edge.pipe.name    = nameInput.value.trim();
    edge.pipe.notes   = notesArea.value;
    hideModal('modal-edge');
    renderEdges();
  };

  document.getElementById('btn-edge-delete').onclick = function() {
    _edges = _edges.filter(function(e) { return e.id !== edgeId; });
    hideModal('modal-edge');
    renderEdges();
  };

  showModal('modal-edge');
}

function setConnectMode(on) {
  _connectMode = on;
  _connectFrom = null;
  const btn  = document.getElementById('btn-connect-mode');
  const hint = document.getElementById('connect-mode-hint');
  const cv   = document.getElementById('canvas');
  if (btn)  btn.classList.toggle('active', on);
  if (cv)   cv.classList.toggle('connect-mode', on);
  if (hint) {
    hint.textContent = on ? 'Click a source block, then a target block' : '';
    hint.classList.toggle('hidden', !on);
  }
  renderCanvas();
}

function _buildTopoOrder() {
  if (!_edges.length) return _blocks.slice();
  const inDeg = {};
  _blocks.forEach(function(b) { inDeg[b.id] = 0; });
  _edges.forEach(function(e) { if (inDeg[e.toId] !== undefined) inDeg[e.toId]++; });
  const queue = _blocks.filter(function(b) { return inDeg[b.id] === 0; }).map(function(b) { return b.id; });
  const result = [];
  while (queue.length) {
    const id = queue.shift();
    const blk = _blocks.find(function(b) { return b.id === id; });
    if (blk) result.push(blk);
    _edges.filter(function(e) { return e.fromId === id; }).forEach(function(e) {
      if (inDeg[e.toId] !== undefined) { inDeg[e.toId]--; if (inDeg[e.toId] === 0) queue.push(e.toId); }
    });
  }
  _blocks.forEach(function(b) {
    if (!result.find(function(r) { return r.id === b.id; })) result.push(b);
  });
  return result;
}

function blockTypeLabel(blk) {
  if (blk.type !== 'tool') return blk.type;
  return blk.tool ? 'tool \xB7 ' + esc(blk.tool) : 'tool';
}

function blockPreview(blk) {
  const MAX = 80;
  function tr(s) {
    s = String(s || '');
    return esc(s.length > MAX ? s.slice(0, MAX) + '\u2026' : s);
  }
  switch (blk.type) {
    case 'tool': {
      const ucLabel = blk.use_case
        ? '<span style="color:var(--accent);font-size:10px;">[' + esc(blk.use_case) + ']</span> '
        : '';
      return ucLabel + '<b>' + esc(blk.tool || '?') + '</b> ' + tr(blk.args || '');
    }
    case 'raw':     return tr(blk.code || '');
    case 'comment': return '<i style="color:var(--text-muted)"># ' + tr(blk.text || '') + '</i>';
    case 'var':     return esc(blk.name || 'VAR') + '=<span style="color:var(--green)">\'' + tr(blk.value || '') + '\'</span>';
    case 'if':      return 'if ' + tr(blk.condition || '') + '; then \u2026';
    case 'for':     return 'for ' + esc(blk.var || 'x') + ' in ' + tr(blk.in || '') + '; do \u2026';
    case 'python':  return '<span style="color:#f7c948">py</span> ' + tr((blk.code || '').replace(/\n/g, ' '));
    default:        return '';
  }
}

// ── Block selection & editor ──────────────────────────────────────────────────
function selectBlock(id) {
  _selected = id;
  document.querySelectorAll('.block').forEach(function(el) {
    el.classList.toggle('selected', el.dataset.id === id);
  });
  const blk = _blocks.find(function(b) { return b.id === id; });
  renderEditor(blk || null);
}

async function renderEditor(blk) {
  const body = document.getElementById('editor-body');
  const panel = document.getElementById('editor-panel');
  if (!blk) {
    body.innerHTML = '<p class="editor-hint">Click a block to edit its parameters.</p>';
    if (panel) panel.classList.add('hidden');
    return;
  }
  if (panel) panel.classList.remove('hidden');
  if (blk.type === 'tool') {
    await renderToolEditor(body, blk);
  } else if (blk.type === 'python') {
    body.innerHTML = editorFields(blk);
    bindEditorFields(body, blk);
    bindPythonCapture(body, blk);
  } else {
    body.innerHTML = editorFields(blk);
    bindEditorFields(body, blk);
  }
  appendVarPicker(body, blk);
}

function bindPythonCapture(body, blk) {
  const capEl = body.querySelector('#py-capture-check');
  const grpEl = body.querySelector('#py-outvar-group');
  if (!capEl || !grpEl) return;
  capEl.addEventListener('change', function() {
    blk.capture = capEl.checked;
    grpEl.style.display = blk.capture ? '' : 'none';
  });
}

// ── Variable Picker ───────────────────────────────────────────────────────────
function appendVarPicker(body, currentBlk) {
  // Collect all named var blocks except the one being edited
  const vars = _blocks.filter(function(b) {
    return b.type === 'var' && b.name && b.id !== currentBlk.id;
  });

  const section = document.createElement('div');
  section.className = 'var-picker';

  const title = document.createElement('div');
  title.className = 'var-picker-title';
  title.textContent = 'Canvas Variables';
  section.appendChild(title);

  if (!vars.length) {
    const empty = document.createElement('div');
    empty.className = 'var-picker-empty';
    empty.textContent = 'No variables on canvas yet. Add a Variable block to use them here.';
    section.appendChild(empty);
  } else {
    const chips = document.createElement('div');
    chips.className = 'var-picker-chips';
    for (const v of vars) {
      const chip = document.createElement('button');
      chip.type = 'button';
      chip.className = 'var-picker-chip';
      chip.textContent = '$' + v.name;
      chip.title = v.value ? '= ' + v.value.slice(0, 60) : 'No value set';
      chip.addEventListener('click', function() {
        insertAtCursor('$' + v.name);
      });
      chips.appendChild(chip);
    }
    section.appendChild(chips);
  }

  body.appendChild(section);

  // Track the last focused input/textarea so insertAtCursor knows where to write
  body.querySelectorAll('input[type="text"], textarea').forEach(function(el) {
    el.addEventListener('focus', function() { _lastFocused = el; });
  });
}

function insertAtCursor(text) {
  const el = _lastFocused;
  if (!el) return;
  el.focus();
  const start = typeof el.selectionStart === 'number' ? el.selectionStart : el.value.length;
  const end   = typeof el.selectionEnd   === 'number' ? el.selectionEnd   : el.value.length;
  el.value = el.value.slice(0, start) + text + el.value.slice(end);
  el.selectionStart = el.selectionEnd = start + text.length;
  // Fire input so block state stays in sync
  el.dispatchEvent(new Event('input', { bubbles: true }));
}

// ── Tool block editor (async – fetches profiles) ──────────────────────────────
async function renderToolEditor(body, blk) {
  const toolInfo = _tools[blk.tool] || {};
  const useCases = await fetchProfile(blk.tool);

  // If no explicit selection exists, default to the strongest available use-case.
  if (!blk.use_case && useCases.length > 0) {
    const best = pickStrongestUseCase(useCases);
    blk.use_case = best ? best.id : '';
    if (blk.use_case && !blk.args) {
      blk.args = buildUseCaseExampleArgs(blk.tool, blk.use_case, useCases);
    }
  }

  body.innerHTML = buildToolEditorHTML(blk, toolInfo, useCases);
  bindToolEditorEvents(body, blk, useCases);
  appendVarPicker(body, blk);
}

function buildToolEditorHTML(blk, toolInfo, useCases) {
  const desc        = blk._desc || toolInfo.description || '';
  const hasProfile  = useCases && useCases.length > 0;

  const toolSelect =
    '<div class="ef-group">' +
      '<label class="ef-label">Tool</label>' +
      '<select class="ef-select" id="ef-tool-select">' +
        Object.keys(_tools).sort().map(function(n) {
          return '<option value="' + esc(n) + '"' + (n === blk.tool ? ' selected' : '') + '>' + esc(n) + '</option>';
        }).join('') +
      '</select>' +
    '</div>';

  const descBox = desc ? '<div class="tool-desc-box">' + esc(desc) + '</div>' : '';

  const useCaseSection = hasProfile
    ? '<div class="ef-group">' +
        '<label class="ef-label">Use Case</label>' +
        '<select class="ef-select uc-select" id="ef-usecase-select">' +
          '<option value="">Custom / Manual</option>' +
          useCases.map(function(uc) {
            return '<option value="' + esc(uc.id) + '"' + (blk.use_case === uc.id ? ' selected' : '') + '>' + esc(uc.label) + '</option>';
          }).join('') +
        '</select>' +
      '</div>' +
      '<div id="uc-desc-box" class="uc-desc-box hidden"></div>' +
      '<div id="uc-params-container"></div>'
    : '';

  const argsPlaceholder = hasProfile && blk.use_case
    ? buildUseCaseExampleArgs(blk.tool, blk.use_case, useCases)
    : '-sV -p 1-1000 $TARGET';

  const argsSection =
    '<div class="ef-group">' +
      '<label class="ef-label">' + (hasProfile ? 'Generated Command Arguments' : 'Arguments / Flags') + '</label>' +
      '<input class="ef-input" id="ef-args-input" type="text"' +
             ' value="' + esc(blk.args || '') + '"' +
             ' placeholder="' + esc(argsPlaceholder) + '" />' +
    '</div>' +
    '<div class="ef-group">' +
      '<label class="ef-check-row">' +
        '<input type="checkbox" id="ef-capture-check"' + (blk.capture ? ' checked' : '') + ' />' +
        ' Capture output to variable' +
      '</label>' +
    '</div>' +
    '<div id="ef-output-var-group"' + (blk.capture ? '' : ' style="display:none"') + '>' +
      '<div class="ef-group">' +
        '<label class="ef-label">Output Variable Name</label>' +
        '<input class="ef-input" id="ef-outvar-input" type="text"' +
               ' value="' + esc(blk.output_var || '') + '" placeholder="RESULT" />' +
      '</div>' +
    '</div>';

  const helpSection = buildToolHelpHTML(blk, toolInfo, useCases);
  return toolSelect + descBox + useCaseSection + argsSection + helpSection;
}

function buildToolHelpHTML(blk, toolInfo, useCases) {
  const uc = (useCases || []).find(function(u) { return u.id === blk.use_case; }) || null;
  const group = toolInfo.tool_group || 'Other';
  const tags = (toolInfo.tags || []).slice(0, 6);

  const params = uc && uc.params && uc.params.length
    ? '<div class="tool-help-row"><strong>Required vars:</strong> ' +
      uc.params.map(function(p) { return '$' + esc(p.key || 'VAR'); }).join(', ') +
      '</div>'
    : '<div class="tool-help-row"><strong>Required vars:</strong> none</div>';

  const exampleCmd = blk.tool
    ? '<pre class="tool-help-code">' + esc(blk.tool + (blk.args ? ' ' + blk.args : '')) + '</pre>'
    : '';

  return '<div class="tool-help-box">' +
    '<div class="tool-help-title">How To Use This Tool</div>' +
    '<div class="tool-help-row"><strong>Type:</strong> ' + esc(group) + '</div>' +
    '<div class="tool-help-row"><strong>Installed:</strong> ' + (toolInfo.installed ? 'Yes' : 'No') + '</div>' +
    '<div class="tool-help-row"><strong>Tags:</strong> ' + esc(tags.length ? tags.join(' · ') : 'n/a') + '</div>' +
    (uc ? '<div class="tool-help-row"><strong>Selected use case:</strong> ' + esc(uc.label || uc.id || 'custom') + '</div>' : '<div class="tool-help-row"><strong>Selected use case:</strong> custom/manual</div>') +
    (uc && uc.description ? '<div class="tool-help-row">' + esc(uc.description) + '</div>' : '') +
    params +
    exampleCmd +
    '<div class="tool-help-note">Tip: define variables in blocks above this command so scripts stay reusable and safer.</div>' +
  '</div>';
}

function bindToolEditorEvents(body, blk, useCases) {
  const toolSel = body.querySelector('#ef-tool-select');
  if (toolSel) {
    toolSel.addEventListener('change', async function() {
      blk.tool      = toolSel.value;
      blk.use_case  = '';
      blk._params   = {};
      blk.args      = '';
      blk._desc     = (_tools[blk.tool] || {}).description || '';
      refreshBlockPreview(blk);
      await renderToolEditor(body, blk);
    });
  }

  const ucSel = body.querySelector('#ef-usecase-select');
  if (ucSel) {
    syncUseCaseDesc(body, blk, useCases);
    buildParamInputs(body, blk, useCases);

    ucSel.addEventListener('change', function() {
      blk.use_case = ucSel.value;
      blk._params  = {};
      syncUseCaseDesc(body, blk, useCases);
      buildParamInputs(body, blk, useCases);

      // On use-case switch, set args to best-practice example for that choice.
      const suggested = buildUseCaseExampleArgs(blk.tool, blk.use_case, useCases);
      blk.args = suggested;
      const argsInput = body.querySelector('#ef-args-input');
      if (argsInput) {
        argsInput.value = suggested;
        argsInput.placeholder = suggested || '-sV -p 1-1000 $TARGET';
      }

      refreshBlockPreview(blk);
    });
  }

  const argsInput = body.querySelector('#ef-args-input');
  if (argsInput) {
    argsInput.addEventListener('input', function() {
      blk.args = argsInput.value;
      refreshBlockPreview(blk);
    });
  }

  const capCheck = body.querySelector('#ef-capture-check');
  if (capCheck) {
    capCheck.addEventListener('change', function() {
      blk.capture = capCheck.checked;
      const grp = body.querySelector('#ef-output-var-group');
      if (grp) grp.style.display = blk.capture ? '' : 'none';
    });
  }

  const outVar = body.querySelector('#ef-outvar-input');
  if (outVar) {
    outVar.addEventListener('input', function() { blk.output_var = outVar.value; });
  }
}

function syncUseCaseDesc(body, blk, useCases) {
  const descBox = body.querySelector('#uc-desc-box');
  if (!descBox) return;
  const uc = (useCases || []).find(function(u) { return u.id === blk.use_case; });
  if (uc && uc.description) {
    descBox.textContent = uc.description;
    descBox.classList.remove('hidden');
  } else {
    descBox.textContent = '';
    descBox.classList.add('hidden');
  }
}

function buildParamInputs(body, blk, useCases) {
  const container = body.querySelector('#uc-params-container');
  if (!container) return;
  container.innerHTML = '';

  const uc = (useCases || []).find(function(u) { return u.id === blk.use_case; });
  if (!uc || !uc.params || uc.params.length === 0) return;

  const header = document.createElement('div');
  header.className = 'ef-label uc-params-header';
  header.textContent = 'Parameters';
  container.appendChild(header);

  if (!blk._params) blk._params = {};

  for (const param of uc.params) {
    const group = document.createElement('div');
    group.className = 'ef-group';
    const reqMark = param.required ? ' <span class="req-mark">*</span>' : '';
    group.innerHTML =
      '<label class="ef-label">' + esc(param.label) + reqMark + '</label>' +
      '<input class="ef-input ef-param-input" type="text"' +
             ' data-key="' + esc(param.key) + '"' +
             ' value="' + esc(blk._params[param.key] || '') + '"' +
             ' placeholder="' + esc(param.placeholder || '') + '" />';
    container.appendChild(group);

    const input = group.querySelector('.ef-param-input');
    input.addEventListener('input', function() {
      blk._params[param.key] = input.value;
      rebuildArgs(body, blk, useCases);
      refreshBlockPreview(blk);
    });
  }
}

function rebuildArgs(body, blk, useCases) {
  const uc = (useCases || []).find(function(u) { return u.id === blk.use_case; });
  if (!uc) return;

  var cmd = uc.template;
  const params = blk._params || {};
  const ucParams = uc.params || [];

  // Replace placeholders with user values when present, otherwise with
  // per-use-case examples so the args field always shows usable guidance.
  for (const p of ucParams) {
    const key = p.key;
    if (!key) continue;
    const userVal = params[key];
    const fallback = p.placeholder || ('$' + key);
    cmd = cmd.split('{' + key + '}').join(userVal || fallback);
  }

  // Strip the leading binary name from the template to get just the args
  const binary = (_tools[blk.tool] || {}).binary || blk.tool;
  const binaryRe = new RegExp('^(sudo\\s+)?' + escapeRegex(binary) + '\\s*');
  blk.args = cmd.replace(binaryRe, '').trim();

  const argsInput = body.querySelector('#ef-args-input');
  if (argsInput) {
    argsInput.value = blk.args;
    argsInput.placeholder = buildUseCaseExampleArgs(blk.tool, blk.use_case, useCases) || '-sV -p 1-1000 $TARGET';
  }
}

function pickStrongestUseCase(useCases) {
  if (!useCases || !useCases.length) return null;

  const strongTerms = [
    'aggressive', 'full', 'all', 'comprehensive', 'active', 'deep',
    'recursive', 'auto', 'enumerate', 'enum', 'version', 'os',
    'dump', 'brute', 'scan'
  ];

  function score(uc) {
    const text = ((uc.label || '') + ' ' + (uc.description || '') + ' ' + (uc.template || '')).toLowerCase();
    let s = 0;
    for (const term of strongTerms) {
      if (text.includes(term)) s += 3;
    }
    s += Math.min((uc.params || []).length, 4);
    s += Math.min((uc.template || '').split(' ').length, 10) / 2;
    return s;
  }

  return useCases.slice().sort(function(a, b) { return score(b) - score(a); })[0];
}

function buildUseCaseExampleArgs(toolName, useCaseId, useCases) {
  const uc = (useCases || []).find(function(u) { return u.id === useCaseId; });
  if (!uc) return '';

  var cmd = uc.template || '';
  for (const p of (uc.params || [])) {
    const key = p.key;
    if (!key) continue;
    const val = p.placeholder || ('$' + key);
    cmd = cmd.split('{' + key + '}').join(val);
  }

  const binary = (_tools[toolName] || {}).binary || toolName;
  const binaryRe = new RegExp('^(sudo\\s+)?' + escapeRegex(binary) + '\\s*');
  return cmd.replace(binaryRe, '').trim();
}

function escapeRegex(s) {
  return String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function refreshBlockPreview(blk) {
  const el = document.querySelector('.block[data-id="' + blk.id + '"]');
  if (!el) return;
  const labelEl   = el.querySelector('.block-label');
  const previewEl = el.querySelector('.block-preview');
  if (labelEl)   labelEl.innerHTML  = blockTypeLabel(blk);
  if (previewEl) previewEl.innerHTML = blockPreview(blk);
}

// ── Generic editor fields (non-tool blocks) ───────────────────────────────────
function editorFields(blk) {
  switch (blk.type) {

    case 'raw': return (
      '<div class="ef-group">' +
        '<label class="ef-label">Bash Code</label>' +
        '<textarea class="ef-textarea" data-field="code"' +
                  ' placeholder="echo hello world">' + esc(blk.code || '') + '</textarea>' +
      '</div>');

    case 'comment': return (
      '<div class="ef-group">' +
        '<label class="ef-label">Comment Text</label>' +
        '<input class="ef-input" type="text" data-field="text"' +
               ' value="' + esc(blk.text || '') + '" placeholder="Section header\u2026" />' +
      '</div>');

    case 'var': return (
      '<div class="ef-group">' +
        '<label class="ef-label">Variable Name</label>' +
        '<input class="ef-input" type="text" data-field="name"' +
               ' value="' + esc(blk.name || '') + '" placeholder="TARGET" />' +
      '</div>' +
      '<div class="ef-group">' +
        '<label class="ef-label">Value</label>' +
        '<input class="ef-input" type="text" data-field="value"' +
               ' value="' + esc(blk.value || '') + '" placeholder="192.168.1.0/24" />' +
      '</div>');

    case 'if': return (
      '<div class="ef-group">' +
        '<label class="ef-label">Condition</label>' +
        '<input class="ef-input" type="text" data-field="condition"' +
               ' value="' + esc(blk.condition || '') + '" placeholder="[ $? -eq 0 ]" />' +
      '</div>' +
      '<div class="ef-group">' +
        '<label class="ef-label">Then (command)</label>' +
        '<input class="ef-input" type="text" data-field="then"' +
               ' value="' + esc(blk.then || '') + '" placeholder=\'echo "success"\' />' +
      '</div>' +
      '<div class="ef-group">' +
        '<label class="ef-label">Else (optional)</label>' +
        '<input class="ef-input" type="text" data-field="else"' +
               ' value="' + esc(blk.else || '') + '" placeholder=\'echo "failed"\' />' +
      '</div>');

    case 'for': return (
      '<div class="ef-group">' +
        '<label class="ef-label">Loop Variable</label>' +
        '<input class="ef-input" type="text" data-field="var"' +
               ' value="' + esc(blk.var || 'item') + '" placeholder="item" />' +
      '</div>' +
      '<div class="ef-group">' +
        '<label class="ef-label">Iterable (in \u2026)</label>' +
        '<input class="ef-input" type="text" data-field="in"' +
               ' value="' + esc(blk.in || '"$@"') + '" placeholder=\'"$@"\' />' +
      '</div>' +
      '<div class="ef-group">' +
        '<label class="ef-label">Body (do \u2026)</label>' +
        '<textarea class="ef-textarea" data-field="do"' +
                  ' placeholder=\'echo "$item"\'>' + esc(blk.do || '') + '</textarea>' +
      '</div>');

    case 'python': return (
      '<div class="ef-group">' +
        '<label class="ef-label">Python 3 Code</label>' +
        '<textarea class="ef-textarea ef-textarea-python" data-field="code"' +
                  ' placeholder="import sys\nfor line in sys.stdin:\n    print(line.strip())">' +
          esc(blk.code || '') +
        '</textarea>' +
      '</div>' +
      '<div class="ef-group">' +
        '<label class="ef-check-row">' +
          '<input type="checkbox" id="py-capture-check" data-field="capture"' + (blk.capture ? ' checked' : '') + ' />' +
          ' Capture stdout to variable' +
        '</label>' +
      '</div>' +
      '<div id="py-outvar-group"' + (blk.capture ? '' : ' style="display:none"') + '>' +
        '<div class="ef-group">' +
          '<label class="ef-label">Output Variable Name</label>' +
          '<input class="ef-input" type="text" data-field="output_var"' +
                 ' value="' + esc(blk.output_var || '') + '" placeholder="PY_RESULT" />' +
        '</div>' +
      '</div>' +
      '<div class="tool-help-note" style="margin-top:8px;">' +
        'Tip: access bash variables inside Python via <code>os.environ[&quot;VAR&quot;]</code> or pass them as args.' +
      '</div>');

    default: return '<p class="editor-hint">Unknown block type.</p>';
  }
}

function bindEditorFields(body, blk) {
  body.querySelectorAll('[data-field]').forEach(function(input) {
    const field = input.dataset.field;
    const isCheck = input.type === 'checkbox';
    input.addEventListener('input', function() {
      blk[field] = isCheck ? input.checked : input.value;
      refreshBlockPreview(blk);
    });
  });
}

// ── Script generation ─────────────────────────────────────────────────────────
async function buildScript() {
  const name = document.getElementById('script-name').value.trim() || 'my_script';
  const desc = document.getElementById('script-desc').value.trim();
  const payload = {
    name: name,
    description: desc,
    blocks: _buildTopoOrder().map(function(b) {
      const clean = {};
      for (const k of Object.keys(b)) {
        if (!k.startsWith('_')) clean[k] = b[k];
      }
      return clean;
    }),
  };
  return api('/api/script/build', { method: 'POST', body: JSON.stringify(payload) });
}

async function loadHostCommands() {
  const listEl = document.getElementById('host-command-list');
  if (!listEl) return;

  listEl.innerHTML = '<div class="host-command-empty">Loading…</div>';
  try {
    const res = await api('/api/script/commands');
    if (!res.ok) {
      listEl.innerHTML = '<div class="host-command-empty">Unable to load command links.</div>';
      return;
    }

    const entries = Object.entries(res.commands || {});
    if (!entries.length) {
      listEl.innerHTML = '<div class="host-command-empty">No host commands linked yet.</div>';
      return;
    }

    listEl.innerHTML = entries.map(function(pair) {
      const cmd = pair[0];
      const meta = pair[1] || {};
      return '<div class="host-command-item">' +
        '<div class="host-command-main">' +
          '<div class="host-command-name">' + esc(cmd) + '</div>' +
          '<div class="host-command-meta">' + esc(meta.bin_path || '') + '</div>' +
        '</div>' +
        '<button class="btn btn-ghost host-command-remove" data-cmd="' + esc(cmd) + '">Remove</button>' +
      '</div>';
    }).join('');
  } catch (e) {
    listEl.innerHTML = '<div class="host-command-empty">Error loading command links.</div>';
  }
}

async function exportWithOptions() {
  if (!_blocks.length) { alert('Canvas is empty.'); return; }

  const exportNameEl = document.getElementById('export-name');
  const installCmdEl = document.getElementById('export-install-command');
  const commandNameEl = document.getElementById('export-command-name');

  const res = await buildScript();
  if (!res.ok) {
    showStatus('export-status', 'Build error: ' + (res.error || 'unknown'), 'err');
    return;
  }

  const exportName = (exportNameEl.value || res.name || 'script').trim();
  const installCommand = !!installCmdEl.checked;
  const commandName = (commandNameEl.value || exportName || 'script').trim();

  // Always download exported script in browser.
  const blob = new Blob([res.script], { type: 'text/x-shellscript' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = exportName + '.sh';
  a.click();
  URL.revokeObjectURL(a.href);

  if (!installCommand) {
    showStatus('export-status', 'Exported .sh file. Host command not installed.', 'ok');
    return;
  }

  const installRes = await api('/api/script/command/install', {
    method: 'POST',
    body: JSON.stringify({
      name: exportName,
      command_name: commandName,
      script: res.script,
      replace: true,
    }),
  });

  if (installRes.ok) {
    showStatus('export-status', 'Exported and installed command: ' + installRes.command, 'ok');
    await loadHostCommands();
  } else {
    const manual = installRes.manual_install ? (' Manual: ' + installRes.manual_install) : '';
    showStatus('export-status', 'Exported file, but command install failed: ' + (installRes.error || 'unknown') + manual, 'err');
  }
}

async function removeHostCommand(commandName) {
  const res = await api('/api/script/command/remove', {
    method: 'POST',
    body: JSON.stringify({ command_name: commandName }),
  });

  if (res.ok) {
    showStatus('export-status', 'Removed command: ' + commandName, 'ok');
    await loadHostCommands();
  } else {
    const manual = res.manual_remove ? (' Manual: ' + res.manual_remove) : '';
    showStatus('export-status', 'Remove failed: ' + (res.error || 'unknown') + manual, 'err');
  }
}

async function runAdvisor() {
  const promptEl = document.getElementById('advisor-prompt');
  const installedOnlyEl = document.getElementById('advisor-installed-only');
  const statusEl = document.getElementById('advisor-status');
  const resultsEl = document.getElementById('advisor-results');
  const applyBtn = document.getElementById('btn-advisor-apply');
  const modeEl = document.getElementById('advisor-mode');
  const modelEl = document.getElementById('advisor-model');

  const prompt = (promptEl.value || '').trim();
  if (!prompt) {
    showStatus('advisor-status', 'Enter a script goal first.', 'err');
    return;
  }

  statusEl.textContent = 'Generating local suggestions…';
  statusEl.className = 'save-status';
  resultsEl.innerHTML = '';
  applyBtn.disabled = true;
  _advisorPlan = null;

  try {
    const res = await api('/api/advisor/plan', {
      method: 'POST',
      body: JSON.stringify({
        prompt: prompt,
        installed_only: !!installedOnlyEl.checked,
        mode: (modeEl && modeEl.value) || 'auto',
        model: (modelEl && modelEl.value.trim()) || 'llama3.1:8b',
      }),
    });

    if (!res.ok) {
      showStatus('advisor-status', 'Advisor failed: ' + (res.error || 'unknown error'), 'err');
      return;
    }

    _advisorPlan = res;
    renderAdvisorResults(res);

    // If user wanted LLM but got heuristic fallback, offer to install Ollama
    const modeWanted = (modeEl && modeEl.value) || 'auto';
    if ((modeWanted === 'llm' || modeWanted === 'auto') && res.planner === 'heuristic') {
      try {
        const status = await api('/api/ollama/status');
        if (!status.installed) {
          _pendingAdvisorRun = true;
          showModal('modal-ollama');
        }
      } catch (_) { /* ignore */ }
    }

    showStatus('advisor-status', 'Suggestions ready.', 'ok');
    applyBtn.disabled = !(res.blocks && res.blocks.length);
  } catch (err) {
    showStatus('advisor-status', 'Advisor request failed: ' + err, 'err');
  }
}

function renderAdvisorResults(plan) {
  const resultsEl = document.getElementById('advisor-results');
  if (!resultsEl) return;

  const suggestions = plan.suggestions || [];
  const notes = plan.notes || [];
  const blocks = plan.blocks || [];

  if (!suggestions.length) {
    resultsEl.innerHTML = '<div class="advisor-empty">No strong matches yet. Try naming the target type, scan goal, or protocol.</div>';
    return;
  }

  resultsEl.innerHTML =
    (plan.planner ? '<div class="advisor-plan-meta">Planner: ' + esc(plan.planner) + (plan.model ? ' · model: ' + esc(plan.model) : '') + '</div>' : '') +
    '<div class="advisor-section-title">Suggested Tools</div>' +
    suggestions.map(function(item) {
      const useCase = item.use_case || {};
      return '<div class="advisor-card">' +
        '<div class="advisor-card-head">' +
          '<div>' +
            '<div class="advisor-tool-name">' + esc(item.tool) + '</div>' +
            '<div class="advisor-tool-group">' + esc(item.group || 'Other') + '</div>' +
          '</div>' +
          '<div class="advisor-installed-pill ' + (item.installed ? 'ok' : 'warn') + '">' + (item.installed ? 'installed' : 'not installed') + '</div>' +
        '</div>' +
        '<div class="advisor-tool-desc">' + esc(item.description || '') + '</div>' +
        (useCase.label ? '<div class="advisor-use-case"><strong>Use case:</strong> ' + esc(useCase.label) + '</div>' : '') +
        (useCase.description ? '<div class="advisor-use-desc">' + esc(useCase.description) + '</div>' : '') +
        (item.args_preview ? '<pre class="advisor-code">' + esc(item.tool + ' ' + item.args_preview) + '</pre>' : '') +
        '<div class="advisor-why">' + esc(item.why || '') + '</div>' +
      '</div>';
    }).join('') +
    '<div class="advisor-section-title">Starter Block Plan</div>' +
    '<div class="advisor-plan-count">' + blocks.length + ' block(s) ready to apply to the canvas.</div>' +
    (notes.length ? '<div class="advisor-notes">' + notes.map(n => '<div>' + esc(n) + '</div>').join('') + '</div>' : '');
}

function applyAdvisorPlan() {
  if (!_advisorPlan || !_advisorPlan.blocks || !_advisorPlan.blocks.length) return;

  const applyModeEl = document.getElementById('advisor-apply-mode');
  const applyMode = applyModeEl ? applyModeEl.value : 'append';

  if (applyMode === 'replace') {
    _blocks = [];
    _edges  = [];
    _nextCol = 0; _nextRow = 0;
    _selected = null;
  }

  const blocks = _advisorPlan.blocks.map(function(block) {
    if (block.type === 'tool') {
      const toolMeta = _tools[block.tool] || {};
      return makeBlock('tool', {
        tool: block.tool || '',
        args: block.args || '',
        use_case: block.use_case || '',
        capture: !!block.capture,
        output_var: block.output_var || '',
        _desc: toolMeta.description || '',
      });
    }
    return makeBlock(block.type, block);
  });

  Array.prototype.push.apply(_blocks, blocks);
  renderCanvas();
  updateEmpty();
  if (blocks.length) {
    selectBlock(blocks[blocks.length - 1].id);
  }
  hideModal('modal-advisor');
}

// ── Event binding ─────────────────────────────────────────────────────────────
function bindEvents() {
  const installedOnlyEl = document.getElementById('chk-installed-only');
  if (installedOnlyEl) {
    installedOnlyEl.addEventListener('change', function(e) {
      _showInstalled = e.target.checked;
      renderSidebar();
    });
  }

  const groupFilterEl = document.getElementById('tool-group-filter');
  if (groupFilterEl) {
    groupFilterEl.addEventListener('change', function(e) {
      _groupFilter = e.target.value;
      renderSidebar();
    });
  }

  const searchEl = document.getElementById('tool-search');
  if (searchEl) {
    searchEl.addEventListener('input', renderSidebar);
  }

  document.querySelectorAll('.block-chip').forEach(function(btn) {
    btn.addEventListener('click', function() { addBlock(btn.dataset.type); });
  });

  document.getElementById('btn-clear').addEventListener('click', function() {
    if (_blocks.length && !confirm('Clear all blocks?')) return;
    _blocks = []; _edges = []; _nextCol = 0; _nextRow = 0;
    _selected = null;
    renderCanvas();
    renderEditor(null);
  });

  document.getElementById('btn-preview').addEventListener('click', async function() {
    if (!_blocks.length) { alert('Canvas is empty \u2013 add some blocks first.'); return; }
    const res = await buildScript();
    if (!res.ok) { alert('Build error: ' + (res.error || 'unknown')); return; }
    document.getElementById('preview-code').textContent = res.script;
    showModal('modal-preview');
  });

  document.getElementById('btn-copy-preview').addEventListener('click', function() {
    const text = document.getElementById('preview-code').textContent;
    navigator.clipboard.writeText(text).then(function() {
      const btn = document.getElementById('btn-copy-preview');
      btn.textContent = 'Copied!';
      setTimeout(function() { btn.textContent = 'Copy'; }, 1500);
    });
  });

  document.getElementById('btn-save').addEventListener('click', function() {
    document.getElementById('save-name').value =
      document.getElementById('script-name').value.trim() || 'my_script';
    document.getElementById('save-status').textContent = '';
    document.getElementById('save-status').className = 'save-status';
    showModal('modal-save');
  });

  document.getElementById('btn-save-confirm').addEventListener('click', async function() {
    const res = await buildScript();
    if (!res.ok) {
      showStatus('save-status', 'Build failed: ' + (res.error || ''), 'err');
      return;
    }
    const name = document.getElementById('save-name').value.trim() || 'script';
    const saveRes = await api('/api/script/save', {
      method: 'POST',
      body: JSON.stringify({ name: name, script: res.script }),
    });
    if (saveRes.ok) {
      showStatus('save-status', 'Saved to ' + saveRes.path, 'ok');
    } else {
      showStatus('save-status', 'Save failed: ' + (saveRes.error || ''), 'err');
    }
  });

  document.getElementById('btn-test').addEventListener('click', async function() {
    if (!_blocks.length) { alert('Canvas is empty — nothing to test.'); return; }
    const btn = document.getElementById('btn-test');
    btn.disabled = true;
    btn.textContent = 'Testing…';
    try {
      const built = await buildScript();
      if (!built.ok) { alert('Build error: ' + (built.error || 'unknown')); return; }
      const res = await api('/api/script/test', {
        method: 'POST',
        body: JSON.stringify({ script: built.script }),
      });
      _scriptTested = true;
      _scriptPassed = !!(res.passed);
      renderScriptTestResults(res);
      showModal('modal-test');
    } catch (e) {
      alert('Test request failed: ' + e);
    } finally {
      btn.disabled = false;
      btn.textContent = 'Test';
    }
  });

  document.getElementById('btn-export').addEventListener('click', async function() {
    if (!_blocks.length) { alert('Canvas is empty.'); return; }
    const scriptName = document.getElementById('script-name').value.trim() || 'my_script';
    document.getElementById('export-name').value = scriptName;
    document.getElementById('export-command-name').value = scriptName;
    document.getElementById('export-install-command').checked = false;
    document.getElementById('export-command-fields').classList.add('hidden');
    document.getElementById('export-status').textContent = '';
    document.getElementById('export-status').className = 'save-status';
    // Show test gate banner
    const banner = document.getElementById('export-test-banner');
    if (banner) {
      if (!_scriptTested) {
        banner.className = 'export-test-banner warn';
        banner.textContent = '⚠ Script has not been tested. Run “Test” before exporting for safety.';
      } else if (!_scriptPassed) {
        banner.className = 'export-test-banner err';
        banner.textContent = '✘ Last test found errors. Review the Test results before exporting.';
      } else {
        banner.className = 'export-test-banner ok';
        banner.textContent = '✔ Test passed — script looks good.';
      }
    }
    await loadHostCommands();
    showModal('modal-export');
  });

  document.getElementById('export-install-command').addEventListener('change', function(e) {
    document.getElementById('export-command-fields').classList.toggle('hidden', !e.target.checked);
  });

  document.getElementById('btn-export-confirm').addEventListener('click', exportWithOptions);

  document.getElementById('host-command-list').addEventListener('click', async function(e) {
    const btn = e.target.closest('.host-command-remove');
    if (!btn) return;
    const cmd = btn.dataset.cmd;
    if (!cmd) return;
    if (!confirm('Remove command from host path: ' + cmd + '?')) return;
    await removeHostCommand(cmd);
  });

  document.getElementById('btn-gitclone').addEventListener('click', function() {
    document.getElementById('clone-url').value = '';
    const out = document.getElementById('clone-output');
    out.textContent = '';
    out.classList.add('hidden');
    const tr = document.getElementById('repo-test-results');
    if (tr) { tr.innerHTML = ''; tr.classList.add('hidden'); }
    const rb = document.getElementById('repo-risk-banner');
    if (rb) rb.classList.add('hidden');
    showModal('modal-gitclone');
  });

  document.getElementById('btn-advisor').addEventListener('click', function() {
    document.getElementById('advisor-status').textContent = '';
    document.getElementById('advisor-status').className = 'save-status';
    document.getElementById('advisor-results').innerHTML = '';
    document.getElementById('advisor-apply-mode').value = 'append';
    document.getElementById('advisor-mode').value = 'auto';
    document.getElementById('btn-advisor-apply').disabled = true;
    showModal('modal-advisor');
  });

  document.getElementById('btn-advisor-run').addEventListener('click', runAdvisor);
  document.getElementById('btn-advisor-apply').addEventListener('click', applyAdvisorPlan);

  document.getElementById('btn-clone-confirm').addEventListener('click', async function() {
    const url = document.getElementById('clone-url').value.trim();
    if (!url) { alert('Enter a GitHub URL.'); return; }

    const btn = document.getElementById('btn-clone-confirm');
    btn.disabled = true;
    btn.textContent = 'Cloning\u2026';

    const out = document.getElementById('clone-output');
    out.textContent = 'Running security scan and cloning\u2026\n';
    out.classList.remove('hidden');

    const tr = document.getElementById('repo-test-results');
    if (tr) { tr.innerHTML = ''; tr.classList.add('hidden'); }
    const rb = document.getElementById('repo-risk-banner');
    if (rb) rb.classList.add('hidden');

    let cloneOk = false;
    let repoName = '';

    try {
      const res = await api('/api/gitclone', {
        method: 'POST',
        body: JSON.stringify({ url: url }),
      });
      out.textContent += res.output || '';
      if (res.ok) {
        cloneOk = true;
        repoName = url.replace(/\.git$/, '').split('/').slice(-2).join('/');
        out.textContent += '\nClone complete. Running script validation\u2026';
        loadRepos();
      } else {
        out.textContent += '\nClone failed.';
      }
    } catch (e) {
      out.textContent += '\nERROR: ' + e;
    } finally {
      btn.disabled = false;
      btn.textContent = 'Clone & Scan';
    }

    if (cloneOk && repoName) {
      btn.disabled = true;
      btn.textContent = 'Testing\u2026';
      try {
        await runRepoTest(repoName);
      } finally {
        btn.disabled = false;
        btn.textContent = 'Clone & Scan';
      }
    }
  });

  const continuBtn = document.getElementById('btn-repo-continue');
  if (continuBtn) {
    continuBtn.addEventListener('click', function() {
      document.getElementById('repo-risk-banner').classList.add('hidden');
    });
  }

  const ollamaInstallBtn = document.getElementById('btn-ollama-install');
  if (ollamaInstallBtn) {
    ollamaInstallBtn.addEventListener('click', async function() {
      const out = document.getElementById('ollama-install-output');
      const note = document.getElementById('ollama-install-note');
      const cancelBtn = document.getElementById('btn-ollama-cancel');
      ollamaInstallBtn.disabled = true;
      ollamaInstallBtn.textContent = 'Installing\u2026';
      cancelBtn.disabled = true;
      out.textContent = '';
      out.classList.remove('hidden');
      note.classList.add('hidden');

      let success = false;
      try {
        const evtSource = new EventSource('/api/ollama/install');
        await new Promise(function(resolve) {
          evtSource.onmessage = function(e) {
            out.textContent += e.data + '\n';
            out.scrollTop = out.scrollHeight;
          };
          evtSource.addEventListener('done', function(e) {
            success = e.data === 'ok';
            evtSource.close();
            resolve();
          });
          evtSource.onerror = function() {
            out.textContent += '\nConnection lost.\n';
            evtSource.close();
            resolve();
          };
        });
      } catch (e) {
        out.textContent += '\nERROR: ' + e + '\n';
      }

      ollamaInstallBtn.disabled = false;
      cancelBtn.disabled = false;

      if (success) {
        ollamaInstallBtn.textContent = 'Installed \u2714';
        ollamaInstallBtn.disabled = true;
        note.classList.remove('hidden');
        if (_pendingAdvisorRun) {
          _pendingAdvisorRun = false;
          setTimeout(function() {
            hideModal('modal-ollama');
            runAdvisor();
          }, 1500);
        }
      } else {
        ollamaInstallBtn.textContent = 'Retry';
      }
    });
  }

  const connectModeBtn = document.getElementById('btn-connect-mode');
  if (connectModeBtn) {
    connectModeBtn.addEventListener('click', function() { setConnectMode(!_connectMode); });
  }
  const resetPanBtn = document.getElementById('btn-reset-pan');
  if (resetPanBtn) {
    resetPanBtn.addEventListener('click', function() {
      _pan.x = 40; _pan.y = 40; _zoom = 1.0;
      _applyWorldTransform();
    });
  }

  document.querySelectorAll('[data-close]').forEach(function(btn) {
    btn.addEventListener('click', function() { hideModal(btn.dataset.close); });
  });
  document.querySelectorAll('.modal-overlay').forEach(function(overlay) {
    overlay.addEventListener('click', function(e) {
      if (e.target === overlay) hideModal(overlay.id);
    });
  });
}

// ── Repo test flow ────────────────────────────────────────────────────────────
async function runRepoTest(repoName) {
  const tr = document.getElementById('repo-test-results');
  const rb = document.getElementById('repo-risk-banner');
  if (!tr) return;

  tr.innerHTML = '<div class="rtr-scanning">Analysing scripts in repository\u2026</div>';
  tr.classList.remove('hidden');

  let data;
  try {
    data = await api('/api/repo/test', {
      method: 'POST',
      body: JSON.stringify({ repo_name: repoName }),
    });
  } catch (e) {
    tr.innerHTML = '<div class="rtr-error">Test request failed: ' + esc(String(e)) + '</div>';
    return;
  }

  if (!data.ok) {
    tr.innerHTML = '<div class="rtr-error">Test error: ' + esc(data.error || 'unknown') + '</div>';
    return;
  }

  tr.innerHTML = renderRepoTestResults(data);

  // Show risk banner if any errors
  if (rb) {
    if (!data.passed) {
      const msgEl = document.getElementById('repo-risk-msg');
      if (msgEl) {
        msgEl.textContent =
          (data.error_count || 0) + ' error(s) and ' +
          (data.warning_count || 0) + ' warning(s) found in ' +
          data.file_count + ' script(s). ' +
          'These scripts may behave unexpectedly or contain unsafe code. ' +
          'Review the details above before using this repo in a script.';
      }
      rb.classList.remove('hidden');
    } else {
      rb.classList.add('hidden');
    }
  }
}

function renderScriptTestResults(res) {
  const levelIcon  = { ok: '✔', warning: '⚠', error: '✘', info: 'ℹ' };
  const levelClass = { ok: 'rtr-ok', warning: 'rtr-warn', error: 'rtr-err', info: 'rtr-info' };

  let html = '<div class="rtr-header">';
  if (res.passed) {
    html += '<span class="rtr-summary rtr-ok">✔ Script checks passed.</span>';
  } else {
    html += '<span class="rtr-summary rtr-err">✘ Script checks found issues.</span>';
  }
  html += '</div>';

  if (res.results && res.results.length) {
    for (const chk of res.results) {
      const cls  = levelClass[chk.level] || 'rtr-info';
      const icon = levelIcon[chk.level]  || 'ℹ';
      html += '<div class="rtr-check ' + cls + '">';
      html += '<div class="rtr-check-tool">' + icon + ' ' + esc(chk.tool) + '</div>';
      if (chk.output) {
        html += '<pre class="rtr-check-output">' + esc(chk.output) + '</pre>';
      }
      html += '</div>';
    }
  }

  const body = document.getElementById('test-results-body');
  if (body) body.innerHTML = html;
}

function renderRepoTestResults(data) {
  const levelIcon = { ok: '\u2714', warning: '\u26a0', error: '\u2718', info: '\u2139' };
  const levelClass = { ok: 'rtr-ok', warning: 'rtr-warn', error: 'rtr-err', info: 'rtr-info' };

  let html = '<div class="rtr-header">';
  if (data.file_count === 0) {
    html += '<span class="rtr-summary rtr-ok">\u2714 No shell scripts found \u2014 nothing to validate.</span>';
  } else if (data.passed) {
    html += '<span class="rtr-summary rtr-ok">\u2714 All clear. ' + esc(data.summary) + '</span>';
  } else {
    html += '<span class="rtr-summary rtr-err">\u2718 Issues found. ' + esc(data.summary) + '</span>';
  }
  html += '</div>';

  if (!data.results || !data.results.length) return html;

  for (const file of data.results) {
    const fileHasError = file.checks.some(function(c) { return c.level === 'error'; });
    const fileHasWarn  = file.checks.some(function(c) { return c.level === 'warning'; });
    const fileClass = fileHasError ? 'rtr-file rtr-file-err'
                    : fileHasWarn  ? 'rtr-file rtr-file-warn'
                    : 'rtr-file rtr-file-ok';

    html += '<details class="' + fileClass + '">';
    html += '<summary>' +
      '<span class="rtr-file-icon">' +
        (fileHasError ? levelIcon.error : fileHasWarn ? levelIcon.warning : levelIcon.ok) +
      '</span> ' +
      esc(file.file) +
    '</summary>';

    for (const chk of file.checks) {
      const cls = levelClass[chk.level] || 'rtr-info';
      const icon = levelIcon[chk.level] || '\u2139';
      html += '<div class="rtr-check ' + cls + '">';
      html += '<div class="rtr-check-tool">' + icon + ' ' + esc(chk.tool) + '</div>';
      html += '<pre class="rtr-check-output">' + esc(chk.output || '') + '</pre>';
      html += '</div>';
    }

    html += '</details>';
  }

  return html;
}

// ── Canvas pan ─────────────────────────────────────────────────────────────
function _applyWorldTransform() {
  const world = document.getElementById('canvas-world');
  if (world) world.style.transform =
    'translate(' + _pan.x + 'px,' + _pan.y + 'px) scale(' + _zoom + ')';
  const lbl = document.getElementById('zoom-label');
  if (lbl) lbl.textContent = Math.round(_zoom * 100) + '%';
  // Empty-state: scale with zoom but stay centered (no pan)
  const empty = document.getElementById('canvas-empty');
  if (empty) empty.style.transform = 'translate(-50%,-50%) scale(' + _zoom + ')';
  // Grid: scale spacing with zoom (dots stay 2px), no pan
  const canvasEl = document.getElementById('canvas');
  if (canvasEl && canvasEl.classList.contains('grid-on')) {
    var gs = (32 * _zoom).toFixed(2) + 'px';
    var gp = (16 * _zoom).toFixed(2) + 'px';
    canvasEl.style.backgroundSize     = gs + ' ' + gs;
    canvasEl.style.backgroundPosition = gp + ' ' + gp;
  }
}

function bindCanvasPan() {
  const canvas = document.getElementById('canvas');
  if (!canvas) return;
  let panStart = null;

  canvas.addEventListener('mousedown', function(e) {
    if (e.target.closest('.block')) return;
    if (_connectMode) return;
    panStart = { mx: e.clientX, my: e.clientY, px: _pan.x, py: _pan.y, moved: false };
    canvas.style.cursor = 'grabbing';
  });

  document.addEventListener('mousemove', function(e) {
    if (!panStart) return;
    const dx = e.clientX - panStart.mx;
    const dy = e.clientY - panStart.my;
    if (Math.abs(dx) > 3 || Math.abs(dy) > 3) panStart.moved = true;
    _pan.x = panStart.px + dx;
    _pan.y = panStart.py + dy;
    _applyWorldTransform();
  });

  document.addEventListener('mouseup', function() {
    if (panStart) {
      if (!panStart.moved && _selected) {
        _selected = null;
        document.querySelectorAll('.block').forEach(function(el) { el.classList.remove('selected'); });
        renderEditor(null);
      }
      panStart = null;
      if (!_connectMode && canvas) canvas.style.cursor = '';
    }
  });

  // Wheel zoom — anchor to: selected block → block centroid → canvas centre
  function _zoomAnchor() {
    const canvasEl = document.getElementById('canvas');
    const cr = canvasEl ? canvasEl.getBoundingClientRect() : { left: 0, top: 0, width: 800, height: 600 };

    // 1. Selected block — use actual rendered position
    if (_selected) {
      const el = document.querySelector('.block[data-id="' + _selected + '"]');
      if (el) {
        const r = el.getBoundingClientRect();
        return {
          cx: (r.left + r.width  / 2) - cr.left,
          cy: (r.top  + r.height / 2) - cr.top
        };
      }
    }
    // 2. Centroid of all blocks (world coords → canvas-relative)
    if (_blocks.length > 0) {
      var sx = 0, sy = 0;
      _blocks.forEach(function(b) { sx += b.x; sy += b.y; });
      return {
        cx: (sx / _blocks.length) * _zoom + _pan.x,
        cy: (sy / _blocks.length) * _zoom + _pan.y
      };
    }
    // 3. Canvas centre
    return { cx: cr.width / 2, cy: cr.height / 2 };
  }

  canvas.addEventListener('wheel', function(e) {
    e.preventDefault();
    const delta = e.deltaY < 0 ? 1.1 : 0.9;
    const newZoom = Math.min(3, Math.max(0.35, _zoom * delta));
    const anchor = _zoomAnchor();
    _pan.x = anchor.cx - (anchor.cx - _pan.x) * (newZoom / _zoom);
    _pan.y = anchor.cy - (anchor.cy - _pan.y) * (newZoom / _zoom);
    _zoom = newZoom;
    _applyWorldTransform();
  }, { passive: false });

  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && _connectMode) setConnectMode(false);
  });
}

// ── Modal helpers ─────────────────────────────────────────────────────────────
function showModal(id) { document.getElementById(id).classList.remove('hidden'); }
function hideModal(id) { document.getElementById(id).classList.add('hidden'); }

function showStatus(elId, msg, cls) {
  const el = document.getElementById(elId);
  el.textContent = msg;
  el.className = 'save-status ' + cls;
}

// ── Utility ───────────────────────────────────────────────────────────────────
function esc(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
