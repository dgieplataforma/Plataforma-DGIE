(function(){
  'use strict';

  const IMAGE_EXTENSIONS=new Set(['jpg','jpeg','png','gif','webp','bmp','svg','avif']);
  const SHEET_EXTENSIONS=new Set(['xls','xlsx','xlsm','csv','ods']);
  const TEXT_EXTENSIONS=new Set(['txt','json','xml','log','dxf']);
  const GENERIC_EXTENSIONS=new Set(['doc','docx','dwg','zip','rar']);
  const VIEWABLE_EXTENSIONS=new Set([...IMAGE_EXTENSIONS,'pdf',...SHEET_EXTENSIONS,...TEXT_EXTENSIONS,...GENERIC_EXTENSIONS]);
  const state={open:false,token:'',url:'',name:'',objectUrls:[],lastFocus:null,bodyOverflow:''};
  let nativeWindowOpen=null;

  function esc(value){
    return String(value??'').replace(/[&<>"']/g,char=>({
      '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'
    })[char]);
  }
  function safeDecode(value){
    try{return decodeURIComponent(String(value||''))}catch(_){return String(value||'')}
  }
  function cleanUrl(value){
    const raw=String(value||'').trim();
    if(!raw)return '';
    if(raw.startsWith('javascript:'))return '';
    return raw;
  }
  function inlineCloudinaryUrl(value){
    const raw=cleanUrl(value);
    if(!raw.includes('res.cloudinary.com')||!raw.includes('/upload/'))return raw;
    return raw.replace(/\/upload\/fl_attachment(?::[^/]*)?\//,'/upload/');
  }
  function extensionOf(url,name=''){
    const candidates=[name];
    try{candidates.push(new URL(url,location.href).pathname)}catch(_){candidates.push(url)}
    for(const candidate of candidates){
      const clean=safeDecode(candidate).split(/[?#]/)[0];
      const match=clean.match(/\.([a-z0-9]{2,5})$/i);
      if(match)return match[1].toLowerCase();
    }
    return '';
  }
  function inferredName(url,name=''){
    const explicit=String(name||'').trim();
    if(explicit&&!/^(abrir|ver|vista previa|descargar|archivo)$/i.test(explicit))return explicit;
    try{
      const part=safeDecode(new URL(url,location.href).pathname.split('/').pop()||'');
      return part||explicit||'Archivo';
    }catch(_){return explicit||'Archivo'}
  }
  function kindOf(url,name=''){
    const ext=extensionOf(url,name);
    if(IMAGE_EXTENSIONS.has(ext))return 'image';
    if(ext==='pdf')return 'pdf';
    if(SHEET_EXTENSIONS.has(ext))return 'sheet';
    if(TEXT_EXTENSIONS.has(ext))return 'text';
    if(GENERIC_EXTENSIONS.has(ext))return 'generic';
    if(/^data:image\//i.test(url)||/^blob:/i.test(url)&&IMAGE_EXTENSIONS.has(extensionOf('',name)))return 'image';
    if(/^data:application\/pdf/i.test(url))return 'pdf';
    return '';
  }
  function isViewable(url,name=''){
    return !!kindOf(url,name)||VIEWABLE_EXTENSIONS.has(extensionOf(url,name));
  }
  function byId(id){return document.getElementById(id)}
  function revokeObjectUrls(){
    state.objectUrls.forEach(url=>{try{URL.revokeObjectURL(url)}catch(_){}});
    state.objectUrls=[];
  }
  function rememberObjectUrl(url){state.objectUrls.push(url);return url}

  function ensureViewer(){
    if(byId('dgie-file-viewer'))return;
    const style=document.createElement('style');
    style.id='dgie-file-viewer-style';
    style.textContent=`
      #dgie-file-viewer{position:fixed;inset:0;z-index:12000;display:none;flex-direction:column;background:#eef3f8;color:#14283d}
      #dgie-file-viewer.visible{display:flex}
      .dgie-file-viewer-head{display:grid;grid-template-columns:auto minmax(0,1fr) auto;align-items:center;gap:12px;min-height:62px;padding:9px max(12px,env(safe-area-inset-right)) 9px max(12px,env(safe-area-inset-left));padding-top:max(9px,env(safe-area-inset-top));background:#fff;border-bottom:1px solid #d9e3ee;box-shadow:0 4px 14px rgba(15,23,42,.07)}
      .dgie-file-viewer-back,.dgie-file-viewer-download{min-height:42px;border:1px solid #b9c9da;border-radius:7px;background:#fff;color:#075aa8;font:800 13px/1 system-ui,-apple-system,"Segoe UI",sans-serif;cursor:pointer;padding:0 14px}
      .dgie-file-viewer-back:hover,.dgie-file-viewer-download:hover{background:#edf6ff;border-color:#75a9d6}
      .dgie-file-viewer-title{min-width:0}
      .dgie-file-viewer-name{font:900 15px/1.25 system-ui,-apple-system,"Segoe UI",sans-serif;color:#123c69;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
      .dgie-file-viewer-type{margin-top:3px;color:#64748b;font:700 11px/1.2 system-ui,-apple-system,"Segoe UI",sans-serif}
      .dgie-file-viewer-body{position:relative;flex:1;min-height:0;overflow:auto;padding:16px}
      .dgie-file-viewer-loading,.dgie-file-viewer-error,.dgie-file-viewer-unsupported{display:flex;min-height:280px;align-items:center;justify-content:center;text-align:center;padding:28px;color:#475569;font:700 14px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif}
      .dgie-file-viewer-error{color:#b42318}
      .dgie-file-viewer-image-wrap{width:100%;min-height:100%;display:flex;align-items:center;justify-content:center}
      .dgie-file-viewer-image{display:block;max-width:100%;max-height:calc(100vh - 100px);object-fit:contain;background:#fff;box-shadow:0 8px 28px rgba(15,23,42,.13)}
      .dgie-file-viewer-frame{display:block;width:100%;height:100%;min-height:calc(100vh - 96px);border:0;background:#fff}
      .dgie-sheet-shell{display:flex;flex-direction:column;min-height:100%;gap:10px}
      .dgie-sheet-tabs{display:flex;gap:6px;overflow:auto;padding-bottom:2px}
      .dgie-sheet-tab{min-height:38px;padding:7px 12px;border:1px solid #cbd8e6;border-radius:7px;background:#fff;color:#47627e;font:800 12px/1 system-ui,-apple-system,"Segoe UI",sans-serif;white-space:nowrap;cursor:pointer}
      .dgie-sheet-tab.active{background:#075aa8;border-color:#075aa8;color:#fff}
      .dgie-sheet-table-wrap{flex:1;overflow:auto;background:#fff;border:1px solid #d7e2ed;border-radius:7px}
      .dgie-sheet-table{border-collapse:collapse;min-width:100%;font:12px/1.35 system-ui,-apple-system,"Segoe UI",sans-serif;color:#243b53}
      .dgie-sheet-table th{position:sticky;top:0;z-index:2;background:#eaf2fa;color:#123c69;font-weight:900}
      .dgie-sheet-table th,.dgie-sheet-table td{padding:7px 9px;border:1px solid #dce6ef;white-space:nowrap;text-align:left;vertical-align:top}
      .dgie-sheet-table tr:nth-child(even) td{background:#f8fafc}
      .dgie-sheet-note{color:#64748b;font:700 11px/1.35 system-ui,-apple-system,"Segoe UI",sans-serif}
      .dgie-text-preview{margin:0;min-height:100%;padding:18px;border:1px solid #d7e2ed;border-radius:7px;background:#fff;white-space:pre-wrap;overflow-wrap:anywhere;font:13px/1.5 ui-monospace,SFMono-Regular,Consolas,monospace;color:#243b53}
      @media(max-width:640px){
        .dgie-file-viewer-head{grid-template-columns:auto minmax(0,1fr) auto;gap:7px;min-height:58px;padding-left:8px;padding-right:8px}
        .dgie-file-viewer-back,.dgie-file-viewer-download{min-height:42px;padding:0 10px;font-size:12px}
        .dgie-file-viewer-name{font-size:13px}
        .dgie-file-viewer-body{padding:8px}
        .dgie-file-viewer-frame{min-height:calc(100vh - 75px)}
        .dgie-sheet-table th,.dgie-sheet-table td{padding:6px 7px;font-size:11px}
      }
    `;
    document.head.appendChild(style);
    const viewer=document.createElement('section');
    viewer.id='dgie-file-viewer';
    viewer.setAttribute('role','dialog');
    viewer.setAttribute('aria-modal','true');
    viewer.setAttribute('aria-label','Visor de archivos');
    viewer.innerHTML=`
      <header class="dgie-file-viewer-head">
        <button type="button" class="dgie-file-viewer-back" id="dgie-file-viewer-back" aria-label="Volver a la plataforma">‹ Volver</button>
        <div class="dgie-file-viewer-title">
          <div class="dgie-file-viewer-name" id="dgie-file-viewer-name">Archivo</div>
          <div class="dgie-file-viewer-type" id="dgie-file-viewer-type"></div>
        </div>
        <button type="button" class="dgie-file-viewer-download" id="dgie-file-viewer-download">Descargar</button>
      </header>
      <div class="dgie-file-viewer-body" id="dgie-file-viewer-body" role="document"></div>
    `;
    document.body.appendChild(viewer);
    byId('dgie-file-viewer-back').addEventListener('click',closeViewer);
    byId('dgie-file-viewer-download').addEventListener('click',()=>downloadCurrent());
  }

  function setBody(html,className=''){
    const body=byId('dgie-file-viewer-body');
    if(!body)return;
    body.className=`dgie-file-viewer-body${className?' '+className:''}`;
    body.innerHTML=html;
    body.scrollTop=0;
  }
  function setLoading(message='Preparando archivo...'){
    setBody(`<div class="dgie-file-viewer-loading">${esc(message)}</div>`);
  }
  function friendlyType(kind,ext){
    if(kind==='image')return 'Imagen';
    if(kind==='pdf')return 'Documento PDF';
    if(kind==='sheet')return `Planilla ${ext?ext.toUpperCase():''}`.trim();
    if(kind==='text')return 'Documento de texto';
    if(kind==='generic')return `Archivo ${ext?ext.toUpperCase():''}`.trim();
    return 'Archivo';
  }

  async function fetchResponse(url){
    const response=await fetch(inlineCloudinaryUrl(url),{credentials:'omit',cache:'no-store'});
    if(!response.ok)throw new Error(`No se pudo cargar el archivo (${response.status}).`);
    return response;
  }
  async function renderImage(url,name){
    const body=byId('dgie-file-viewer-body');
    if(!body)return;
    setBody('<div class="dgie-file-viewer-image-wrap"><img class="dgie-file-viewer-image" alt=""></div>');
    const image=body.querySelector('img');
    image.alt=name;
    image.addEventListener('error',()=>setBody('<div class="dgie-file-viewer-error">No se pudo mostrar la imagen. Podés descargarla desde el botón superior.</div>'),{once:true});
    image.src=inlineCloudinaryUrl(url);
  }
  async function renderPdf(url){
    setLoading('Preparando PDF...');
    try{
      const blob=await (await fetchResponse(url)).blob();
      const objectUrl=rememberObjectUrl(URL.createObjectURL(blob.type?blob:new Blob([blob],{type:'application/pdf'})));
      setBody(`<iframe class="dgie-file-viewer-frame" title="Documento PDF" src="${esc(objectUrl)}"></iframe>`);
    }catch(_){
      const direct=inlineCloudinaryUrl(url);
      setBody(`<iframe class="dgie-file-viewer-frame" title="Documento PDF" src="${esc(direct)}"></iframe>`);
    }
  }
  function renderSheetTable(workbook,sheetName){
    const worksheet=workbook.Sheets[sheetName];
    const rows=window.XLSX.utils.sheet_to_json(worksheet,{header:1,raw:false,defval:''});
    const maxRows=5000;
    const maxColumns=100;
    const visible=rows.slice(0,maxRows);
    const columns=Math.min(maxColumns,visible.reduce((max,row)=>Math.max(max,Array.isArray(row)?row.length:0),0));
    const header=visible[0]||[];
    const bodyRows=visible.slice(1);
    const headHtml=Array.from({length:columns},(_,index)=>`<th>${esc(header[index]||String.fromCharCode(65+(index%26)))}</th>`).join('');
    const rowsHtml=bodyRows.map(row=>`<tr>${Array.from({length:columns},(_,index)=>`<td>${esc(row[index])}</td>`).join('')}</tr>`).join('');
    const truncated=rows.length>maxRows||visible.some(row=>Array.isArray(row)&&row.length>maxColumns);
    const target=byId('dgie-sheet-table-target');
    if(target)target.innerHTML=`<div class="dgie-sheet-table-wrap"><table class="dgie-sheet-table"><thead><tr>${headHtml}</tr></thead><tbody>${rowsHtml}</tbody></table></div>${truncated?'<div class="dgie-sheet-note">La vista previa muestra las primeras 5.000 filas y 100 columnas. El archivo descargado conserva la información completa.</div>':''}`;
    document.querySelectorAll('.dgie-sheet-tab').forEach(button=>button.classList.toggle('active',button.dataset.sheet===sheetName));
  }
  async function renderSheet(url){
    if(!window.XLSX)throw new Error('El lector de planillas no está disponible.');
    setLoading('Preparando planilla...');
    const buffer=await (await fetchResponse(url)).arrayBuffer();
    const workbook=window.XLSX.read(buffer,{type:'array',cellDates:true});
    if(!workbook.SheetNames.length)throw new Error('La planilla no contiene hojas visibles.');
    setBody(`<div class="dgie-sheet-shell"><div class="dgie-sheet-tabs">${workbook.SheetNames.map(name=>`<button type="button" class="dgie-sheet-tab" data-sheet="${esc(name)}">${esc(name)}</button>`).join('')}</div><div id="dgie-sheet-table-target" class="dgie-sheet-shell"></div></div>`);
    document.querySelectorAll('.dgie-sheet-tab').forEach(button=>button.addEventListener('click',()=>renderSheetTable(workbook,button.dataset.sheet)));
    renderSheetTable(workbook,workbook.SheetNames[0]);
  }
  async function renderText(url){
    setLoading('Preparando documento...');
    const content=await (await fetchResponse(url)).text();
    setBody(`<pre class="dgie-text-preview">${esc(content)}</pre>`);
  }
  async function renderDocx(url){
    if(!window.JSZip)throw new Error('El lector de documentos no está disponible.');
    setLoading('Preparando documento...');
    const buffer=await (await fetchResponse(url)).arrayBuffer();
    const zip=await window.JSZip.loadAsync(buffer);
    const documentFile=zip.file('word/document.xml');
    if(!documentFile)throw new Error('El documento no tiene contenido legible.');
    const xml=await documentFile.async('string');
    const parsed=new DOMParser().parseFromString(xml,'application/xml');
    const paragraphs=Array.from(parsed.getElementsByTagNameNS('*','p')).map(paragraph=>
      Array.from(paragraph.getElementsByTagNameNS('*','t')).map(node=>node.textContent||'').join('')
    ).filter(Boolean);
    setBody(`<div class="dgie-text-preview" style="font-family:system-ui,-apple-system,'Segoe UI',sans-serif">${paragraphs.length?paragraphs.map(text=>`<p style="margin:0 0 10px">${esc(text)}</p>`).join(''):'El documento no contiene texto visible.'}</div>`);
  }
  async function renderZip(url){
    if(!window.JSZip)throw new Error('El lector de archivos comprimidos no está disponible.');
    setLoading('Leyendo contenido del archivo...');
    const buffer=await (await fetchResponse(url)).arrayBuffer();
    const zip=await window.JSZip.loadAsync(buffer);
    const entries=Object.values(zip.files).filter(entry=>!entry.dir);
    setBody(`<div class="dgie-text-preview" style="font-family:system-ui,-apple-system,'Segoe UI',sans-serif"><strong>${entries.length} archivo${entries.length===1?'':'s'} en el contenido</strong><div style="display:grid;gap:7px;margin-top:14px">${entries.map(entry=>`<div style="padding:7px 9px;border:1px solid #dce6ef;border-radius:6px;background:#f8fafc">${esc(entry.name)}</div>`).join('')}</div></div>`);
  }
  async function renderCurrent(){
    const kind=kindOf(state.url,state.name);
    try{
      if(kind==='image')return await renderImage(state.url,state.name);
      if(kind==='pdf')return await renderPdf(state.url);
      if(kind==='sheet')return await renderSheet(state.url);
      if(kind==='text')return await renderText(state.url);
      const ext=extensionOf(state.url,state.name);
      if(ext==='docx')return await renderDocx(state.url);
      if(ext==='zip')return await renderZip(state.url);
      setBody('<div class="dgie-file-viewer-unsupported">Este tipo de archivo no tiene una vista previa compatible. Podés guardarlo con el botón Descargar sin salir de la aplicación.</div>');
    }catch(error){
      console.warn('No se pudo mostrar el archivo dentro de la aplicación',error);
      setBody(`<div class="dgie-file-viewer-error">No se pudo preparar la vista previa.<br>El archivo sigue disponible para descargar.</div>`);
    }
  }
  async function openViewer(url,name='',options={}){
    const source=cleanUrl(url);
    if(!source)return false;
    ensureViewer();
    revokeObjectUrls();
    state.url=source;
    state.name=inferredName(source,name);
    state.lastFocus=document.activeElement;
    byId('dgie-file-viewer-name').textContent=state.name;
    const kind=kindOf(source,state.name);
    byId('dgie-file-viewer-type').textContent=friendlyType(kind,extensionOf(source,state.name));
    byId('dgie-file-viewer-download').textContent=kind==='sheet'?'Descargar para editar':'Descargar';
    byId('dgie-file-viewer').classList.add('visible');
    state.bodyOverflow=document.body.style.overflow;
    document.body.style.overflow='hidden';
    state.open=true;
    if(!options.fromHistory){
      state.token=`file-${Date.now()}-${Math.random().toString(36).slice(2,7)}`;
      history.pushState({...history.state,dgieFileViewer:state.token},'',location.href);
    }
    setLoading();
    byId('dgie-file-viewer-back').focus();
    await renderCurrent();
    return true;
  }
  function hideViewer(){
    if(!state.open)return;
    revokeObjectUrls();
    byId('dgie-file-viewer')?.classList.remove('visible');
    setBody('');
    document.body.style.overflow=state.bodyOverflow;
    state.open=false;
    state.token='';
    try{state.lastFocus?.focus()}catch(_){}
  }
  function closeViewer(){
    if(!state.open)return;
    if(history.state?.dgieFileViewer===state.token)history.back();
    else hideViewer();
  }
  async function downloadCurrent(){
    const button=byId('dgie-file-viewer-download');
    if(!state.url||!button)return;
    const original=button.textContent;
    button.disabled=true;
    button.textContent='Preparando...';
    try{
      const blob=await (await fetchResponse(state.url)).blob();
      const objectUrl=URL.createObjectURL(blob);
      const anchor=document.createElement('a');
      anchor.href=objectUrl;
      anchor.download=state.name||'archivo';
      anchor.dataset.dgieNativeDownload='1';
      document.body.appendChild(anchor);
      anchor.click();
      anchor.remove();
      setTimeout(()=>URL.revokeObjectURL(objectUrl),2000);
    }catch(error){
      console.warn('No se pudo descargar el archivo',error);
      alert('No se pudo descargar el archivo en este momento.');
    }finally{
      button.disabled=false;
      button.textContent=original;
    }
  }
  function linkFileInfo(anchor){
    const href=cleanUrl(anchor?.href||anchor?.getAttribute?.('href'));
    if(!href||href.startsWith('blob:')||anchor?.dataset?.dgieNativeDownload)return null;
    const name=anchor.getAttribute('download')||anchor.textContent?.trim()||'';
    return isViewable(href,name)?{url:href,name}:null;
  }
  function imageFileInfo(target){
    const image=target?.closest?.('img');
    if(!image)return null;
    if(!image.matches('.reclamo-foto-thumb,.foto-grid img,.foto-item img,.intervencion-photo-row img,[data-dgie-file-image]'))return null;
    const url=cleanUrl(image.currentSrc||image.src);
    return url?{url,name:image.alt||image.title||'Imagen'}:null;
  }
  function interceptClick(event){
    if(event.defaultPrevented||event.button!==0)return;
    const link=event.target?.closest?.('a[href]');
    const info=link?linkFileInfo(link):imageFileInfo(event.target);
    if(!info)return;
    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();
    openViewer(info.url,info.name);
  }

  window.abrirArchivoDGIE=openViewer;
  window.cerrarArchivoDGIE=closeViewer;
  window.addEventListener('popstate',()=>{
    if(state.open&&history.state?.dgieFileViewer!==state.token)hideViewer();
  });
  document.addEventListener('keydown',event=>{
    if(event.key==='Escape'&&state.open){event.preventDefault();closeViewer()}
  });
  document.addEventListener('click',interceptClick,true);
  document.addEventListener('DOMContentLoaded',ensureViewer,{once:true});
  if(document.readyState!=='loading')ensureViewer();

  nativeWindowOpen=window.open.bind(window);
  window.open=function(url,target,features){
    const source=typeof url==='string'?cleanUrl(url):'';
    if(source&&isViewable(source,'')){
      openViewer(source,'');
      return null;
    }
    return nativeWindowOpen(url,target,features);
  };
})();
