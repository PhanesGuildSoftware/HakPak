async function api(path, opts={}){
  const res = await fetch(path, {headers:{'Content-Type':'application/json'}, ...opts});
  return res.json();
}

async function refresh(){
  const vendorUrls = {
    'nessus': 'https://www.tenable.com/products/nessus/nessus-essentials',
    'maltego': 'https://www.maltego.com/downloads/',
    'burpsuite': 'https://portswigger.net/burp/communitydownload'
  };
  const det = await api('/api/detect');
  document.getElementById('detected').textContent = det.output?.trim() || '';

  const tools = await api('/api/tools');
  const st = await api('/api/status');
  const installed = (st.state && st.state.installed) || {};
  const c = document.getElementById('tools');
  c.innerHTML='';
  tools.tools?.forEach(t => {
    const el = document.createElement('div');
    el.className='tool';
    const isInstalled = !!installed[t.name];
    const isVendor = !!vendorUrls[t.name];
    const action = isInstalled ? 'Uninstall' : (isVendor ? 'Get' : 'Install');
    const cls = isInstalled ? 'small danger' : 'small';
    const badges = [];
    if (t.nativeAvailable) badges.push('<span class="badge native" title="Available via package manager">Native</span>');
    if (isVendor) badges.push('<span class="badge vendor" title="Vendor download required">Vendor</span>');
    const badgeHtml = badges.length ? `<div class="badges">${badges.join(' ')}</div>` : '';
    const updateBtn = isInstalled ? `<button class="small" data-action="update" data-name="${t.name}">Update</button>` : '';
    el.innerHTML = `<div>
        <div class="name">${t.name}</div>
        ${badgeHtml}
        <div class="methods">${(t.methods||[]).join(', ')}</div>
      </div>
      <div>
        <button class="${cls}" data-action="${action.toLowerCase()}" data-name="${t.name}" data-method="auto">${action}</button>
        ${updateBtn}
      </div>`;
    c.appendChild(el);
  });
  c.onclick = async (e)=>{
    const b = e.target.closest('button');
    if(!b) return;
    const name = b.getAttribute('data-name');
    const act = b.getAttribute('data-action');
    if(act==='install' && vendorUrls[name]){
      try{
        window.open(vendorUrls[name], '_blank', 'noopener');
      } catch(err){
        alert('Open this URL to download: '+vendorUrls[name]);
      }
      return; // Do not attempt an install via API for vendor tools
    }
    b.disabled = true; b.textContent = (act==='uninstall')? 'Uninstalling…' : (act==='update' ? 'Updating…' : 'Installing…');
    let out;
    if(act==='uninstall'){
      out = await api('/api/uninstall', {method:'POST', body: JSON.stringify({tool:name})});
    } else if(act==='update'){
      out = await api('/api/update', {method:'POST', body: JSON.stringify({tool:name})});
    } else {
      const method = b.getAttribute('data-method')||'auto';
      out = await api('/api/install', {method:'POST', body: JSON.stringify({tool:name, method})});
    }
    b.textContent = out.ok? (act==='uninstall'?'Uninstalled':(act==='update'?'Updated':'Installed')) : 'Failed';
    setTimeout(()=>{ refresh(); }, 900);
  };

  status();
}

async function status(){
  const st = await api('/api/status');
  document.getElementById('status').textContent = JSON.stringify(st.state || {}, null, 2);
}

document.getElementById('repo-add').onclick = async ()=>{
  const r = await api('/api/repo', {method:'POST', body: JSON.stringify({action:'add'})});
  alert((r.ok?'OK: ':'ERR: ')+ (r.output||''));
};
document.getElementById('repo-status').onclick = async ()=>{
  const r = await api('/api/repo', {method:'POST', body: JSON.stringify({action:'status'})});
  alert(r.output||'');
};
document.getElementById('repo-remove').onclick = async ()=>{
  const r = await api('/api/repo', {method:'POST', body: JSON.stringify({action:'remove'})});
  alert((r.ok?'OK: ':'ERR: ')+ (r.output||''));
};

// Controls
const refreshBtn = document.getElementById('refreshBtn');
if (refreshBtn) refreshBtn.addEventListener('click', ()=>{ refresh(); });
const updateAllBtn = document.getElementById('updateAllBtn');
if (updateAllBtn) updateAllBtn.addEventListener('click', async ()=>{
  updateAllBtn.disabled = true; const prev = updateAllBtn.textContent; updateAllBtn.textContent = 'Updating…';
  try{
    const out = await api('/api/update', {method:'POST', body: JSON.stringify({tool:'all'})});
    alert(out.ok ? 'All tools updated' : (out.output || 'Update failed'));
  } catch(e){
    alert(e.message||String(e));
  } finally {
    updateAllBtn.disabled = false; updateAllBtn.textContent = prev; refresh();
  }
});

refresh();
