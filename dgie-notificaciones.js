(function(){
  'use strict';

  const PUBLIC_KEY='BImxVQUuI8gXsAJ50jH_pK8KwLeVPEkGlFpWR2DMHhThZl5JKLDpjoSUGgCLIKu4c8VPj7Y5NYXJEQwjUljkj3w';
  const WORKER_URL='/service-worker.js';
  const DISPATCH_URL='/api/push/dispatch';
  const ALLOWED_KINDS=new Set(['comunicado','reclamo','certificado','comentario_intervencion','comentario_relevamiento']);
  const state={registration:null,user:null,busy:false,enabled:false,status:'',pendingKind:'',pendingSourceId:'',routing:false,focusTimers:[],recentDispatches:new Map(),unreadCount:0,notifications:[],inboxOpen:false,inboxLoading:false};

  try{
    const params=new URLSearchParams(window.location.search);
    const kind=params.get('dgiePush');
    if(ALLOWED_KINDS.has(kind))state.pendingKind=kind;
    state.pendingSourceId=String(params.get('sourceId')||'');
  }catch(_){}

  function user(){
    try{return window.currentUser||state.user||null}catch(_){return state.user||null}
  }
  function role(){
    return String(user()?.role||'').toLowerCase();
  }
  function canReceive(){
    return ['inspector','empresa','coordinador'].includes(role());
  }
  function supported(){
    return !!(window.isSecureContext&&'serviceWorker' in navigator&&'PushManager' in window&&'Notification' in window);
  }
  function base64Key(value){
    const padding='='.repeat((4-value.length%4)%4);
    const raw=atob((value+padding).replace(/-/g,'+').replace(/_/g,'/'));
    return Uint8Array.from(raw,char=>char.charCodeAt(0));
  }
  function subscriptionRow(subscription){
    const json=subscription.toJSON();
    return {
      endpoint:json.endpoint||subscription.endpoint,
      p256dh:json.keys?.p256dh||'',
      auth:json.keys?.auth||'',
      userAgent:navigator.userAgent||''
    };
  }
  async function registerWorker(){
    if(!supported())return null;
    if(!state.registration){
      state.registration=await navigator.serviceWorker.register(WORKER_URL,{scope:'/',updateViaCache:'none'});
    }
    return navigator.serviceWorker.ready;
  }
  async function setBadge(count){
    const value=Math.max(0,Number(count)||0);
    state.unreadCount=value;
    try{
      if(value>0&&'setAppBadge' in navigator)await navigator.setAppBadge(value);
      else if(value===0&&'clearAppBadge' in navigator)await navigator.clearAppBadge();
    }catch(_){}
    renderInboxButton();
    return value;
  }
  async function syncBadge(){
    if(!user()||!window.DGIE_DB?.isConfigured||typeof window.DGIE_DB.contarNotificacionesPushPendientes!=='function')return 0;
    const result=await window.DGIE_DB.contarNotificacionesPushPendientes();
    if(result?.error)throw result.error;
    return setBadge(result?.data||0);
  }
  async function saveSubscription(subscription){
    if(!window.DGIE_DB?.isConfigured||typeof window.DGIE_DB.registrarSuscripcionPush!=='function'){
      throw new Error('La activacion todavia no esta disponible.');
    }
    const result=await window.DGIE_DB.registrarSuscripcionPush(subscriptionRow(subscription));
    if(result?.error)throw result.error;
    state.enabled=true;
    state.status='';
    await syncBadge();
    renderPrompt();
    return subscription;
  }
  async function ensureSubscription(){
    if(!user()||!canReceive()||Notification.permission!=='granted')return null;
    const registration=await registerWorker();
    if(!registration)return null;
    let subscription=await registration.pushManager.getSubscription();
    if(!subscription){
      subscription=await registration.pushManager.subscribe({
        userVisibleOnly:true,
        applicationServerKey:base64Key(PUBLIC_KEY)
      });
    }
    return saveSubscription(subscription);
  }
  async function enable(){
    if(state.busy||!user())return;
    state.busy=true;
    state.status='';
    renderPrompt();
    try{
      const permission=await Notification.requestPermission();
      if(permission!=='granted'){
        state.enabled=false;
        state.status='Habilitalas desde Ajustes > Notificaciones.';
        return;
      }
      await ensureSubscription();
    }catch(error){
      state.enabled=false;
      state.status=String(error?.message||'No se pudieron activar las notificaciones.');
      console.warn('No se pudieron activar las notificaciones',error);
    }finally{
      state.busy=false;
      renderPrompt();
    }
  }
  async function disable(){
    try{
      const registration=await registerWorker();
      const subscription=await registration?.pushManager.getSubscription();
      if(subscription){
        if(window.DGIE_DB?.isConfigured&&typeof window.DGIE_DB.eliminarSuscripcionPush==='function'){
          await window.DGIE_DB.eliminarSuscripcionPush(subscription.endpoint).catch(()=>{});
        }
        await subscription.unsubscribe().catch(()=>{});
      }
    }catch(_){}
    state.enabled=false;
    await setBadge(0);
  }
  function escapeText(value){
    return String(value??'').replace(/[&<>"']/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
  }
  function notificationDate(value){
    if(!value)return '';
    try{return new Date(value).toLocaleString('es-AR',{day:'2-digit',month:'2-digit',hour:'2-digit',minute:'2-digit'})}
    catch(_){return ''}
  }
  function notificationKindLabel(kind){
    return {comunicado:'Comunicaciones',reclamo:'Reclamos',certificado:'Certificaci\u00f3n',comentario_intervencion:'Intervenciones',comentario_relevamiento:'Relevamientos'}[kind]||'Novedad';
  }
  function ensureInbox(){
    const right=document.querySelector('#app-wrapper .topbar-right');
    if(!right||!user())return null;
    let button=document.getElementById('dgie-notifications-button');
    if(!button){
      button=document.createElement('button');
      button.type='button';
      button.id='dgie-notifications-button';
      button.className='dgie-notifications-button';
      button.setAttribute('aria-label','Abrir notificaciones');
      button.setAttribute('aria-haspopup','dialog');
      button.innerHTML='<span class="dgie-notifications-bell" aria-hidden="true">&#128276;</span><span class="dgie-notifications-count" id="dgie-notifications-count" hidden>0</span>';
      button.addEventListener('click',event=>{event.stopPropagation();toggleInbox()});
      right.insertBefore(button,right.querySelector('.user-chip'));
    }
    let panel=document.getElementById('dgie-notifications-panel');
    if(!panel){
      panel=document.createElement('section');
      panel.id='dgie-notifications-panel';
      panel.className='dgie-notifications-panel';
      panel.setAttribute('role','dialog');
      panel.setAttribute('aria-label','Notificaciones pendientes');
      panel.hidden=true;
      document.body.appendChild(panel);
    }
    return panel;
  }
  function renderInboxButton(){
    const panel=ensureInbox();
    const button=document.getElementById('dgie-notifications-button');
    const count=document.getElementById('dgie-notifications-count');
    if(count){
      count.textContent=state.unreadCount>99?'99+':String(state.unreadCount);
      count.hidden=state.unreadCount<1;
    }
    if(button){
      button.classList.toggle('has-pending',state.unreadCount>0);
      button.setAttribute('aria-label',state.unreadCount?'Notificaciones: '+state.unreadCount+' pendientes':'No hay notificaciones pendientes');
      button.setAttribute('aria-expanded',state.inboxOpen?'true':'false');
    }
    if(!panel)return;
    panel.hidden=!state.inboxOpen;
    if(!state.inboxOpen)return;
    const rows=state.notifications;
    const content=state.inboxLoading
      ?'<div class="dgie-notifications-empty">Cargando novedades...</div>'
      :rows.length
        ?rows.map(item=>'<button type="button" class="dgie-notification-item" data-notification-id="'+escapeText(item.id)+'"><span class="dgie-notification-kind">'+escapeText(notificationKindLabel(item.kind))+'</span><strong>'+escapeText(item.title||'Nueva notificaci\u00f3n')+'</strong><span class="dgie-notification-body">'+escapeText(item.body||'')+'</span><time>'+escapeText(notificationDate(item.created_at))+'</time></button>').join('')
        :'<div class="dgie-notifications-empty"><strong>Est\u00e1s al d\u00eda.</strong><span>No hay notificaciones pendientes.</span></div>';
    panel.innerHTML='<div class="dgie-notifications-head"><div><strong>Notificaciones</strong><span>'+state.unreadCount+' pendiente'+(state.unreadCount===1?'':'s')+'</span></div>'+(state.unreadCount?'<button type="button" id="dgie-notifications-read-all">Marcar todas como le\u00eddas</button>':'')+'</div><div class="dgie-notifications-list">'+content+'</div>';
    panel.querySelectorAll('[data-notification-id]').forEach(element=>{
      element.addEventListener('click',()=>openNotification(rows.find(item=>String(item.id)===element.dataset.notificationId)));
    });
    panel.querySelector('#dgie-notifications-read-all')?.addEventListener('click',markAllRead);
  }
  async function loadInbox(openAfter=false){
    if(!user()||!window.DGIE_DB?.isConfigured||typeof window.DGIE_DB.listarNotificacionesPushPendientes!=='function')return [];
    state.inboxLoading=true;
    if(openAfter)state.inboxOpen=true;
    renderInboxButton();
    try{
      const result=await window.DGIE_DB.listarNotificacionesPushPendientes(50);
      if(result?.error)throw result.error;
      state.notifications=Array.isArray(result?.data)?result.data:[];
      return state.notifications;
    }catch(error){
      console.warn('No se pudieron cargar las notificaciones pendientes',error);
      state.notifications=[];
      return [];
    }finally{
      state.inboxLoading=false;
      renderInboxButton();
    }
  }
  async function toggleInbox(){
    state.inboxOpen=!state.inboxOpen;
    if(state.inboxOpen)await loadInbox(true);
    else renderInboxButton();
  }
  async function markAllRead(){
    if(!window.DGIE_DB?.isConfigured||typeof window.DGIE_DB.marcarNotificacionesPushLeidas!=='function')return;
    const result=await window.DGIE_DB.marcarNotificacionesPushLeidas(null);
    if(result?.error){console.warn('No se pudieron marcar las notificaciones como le\u00eddas',result.error);return}
    state.notifications=[];
    state.inboxOpen=false;
    await setBadge(0);
  }
  async function openNotification(item){
    if(!item)return;
    await markRead(item.kind);
    state.inboxOpen=false;
    renderInboxButton();
    const target=new URL(item.url||'/',window.location.origin);
    window.location.assign(target.href);
  }
  function cerrarInbox(){
    if(!state.inboxOpen)return;
    state.inboxOpen=false;
    renderInboxButton();
  }
  document.addEventListener('click',event=>{
    if(!state.inboxOpen)return;
    if(event.target.closest('#dgie-notifications-panel')||event.target.closest('#dgie-notifications-button'))return;
    cerrarInbox();
  });
  document.addEventListener('keydown',event=>{
    if(event.key==='Escape')cerrarInbox();
  });
  function promptMarkup(){
    const denied=Notification.permission==='denied';
    const title=denied?'Notificaciones bloqueadas':'Recibi avisos en este dispositivo';
    const enabledText=role()==='inspector'
      ?'Te avisaremos por comunicados, reclamos, certificados y comentarios de tu zona.'
      :role()==='empresa'
        ?'Te avisaremos solamente por nuevos comunicados dirigidos a tu empresa.'
        :'Te avisaremos por comunicaciones y respuestas de los inspectores.';
    const text=denied?'Podes habilitarlas desde Ajustes > Notificaciones.':enabledText;
    const button=denied?'':`<button type="button" class="dgie-push-optin-button" onclick="DGIE_PUSH.enable()" ${state.busy?'disabled':''}>${state.busy?'Activando...':'Activar notificaciones'}</button>`;
    return `<div class="dgie-push-optin-copy"><div class="dgie-push-optin-title">${title}</div><div class="dgie-push-optin-text">${text}</div>${state.status?`<div class="dgie-push-optin-status">${String(state.status).replace(/[&<>"']/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]))}</div>`:''}</div>${button}`;
  }
  function renderPrompt(){
    const content=document.getElementById('main-content');
    const existing=document.getElementById('dgie-push-optin');
    if(!content||!user()||!canReceive()||!supported()||state.enabled){
      existing?.remove();
      return;
    }
    const element=existing||document.createElement('div');
    element.id='dgie-push-optin';
    element.className='dgie-push-optin';
    element.setAttribute('role','status');
    element.innerHTML=promptMarkup();
    if(!existing)content.prepend(element);
  }
  const markReadInFlight=new Map();
  const markReadAt=new Map();
  async function markRead(kind){
    if(!ALLOWED_KINDS.has(kind)||!user())return;
    if(!window.DGIE_DB?.isConfigured||typeof window.DGIE_DB.marcarNotificacionesPushLeidas!=='function')return;
    const now=Date.now();
    if(now-Number(markReadAt.get(kind)||0)<15000)return;
    if(markReadInFlight.has(kind))return markReadInFlight.get(kind);
    const request=(async()=>{
      try{
        const result=await window.DGIE_DB.marcarNotificacionesPushLeidas(kind);
        if(result?.error)throw result.error;
        markReadAt.set(kind,Date.now());
        await syncBadge();
        await loadInbox(false);
      }catch(error){
        console.warn('No se pudo actualizar el contador de notificaciones',error);
      }finally{
        markReadInFlight.delete(kind);
      }
    })();
    markReadInFlight.set(kind,request);
    return request;
  }
  function kindForActiveTab(){
    const label=String(document.querySelector('#nav-tabs>.tab.active')?.textContent||'').trim().toLowerCase();
    if(label.includes('comunicaciones'))return 'comunicado';
    if(label.includes('certificacion')||label.includes('certificación'))return 'certificado';
    if(label.includes('intervenciones'))return 'comentario_intervencion';
    if(label.includes('relevamientos'))return 'comentario_relevamiento';
    if(role()==='inspector'&&/^zona\s+\d+/.test(label))return 'reclamo';
    if(label==='reclamos'||label.startsWith('reclamos '))return 'reclamo';
    return '';
  }
  function cleanPushQuery(){
    try{
      const url=new URL(window.location.href);
      url.searchParams.delete('dgiePush');
      url.searchParams.delete('sourceId');
      const query=url.searchParams.toString();
      window.history.replaceState({},'',url.pathname+(query?`?${query}`:'')+url.hash);
    }catch(_){}
  }
  function ensureTargetStyle(){
    if(document.getElementById('dgie-push-target-style'))return;
    const style=document.createElement('style');
    style.id='dgie-push-target-style';
    style.textContent='.dgie-push-target{outline:3px solid #0b74c9!important;outline-offset:3px;background:#eef7ff!important;scroll-margin-block:110px 90px}';
    document.head.appendChild(style);
  }
  function pendingRecord(){
    const sourceId=String(state.pendingSourceId||'');
    const recordId=sourceId.split(':')[0];
    if(!sourceId)return null;
    if(state.pendingKind==='comunicado'){
      const rows=typeof COMUNICACIONES!=='undefined'&&Array.isArray(COMUNICACIONES)?COMUNICACIONES:[];
      return rows.find(item=>String(item?.remoteId||item?.id||'')===recordId)||null;
    }
    if(state.pendingKind==='certificado'){
      const rows=typeof CERTIFICADOS_MEDICION!=='undefined'&&Array.isArray(CERTIFICADOS_MEDICION)?CERTIFICADOS_MEDICION:[];
      return rows.find(item=>String(item?.id||item?.localId||'')===recordId)||null;
    }
    if(state.pendingKind==='comentario_intervencion'){
      const rows=typeof INTERVENCIONES!=='undefined'&&Array.isArray(INTERVENCIONES)?INTERVENCIONES:[];
      return rows.find(item=>String(item?.remoteId||item?.id||'')===recordId)||null;
    }
    if(state.pendingKind==='comentario_relevamiento'){
      const groups=typeof RELEVAMIENTOS!=='undefined'&&RELEVAMIENTOS?RELEVAMIENTOS:{};
      for(const [estId,items] of Object.entries(groups)){
        const record=(Array.isArray(items)?items:[]).find(item=>String(item?.remoteId||item?.id||'')===recordId);
        if(record)return {...record,_dgieEstId:Number(estId)};
      }
      return null;
    }
    const rows=typeof RECLAMOS_ZONA!=='undefined'&&Array.isArray(RECLAMOS_ZONA)?RECLAMOS_ZONA:[];
    return rows.find(item=>String(item?.remoteId||item?.id||'')===recordId)||null;
  }
  function pendingElement(){
    const sourceId=String(state.pendingSourceId||'');
    const recordId=sourceId.split(':')[0];
    if(!sourceId)return null;
    if(state.pendingKind==='comunicado'){
      const direct=document.getElementById(`comm-card-${recordId}`);
      if(direct)return direct;
      const record=pendingRecord();
      const needle=String(record?.titulo||record?.mensaje||'').trim();
      return needle?[...document.querySelectorAll('.comm-card')].find(card=>String(card.textContent||'').includes(needle))||null:null;
    }
    if(state.pendingKind==='certificado'){
      const key=recordId.replace(/[^a-zA-Z0-9_-]/g,'_');
      return [...document.querySelectorAll('[data-cert-card]')].find(card=>card.getAttribute('data-cert-card')===key)||null;
    }
    if(state.pendingKind==='comentario_intervencion'){
      const record=pendingRecord();
      const key=String(record?.id||recordId).replace(/[^a-zA-Z0-9_-]/g,'_');
      return document.querySelector(`[data-int-comentarios="${key}"]`)
        ||document.querySelector(`[data-int-comentarios-paquete] [data-int-comentarios="${key}"]`)
        ||null;
    }
    if(state.pendingKind==='comentario_relevamiento'){
      const record=pendingRecord();
      const base=String(record?.remoteId||record?.id||recordId).replace(/[^a-zA-Z0-9_-]/g,'_');
      const key=`rel_${Number(record?._dgieEstId||record?.establecimiento_id||0)}_${base}`;
      const input=document.getElementById(`rel-comment-${key}`)
        ||document.querySelector(`[id^="rel-resp-${key}-"]`);
      return input?.closest('.intervencion-card')||input?.parentElement||null;
    }
    const direct=[...document.querySelectorAll('[data-dgie-reclamo-id]')].find(row=>row.getAttribute('data-dgie-reclamo-id')===recordId);
    if(direct)return direct;
    const record=pendingRecord();
    const numero=record?(typeof reclamoNumeroVisible==='function'?reclamoNumeroVisible(record):record.numero):'';
    return numero?[...document.querySelectorAll('.reclamo-row')].find(row=>String(row.textContent||'').includes(String(numero)))||null:null;
  }
  function finishPushNavigation(){
    state.focusTimers.forEach(timer=>clearTimeout(timer));
    state.focusTimers=[];
    state.pendingKind='';
    state.pendingSourceId='';
    state.routing=false;
    cleanPushQuery();
  }
  function focusPendingTarget(){
    if(!state.pendingKind||!user())return false;
    if(!state.pendingSourceId){finishPushNavigation();return true}
    const target=pendingElement();
    if(!target)return false;
    ensureTargetStyle();
    target.classList.add('dgie-push-target');
    target.scrollIntoView({behavior:'auto',block:'center',inline:'nearest'});
    const previousTabindex=target.getAttribute('tabindex');
    target.setAttribute('tabindex','-1');
    try{target.focus({preventScroll:true})}catch(_){target.focus()}
    setTimeout(()=>{
      target.classList.remove('dgie-push-target');
      if(previousTabindex===null)target.removeAttribute('tabindex');
      else target.setAttribute('tabindex',previousTabindex);
    },10000);
    finishPushNavigation();
    return true;
  }
  function schedulePushFocus(){
    state.focusTimers.forEach(timer=>clearTimeout(timer));
    state.focusTimers=[];
    const waits=[0,250,700,1500,3000,5500,8500];
    waits.forEach((delay,index)=>{
      const timer=setTimeout(()=>{
        if(!state.pendingKind)return;
        if(focusPendingTarget())return;
        if(index===waits.length-1)state.routing=false;
      },delay);
      state.focusTimers.push(timer);
    });
  }
  function navigateFromPush(){
    const kind=state.pendingKind;
    if(!kind||!user()||state.routing)return;
    const tabs=Array.from(document.querySelectorAll('#nav-tabs>.tab'));
    const index=tabs.findIndex(tab=>{
      const label=String(tab.textContent||'').trim().toLowerCase();
      if(kind==='comunicado')return label.includes('comunicaciones');
      if(kind==='certificado')return label.includes('certificacion')||label.includes('certificación');
      if(kind==='comentario_intervencion')return label.includes('intervenciones');
      if(kind==='comentario_relevamiento')return label.includes('relevamientos');
      if(role()==='inspector')return /^zona\s+\d+/.test(label);
      return label==='reclamos'||label.startsWith('reclamos ');
    });
    if(index<0)return;
    state.routing=true;
    if(typeof window.renderTab==='function')window.renderTab(index);
    if(kind==='comentario_intervencion'){
      setTimeout(()=>{
        const record=pendingRecord();
        if(record&&typeof window.verDetalleIntervencion==='function')window.verDetalleIntervencion(record.id);
        schedulePushFocus();
      },120);
    }else if(kind==='comunicado'){
      setTimeout(()=>{
        const record=pendingRecord();
        const id=String(record?.remoteId||record?.id||state.pendingSourceId.split(':')[0]||'');
        if(id&&window.DGIE_COMUNICACIONES_PRO?.state){
          window.DGIE_COMUNICACIONES_PRO.state.selectedId=id;
          window.DGIE_COMUNICACIONES_PRO.render?.();
        }
        schedulePushFocus();
      },120);
    }else{
      schedulePushFocus();
    }
  }
  function attr(value){
    return String(value??'').replace(/[&<>"']/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
  }
  const previousRowReclamo=window.rowReclamo;
  if(typeof previousRowReclamo==='function'){
    window.rowReclamo=function(reclamo){
      const html=previousRowReclamo.apply(this,arguments);
      const id=String(reclamo?.remoteId||reclamo?.id||'');
      if(!id||String(html).includes('data-dgie-reclamo-id='))return html;
      return String(html).replace('class="reclamo-row"',`class="reclamo-row" data-dgie-reclamo-id="${attr(id)}"`);
    };
  }
  async function dispatch(kind,sourceId){
    if(!ALLOWED_KINDS.has(kind)||!sourceId||!window.DGIE_DB?.isConfigured)return;
    const dispatchKey=`${kind}:${sourceId}`;
    const startedAt=Date.now();
    if(startedAt-Number(state.recentDispatches.get(dispatchKey)||0)<30000)return;
    state.recentDispatches.set(dispatchKey,startedAt);
    setTimeout(()=>{
      if(state.recentDispatches.get(dispatchKey)===startedAt)state.recentDispatches.delete(dispatchKey);
    },30000);
    const waits=[0,1200,3500];
    let lastError=null;
    for(let attempt=0;attempt<waits.length;attempt++){
      if(waits[attempt])await new Promise(resolve=>setTimeout(resolve,waits[attempt]));
      try{
        const tokenResult=await window.DGIE_DB.tokenAccesoPush?.();
        const token=tokenResult?.data;
        if(!token)throw new Error('La sesion no tiene un token valido.');
        const response=await fetch(DISPATCH_URL,{
          method:'POST',
          headers:{'Content-Type':'application/json','Authorization':`Bearer ${token}`},
          body:JSON.stringify({kind,sourceId:String(sourceId)}),
          keepalive:true
        });
        if(response.ok)return await response.json().catch(()=>({ok:true}));
        const detail=await response.json().catch(()=>({}));
        const error=new Error(detail?.error||`Error ${response.status}`);
        error.status=response.status;
        if(response.status>=400&&response.status<500&&response.status!==429)throw error;
        lastError=error;
      }catch(error){
        lastError=error;
        if(Number(error?.status)>=400&&Number(error?.status)<500&&Number(error?.status)!==429)break;
      }
    }
    console.warn('El registro se guardo, pero la notificacion quedo pendiente de reintento',lastError);
    return {ok:false,pending:true};
  }
  function onUserLoaded(nextUser){
    state.user=nextUser||user();
    setTimeout(()=>{
      renderPrompt();
      ensureInbox();
      syncBadge().catch(error=>console.warn('No se pudo actualizar el contador de notificaciones',error));
      loadInbox(false);
      navigateFromPush();
      if(canReceive()&&supported()&&Notification.permission==='granted')ensureSubscription().catch(error=>{
        state.status=String(error?.message||'No se pudo actualizar la suscripcion.');
        renderPrompt();
      });
    },500);
  }

  window.DGIE_PUSH={enable,disable,dispatch,markRead,syncBadge,supported};

  const previousLoadUser=window.loadUser;
  if(typeof previousLoadUser==='function'){
    window.loadUser=function(nextUser){
      const result=previousLoadUser.apply(this,arguments);
      onUserLoaded(nextUser);
      return result;
    };
  }
  const previousRenderTab=window.renderTab;
  if(typeof previousRenderTab==='function'){
    window.renderTab=function(){
      const result=previousRenderTab.apply(this,arguments);
      setTimeout(()=>{
        renderPrompt();
        const kind=kindForActiveTab();
        if(kind)markRead(kind);
        if(state.pendingKind&&!focusPendingTarget()&&!state.routing)navigateFromPush();
      },0);
      return result;
    };
  }
  const previousLogout=window.doLogout;
  if(typeof previousLogout==='function'){
    window.doLogout=async function(){
      await setBadge(0);
      state.user=null;
      return previousLogout.apply(this,arguments);
    };
  }

  navigator.serviceWorker?.addEventListener('message',event=>{
    if(event.data?.type==='DGIE_PUSH_BADGE')setBadge(event.data.count);
  });
  document.addEventListener('DOMContentLoaded',()=>{
    registerWorker().then(()=>{
      if(user())onUserLoaded(user());
    }).catch(error=>console.warn('No se pudo iniciar el receptor de notificaciones',error));
  },{once:true});
})();
