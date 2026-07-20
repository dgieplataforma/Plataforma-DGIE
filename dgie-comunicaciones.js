(function(){
  'use strict';

  if(window.DGIE_COMUNICACIONES_PRO?.version)return;

  const VERSION=1;
  const COMPLETE_STATES=new Set(['completado','visto','cerrada']);
  const MANAGER_ROLES=new Set(['coordinador','direccion','director']);
  const FIELD_TYPES={
    texto:'Texto corto',
    parrafo:'Texto extenso',
    numero:'Número',
    fecha:'Fecha',
    si_no:'Sí / No',
    opcion:'Selección única',
    multiple:'Selección múltiple',
    establecimientos:'Establecimientos con comentario'
  };
  const STATUS_LABELS={
    pendiente:'Pendiente',
    en_proceso:'En curso',
    completado:'Completado',
    visto:'Leído',
    vencido:'Vencido',
    cerrada:'Cerrado'
  };
  const state={
    container:null,
    selectedId:null,
    detailView:'resumen',
    list:{q:'',status:'',type:''},
    table:{q:'',zone:'',status:''},
    responseDrafts:{},
    dirtyResponses:{},
    responseFiles:{},
    editingResponses:{},
    composeFiles:[],
    compose:null,
    template:'respuesta',
    formOpen:false,
    syncing:false,
    busy:false,
    lastSync:0,
    charts:{},
    toast:null,
    toastTimer:null,
    filterTimer:null
  };

  function esc(value){
    return String(value==null?'':value).replace(/[&<>"']/g,char=>({
      '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'
    }[char]));
  }
  function normalize(value){
    return String(value||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().trim();
  }
  function clone(value){
    try{return JSON.parse(JSON.stringify(value));}catch(_){return value;}
  }
  function nowIso(){return new Date().toISOString();}
  function user(){
    try{return currentUser||null;}catch(_){return null;}
  }
  function role(){return String(user()?.role||'').toLowerCase();}
  function isManager(){return MANAGER_ROLES.has(role());}
  function isCompany(){return role()==='empresa';}
  function isInspector(){return role()==='inspector';}
  async function verifiedManagerProfile(){
    if(!isManager())throw new Error('Solo Dirección o Coordinación puede crear pedidos.');
    if(typeof window.DGIE_DB?.currentProfile!=='function'){
      throw new Error('No se pudo verificar la sesión del sistema. Volvé a ingresar.');
    }
    const result=await window.DGIE_DB.currentProfile();
    if(result?.error||!result?.data){
      throw new Error('La sesión venció o no está disponible. Cerrá sesión y volvé a ingresar.');
    }
    const profile=result.data;
    const dbRole=String(profile.rol||'').toLowerCase();
    if(!['director','coordinador'].includes(dbRole)){
      throw new Error('La sesión cambió en otra pestaña. Volvé a ingresar como Dirección o Coordinación en esta pestaña.');
    }
    const visibleUser=user();
    if(visibleUser?.id&&String(visibleUser.id)!==String(profile.id)){
      throw new Error('La cuenta activa cambió en otra pestaña. Recargá esta página e ingresá nuevamente.');
    }
    return profile;
  }
  async function verifiedInspectorProfile(){
    if(!isInspector())throw new Error('Solo un inspector puede notificar a la empresa.');
    if(typeof window.DGIE_DB?.currentProfile!=='function'){
      throw new Error('No se pudo verificar la sesión del sistema. Volvé a ingresar.');
    }
    const result=await window.DGIE_DB.currentProfile();
    if(result?.error||!result?.data){
      throw new Error('La sesión venció o no está disponible. Cerrá sesión y volvé a ingresar.');
    }
    const profile=result.data;
    if(String(profile.rol||'').toLowerCase()!=='inspector'){
      throw new Error('La sesión activa no corresponde a un inspector. Volvé a ingresar.');
    }
    const visibleUser=user();
    if(visibleUser?.id&&String(visibleUser.id)!==String(profile.id)){
      throw new Error('La cuenta activa cambió en otra pestaña. Recargá esta página e ingresá nuevamente.');
    }
    if(Number(profile.zona||0)!==Number(visibleUser?.zona||0)){
      throw new Error('La zona de la sesión no coincide con la zona visible. Volvé a ingresar.');
    }
    return profile;
  }
  function communications(){
    try{return Array.isArray(COMUNICACIONES)?COMUNICACIONES:[];}catch(_){return [];}
  }
  function establishments(){
    try{return Array.isArray(ESTABS)?ESTABS:[];}catch(_){return [];}
  }
  function inspectors(){
    try{return Array.isArray(INSPECTORS)?INSPECTORS:[];}catch(_){return [];}
  }
  function companies(){
    try{return EMPRESAS_DATA||{};}catch(_){return {};}
  }
  function zones(){return Array.from({length:17},(_,index)=>index+1);}
  function commId(c){return String(c?.remoteId||c?.id||'');}
  function findComm(id){
    return communications().find(c=>commId(c)===String(id)||String(c?.id||'')===String(id));
  }
  function inspectorKey(zone){return String(Number(zone));}
  function companyKey(zone){return `empresa-${Number(zone)}`;}
  function currentKey(){
    const zone=Number(user()?.zona||0);
    return isCompany()?companyKey(zone):inspectorKey(zone);
  }
  function formatDate(value,withTime=true){
    if(!value)return 'Sin actividad';
    const date=new Date(value);
    if(Number.isNaN(date.getTime()))return String(value);
    return new Intl.DateTimeFormat('es-AR',withTime
      ?{day:'2-digit',month:'2-digit',year:'numeric',hour:'2-digit',minute:'2-digit'}
      :{day:'2-digit',month:'2-digit',year:'numeric'}
    ).format(date);
  }
  function formatShortDate(value){
    if(!value)return 'Sin fecha límite';
    const raw=String(value);
    const date=/^\d{4}-\d{2}-\d{2}$/.test(raw)?new Date(`${raw}T23:59:59`):new Date(raw);
    return Number.isNaN(date.getTime())?raw:formatDate(date,false);
  }
  function timestamp(value){
    const time=value?new Date(value).getTime():0;
    return Number.isFinite(time)?time:0;
  }
  function safeFileName(value){
    return String(value||'comunicacion').normalize('NFD').replace(/[\u0300-\u036f]/g,'')
      .replace(/[^a-zA-Z0-9_-]+/g,'_').replace(/^_+|_+$/g,'').slice(0,70)||'comunicacion';
  }
  function uniqueId(prefix='campo'){
    return `${prefix}_${Date.now().toString(36)}_${Math.random().toString(36).slice(2,7)}`;
  }
  function showToast(message,type='success'){
    state.toast={message:String(message||''),type};
    clearTimeout(state.toastTimer);
    renderToast();
    state.toastTimer=setTimeout(()=>{state.toast=null;renderToast();},4300);
  }
  function renderToast(){
    document.querySelectorAll('.dgc-toast').forEach(node=>node.remove());
    if(!state.toast)return;
    const node=document.createElement('div');
    node.className=`dgc-toast ${state.toast.type==='error'?'is-error':state.toast.type==='info'?'is-info':''}`;
    node.setAttribute('role','status');
    node.textContent=state.toast.message;
    document.body.appendChild(node);
  }
  function scheduleFilterRender(selector){
    clearTimeout(state.filterTimer);
    state.filterTimer=setTimeout(()=>{
      renderPage();
      requestAnimationFrame(()=>{
        const input=state.container?.querySelector(selector);
        if(!input)return;
        input.focus();
        if(typeof input.setSelectionRange==='function'){
          const end=String(input.value||'').length;
          input.setSelectionRange(end,end);
        }
      });
    },140);
  }

  function schemaFor(c){
    const raw=c?.encuesta;
    if(raw&&typeof raw==='object'&&!Array.isArray(raw)&&Number(raw.version)>=3&&Array.isArray(raw.campos)){
      return {
        version:Number(raw.version)||3,
        meta:{...(raw.meta||{})},
        campos:raw.campos.map((field,index)=>normalizeField(field,index))
      };
    }
    if(raw&&typeof raw==='object'&&!Array.isArray(raw)&&(raw.pregunta||Array.isArray(raw.opciones))){
      return {
        version:1,
        meta:{prioridad:c?.prioridad||'normal',fechaLimite:c?.fechaLimite||''},
        campos:[normalizeField({
          id:'legacy_encuesta',
          tipo:'multiple',
          etiqueta:raw.pregunta||'Encuesta',
          opciones:Array.isArray(raw.opciones)?raw.opciones:[],
          requerido:false
        },0)]
      };
    }
    if(Array.isArray(raw)&&raw.length){
      return {
        version:1,
        meta:{prioridad:c?.prioridad||'normal',fechaLimite:c?.fechaLimite||''},
        campos:[normalizeField({
          id:'legacy_encuesta',
          tipo:'multiple',
          etiqueta:'Encuesta',
          opciones:raw,
          requerido:false
        },0)]
      };
    }
    return {
      version:1,
      meta:{prioridad:c?.prioridad||'normal',fechaLimite:c?.fechaLimite||''},
      campos:String(c?.tipo||'')==='tarea'
        ?[normalizeField({id:'respuesta_general',tipo:'parrafo',etiqueta:'Respuesta',requerido:false},0)]
        :[]
    };
  }
  function normalizeField(field,index){
    const type=FIELD_TYPES[field?.tipo]?field.tipo:'texto';
    return {
      id:String(field?.id||`campo_${index+1}`),
      tipo:type,
      etiqueta:String(field?.etiqueta||FIELD_TYPES[type]||`Campo ${index+1}`),
      requerido:!!field?.requerido,
      opciones:Array.isArray(field?.opciones)?field.opciones.map(String).filter(Boolean):[],
      comentarioPorItem:field?.comentarioPorItem!==false,
      ayuda:String(field?.ayuda||'')
    };
  }
  function communicationMeta(c){
    const raw=c?.encuesta;
    return raw&&typeof raw==='object'&&!Array.isArray(raw)&&raw.meta&&typeof raw.meta==='object'
      ?raw.meta
      :{};
  }
  function isInspectorCompanyNotification(c){
    const meta=communicationMeta(c);
    return meta.clase==='notificacion_empresa'
      ||(meta.origenRol==='inspector'&&c?.alcance==='empresa_zona'&&isNotice(c));
  }
  function copiedToCoordination(c){
    return communicationMeta(c).copiaCoordinacion===true;
  }
  function authoredByCurrentUser(c){
    const currentId=user()?.id;
    const creatorId=c?.creadoPorId||c?.creado_por;
    if(currentId&&creatorId)return String(currentId)===String(creatorId);
    const meta=communicationMeta(c);
    return isInspectorCompanyNotification(c)
      &&Number(meta.origenZona||0)===Number(user()?.zona||0)
      &&(!c?.creadoPor||normalize(c.creadoPor)===normalize(user()?.name));
  }
  function isOwnInspectorNotification(c){
    return isInspector()&&isInspectorCompanyNotification(c)&&authoredByCurrentUser(c);
  }
  function priority(c){
    const value=String(schemaFor(c).meta?.prioridad||c?.prioridad||'normal').toLowerCase();
    return ['urgente','alta','normal','baja'].includes(value)?value:'normal';
  }
  function deadline(c){return schemaFor(c).meta?.fechaLimite||c?.fechaLimite||c?.vencimiento||'';}
  function isNotice(c){return ['notificacion','comunicado','aviso'].includes(String(c?.tipo||''));}
  function stateFor(c,key){return (c?.estados||{})[String(key)]||{estado:'pendiente'};}
  function destinationName(type,zone){
    if(type==='empresa'){
      const data=companies()?.[zone]||companies()?.[String(zone)]||{};
      return data.razonSocial?`${data.razonSocial} · Zona ${zone}`:`Empresa · Zona ${zone}`;
    }
    const name=inspectors()[Number(zone)-1];
    return name?`${name} · Zona ${zone}`:`Inspector/a · Zona ${zone}`;
  }
  function destinations(c){
    const selected=(Array.isArray(c?.zonas)?c.zonas:[]).map(Number).filter(Boolean);
    if(c?.alcance==='general')return zones().map(zone=>({key:inspectorKey(zone),zone,type:'inspector',label:destinationName('inspector',zone)}));
    if(c?.alcance==='zona')return selected.map(zone=>({key:inspectorKey(zone),zone,type:'inspector',label:destinationName('inspector',zone)}));
    if(c?.alcance==='empresas')return zones().map(zone=>({key:companyKey(zone),zone,type:'empresa',label:destinationName('empresa',zone)}));
    if(c?.alcance==='empresa_zona')return selected.map(zone=>({key:companyKey(zone),zone,type:'empresa',label:destinationName('empresa',zone)}));
    return [];
  }
  function destinationScope(c){
    if(c?.alcance==='general')return 'Todos los inspectores';
    if(c?.alcance==='empresas')return 'Todas las empresas';
    const names=destinations(c).map(item=>`Zona ${item.zone}`);
    return names.length?names.join(', '):'Sin destinatarios';
  }
  function normalizedStatus(c,destination){
    const status=String(stateFor(c,destination.key).estado||'pendiente');
    if(COMPLETE_STATES.has(status))return isNotice(c)?'visto':'completado';
    return status==='en_proceso'?'en_proceso':'pendiente';
  }
  function isOverdue(c,destination){
    const limit=deadline(c);
    if(!limit||COMPLETE_STATES.has(String(stateFor(c,destination.key).estado||'')))return false;
    const date=/^\d{4}-\d{2}-\d{2}$/.test(String(limit))?new Date(`${limit}T23:59:59`):new Date(limit);
    return !Number.isNaN(date.getTime())&&date.getTime()<Date.now();
  }
  function overallStatus(c){
    const list=destinations(c);
    if(!list.length)return 'pendiente';
    if(list.some(destination=>isOverdue(c,destination)))return 'vencido';
    const statuses=list.map(destination=>normalizedStatus(c,destination));
    if(statuses.every(status=>status==='completado'||status==='visto'))return 'completado';
    if(statuses.some(status=>status==='en_proceso'||status==='completado'||status==='visto'))return 'en_proceso';
    return 'pendiente';
  }
  function summary(c){
    const list=destinations(c);
    const completed=list.filter(destination=>COMPLETE_STATES.has(String(stateFor(c,destination.key).estado||''))).length;
    const inProgress=list.filter(destination=>String(stateFor(c,destination.key).estado||'')==='en_proceso').length;
    const overdue=list.filter(destination=>isOverdue(c,destination)).length;
    const pending=Math.max(0,list.length-completed-inProgress);
    return {
      total:list.length,
      completed,
      inProgress,
      pending,
      overdue,
      percent:list.length?Math.round(completed*100/list.length):0
    };
  }
  function lastActivity(c){
    const responseDates=Object.values(c?.estados||{}).map(item=>timestamp(item?.fecha||item?.completadoFecha));
    return Math.max(timestamp(c?.updatedAt||c?.updated_at||c?.createdAt||c?.created_at),0,...responseDates);
  }
  function statusBadge(status){
    const className=status==='completado'||status==='visto'?'is-green':status==='en_proceso'?'is-amber':status==='vencido'?'is-red':'';
    return `<span class="dgc-badge ${className}">${esc(STATUS_LABELS[status]||status)}</span>`;
  }
  function priorityBadge(c){
    const value=priority(c);
    const label={urgente:'Urgente',alta:'Alta',normal:'Normal',baja:'Baja'}[value];
    const className=value==='urgente'?'is-red':value==='alta'?'is-amber':value==='normal'?'is-blue':'';
    return `<span class="dgc-badge ${className}">${label}</span>`;
  }

  function visibleCommunications(){
    let list=communications().slice();
    if(isManager()){
      list=list.filter(c=>!isInspectorCompanyNotification(c)||copiedToCoordination(c));
    }else if(isInspector()){
      const key=currentKey();
      list=list.filter(c=>destinations(c).some(destination=>destination.key===key)||isOwnInspectorNotification(c));
    }else{
      const key=currentKey();
      list=list.filter(c=>destinations(c).some(destination=>destination.key===key));
    }
    const q=normalize(state.list.q);
    list=list.filter(c=>{
      const status=overallStatus(c);
      const matchesText=!q||normalize(`${c?.titulo||''} ${c?.mensaje||''} ${destinationScope(c)}`).includes(q);
      const matchesStatus=!state.list.status||status===state.list.status;
      const matchesType=!state.list.type
        ||(state.list.type==='tarea'&&!isNotice(c))
        ||(state.list.type==='notificacion'&&isNotice(c))
        ||(state.list.type==='enviadas'&&isOwnInspectorNotification(c))
        ||(state.list.type==='copias'&&isInspectorCompanyNotification(c)&&copiedToCoordination(c));
      return matchesText&&matchesStatus&&matchesType;
    });
    return list.sort((a,b)=>lastActivity(b)-lastActivity(a));
  }
  function ensureSelection(list){
    if(state.selectedId&&list.some(c=>commId(c)===String(state.selectedId)))return;
    state.selectedId=list[0]?commId(list[0]):null;
    state.detailView='resumen';
  }
  function globalSummary(list){
    if(isManager()){
      const requests=list.filter(c=>!isNotice(c));
      const totals=requests.reduce((acc,c)=>{
        const data=summary(c);
        acc.responses+=data.total;
        acc.completed+=data.completed;
        acc.pending+=data.pending+data.inProgress;
        if(data.overdue)acc.overdue++;
        return acc;
      },{responses:0,completed:0,pending:0,overdue:0});
      return [
        {label:'Pedidos activos',value:requests.length,note:'Solicitudes disponibles',tone:'blue'},
        {label:'Respuestas recibidas',value:totals.completed,note:`de ${totals.responses} esperadas`,tone:'green'},
        {label:'Respuestas pendientes',value:totals.pending,note:'Incluye avances guardados',tone:'amber'},
        {label:'Pedidos vencidos',value:totals.overdue,note:'Con destinatarios pendientes',tone:'red'}
      ];
    }
    const key=currentKey();
    const incoming=isInspector()?list.filter(c=>!isOwnInspectorNotification(c)):list;
    const sent=isInspector()?list.filter(isOwnInspectorNotification):[];
    const assigned=incoming.length;
    const completed=incoming.filter(c=>COMPLETE_STATES.has(String(stateFor(c,key).estado||''))).length;
    const inProgress=incoming.filter(c=>String(stateFor(c,key).estado||'')==='en_proceso').length;
    const overdue=incoming.filter(c=>isOverdue(c,{key})).length;
    return [
      {label:'Asignados',value:assigned,note:sent.length?`${sent.length} notificación${sent.length===1?'':'es'} enviada${sent.length===1?'':'s'}`:'Pedidos y avisos',tone:'blue'},
      {label:'Completados',value:completed,note:'Respuestas enviadas',tone:'green'},
      {label:'En curso',value:inProgress,note:'Borradores guardados',tone:'amber'},
      {label:'Vencidos',value:overdue,note:'Requieren atención',tone:'red'}
    ];
  }
  function renderGlobalKpis(list){
    return `<div class="dgc-global-kpis">${globalSummary(list).map(item=>`
      <div class="dgc-kpi is-${item.tone}">
        <div class="dgc-kpi-label">${esc(item.label)}</div>
        <div class="dgc-kpi-value">${esc(item.value)}</div>
        <div class="dgc-kpi-note">${esc(item.note)}</div>
      </div>`).join('')}</div>`;
  }
  function renderListItem(c){
    const data=summary(c);
    const status=overallStatus(c);
    const active=commId(c)===String(state.selectedId);
    const outgoing=isOwnInspectorNotification(c);
    const inspectorNotice=isInspectorCompanyNotification(c);
    const responseStatus=!isManager()&&!outgoing?normalizedStatus(c,{key:currentKey()}):status;
    return `<button type="button" class="dgc-list-item ${active?'is-active':''}" data-dgc-action="select" data-comm-id="${esc(commId(c))}">
      <div class="dgc-list-top">
        <div class="dgc-list-title">${esc(c?.titulo||'Sin título')}</div>
        ${statusBadge(responseStatus)}
      </div>
      <div class="dgc-list-meta">${esc(formatDate(c?.createdAt||c?.created_at))} · ${esc(destinationScope(c))}</div>
      <div class="dgc-list-preview">${esc(c?.mensaje||'')}</div>
      <div class="dgc-list-foot">
        ${priorityBadge(c)}
        <span class="dgc-badge ${isNotice(c)?'is-blue':'is-amber'}">${inspectorNotice?'Notificación a empresa':isNotice(c)?'Aviso':'Pedido'}</span>
        ${outgoing?'<span class="dgc-badge">Enviada</span>':''}
        ${copiedToCoordination(c)?'<span class="dgc-badge is-blue">Copia a Coordinación</span>':''}
        ${isManager()?`<span class="dgc-badge">${data.completed}/${data.total} respondieron</span>`:''}
      </div>
    </button>`;
  }
  function renderInbox(list){
    return `<aside class="dgc-pane dgc-inbox">
      <div class="dgc-pane-head">
        <div class="dgc-pane-title">${isManager()?'Pedidos y avisos':isInspector()?'Bandeja y enviados':'Mi bandeja'}</div>
        <span class="dgc-count">${list.length}</span>
      </div>
      <div class="dgc-filter-stack">
        <input class="dgc-input dgc-search" data-dgc-list-filter="q" value="${esc(state.list.q)}" placeholder="Buscar por título o contenido">
        <select class="dgc-select" data-dgc-list-filter="status">
          <option value="" ${!state.list.status?'selected':''}>Todos los estados</option>
          <option value="pendiente" ${state.list.status==='pendiente'?'selected':''}>Pendientes</option>
          <option value="en_proceso" ${state.list.status==='en_proceso'?'selected':''}>En curso</option>
          <option value="completado" ${state.list.status==='completado'?'selected':''}>Completados</option>
          <option value="vencido" ${state.list.status==='vencido'?'selected':''}>Vencidos</option>
        </select>
        <select class="dgc-select" data-dgc-list-filter="type">
          <option value="" ${!state.list.type?'selected':''}>Pedidos y avisos</option>
          <option value="tarea" ${state.list.type==='tarea'?'selected':''}>Solo pedidos</option>
          <option value="notificacion" ${state.list.type==='notificacion'?'selected':''}>Solo avisos</option>
          ${isInspector()?`<option value="enviadas" ${state.list.type==='enviadas'?'selected':''}>Enviadas a empresa</option>`:''}
          ${isManager()?`<option value="copias" ${state.list.type==='copias'?'selected':''}>Copias de inspectores</option>`:''}
        </select>
      </div>
      <div class="dgc-list">
        ${list.length?list.map(renderListItem).join(''):`<div class="dgc-empty"><strong>Sin resultados</strong>No hay comunicaciones para los filtros seleccionados.</div>`}
      </div>
    </aside>`;
  }
  function renderAttachments(files,label='Adjunto'){
    const list=Array.isArray(files)?files:[];
    if(!list.length)return '';
    return `<div class="dgc-file-list">${list.map((file,index)=>{
      const name=file?.nombre||file?.name||`Archivo ${index+1}`;
      const url=file?.url||file?.secure_url||file?.dataUrl||'';
      return `<button type="button" class="dgc-btn" data-dgc-action="download" data-file-url="${esc(url)}" data-file-name="${esc(name)}">${esc(label)} ${index+1}: ${esc(name)}</button>`;
    }).join('')}</div>`;
  }
  function renderDetailHeader(c){
    const inspectorNotice=isInspectorCompanyNotification(c);
    return `<div class="dgc-detail-head">
      <div class="dgc-detail-head-top">
        <div>
          <h2 class="dgc-detail-title">${esc(c?.titulo||'Sin título')}</h2>
          <div class="dgc-detail-meta">${esc(formatDate(c?.createdAt||c?.created_at))} · Por ${esc(c?.creadoPor||c?.creado_por_nombre||'Coordinación')} · ${esc(destinationScope(c))}</div>
        </div>
        <div class="dgc-inline-actions">
          ${statusBadge(overallStatus(c))}${priorityBadge(c)}${inspectorNotice?'<span class="dgc-badge">Inspector a empresa</span>':''}${copiedToCoordination(c)?'<span class="dgc-badge is-blue">Coordinación en copia</span>':''}${deadline(c)?`<span class="dgc-badge">${esc(formatShortDate(deadline(c)))}</span>`:''}
          ${isManager()?`<button type="button" class="dgc-btn dgc-btn-danger" data-dgc-action="delete-communication" data-comm-id="${esc(commId(c))}" ${state.busy?'disabled':''}>${state.busy?'Eliminando…':'Eliminar'}</button>`:''}
        </div>
      </div>
      <div class="dgc-message">${esc(c?.mensaje||'')}</div>
      ${renderAttachments(c?.archivos,'Adjunto')}
    </div>`;
  }
  function renderDetailKpis(c){
    const data=summary(c);
    return `<div class="dgc-detail-kpis">
      <div class="dgc-kpi is-blue"><div class="dgc-kpi-label">Destinatarios</div><div class="dgc-kpi-value">${data.total}</div><div class="dgc-kpi-note">Respuestas esperadas</div></div>
      <div class="dgc-kpi is-green"><div class="dgc-kpi-label">Completaron</div><div class="dgc-kpi-value">${data.completed}</div><div class="dgc-kpi-note">${data.percent}% del total</div></div>
      <div class="dgc-kpi is-amber"><div class="dgc-kpi-label">En curso</div><div class="dgc-kpi-value">${data.inProgress}</div><div class="dgc-kpi-note">Guardaron avance</div></div>
      <div class="dgc-kpi"><div class="dgc-kpi-label">Pendientes</div><div class="dgc-kpi-value">${data.pending}</div><div class="dgc-kpi-note">Sin completar</div></div>
      <div class="dgc-kpi is-red"><div class="dgc-kpi-label">Vencidos</div><div class="dgc-kpi-value">${data.overdue}</div><div class="dgc-kpi-note">Fuera de plazo</div></div>
    </div>
    <div class="dgc-progress" title="${data.percent}% completado"><span style="width:${data.percent}%"></span></div>`;
  }
  function renderDefinition(c){
    const fields=schemaFor(c).campos;
    if(!fields.length)return `<div class="dgc-definition"><h3>Tipo de comunicación</h3><div class="dgc-field-summary"><div class="dgc-field-summary-item"><strong>Aviso informativo</strong>Los destinatarios solo deben marcarlo como leído.</div></div></div>`;
    return `<div class="dgc-definition">
      <h3>Información solicitada</h3>
      <div class="dgc-field-summary">${fields.map(field=>`
        <div class="dgc-field-summary-item">
          <strong>${esc(field.etiqueta)} ${field.requerido?'<span class="dgc-required">*</span>':''}</strong>
          ${esc(FIELD_TYPES[field.tipo]||field.tipo)}${field.opciones.length?` · ${esc(field.opciones.join(', '))}`:''}
        </div>`).join('')}</div>
    </div>`;
  }
  function renderManagerOverview(c){
    return `${renderDetailKpis(c)}
      <div class="dgc-charts">
        <div class="dgc-chart">
          <div class="dgc-chart-title">Estado de respuestas</div>
          <div class="dgc-chart-wrap"><canvas id="dgc-status-chart"></canvas></div>
        </div>
        <div class="dgc-chart">
          <div class="dgc-chart-title" id="dgc-response-chart-title">Información recopilada</div>
          <div class="dgc-chart-wrap"><canvas id="dgc-response-chart"></canvas></div>
        </div>
      </div>
      ${renderDefinition(c)}`;
  }
  function trackingRows(c){
    return destinations(c).map(destination=>{
      const response=stateFor(c,destination.key);
      const status=isOverdue(c,destination)&&!COMPLETE_STATES.has(String(response.estado||''))?'vencido':normalizedStatus(c,destination);
      const validation=(c?.validaciones||{})[String(destination.key)]||{};
      return {
        key:destination.key,
        zone:destination.zone,
        recipient:destination.label,
        status,
        updated:response.fecha||response.completadoFecha||'',
        completedBy:response.completadoPor||response.usuario||'',
        completedAt:response.completadoFecha||'',
        validation:!!validation.validado
      };
    });
  }
  function filteredTrackingRows(c){
    const q=normalize(state.table.q);
    return trackingRows(c).filter(row=>
      (!state.table.zone||String(row.zone)===String(state.table.zone))&&
      (!state.table.status||row.status===state.table.status)&&
      (!q||normalize(`${row.recipient} ${row.completedBy} ${row.status}`).includes(q))
    );
  }
  function renderTableToolbar(c,mode){
    return `<div class="dgc-toolbar">
      <input class="dgc-input" data-dgc-table-filter="q" value="${esc(state.table.q)}" placeholder="Buscar destinatario o respuesta">
      <select class="dgc-select" data-dgc-table-filter="zone">
        <option value="">Todas las zonas</option>
        ${zones().map(zone=>`<option value="${zone}" ${String(state.table.zone)===String(zone)?'selected':''}>Zona ${zone}</option>`).join('')}
      </select>
      <select class="dgc-select" data-dgc-table-filter="status">
        <option value="">Todos los estados</option>
        <option value="pendiente" ${state.table.status==='pendiente'?'selected':''}>Pendiente</option>
        <option value="en_proceso" ${state.table.status==='en_proceso'?'selected':''}>En curso</option>
        <option value="completado" ${state.table.status==='completado'?'selected':''}>Completado</option>
        <option value="visto" ${state.table.status==='visto'?'selected':''}>Leído</option>
        <option value="vencido" ${state.table.status==='vencido'?'selected':''}>Vencido</option>
      </select>
      ${mode==='results'?`<div class="dgc-inline-actions">
        <button type="button" class="dgc-btn" data-dgc-action="export-excel" data-comm-id="${esc(commId(c))}">Excel</button>
        <button type="button" class="dgc-btn" data-dgc-action="export-pdf" data-comm-id="${esc(commId(c))}">PDF</button>
      </div>`:'<div></div>'}
    </div>`;
  }
  function renderTracking(c){
    const rows=filteredTrackingRows(c);
    return `${renderDetailKpis(c)}
      <div style="margin-top:14px">
        <h3 class="dgc-section-title">Seguimiento por inspector</h3>
        ${renderTableToolbar(c,'tracking')}
        <div class="dgc-table-wrap"><table class="dgc-table">
          <thead><tr><th>Inspector / destinatario</th><th>Zona</th><th>Estado</th><th>Última actividad</th><th>Completado por</th><th>Fecha de cierre</th><th>Validación</th></tr></thead>
          <tbody>${rows.length?rows.map(row=>`<tr>
            <td class="dgc-cell-main">${esc(row.recipient)}</td>
            <td>Zona ${row.zone}</td>
            <td>${statusBadge(row.status)}</td>
            <td>${esc(formatDate(row.updated))}</td>
            <td>${esc(row.completedBy||'—')}</td>
            <td>${row.completedAt?esc(formatDate(row.completedAt)):'—'}</td>
            <td>${!isNotice(c)&&COMPLETE_STATES.has(String(stateFor(c,row.key).estado||''))?`<label class="dgc-check"><input type="checkbox" data-dgc-validation="${esc(row.key)}" data-comm-id="${esc(commId(c))}" ${row.validation?'checked':''}> Revisada</label>`:'—'}</td>
          </tr>`).join(''):`<tr><td class="dgc-table-empty" colspan="7">No hay destinatarios para los filtros seleccionados.</td></tr>`}</tbody>
        </table></div>
      </div>`;
  }
  function legacyAnswers(c,response,fields){
    const output={...(response?.respuestas||{})};
    fields.forEach(field=>{
      if(output[field.id]!==undefined)return;
      if(field.tipo==='establecimientos'&&Array.isArray(response?.establecimientos))output[field.id]=clone(response.establecimientos);
      if(field.id==='respuesta_general'&&response?.respuestaTexto)output[field.id]=response.respuestaTexto;
      if(field.id==='legacy_encuesta'&&response?.encuesta){
        const raw=response.encuesta?.opciones||response.encuesta||{};
        output[field.id]=Object.keys(raw).filter(key=>{
          const item=raw[key];
          return typeof item==='object'?!!item.checked:!!item;
        }).map(key=>{
          const item=raw[key];
          return typeof item==='object'?(item.label||field.opciones[Number(key)]):field.opciones[Number(key)];
        }).filter(Boolean);
      }
    });
    return output;
  }
  function answerValue(c,response,field){
    return legacyAnswers(c,response,schemaFor(c).campos)[field.id];
  }
  function displayAnswer(field,value){
    if(field.tipo==='si_no'){
      if(value===true||String(value)==='si')return 'Sí';
      if(value===false||String(value)==='no')return 'No';
      return '';
    }
    if(field.tipo==='multiple')return Array.isArray(value)?value.join(', '):String(value||'');
    if(field.tipo==='establecimientos'){
      return (Array.isArray(value)?value:[]).map(item=>`${item?.nombre||'Establecimiento'}${item?.comentario?`: ${item.comentario}`:''}`).join(' | ');
    }
    return value==null?'':String(value);
  }
  function resultDataset(c){
    const fields=schemaFor(c).campos;
    const anchor=fields.find(field=>field.tipo==='establecimientos')||null;
    const columns=[
      {key:'recipient',label:'Inspector / destinatario'},
      {key:'zoneLabel',label:'Zona'},
      {key:'statusLabel',label:'Estado'},
      {key:'updatedLabel',label:'Última actualización'}
    ];
    fields.forEach(field=>{
      columns.push({key:`field_${field.id}`,label:field.etiqueta});
      if(field.tipo==='establecimientos'&&field.comentarioPorItem)columns.push({key:`comment_${field.id}`,label:`${field.etiqueta} · Comentario`});
    });
    const rows=[];
    destinations(c).forEach(destination=>{
      const response=stateFor(c,destination.key);
      const status=isOverdue(c,destination)&&!COMPLETE_STATES.has(String(response.estado||''))?'vencido':normalizedStatus(c,destination);
      const answers=legacyAnswers(c,response,fields);
      const anchorItems=anchor&&Array.isArray(answers[anchor.id])&&answers[anchor.id].length?answers[anchor.id]:[null];
      anchorItems.forEach(anchorItem=>{
        const row={
          recipient:destination.label,
          zoneLabel:`Zona ${destination.zone}`,
          statusLabel:STATUS_LABELS[status]||status,
          updatedLabel:response.fecha?formatDate(response.fecha):'Sin actividad',
          _zone:String(destination.zone),
          _status:status,
          _search:''
        };
        fields.forEach(field=>{
          const value=answers[field.id];
          if(field.tipo==='establecimientos'&&field.id===anchor?.id){
            row[`field_${field.id}`]=anchorItem?.nombre||'';
            if(field.comentarioPorItem)row[`comment_${field.id}`]=anchorItem?.comentario||'';
          }else{
            row[`field_${field.id}`]=displayAnswer(field,value);
            if(field.tipo==='establecimientos'&&field.comentarioPorItem)row[`comment_${field.id}`]='';
          }
        });
        row._search=normalize(columns.map(column=>row[column.key]||'').join(' '));
        rows.push(row);
      });
    });
    return {columns,rows};
  }
  function filteredResultDataset(c){
    const data=resultDataset(c);
    const q=normalize(state.table.q);
    return {
      columns:data.columns,
      rows:data.rows.filter(row=>
        (!state.table.zone||row._zone===String(state.table.zone))&&
        (!state.table.status||row._status===state.table.status)&&
        (!q||row._search.includes(q))
      )
    };
  }
  function renderResults(c){
    const data=filteredResultDataset(c);
    return `${renderDetailKpis(c)}
      <div style="margin-top:14px">
        <h3 class="dgc-section-title">Resultados consolidados</h3>
        ${renderTableToolbar(c,'results')}
        <div class="dgc-table-wrap"><table class="dgc-table">
          <thead><tr>${data.columns.map(column=>`<th>${esc(column.label)}</th>`).join('')}</tr></thead>
          <tbody>${data.rows.length?data.rows.map(row=>`<tr>${data.columns.map((column,index)=>`<td class="${index===0?'dgc-cell-main':''}">${esc(row[column.key]||'—')}</td>`).join('')}</tr>`).join(''):`<tr><td class="dgc-table-empty" colspan="${data.columns.length}">No hay resultados para los filtros seleccionados.</td></tr>`}</tbody>
        </table></div>
      </div>`;
  }
  function renderManagerDetail(c){
    if(!c)return `<section class="dgc-pane dgc-detail"><div class="dgc-empty"><strong>Seleccioná un pedido</strong>Elegí una comunicación de la bandeja para ver su seguimiento y resultados.</div></section>`;
    const content=state.detailView==='seguimiento'?renderTracking(c):state.detailView==='resultados'?renderResults(c):renderManagerOverview(c);
    return `<section class="dgc-pane dgc-detail">
      ${renderDetailHeader(c)}
      <div class="dgc-tabs" role="tablist">
        <button type="button" class="dgc-tab ${state.detailView==='resumen'?'is-active':''}" data-dgc-action="detail-view" data-view="resumen">Resumen y gráficos</button>
        <button type="button" class="dgc-tab ${state.detailView==='seguimiento'?'is-active':''}" data-dgc-action="detail-view" data-view="seguimiento">Seguimiento</button>
        <button type="button" class="dgc-tab ${state.detailView==='resultados'?'is-active':''}" data-dgc-action="detail-view" data-view="resultados">Resultados y exportación</button>
      </div>
      <div class="dgc-detail-body">${content}</div>
    </section>`;
  }

  function establishmentsForCurrentUser(){
    const zone=Number(user()?.zona||0);
    return establishments().filter(item=>Number(item?.zona)===zone)
      .sort((a,b)=>String(a?.n||'').localeCompare(String(b?.n||''),'es'));
  }
  function initialDraft(c){
    const response=stateFor(c,currentKey());
    return legacyAnswers(c,response,schemaFor(c).campos);
  }
  function draftFor(c){
    const id=commId(c);
    if(!state.responseDrafts[id])state.responseDrafts[id]=clone(initialDraft(c));
    return state.responseDrafts[id];
  }
  function completedForCurrent(c){
    return COMPLETE_STATES.has(String(stateFor(c,currentKey()).estado||''));
  }
  function readOnlyResponse(c){
    return completedForCurrent(c)&&!state.editingResponses[commId(c)];
  }
  function renderReadValue(field,value){
    if(field.tipo==='establecimientos'){
      const items=Array.isArray(value)?value:[];
      if(!items.length)return `<div class="dgc-read-value">Sin establecimientos informados</div>`;
      return `<div class="dgc-read-establishments">
        <div class="dgc-read-est-count">${items.length} establecimiento${items.length===1?'':'s'} informado${items.length===1?'':'s'}</div>
        <div class="dgc-read-est-table" role="table" aria-label="${esc(field.etiqueta||'Establecimientos informados')}">
          <div class="dgc-read-est-row is-head" role="row">
            <div role="columnheader">Establecimiento</div>
            <div role="columnheader">Comentario</div>
          </div>
          ${items.map(item=>`<div class="dgc-read-est-row" role="row">
            <div class="dgc-read-est-school" role="cell">${esc(item?.nombre||'Establecimiento')}</div>
            <div class="dgc-read-est-comment ${item?.comentario?'':'is-empty'}" role="cell">${esc(item?.comentario||'Sin comentario')}</div>
          </div>`).join('')}
        </div>
      </div>`;
    }
    const display=displayAnswer(field,value);
    return `<div class="dgc-read-value">${esc(display||'Sin respuesta')}</div>`;
  }
  function renderEstablishmentField(c,field,value,readOnly){
    const selected=Array.isArray(value)?value:[];
    if(readOnly)return renderReadValue(field,selected);
    const used=new Set(selected.map(item=>Number(item?.estId)));
    const options=establishmentsForCurrentUser().filter(item=>!used.has(Number(item.id)));
    return `<div>
      <div class="dgc-est-tools">
        <select class="dgc-select" id="dgc-est-select-${esc(field.id)}">
          <option value="">Seleccionar establecimiento</option>
          ${options.map(item=>`<option value="${Number(item.id)}">${esc(item.n||'Establecimiento')}</option>`).join('')}
        </select>
        <button type="button" class="dgc-btn" data-dgc-action="add-establishment" data-comm-id="${esc(commId(c))}" data-field-id="${esc(field.id)}">Agregar</button>
      </div>
      <div class="dgc-est-list">${selected.length?selected.map(item=>`
        <div class="dgc-est-row">
          <div class="dgc-est-row-head">
            <div class="dgc-est-name">${esc(item?.nombre||'Establecimiento')}</div>
            <button type="button" class="dgc-btn dgc-btn-danger" data-dgc-action="remove-establishment" data-comm-id="${esc(commId(c))}" data-field-id="${esc(field.id)}" data-est-id="${Number(item?.estId||0)}">Quitar</button>
          </div>
          ${field.comentarioPorItem?`<textarea class="dgc-textarea" style="min-height:66px" data-dgc-est-comment="${Number(item?.estId||0)}" data-field-id="${esc(field.id)}" data-comm-id="${esc(commId(c))}" placeholder="Comentario sobre este establecimiento">${esc(item?.comentario||'')}</textarea>`:''}
        </div>`).join(''):`<div class="dgc-help">Todavía no seleccionaste establecimientos.</div>`}</div>
    </div>`;
  }
  function renderResponseControl(c,field,value,readOnly){
    if(field.tipo==='establecimientos')return renderEstablishmentField(c,field,value,readOnly);
    if(readOnly)return renderReadValue(field,value);
    const common=`data-dgc-response-field="${esc(field.id)}" data-comm-id="${esc(commId(c))}"`;
    if(field.tipo==='parrafo')return `<textarea class="dgc-textarea" ${common} placeholder="Escribir respuesta">${esc(value||'')}</textarea>`;
    if(field.tipo==='numero')return `<input class="dgc-input" type="number" step="any" ${common} value="${esc(value??'')}">`;
    if(field.tipo==='fecha')return `<input class="dgc-input" type="date" ${common} value="${esc(value||'')}">`;
    if(field.tipo==='si_no')return `<select class="dgc-select" ${common}><option value="">Seleccionar</option><option value="si" ${value===true||value==='si'?'selected':''}>Sí</option><option value="no" ${value===false||value==='no'?'selected':''}>No</option></select>`;
    if(field.tipo==='opcion')return `<select class="dgc-select" ${common}><option value="">Seleccionar</option>${field.opciones.map(option=>`<option value="${esc(option)}" ${String(value||'')===option?'selected':''}>${esc(option)}</option>`).join('')}</select>`;
    if(field.tipo==='multiple'){
      const selected=new Set(Array.isArray(value)?value:[]);
      return `<div class="dgc-options">${field.opciones.map(option=>`<label class="dgc-option"><input type="checkbox" data-dgc-multi-field="${esc(field.id)}" data-comm-id="${esc(commId(c))}" value="${esc(option)}" ${selected.has(option)?'checked':''}> <span>${esc(option)}</span></label>`).join('')}</div>`;
    }
    return `<input class="dgc-input" type="text" ${common} value="${esc(value||'')}" placeholder="Escribir respuesta">`;
  }
  function renderInspectorDetail(c){
    if(!c)return `<section class="dgc-pane dgc-detail"><div class="dgc-empty"><strong>Seleccioná una comunicación</strong>Elegí un elemento de tu bandeja para leerlo y responder.</div></section>`;
    const response=stateFor(c,currentKey());
    const fields=schemaFor(c).campos;
    const draft=draftFor(c);
    const readOnly=readOnlyResponse(c);
    const status=isOverdue(c,{key:currentKey()})&&!completedForCurrent(c)?'vencido':normalizedStatus(c,{key:currentKey()});
    const noticeAction=isNotice(c)&&!completedForCurrent(c)?`<button type="button" class="dgc-btn dgc-btn-primary" data-dgc-action="mark-read" data-comm-id="${esc(commId(c))}" ${state.busy?'disabled':''}>${state.busy?'Registrando…':'Marcar como leído'}</button>`:'';
    return `<section class="dgc-pane dgc-detail">
      ${renderDetailHeader(c)}
      <div class="dgc-detail-body">
        <div class="dgc-response-status">
          <div>
            <div class="dgc-label">Tu estado</div>
            <div style="margin-top:5px">${statusBadge(status)}</div>
          </div>
          <div class="dgc-detail-meta">${response?.fecha?`Última actualización: ${esc(formatDate(response.fecha))}`:'Todavía no registraste actividad.'}</div>
          <div class="dgc-inline-actions">${noticeAction}${completedForCurrent(c)&&!isNotice(c)&&readOnly?`<button type="button" class="dgc-btn" data-dgc-action="edit-response" data-comm-id="${esc(commId(c))}" ${state.busy?'disabled':''}>Editar respuesta</button>`:''}</div>
        </div>
        ${isNotice(c)?`<div class="dgc-alert ${completedForCurrent(c)?'is-success':''}">${completedForCurrent(c)?'Aviso leído y registrado.':'Leé el aviso y marcá la confirmación para que Coordinación pueda hacer el seguimiento.'}</div>`:`
          <div>
            ${fields.map(field=>`<div class="dgc-response-field">
              <label class="dgc-label">${esc(field.etiqueta)} ${field.requerido?'<span class="dgc-required">*</span>':''}</label>
              ${field.ayuda?`<div class="dgc-help">${esc(field.ayuda)}</div>`:''}
              <div style="margin-top:7px">${renderResponseControl(c,field,draft[field.id],readOnly)}</div>
            </div>`).join('')}
            ${readOnly?renderAttachments(response?.archivosRespuesta,'Respuesta adjunta'):`<div class="dgc-response-field">
              <label class="dgc-label">Archivos de respaldo <span class="dgc-help">(opcional)</span></label>
              ${renderAttachments(response?.archivosRespuesta,'Respuesta adjunta')}
              <input class="dgc-input" style="margin-top:8px" type="file" multiple accept="image/*,.pdf,.xls,.xlsx,.doc,.docx" data-dgc-response-files="${esc(commId(c))}" ${state.busy?'disabled':''}>
            </div>`}
            ${readOnly?'':`<div class="dgc-inline-actions" style="margin-top:14px">
              <button type="button" class="dgc-btn" data-dgc-action="save-draft" data-comm-id="${esc(commId(c))}" ${state.busy?'disabled':''}>${state.busy?'Guardando…':'Guardar avance'}</button>
              <button type="button" class="dgc-btn dgc-btn-primary" data-dgc-action="submit-response" data-comm-id="${esc(commId(c))}" ${state.busy?'disabled':''}>${state.busy?'Enviando…':'Enviar respuesta'}</button>
            </div>`}
          </div>`}
      </div>
    </section>`;
  }
  function renderInspectorSentDetail(c){
    if(!c)return `<section class="dgc-pane dgc-detail"><div class="dgc-empty"><strong>Seleccioná una notificación</strong>Elegí un envío para consultar su estado.</div></section>`;
    const destination=destinations(c)[0]||null;
    const response=destination?stateFor(c,destination.key):{estado:'pendiente'};
    const status=destination&&isOverdue(c,destination)&&!COMPLETE_STATES.has(String(response.estado||''))
      ?'vencido'
      :destination?normalizedStatus(c,destination):'pendiente';
    const read=COMPLETE_STATES.has(String(response.estado||''));
    return `<section class="dgc-pane dgc-detail">
      ${renderDetailHeader(c)}
      <div class="dgc-detail-body">
        <div class="dgc-response-status">
          <div>
            <div class="dgc-label">Estado en la empresa</div>
            <div style="margin-top:5px">${statusBadge(status)}</div>
          </div>
          <div class="dgc-detail-meta">${read&&response?.fecha?`Lectura registrada: ${esc(formatDate(response.fecha))}`:'La empresa todavía no registró la lectura.'}</div>
        </div>
        <div class="dgc-delivery-facts">
          <div><span>Destinatario</span><strong>${esc(destination?.label||'Empresa de la zona')}</strong></div>
          <div><span>Copia</span><strong>${copiedToCoordination(c)?'Coordinación':'Sin copia'}</strong></div>
          <div><span>Enviada</span><strong>${esc(formatDate(c?.createdAt||c?.created_at))}</strong></div>
        </div>
        <div class="dgc-alert ${read?'is-success':''}">${read?'La empresa confirmó la lectura de esta notificación.':'La notificación fue enviada y está pendiente de lectura por la empresa.'}</div>
      </div>
    </section>`;
  }

  function defaultFields(template){
    if(template==='establecimientos')return [normalizeField({id:uniqueId(),tipo:'establecimientos',etiqueta:'Establecimientos a informar',requerido:true,comentarioPorItem:true},0)];
    if(template==='encuesta')return [normalizeField({id:uniqueId(),tipo:'opcion',etiqueta:'Seleccione una opción',requerido:true,opciones:['Sí','No','Parcialmente']},0)];
    if(template==='confirmacion')return [normalizeField({id:uniqueId(),tipo:'si_no',etiqueta:'¿Se realizó lo solicitado?',requerido:true},0)];
    return [normalizeField({id:uniqueId(),tipo:'parrafo',etiqueta:'Respuesta',requerido:true},0)];
  }
  function resetCompose(template='respuesta'){
    state.template=template;
    state.compose={
      mode:'gestion',
      tipo:'tarea',
      alcance:'general',
      zonas:[],
      prioridad:'normal',
      fechaLimite:'',
      titulo:'',
      mensaje:'',
      campos:defaultFields(template)
    };
    state.composeFiles=[];
  }
  function resetInspectorNotification(){
    const zone=Number(user()?.zona||0);
    state.template='aviso';
    state.compose={
      mode:'inspector_empresa',
      tipo:'notificacion',
      alcance:'empresa_zona',
      zonas:zone?[zone]:[],
      prioridad:'normal',
      fechaLimite:'',
      titulo:'',
      mensaje:'',
      campos:[],
      copiaCoordinacion:false
    };
    state.composeFiles=[];
  }
  function renderBuilderField(field,index){
    return `<div class="dgc-builder-row">
      <div class="dgc-builder-grid">
        <label class="dgc-form-field"><span class="dgc-label">Nombre del campo</span><input class="dgc-input" data-dgc-field-prop="etiqueta" data-field-id="${esc(field.id)}" value="${esc(field.etiqueta)}"></label>
        <label class="dgc-form-field"><span class="dgc-label">Tipo de respuesta</span><select class="dgc-select" data-dgc-field-prop="tipo" data-field-id="${esc(field.id)}">${Object.entries(FIELD_TYPES).map(([value,label])=>`<option value="${value}" ${field.tipo===value?'selected':''}>${esc(label)}</option>`).join('')}</select></label>
        <label class="dgc-check" style="padding-bottom:9px"><input type="checkbox" data-dgc-field-prop="requerido" data-field-id="${esc(field.id)}" ${field.requerido?'checked':''}> Obligatorio</label>
        <button type="button" class="dgc-btn dgc-btn-danger" data-dgc-action="remove-field" data-field-id="${esc(field.id)}" ${state.compose.campos.length===1?'disabled':''}>Quitar</button>
      </div>
      ${['opcion','multiple'].includes(field.tipo)?`<label class="dgc-form-field dgc-builder-options"><span class="dgc-label">Opciones, una por línea</span><textarea class="dgc-textarea" style="min-height:72px" data-dgc-field-prop="opciones" data-field-id="${esc(field.id)}">${esc(field.opciones.join('\n'))}</textarea></label>`:''}
      ${field.tipo==='establecimientos'?`<label class="dgc-check" style="margin-top:8px"><input type="checkbox" data-dgc-field-prop="comentarioPorItem" data-field-id="${esc(field.id)}" ${field.comentarioPorItem?'checked':''}> Solicitar un comentario por cada establecimiento</label>`:''}
    </div>`;
  }
  function renderInspectorNotificationDialog(data){
    const zone=Number(user()?.zona||0);
    return `<div class="dgc-dialog-backdrop" role="presentation">
      <div class="dgc-dialog dgc-dialog-compact" role="dialog" aria-modal="true" aria-labelledby="dgc-dialog-title">
        <div class="dgc-dialog-head">
          <div><div class="dgc-dialog-title" id="dgc-dialog-title">Notificar a la empresa</div><div class="dgc-dialog-sub">Nueva comunicación desde la inspección de Zona ${zone||'—'}.</div></div>
          <button type="button" class="dgc-btn dgc-close" aria-label="Cerrar" title="Cerrar" data-dgc-action="close-compose">×</button>
        </div>
        <div class="dgc-dialog-body">
          <div class="dgc-recipient-line">
            <span>Destinatario</span>
            <strong>${esc(destinationName('empresa',zone))}</strong>
          </div>
          <div class="dgc-form-section">
            <div class="dgc-form-grid">
              <label class="dgc-form-field"><span class="dgc-label">Prioridad</span><select class="dgc-select" data-dgc-compose="prioridad"><option value="normal" ${data.prioridad==='normal'?'selected':''}>Normal</option><option value="alta" ${data.prioridad==='alta'?'selected':''}>Alta</option><option value="urgente" ${data.prioridad==='urgente'?'selected':''}>Urgente</option><option value="baja" ${data.prioridad==='baja'?'selected':''}>Baja</option></select></label>
              <label class="dgc-check dgc-copy-option"><input type="checkbox" data-dgc-compose="copiaCoordinacion" ${data.copiaCoordinacion?'checked':''}> Enviar copia a Coordinación</label>
              <label class="dgc-form-field is-full"><span class="dgc-label">Título <span class="dgc-required">*</span></span><input class="dgc-input" data-dgc-compose="titulo" value="${esc(data.titulo)}" placeholder="Asunto de la notificación"></label>
              <label class="dgc-form-field is-full"><span class="dgc-label">Mensaje <span class="dgc-required">*</span></span><textarea class="dgc-textarea" data-dgc-compose="mensaje" placeholder="Escribí el detalle para la empresa">${esc(data.mensaje)}</textarea></label>
              <label class="dgc-form-field is-full"><span class="dgc-label">Archivos adjuntos</span><input class="dgc-input" type="file" multiple accept="image/*,.pdf,.xls,.xlsx,.doc,.docx" data-dgc-compose-files><span class="dgc-help">${state.composeFiles.length?`${state.composeFiles.length} archivo(s) seleccionado(s)`:'Opcional'}</span></label>
            </div>
          </div>
        </div>
        <div class="dgc-dialog-foot">
          <div class="dgc-sync"><span class="dgc-sync-dot ${window.DGIE_DB?.isConfigured?'':'is-warn'}"></span>${window.DGIE_DB?.isConfigured?'Listo para enviar':'Sin conexión'}</div>
          <div class="dgc-inline-actions"><button type="button" class="dgc-btn" data-dgc-action="close-compose">Cancelar</button><button type="button" class="dgc-btn dgc-btn-primary" data-dgc-action="save-communication" ${state.busy?'disabled':''}>${state.busy?'Enviando…':'Enviar notificación'}</button></div>
        </div>
      </div>
    </div>`;
  }
  function renderCreateDialog(){
    if(!state.formOpen||!state.compose)return '';
    const data=state.compose;
    if(data.mode==='inspector_empresa')return renderInspectorNotificationDialog(data);
    const needsZones=['zona','empresa_zona'].includes(data.alcance);
    return `<div class="dgc-dialog-backdrop" role="presentation">
      <div class="dgc-dialog" role="dialog" aria-modal="true" aria-labelledby="dgc-dialog-title">
        <div class="dgc-dialog-head">
          <div><div class="dgc-dialog-title" id="dgc-dialog-title">Nuevo pedido o aviso</div><div class="dgc-dialog-sub">Definí qué necesitás y cómo debe responder cada destinatario.</div></div>
          <button type="button" class="dgc-btn dgc-close" aria-label="Cerrar" title="Cerrar" data-dgc-action="close-compose">×</button>
        </div>
        <div class="dgc-dialog-body">
          <div class="dgc-form-section">
            <div class="dgc-form-grid">
              <label class="dgc-form-field"><span class="dgc-label">Tipo</span><select class="dgc-select" data-dgc-compose="tipo"><option value="tarea" ${data.tipo==='tarea'?'selected':''}>Pedido con respuesta</option><option value="notificacion" ${data.tipo==='notificacion'?'selected':''}>Aviso con confirmación de lectura</option></select></label>
              <label class="dgc-form-field"><span class="dgc-label">Prioridad</span><select class="dgc-select" data-dgc-compose="prioridad"><option value="normal" ${data.prioridad==='normal'?'selected':''}>Normal</option><option value="alta" ${data.prioridad==='alta'?'selected':''}>Alta</option><option value="urgente" ${data.prioridad==='urgente'?'selected':''}>Urgente</option><option value="baja" ${data.prioridad==='baja'?'selected':''}>Baja</option></select></label>
              <label class="dgc-form-field"><span class="dgc-label">Destinatarios</span><select class="dgc-select" data-dgc-compose="alcance"><option value="general" ${data.alcance==='general'?'selected':''}>Todos los inspectores</option><option value="zona" ${data.alcance==='zona'?'selected':''}>Inspectores de zonas seleccionadas</option><option value="empresas" ${data.alcance==='empresas'?'selected':''}>Todas las empresas</option><option value="empresa_zona" ${data.alcance==='empresa_zona'?'selected':''}>Empresas de zonas seleccionadas</option></select></label>
              <label class="dgc-form-field"><span class="dgc-label">Fecha límite</span><input class="dgc-input" type="date" data-dgc-compose="fechaLimite" value="${esc(data.fechaLimite)}"></label>
              ${needsZones?`<div class="dgc-form-field is-full"><span class="dgc-label">Zonas destinatarias</span><div class="dgc-zone-grid">${zones().map(zone=>`<label class="dgc-zone-option"><input type="checkbox" data-dgc-compose-zone="${zone}" ${data.zonas.includes(zone)?'checked':''}> Zona ${zone}</label>`).join('')}</div></div>`:''}
              <label class="dgc-form-field is-full"><span class="dgc-label">Título <span class="dgc-required">*</span></span><input class="dgc-input" data-dgc-compose="titulo" value="${esc(data.titulo)}" placeholder="Ej.: Informar establecimientos sin calefacción"></label>
              <label class="dgc-form-field is-full"><span class="dgc-label">Instrucciones <span class="dgc-required">*</span></span><textarea class="dgc-textarea" data-dgc-compose="mensaje" placeholder="Explicá qué información necesitás y para qué fecha">${esc(data.mensaje)}</textarea></label>
            </div>
          </div>
          ${data.tipo==='tarea'?`<div class="dgc-form-section">
            <h3 class="dgc-section-title">Formato de la respuesta</h3>
            <div class="dgc-template-row">
              <button type="button" class="dgc-template ${state.template==='establecimientos'?'is-active':''}" data-dgc-action="template" data-template="establecimientos"><strong>Establecimientos</strong><span>Selecciona escuelas y agrega comentarios por cada una.</span></button>
              <button type="button" class="dgc-template ${state.template==='encuesta'?'is-active':''}" data-dgc-action="template" data-template="encuesta"><strong>Encuesta</strong><span>Recopila una opción comparable por inspector.</span></button>
              <button type="button" class="dgc-template ${state.template==='respuesta'?'is-active':''}" data-dgc-action="template" data-template="respuesta"><strong>Respuesta libre</strong><span>Solicita una explicación o informe escrito.</span></button>
              <button type="button" class="dgc-template ${state.template==='confirmacion'?'is-active':''}" data-dgc-action="template" data-template="confirmacion"><strong>Confirmación</strong><span>Obtiene una respuesta Sí o No.</span></button>
            </div>
            <div class="dgc-fields-builder" style="margin-top:10px">${data.campos.map(renderBuilderField).join('')}</div>
            <button type="button" class="dgc-btn" style="margin-top:9px" data-dgc-action="add-field">Agregar otro campo</button>
          </div>`:''}
          <div class="dgc-form-section">
            <label class="dgc-form-field"><span class="dgc-label">Archivos adjuntos</span><input class="dgc-input" type="file" multiple accept="image/*,.pdf,.xls,.xlsx,.doc,.docx" data-dgc-compose-files><span class="dgc-help">${state.composeFiles.length?`${state.composeFiles.length} archivo(s) seleccionado(s)`:'Opcional. Los destinatarios podrán descargarlos.'}</span></label>
          </div>
        </div>
          <div class="dgc-dialog-foot">
            <div class="dgc-sync"><span class="dgc-sync-dot ${window.DGIE_DB?.isConfigured?'':'is-warn'}"></span>${window.DGIE_DB?.isConfigured?'Listo para enviar':'Sin conexión'}</div>
          <div class="dgc-inline-actions"><button type="button" class="dgc-btn" data-dgc-action="close-compose">Cancelar</button><button type="button" class="dgc-btn dgc-btn-primary" data-dgc-action="save-communication" ${state.busy?'disabled':''}>${state.busy?'Guardando…':'Enviar'}</button></div>
        </div>
      </div>
    </div>`;
  }
  function renderPage(){
    if(!state.container)return;
    destroyCharts();
    const list=visibleCommunications();
    ensureSelection(list);
    const selected=findComm(state.selectedId);
    const subtitle=isManager()
      ?'Creá pedidos estructurados, seguí cada respuesta y exportá resultados consolidados.'
      :isInspector()
        ?'Respondé pedidos, consultá avisos y notificá a la empresa de tu zona.'
        :'Consultá las comunicaciones recibidas y registrá su lectura.';
    const detail=isManager()
      ?renderManagerDetail(selected)
      :isOwnInspectorNotification(selected)
        ?renderInspectorSentDetail(selected)
        :renderInspectorDetail(selected);
    state.container.innerHTML=`<div class="dgc-page" id="dgc-root">
      <div class="dgc-header">
        <div><h1>${isManager()?'Comunicaciones y pedidos':'Comunicaciones'}</h1><p>${subtitle}</p></div>
        ${isManager()?`<div class="dgc-header-actions"><button type="button" class="dgc-btn dgc-btn-primary" data-dgc-action="new-communication">Nuevo pedido</button></div>`:isInspector()?`<div class="dgc-header-actions"><button type="button" class="dgc-btn dgc-btn-primary" data-dgc-action="new-company-notification">Notificar a empresa</button></div>`:''}
      </div>
      ${state.toast?`<div class="dgc-alert ${state.toast.type==='error'?'is-error':state.toast.type==='success'?'is-success':''}">${esc(state.toast.message)}</div>`:''}
      ${renderGlobalKpis(list)}
      <div class="dgc-shell">
        ${renderInbox(list)}
        ${detail}
      </div>
      ${renderCreateDialog()}
    </div>`;
    renderToast();
    if(isManager()&&selected&&state.detailView==='resumen')setTimeout(()=>renderCharts(selected),40);
  }

  function destroyCharts(){
    Object.values(state.charts).forEach(chart=>{try{chart?.destroy?.();}catch(_){}});
    state.charts={};
  }
  function responseChartData(c){
    const fields=schemaFor(c).campos;
    const choice=fields.find(field=>['opcion','multiple','si_no'].includes(field.tipo));
    if(choice){
      const labels=choice.tipo==='si_no'?['Sí','No']:choice.opciones;
      const values=labels.map(()=>0);
      destinations(c).forEach(destination=>{
        const value=answerValue(c,stateFor(c,destination.key),choice);
        const selected=Array.isArray(value)?value:[value===true?'Sí':value===false?'No':value];
        selected.filter(Boolean).forEach(item=>{
          const index=labels.findIndex(label=>normalize(label)===normalize(item));
          if(index>=0)values[index]++;
        });
      });
      return {title:choice.etiqueta,labels,values};
    }
    const establishmentField=fields.find(field=>field.tipo==='establecimientos');
    if(establishmentField){
      const labels=destinations(c).map(destination=>`Z${destination.zone}`);
      const values=destinations(c).map(destination=>{
        const value=answerValue(c,stateFor(c,destination.key),establishmentField);
        return Array.isArray(value)?value.length:0;
      });
      return {title:`Cantidad informada · ${establishmentField.etiqueta}`,labels,values};
    }
    const list=destinations(c);
    return {
      title:'Avance por zona',
      labels:list.map(destination=>`Z${destination.zone}`),
      values:list.map(destination=>COMPLETE_STATES.has(String(stateFor(c,destination.key).estado||''))?1:0)
    };
  }
  function renderCharts(c){
    if(!window.Chart||!document.getElementById('dgc-status-chart'))return;
    destroyCharts();
    const data=summary(c);
    const statusCanvas=document.getElementById('dgc-status-chart');
    const responseCanvas=document.getElementById('dgc-response-chart');
    if(!statusCanvas||!responseCanvas)return;
    state.charts.status=new Chart(statusCanvas,{
      type:'doughnut',
      data:{labels:['Completado','En curso','Pendiente','Vencido'],datasets:[{data:[data.completed,data.inProgress,data.pending-data.overdue,data.overdue].map(value=>Math.max(0,value)),backgroundColor:['#15803d','#d97706','#94a3b8','#b91c1c'],borderWidth:0}]},
      options:{responsive:true,maintainAspectRatio:false,cutout:'66%',plugins:{legend:{position:'bottom',labels:{boxWidth:10,font:{size:11}}}}}
    });
    const response=responseChartData(c);
    const title=document.getElementById('dgc-response-chart-title');
    if(title)title.textContent=response.title;
    state.charts.responses=new Chart(responseCanvas,{
      type:'bar',
      data:{labels:response.labels,datasets:[{label:'Respuestas',data:response.values,backgroundColor:'#2b7a78',borderRadius:3,maxBarThickness:34}]},
      options:{responsive:true,maintainAspectRatio:false,indexAxis:response.labels.length>9?'y':'x',scales:{x:{beginAtZero:true,ticks:{precision:0}},y:{beginAtZero:true,ticks:{precision:0}}},plugins:{legend:{display:false}}}
    });
  }

  async function readFiles(files,folder='comunicaciones'){
    const list=[...(files||[])];
    if(!list.length)return [];
    const reader=typeof window.leerArchivoDGIE==='function'?window.leerArchivoDGIE:null;
    const output=[];
    for(const file of list){
      if(reader){
        const saved=await reader(file,folder);
        if(saved)output.push(saved);
      }else output.push({nombre:file.name,name:file.name,url:''});
    }
    return output;
  }
  async function refreshRemote(options={}){
    if(state.syncing)return;
    if(!window.DGIE_DB?.isConfigured||typeof window.DGIE_DB.listarComunicaciones!=='function'){
      if(!options.quiet)showToast('No hay conexión disponible.','error');
      renderPage();
      return;
    }
    state.syncing=true;
    renderPage();
    try{
      const result=await window.DGIE_DB.listarComunicaciones();
      if(result?.error)throw result.error;
      const rows=Array.isArray(result?.data)?result.data:[];
      const mapped=rows.map((row,index)=>typeof window.mapRemoteComunicacion==='function'?window.mapRemoteComunicacion(row,index):row);
      communications().splice(0,communications().length,...mapped);
      Object.keys(state.responseDrafts).forEach(id=>{
        if(!state.dirtyResponses[id])delete state.responseDrafts[id];
      });
      state.lastSync=Date.now();
      ensureSelection(visibleCommunications());
      if(!options.quiet)showToast('Comunicaciones actualizadas.','success');
    }catch(error){
      showToast(`No se pudieron actualizar las comunicaciones: ${error?.message||error}`,'error');
    }finally{
      state.syncing=false;
      renderPage();
    }
  }
  function validateCompose(){
    const data=state.compose;
    if(!data?.titulo.trim()||!data?.mensaje.trim())return 'Completá el título y las instrucciones.';
    if(data.mode==='inspector_empresa'&&!Number(user()?.zona||0))return 'No se pudo determinar la zona del inspector.';
    if(['zona','empresa_zona'].includes(data.alcance)&&!data.zonas.length)return 'Seleccioná al menos una zona destinataria.';
    if(data.tipo==='tarea'){
      if(!data.campos.length)return 'Agregá al menos un campo para la respuesta.';
      for(const field of data.campos){
        if(!field.etiqueta.trim())return 'Todos los campos deben tener un nombre.';
        if(['opcion','multiple'].includes(field.tipo)&&field.opciones.length<2)return `Agregá al menos dos opciones en “${field.etiqueta}”.`;
      }
    }
    return '';
  }
  async function saveCommunication(){
    const errorMessage=validateCompose();
    if(errorMessage){showToast(errorMessage,'error');return;}
    if(!window.DGIE_DB?.isConfigured||typeof window.DGIE_DB.crearComunicacion!=='function'){
      showToast('No se puede enviar porque el servicio no está disponible.','error');
      return;
    }
    state.busy=true;
    renderPage();
    try{
      const data=state.compose;
      const inspectorMode=data.mode==='inspector_empresa';
      const profile=inspectorMode?await verifiedInspectorProfile():await verifiedManagerProfile();
      const inspectorZone=Number(profile?.zona||user()?.zona||0);
      if(inspectorMode){
        data.tipo='notificacion';
        data.alcance='empresa_zona';
        data.zonas=[inspectorZone];
        data.campos=[];
      }
      const files=await readFiles(state.composeFiles,'comunicaciones');
      const config={
        version:3,
        meta:{
          prioridad:data.prioridad,
          fechaLimite:data.fechaLimite||'',
          estado:'activo',
          clase:inspectorMode?'notificacion_empresa':'comunicacion_gestion',
          origenRol:inspectorMode?'inspector':String(profile?.rol||role()),
          origenZona:inspectorMode?inspectorZone:null,
          copiaCoordinacion:inspectorMode?!!data.copiaCoordinacion:false
        },
        campos:data.tipo==='tarea'?data.campos.map(normalizeField):[]
      };
      const row={
        tipo:data.tipo,
        titulo:data.titulo.trim(),
        mensaje:data.mensaje.trim(),
        alcance:data.alcance,
        zonas:['zona','empresa_zona'].includes(data.alcance)?data.zonas.slice().sort((a,b)=>a-b):[],
        creado_por:profile.id,
        creado_por_nombre:profile.nombre||user()?.name||'Coordinación',
        estados:{},
        validaciones:{},
        encuesta:config,
        archivos:files
      };
      const result=await window.DGIE_DB.crearComunicacion(row);
      if(result?.error)throw result.error;
      const mapped=typeof window.mapRemoteComunicacion==='function'
        ?window.mapRemoteComunicacion(result.data,0)
        :{...result.data,remoteId:result.data?.id,_remoteSaved:true};
      communications().unshift(mapped);
      state.selectedId=commId(mapped);
      state.formOpen=false;
      state.compose=null;
      state.composeFiles=[];
      state.detailView='resumen';
      state.lastSync=Date.now();
      showToast(inspectorMode?'Notificación enviada a la empresa.':'Pedido enviado y guardado correctamente.','success');
    }catch(error){
      showToast(`No se pudo enviar la comunicación: ${error?.message||error}`,'error');
    }finally{
      state.busy=false;
      renderPage();
    }
  }
  async function deleteCommunication(c){
    if(!c||!isManager())return;
    const title=String(c?.titulo||'esta comunicación').trim();
    const accepted=window.confirm(`¿Eliminar “${title}”?\n\nSe eliminarán la comunicación y todas sus respuestas. Esta acción no se puede deshacer.`);
    if(!accepted)return;
    state.busy=true;
    renderPage();
    try{
      await verifiedManagerProfile();
      const id=c?.remoteId||c?.id;
      if(c?._remoteSaved){
        if(!window.DGIE_DB?.isConfigured||typeof window.DGIE_DB.eliminarComunicacion!=='function'){
          throw new Error('No se pudo conectar con el servicio de eliminación.');
        }
        const result=await window.DGIE_DB.eliminarComunicacion(id);
        if(result?.error)throw result.error;
      }
      const list=communications();
      const index=list.findIndex(item=>item===c||commId(item)===String(id));
      if(index>=0)list.splice(index,1);
      delete state.responseDrafts[String(id)];
      delete state.dirtyResponses[String(id)];
      delete state.responseFiles[String(id)];
      delete state.editingResponses[String(id)];
      const visible=visibleCommunications();
      state.selectedId=visible[0]?commId(visible[0]):null;
      state.detailView='resumen';
      state.table={q:'',zone:'',status:''};
      state.lastSync=Date.now();
      showToast('Comunicación eliminada.','success');
    }catch(error){
      showToast(`No se pudo eliminar la comunicación: ${error?.message||error}`,'error');
    }finally{
      state.busy=false;
      renderPage();
    }
  }
  function responseValidation(c,draft){
    for(const field of schemaFor(c).campos){
      if(!field.requerido)continue;
      const value=draft[field.id];
      const empty=value==null||value===''||(Array.isArray(value)&&!value.length);
      if(empty)return `Completá el campo obligatorio “${field.etiqueta}”.`;
    }
    return '';
  }
  async function mergeRemoteState(c,key,nextState){
    const id=c?.remoteId||c?.id;
    if(!c?._remoteSaved||!id||!window.DGIE_DB?.isConfigured){
      c.estados={...(c.estados||{}),[key]:nextState};
      if(typeof window.saveAppState==='function')window.saveAppState();
      return;
    }
    if(typeof window.DGIE_DB.actualizarRespuestaComunicacion==='function'){
      const result=await window.DGIE_DB.actualizarRespuestaComunicacion(id,key,nextState);
      if(result?.error)throw result.error;
      c.estados=result?.data?.estados||{...(c.estados||{}),[key]:nextState};
      return;
    }
    const latest=await window.DGIE_DB.client.from('comunicaciones').select('estados').eq('id',id).single();
    if(latest?.error)throw latest.error;
    const states={...(latest?.data?.estados||{}),[key]:nextState};
    const updated=await window.DGIE_DB.actualizarComunicacion(id,{estados:states});
    if(updated?.error)throw updated.error;
    c.estados=updated?.data?.estados||states;
  }
  async function saveResponse(c,complete){
    if(!c)return;
    const draft=clone(draftFor(c));
    if(complete){
      const errorMessage=responseValidation(c,draft);
      if(errorMessage){showToast(errorMessage,'error');return;}
    }
    state.busy=true;
    renderPage();
    try{
      const key=currentKey();
      const previous=stateFor(c,key);
      const uploaded=await readFiles(state.responseFiles[commId(c)]||[],'comunicaciones-respuestas');
      const next={
        ...previous,
        estado:complete?'completado':'en_proceso',
        usuario:user()?.name||role(),
        zona:Number(user()?.zona||0),
        fecha:nowIso(),
        respuestas:draft
      };
      const generalField=schemaFor(c).campos.find(field=>['texto','parrafo'].includes(field.tipo));
      const establishmentsField=schemaFor(c).campos.find(field=>field.tipo==='establecimientos');
      if(generalField)next.respuestaTexto=String(draft[generalField.id]||'');
      if(establishmentsField)next.establecimientos=clone(draft[establishmentsField.id]||[]);
      if(uploaded.length)next.archivosRespuesta=[...(Array.isArray(previous?.archivosRespuesta)?previous.archivosRespuesta:[]),...uploaded];
      if(complete){
        next.completadoPor=user()?.name||role();
        next.completadoFecha=nowIso();
      }else{
        delete next.completadoPor;
        delete next.completadoFecha;
      }
      await mergeRemoteState(c,key,next);
      delete state.dirtyResponses[commId(c)];
      state.responseFiles[commId(c)]=[];
      state.editingResponses[commId(c)]=false;
      state.lastSync=Date.now();
      showToast(complete?'Respuesta enviada a Coordinación.':'Avance guardado.','success');
    }catch(error){
      showToast(`No se pudo guardar la respuesta: ${error?.message||error}`,'error');
    }finally{
      state.busy=false;
      renderPage();
    }
  }
  async function markRead(c){
    if(!c)return;
    state.busy=true;
    renderPage();
    try{
      const key=currentKey();
      const next={
        ...stateFor(c,key),
        estado:'visto',
        usuario:user()?.name||role(),
        fecha:nowIso(),
        completadoPor:user()?.name||role(),
        completadoFecha:nowIso()
      };
      await mergeRemoteState(c,key,next);
      showToast('Lectura registrada.','success');
    }catch(error){
      showToast(`No se pudo registrar la lectura: ${error?.message||error}`,'error');
    }finally{
      state.busy=false;
      renderPage();
    }
  }
  async function saveValidation(c,key,validated){
    if(!c)return;
    try{
      const id=c?.remoteId||c?.id;
      const value={validado:!!validated,por:user()?.name||'Coordinación',fecha:nowIso()};
      if(c?._remoteSaved&&window.DGIE_DB?.isConfigured){
        let result;
        if(typeof window.DGIE_DB.actualizarValidacionComunicacion==='function'){
          result=await window.DGIE_DB.actualizarValidacionComunicacion(id,key,value);
        }else{
          const latest=await window.DGIE_DB.client.from('comunicaciones').select('validaciones').eq('id',id).single();
          if(latest?.error)throw latest.error;
          const validations={...(latest?.data?.validaciones||{}),[key]:value};
          result=await window.DGIE_DB.actualizarComunicacion(id,{validaciones:validations});
        }
        if(result?.error)throw result.error;
        c.validaciones=result?.data?.validaciones||{...(c.validaciones||{}),[key]:value};
      }else{
        c.validaciones={...(c.validaciones||{}),[key]:value};
      }
      showToast(validated?'Respuesta marcada como revisada.':'Se quitó la validación.','success');
      renderPage();
    }catch(error){
      showToast(`No se pudo actualizar la validación: ${error?.message||error}`,'error');
      renderPage();
    }
  }

  function exportExcel(c){
    if(!window.XLSX){showToast('La librería de Excel no está disponible. Recargá la página.','error');return;}
    const results=filteredResultDataset(c);
    const tracking=filteredTrackingRows(c);
    const resultObjects=results.rows.map(row=>Object.fromEntries(results.columns.map(column=>[column.label,row[column.key]||''])));
    const trackingObjects=tracking.map(row=>({
      'Inspector / destinatario':row.recipient,
      'Zona':`Zona ${row.zone}`,
      'Estado':STATUS_LABELS[row.status]||row.status,
      'Última actividad':row.updated?formatDate(row.updated):'Sin actividad',
      'Completado por':row.completedBy||'',
      'Fecha de cierre':row.completedAt?formatDate(row.completedAt):'',
      'Validada':row.validation?'Sí':'No'
    }));
    const data=summary(c);
    const summarySheet=XLSX.utils.aoa_to_sheet([
      ['Pedido',c?.titulo||''],
      ['Creado',formatDate(c?.createdAt||c?.created_at)],
      ['Alcance',destinationScope(c)],
      ['Fecha límite',formatShortDate(deadline(c))],
      ['Destinatarios',data.total],
      ['Completaron',data.completed],
      ['En curso',data.inProgress],
      ['Pendientes',data.pending],
      ['Vencidos',data.overdue],
      ['Avance',`${data.percent}%`]
    ]);
    const resultSheet=XLSX.utils.json_to_sheet(resultObjects.length?resultObjects:[Object.fromEntries(results.columns.map(column=>[column.label,'']))]);
    const trackingSheet=XLSX.utils.json_to_sheet(trackingObjects.length?trackingObjects:[{'Inspector / destinatario':'Sin resultados'}]);
    if(resultSheet['!ref'])resultSheet['!autofilter']={ref:resultSheet['!ref']};
    if(trackingSheet['!ref'])trackingSheet['!autofilter']={ref:trackingSheet['!ref']};
    resultSheet['!cols']=results.columns.map(column=>({wch:Math.min(55,Math.max(14,column.label.length+3))}));
    trackingSheet['!cols']=[{wch:34},{wch:12},{wch:16},{wch:22},{wch:24},{wch:22},{wch:12}];
    summarySheet['!cols']=[{wch:22},{wch:60}];
    const book=XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(book,resultSheet,'Resultados');
    XLSX.utils.book_append_sheet(book,trackingSheet,'Seguimiento');
    XLSX.utils.book_append_sheet(book,summarySheet,'Resumen');
    XLSX.writeFile(book,`DGIE_Comunicacion_${safeFileName(c?.titulo)}_${new Date().toISOString().slice(0,10)}.xlsx`);
  }
  function exportPdf(c){
    const results=filteredResultDataset(c);
    const data=summary(c);
    const tableRows=results.rows.length?results.rows.map(row=>`<tr>${results.columns.map(column=>`<td>${esc(row[column.key]||'—')}</td>`).join('')}</tr>`).join(''):`<tr><td colspan="${results.columns.length}">Sin resultados para los filtros seleccionados.</td></tr>`;
    const report=`<!doctype html><html lang="es"><head><meta charset="utf-8"><title>${esc(c?.titulo||'Comunicación')}</title><style>
      *{box-sizing:border-box}body{font-family:Arial,sans-serif;color:#172033;margin:18mm;font-size:10pt}h1{font-size:18pt;color:#123c69;margin:0 0 4px}p{margin:3px 0;color:#475569}.meta{border-bottom:2px solid #123c69;padding-bottom:10px;margin-bottom:12px}.kpis{display:grid;grid-template-columns:repeat(5,1fr);gap:6px;margin:12px 0}.kpi{border:1px solid #cbd5e1;padding:8px}.kpi b{display:block;font-size:16pt;color:#123c69}.kpi span{font-size:8pt;color:#64748b}table{width:100%;border-collapse:collapse;margin-top:12px}th{background:#e8eef5;color:#172033;text-align:left;font-size:8pt;padding:6px;border:1px solid #aebdca}td{font-size:8pt;padding:6px;border:1px solid #cbd5e1;vertical-align:top;overflow-wrap:anywhere}.foot{margin-top:10px;font-size:8pt;color:#64748b}@page{size:landscape;margin:12mm}@media print{body{margin:0}.no-print{display:none}}
    </style></head><body>
      <div class="meta"><h1>${esc(c?.titulo||'Comunicación')}</h1><p>${esc(c?.mensaje||'')}</p><p><strong>Alcance:</strong> ${esc(destinationScope(c))} · <strong>Fecha límite:</strong> ${esc(formatShortDate(deadline(c)))}</p></div>
      <div class="kpis"><div class="kpi"><b>${data.total}</b><span>Destinatarios</span></div><div class="kpi"><b>${data.completed}</b><span>Completaron</span></div><div class="kpi"><b>${data.inProgress}</b><span>En curso</span></div><div class="kpi"><b>${data.pending}</b><span>Pendientes</span></div><div class="kpi"><b>${data.overdue}</b><span>Vencidos</span></div></div>
      <table><thead><tr>${results.columns.map(column=>`<th>${esc(column.label)}</th>`).join('')}</tr></thead><tbody>${tableRows}</tbody></table>
      <div class="foot">Reporte generado el ${esc(formatDate(nowIso()))}. Los datos corresponden a los filtros visibles en la plataforma.</div>
    </body></html>`;
    const frame=document.createElement('iframe');
    frame.setAttribute('aria-hidden','true');
    frame.style.cssText='position:fixed;right:0;bottom:0;width:1px;height:1px;border:0;opacity:0;pointer-events:none';
    const cleanup=()=>{setTimeout(()=>frame.remove(),250);};
    frame.addEventListener('load',()=>{
      const printWindow=frame.contentWindow;
      if(!printWindow){cleanup();showToast('No se pudo abrir la impresión del informe.','error');return;}
      printWindow.addEventListener('afterprint',cleanup,{once:true});
      setTimeout(()=>{
        try{
          printWindow.focus();
          printWindow.print();
          setTimeout(()=>{if(frame.isConnected)frame.remove();},60000);
        }catch(error){
          cleanup();
          showToast(`No se pudo imprimir el informe: ${error?.message||error}`,'error');
        }
      },120);
    },{once:true});
    document.body.appendChild(frame);
    frame.srcdoc=report;
    showToast('Se abrió la impresión. Elegí “Guardar como PDF” para descargar el informe.','info');
  }

  function updateComposeFromElement(element){
    if(!state.compose)return;
    const property=element.dataset.dgcCompose;
    if(!property)return;
    state.compose[property]=element.type==='checkbox'?!!element.checked:element.value;
    if(property==='alcance')state.compose.zonas=[];
    if(property==='tipo'&&element.value==='notificacion')state.template='aviso';
  }
  function updateBuilderField(element){
    const id=element.dataset.fieldId;
    const property=element.dataset.dgcFieldProp;
    const field=state.compose?.campos?.find(item=>item.id===id);
    if(!field||!property)return;
    if(property==='requerido'||property==='comentarioPorItem')field[property]=!!element.checked;
    else if(property==='opciones')field.opciones=String(element.value||'').split('\n').map(value=>value.trim()).filter(Boolean);
    else field[property]=element.value;
    if(property==='tipo'&&!['opcion','multiple'].includes(field.tipo))field.opciones=[];
    if(property==='tipo'&&field.tipo==='si_no')field.opciones=['Sí','No'];
    state.template='personalizado';
  }
  function updateResponseValue(element){
    const id=element.dataset.commId;
    const fieldId=element.dataset.dgcResponseField;
    const c=findComm(id);
    if(!c||!fieldId)return;
    const field=schemaFor(c).campos.find(item=>item.id===fieldId);
    const draft=draftFor(c);
    let value=element.value;
    if(field?.tipo==='numero')value=value===''?'':Number(value);
    if(field?.tipo==='si_no')value=value==='si'?true:value==='no'?false:'';
    draft[fieldId]=value;
    state.dirtyResponses[commId(c)]=true;
  }
  function updateMultiValue(element){
    const c=findComm(element.dataset.commId);
    const fieldId=element.dataset.dgcMultiField;
    if(!c||!fieldId)return;
    const draft=draftFor(c);
    const selected=new Set(Array.isArray(draft[fieldId])?draft[fieldId]:[]);
    if(element.checked)selected.add(element.value);else selected.delete(element.value);
    draft[fieldId]=[...selected];
    state.dirtyResponses[commId(c)]=true;
  }
  function addEstablishment(c,fieldId){
    const select=document.getElementById(`dgc-est-select-${fieldId}`);
    const estId=Number(select?.value||0);
    const establishment=establishments().find(item=>Number(item.id)===estId);
    if(!c||!establishment)return;
    const draft=draftFor(c);
    const list=Array.isArray(draft[fieldId])?draft[fieldId]:[];
    if(!list.some(item=>Number(item.estId)===estId))list.push({estId,nombre:establishment.n||'Establecimiento',comentario:''});
    draft[fieldId]=list;
    state.dirtyResponses[commId(c)]=true;
    renderPage();
  }
  function removeEstablishment(c,fieldId,estId){
    if(!c)return;
    const draft=draftFor(c);
    draft[fieldId]=(Array.isArray(draft[fieldId])?draft[fieldId]:[]).filter(item=>Number(item.estId)!==Number(estId));
    state.dirtyResponses[commId(c)]=true;
    renderPage();
  }
  function updateEstablishmentComment(element){
    const c=findComm(element.dataset.commId);
    const fieldId=element.dataset.fieldId;
    const estId=Number(element.dataset.dgcEstComment||0);
    if(!c||!fieldId||!estId)return;
    const draft=draftFor(c);
    const item=(Array.isArray(draft[fieldId])?draft[fieldId]:[]).find(value=>Number(value.estId)===estId);
    if(item){
      item.comentario=element.value;
      state.dirtyResponses[commId(c)]=true;
    }
  }

  async function handleAction(button){
    const action=button.dataset.dgcAction;
    if(state.busy&&['save-communication','delete-communication','save-draft','submit-response','mark-read'].includes(action))return;
    const c=findComm(button.dataset.commId||state.selectedId);
    if(action==='select'){
      state.selectedId=button.dataset.commId;
      state.detailView='resumen';
      state.table={q:'',zone:'',status:''};
      renderPage();
      return;
    }
    if(action==='detail-view'){state.detailView=button.dataset.view||'resumen';renderPage();return;}
    if(action==='refresh'){await refreshRemote();return;}
    if(action==='new-communication'){resetCompose('respuesta');state.formOpen=true;renderPage();return;}
    if(action==='new-company-notification'){resetInspectorNotification();state.formOpen=true;renderPage();return;}
    if(action==='close-compose'){state.formOpen=false;state.compose=null;state.composeFiles=[];renderPage();return;}
    if(action==='template'){
      const template=button.dataset.template||'respuesta';
      state.template=template;
      state.compose.campos=defaultFields(template);
      renderPage();
      return;
    }
    if(action==='add-field'){
      state.compose.campos.push(normalizeField({id:uniqueId(),tipo:'texto',etiqueta:`Campo ${state.compose.campos.length+1}`,requerido:false},state.compose.campos.length));
      state.template='personalizado';
      renderPage();
      return;
    }
    if(action==='remove-field'){
      state.compose.campos=state.compose.campos.filter(field=>field.id!==button.dataset.fieldId);
      renderPage();
      return;
    }
    if(action==='save-communication'){await saveCommunication();return;}
    if(action==='delete-communication'){await deleteCommunication(c);return;}
    if(action==='edit-response'){state.editingResponses[commId(c)]=true;renderPage();return;}
    if(action==='save-draft'){await saveResponse(c,false);return;}
    if(action==='submit-response'){await saveResponse(c,true);return;}
    if(action==='mark-read'){await markRead(c);return;}
    if(action==='add-establishment'){addEstablishment(c,button.dataset.fieldId);return;}
    if(action==='remove-establishment'){removeEstablishment(c,button.dataset.fieldId,button.dataset.estId);return;}
    if(action==='export-excel'){exportExcel(c);return;}
    if(action==='export-pdf'){exportPdf(c);return;}
    if(action==='download'){
      const url=button.dataset.fileUrl||'';
      const name=button.dataset.fileName||'archivo';
      if(typeof window.descargarArchivoComunicacion==='function')window.descargarArchivoComunicacion(url,name);
      else if(url)window.open(url,'_blank','noopener');
    }
  }
  document.addEventListener('click',event=>{
    const button=event.target.closest?.('[data-dgc-action]');
    if(!button||!button.closest('#dgc-root'))return;
    event.preventDefault();
    handleAction(button);
  });
  document.addEventListener('input',event=>{
    const element=event.target;
    if(!element.closest?.('#dgc-root'))return;
    if(element.dataset.dgcCompose)updateComposeFromElement(element);
    if(element.dataset.dgcFieldProp)updateBuilderField(element);
    if(element.dataset.dgcResponseField)updateResponseValue(element);
    if(element.dataset.dgcEstComment)updateEstablishmentComment(element);
    const listFilter=element.dataset.dgcListFilter;
    if(listFilter){
      state.list[listFilter]=element.value;
      if(element.tagName==='INPUT')scheduleFilterRender(`[data-dgc-list-filter="${listFilter}"]`);
    }
    const tableFilter=element.dataset.dgcTableFilter;
    if(tableFilter){
      state.table[tableFilter]=element.value;
      if(element.tagName==='INPUT')scheduleFilterRender(`[data-dgc-table-filter="${tableFilter}"]`);
    }
  });
  document.addEventListener('change',event=>{
    const element=event.target;
    if(!element.closest?.('#dgc-root'))return;
    if(element.dataset.dgcCompose){
      updateComposeFromElement(element);
      if(['alcance','tipo'].includes(element.dataset.dgcCompose))renderPage();
    }
    if(element.dataset.dgcComposeZone){
      const zone=Number(element.dataset.dgcComposeZone);
      const selected=new Set(state.compose?.zonas||[]);
      if(element.checked)selected.add(zone);else selected.delete(zone);
      state.compose.zonas=[...selected].sort((a,b)=>a-b);
    }
    if(element.dataset.dgcFieldProp){
      updateBuilderField(element);
      if(element.dataset.dgcFieldProp==='tipo')renderPage();
    }
    if(element.dataset.dgcResponseField)updateResponseValue(element);
    if(element.dataset.dgcMultiField)updateMultiValue(element);
    if(element.dataset.dgcListFilter&&element.tagName==='SELECT'){state.list[element.dataset.dgcListFilter]=element.value;renderPage();}
    if(element.dataset.dgcTableFilter&&element.tagName==='SELECT'){state.table[element.dataset.dgcTableFilter]=element.value;renderPage();}
    if(element.hasAttribute('data-dgc-compose-files'))state.composeFiles=[...(element.files||[])];
    if(element.dataset.dgcResponseFiles)state.responseFiles[element.dataset.dgcResponseFiles]=[...(element.files||[])];
    if(element.dataset.dgcValidation){
      const c=findComm(element.dataset.commId);
      saveValidation(c,element.dataset.dgcValidation,element.checked);
    }
  });

  const previousMap=window.mapRemoteComunicacion;
  window.mapRemoteComunicacion=function(row,index){
    const base=typeof previousMap==='function'?previousMap.apply(this,arguments):{};
    return {
      ...base,
      id:base.id??index+1,
      remoteId:row?.id||base.remoteId,
      _remoteSaved:true,
      tipo:row?.tipo||base.tipo||'notificacion',
      titulo:row?.titulo||base.titulo||'Comunicación',
      mensaje:row?.mensaje||base.mensaje||'',
      alcance:row?.alcance||base.alcance||'general',
      zonas:Array.isArray(row?.zonas)?row.zonas.map(Number):(base.zonas||[]),
      creadoPorId:row?.creado_por||base.creadoPorId||base.creado_por||null,
      creadoPor:row?.creado_por_nombre||row?.creadoPor||base.creadoPor||'Coordinación',
      createdAt:row?.created_at||row?.createdAt||base.createdAt||nowIso(),
      updatedAt:row?.updated_at||row?.updatedAt||base.updatedAt||null,
      estados:row?.estados||base.estados||{},
      validaciones:row?.validaciones||base.validaciones||{},
      encuesta:row?.encuesta??base.encuesta??null,
      archivos:Array.isArray(row?.archivos)?row.archivos:(base.archivos||[])
    };
  };

  window.renderComunicaciones=function(container){
    if(!container)return;
    state.container=container;
    renderPage();
    if(window.DGIE_DB?.isConfigured&&Date.now()-state.lastSync>15000&&!state.syncing){
      setTimeout(()=>refreshRemote({quiet:true}),80);
    }
  };

  document.addEventListener('dgie:data-ready',()=>{
    if(document.getElementById('dgc-root')){
      state.lastSync=Date.now();
      renderPage();
    }
  });
  document.addEventListener('visibilitychange',()=>{
    if(!document.hidden&&document.getElementById('dgc-root')&&Date.now()-state.lastSync>60000)refreshRemote({quiet:true});
  });
  setInterval(()=>{
    if(!document.hidden&&document.getElementById('dgc-root')&&Date.now()-state.lastSync>90000)refreshRemote({quiet:true});
  },30000);

  window.DGIE_COMUNICACIONES_PRO={
    version:VERSION,
    refresh:refreshRemote,
    render:renderPage,
    schemaFor,
    resultDataset,
    state
  };
})();
