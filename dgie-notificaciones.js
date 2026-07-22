(function(){
  'use strict';

  const PUBLIC_KEY='BImxVQUuI8gXsAJ50jH_pK8KwLeVPEkGlFpWR2DMHhThZl5JKLDpjoSUGgCLIKu4c8VPj7Y5NYXJEQwjUljkj3w';
  const WORKER_URL='/service-worker.js';
  const DISPATCH_URL='/api/push/dispatch';
  const state={registration:null,user:null,busy:false,enabled:false,status:'',pendingKind:''};

  try{
    const params=new URLSearchParams(window.location.search);
    const kind=params.get('dgiePush');
    if(['comunicado','reclamo'].includes(kind))state.pendingKind=kind;
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
    try{
      if(value>0&&'setAppBadge' in navigator)await navigator.setAppBadge(value);
      else if(value===0&&'clearAppBadge' in navigator)await navigator.clearAppBadge();
    }catch(_){}
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
  function promptMarkup(){
    const denied=Notification.permission==='denied';
    const title=denied?'Notificaciones bloqueadas':'Recibi avisos en este dispositivo';
    const enabledText=role()==='inspector'
      ?'Te avisaremos solamente por nuevos comunicados y reclamos de tu zona.'
      :role()==='empresa'
        ?'Te avisaremos solamente por nuevos comunicados dirigidos a tu empresa.'
        :'Te avisaremos cuando un inspector envie una comunicacion con copia.';
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
  async function markRead(kind){
    if(!['comunicado','reclamo'].includes(kind)||!user())return;
    if(!window.DGIE_DB?.isConfigured||typeof window.DGIE_DB.marcarNotificacionesPushLeidas!=='function')return;
    try{
      const result=await window.DGIE_DB.marcarNotificacionesPushLeidas(kind);
      if(result?.error)throw result.error;
      await syncBadge();
    }catch(error){
      console.warn('No se pudo actualizar el contador de notificaciones',error);
    }
  }
  function kindForActiveTab(){
    const label=String(document.querySelector('#nav-tabs>.tab.active')?.textContent||'').trim().toLowerCase();
    if(label.includes('comunicaciones'))return 'comunicado';
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
  function navigateFromPush(){
    const kind=state.pendingKind;
    if(!kind||!user())return;
    const tabs=Array.from(document.querySelectorAll('#nav-tabs>.tab'));
    const index=tabs.findIndex(tab=>{
      const label=String(tab.textContent||'').trim().toLowerCase();
      if(kind==='comunicado')return label.includes('comunicaciones');
      if(role()==='inspector')return /^zona\s+\d+/.test(label);
      return label==='reclamos'||label.startsWith('reclamos ');
    });
    if(index<0)return;
    state.pendingKind='';
    if(typeof window.renderTab==='function')window.renderTab(index);
    cleanPushQuery();
  }
  async function dispatch(kind,sourceId){
    if(!['comunicado','reclamo'].includes(kind)||!sourceId||!window.DGIE_DB?.isConfigured)return;
    try{
      const tokenResult=await window.DGIE_DB.tokenAccesoPush?.();
      const token=tokenResult?.data;
      if(!token)return;
      const response=await fetch(DISPATCH_URL,{
        method:'POST',
        headers:{'Content-Type':'application/json','Authorization':`Bearer ${token}`},
        body:JSON.stringify({kind,sourceId:String(sourceId)}),
        keepalive:true
      });
      if(!response.ok){
        const detail=await response.json().catch(()=>({}));
        throw new Error(detail?.error||`Error ${response.status}`);
      }
    }catch(error){
      console.warn('El registro se guardo, pero no se pudo emitir su notificacion',error);
    }
  }
  function onUserLoaded(nextUser){
    state.user=nextUser||user();
    setTimeout(()=>{
      renderPrompt();
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
      },0);
      return result;
    };
  }
  const previousLogout=window.doLogout;
  if(typeof previousLogout==='function'){
    window.doLogout=async function(){
      await disable();
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
