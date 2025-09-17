async function api(path, opts={}){
  const res = await fetch(path, {headers:{'Content-Type':'application/json'}, ...opts});
  return res.json();
}

async function refresh(){
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
    const action = isInstalled ? 'Uninstall' : 'Install';
    const cls = isInstalled ? 'small danger' : 'small';
    el.innerHTML = `<div><div class="name">${t.name}</div><div class="methods">${(t.methods||[]).join(', ')}</div></div>
    <div><button class="${cls}" data-action="${action.toLowerCase()}" data-name="${t.name}" data-method="auto">${action}</button></div>`;
    c.appendChild(el);
  });
  c.onclick = async (e)=>{
    const b = e.target.closest('button');
    if(!b) return;
    const name = b.getAttribute('data-name');
    const act = b.getAttribute('data-action');
    b.disabled = true; b.textContent = (act==='uninstall')? 'Uninstalling…' : 'Installing…';
    let out;
    if(act==='uninstall'){
      out = await api('/api/uninstall', {method:'POST', body: JSON.stringify({tool:name})});
    } else {
      const method = b.getAttribute('data-method')||'auto';
      out = await api('/api/install', {method:'POST', body: JSON.stringify({tool:name, method})});
    }
    b.textContent = out.ok? (act==='uninstall'?'Uninstalled':'Installed') : 'Failed';
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

refresh();
