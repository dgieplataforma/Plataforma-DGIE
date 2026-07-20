(function(){
  'use strict';

  const ESTADO_PENDIENTE='pendiente';
  const ESTADO_DEVUELTO='devuelto';
  const ESTADO_MEDIDO='medido';
  const tabsActivas={inspector:ESTADO_PENDIENTE,empresa:ESTADO_PENDIENTE};

  function usuario(){
    try{return currentUser||null}catch(_){return window.currentUser||null}
  }
  function esc(value){
    return String(value??'').replace(/[&<>"']/g,char=>({
      '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'
    })[char]);
  }
  function numero(value){
    return Number(String(value??'').replace(',','.'))||0;
  }
  function modulos(value){
    return numero(value).toLocaleString('es-AR',{
      minimumFractionDigits:3,
      maximumFractionDigits:3
    });
  }
  function estadoFlujo(certificado){
    const estado=String(certificado?.estado||ESTADO_PENDIENTE).toLowerCase();
    if(estado===ESTADO_MEDIDO)return ESTADO_MEDIDO;
    if(estado===ESTADO_DEVUELTO)return ESTADO_DEVUELTO;
    return ESTADO_PENDIENTE;
  }
  function idCertificado(certificado){
    return certificado?.id??certificado?.localId??'';
  }
  function claveCertificado(certificado){
    return String(
      certificado?.id||
      certificado?.localId||
      `${certificado?.zona||''}-${certificado?.establecimiento_id||''}-${certificado?.archivo_original||''}-${certificado?.created_at||''}`
    ).replace(/[^a-zA-Z0-9_-]/g,'_');
  }
  function certificados(){
    return Array.isArray(window.CERTIFICADOS_MEDICION)?window.CERTIFICADOS_MEDICION:[];
  }
  function certificadoPorId(id){
    return certificados().find(certificado=>
      String(certificado?.id)===String(id)||
      String(certificado?.localId)===String(id)||
      claveCertificado(certificado)===String(id)
    );
  }
  function zonaCertificado(certificado){
    const directa=Number(certificado?.zona);
    if(directa)return directa;
    try{
      return typeof zonaEstablecimiento==='function'
        ? Number(zonaEstablecimiento(certificado?.establecimiento_id)||0)
        : 0;
    }catch(_){
      return 0;
    }
  }
  function certificadosZona(zona){
    return certificados().filter(certificado=>
      String(certificado?.estado||'')!=='eliminado'&&
      Number(zonaCertificado(certificado))===Number(zona)
    );
  }
  function limpiarObservacion(value){
    if(typeof window.limpiarObsCert==='function')return window.limpiarObsCert(value);
    return String(value||'').replace(/\s*\[[A-Z_]+:[^\]]*\]/g,'').trim();
  }
  function conversaciones(certificado){
    if(typeof window.conversacionCert==='function'){
      const items=window.conversacionCert(certificado);
      return Array.isArray(items)?items:[];
    }
    return Array.isArray(certificado?.conversacion)?certificado.conversacion:[];
  }
  function etiquetasTecnicas(value,opciones={}){
    const permitidas=opciones.empresa
      ? ['RUBRO_CERT','RUBROS_CERT']
      : ['OS_CERT','RUBRO_CERT','RUBROS_CERT','ARCHIVO_RENOMBRE'];
    const patron=new RegExp(`\\[(?:${permitidas.join('|')}):[^\\]]*\\]`,'g');
    return [...new Set(String(value||'').match(patron)||[])];
  }
  function observacionConConversacion(texto,etiquetas,mensajes){
    const base=[String(texto||'').trim(),...(etiquetas||[])].filter(Boolean).join('\n');
    if(typeof window.obsConConversacion==='function'){
      return window.obsConConversacion(base,mensajes);
    }
    return [base,`[CONV_CERT:${encodeURIComponent(JSON.stringify(mensajes||[]))}]`]
      .filter(Boolean)
      .join('\n');
  }
  function motivoDevolucion(certificado){
    const mensajes=conversaciones(certificado);
    for(let index=mensajes.length-1;index>=0;index--){
      const mensaje=mensajes[index]||{};
      if(String(mensaje.tipo||'')==='devolucion'){
        return String(mensaje.motivo||mensaje.texto||'').replace(/^Devoluci[oó]n:\s*/i,'').trim();
      }
    }
    return limpiarObservacion(certificado?.observaciones_inspector)||'No se registró un motivo.';
  }
  function fecha(value){
    if(!value)return '';
    try{
      return new Date(value).toLocaleString('es-AR',{
        day:'2-digit',
        month:'2-digit',
        year:'numeric',
        hour:'2-digit',
        minute:'2-digit'
      });
    }catch(_){
      return '';
    }
  }
  function enlaceOriginal(certificado){
    const nombre=esc(certificado?.archivo_original||'Archivo certificado');
    return certificado?.url_original
      ? `<a href="${esc(certificado.url_original)}" target="_blank" rel="noopener">${nombre}</a>`
      : nombre;
  }
  function mensajeError(error,accion){
    const detalle=String(error?.message||error||'').trim();
    if(/row-level security|permission denied|not authorized/i.test(detalle)){
      return `No tenés permisos para ${accion}. Actualizá la página y volvé a intentarlo.`;
    }
    if(/check constraint|23514|estado/i.test(detalle)){
      return `No se pudo ${accion} porque falta habilitar el estado “Devuelto” en la base de datos.`;
    }
    return `No se pudo ${accion}.${detalle?` Detalle: ${detalle}`:''}`;
  }
  async function actualizarConCompatibilidad(id,patch){
    if(typeof window.actualizarCertificado!=='function'){
      throw new Error('El servicio de certificados no está disponible.');
    }
    try{
      await window.actualizarCertificado(id,patch);
    }catch(error){
      const detalle=String(error?.message||error||'');
      if(Object.prototype.hasOwnProperty.call(patch,'conversacion')&&
        /conversacion|schema cache|column/i.test(detalle)){
        const compatible={...patch};
        delete compatible.conversacion;
        await window.actualizarCertificado(id,compatible);
        return;
      }
      throw error;
    }
  }
  function hijoDirectoClase(elemento,clase){
    return [...(elemento?.children||[])].find(hijo=>hijo.classList?.contains(clase))||null;
  }
  function tituloDirecto(tarjeta){
    const cabecera=hijoDirectoClase(tarjeta,'card-header');
    return cabecera?.querySelector('.card-title')?.textContent?.trim()||'';
  }
  function boton(texto,clases,accion){
    const elemento=document.createElement('button');
    elemento.type='button';
    elemento.className=clases;
    elemento.textContent=texto;
    elemento.dataset.certWorkflowAction='1';
    elemento.addEventListener('click',accion);
    return elemento;
  }
  function actualizarBadgeEstado(acciones,estado){
    const badge=[...(acciones?.children||[])].find(elemento=>elemento.classList?.contains('badge'));
    if(!badge)return;
    badge.classList.remove('b-info','b-warn','b-ok','b-danger','b-neutral');
    if(estado===ESTADO_DEVUELTO){
      badge.classList.add('b-danger');
      badge.textContent='Devuelto';
    }else{
      badge.classList.add('b-info');
      badge.textContent='Pendiente';
    }
  }
  function insertarAntesDeEliminar(acciones,elemento){
    const eliminar=[...(acciones?.querySelectorAll('button')||[])]
      .find(item=>item.textContent.trim()==='Eliminar');
    acciones.insertBefore(elemento,eliminar||null);
  }
  function mejorarTarjeta(tarjeta,certificado,rol){
    if(!tarjeta||!certificado)return;
    const estado=estadoFlujo(certificado);
    tarjeta.dataset.certCard=claveCertificado(certificado);
    tarjeta.dataset.certId=String(idCertificado(certificado));
    tarjeta.dataset.certEstado=estado;

    tarjeta.querySelectorAll('[data-cert-workflow-action]').forEach(elemento=>elemento.remove());
    tarjeta.querySelectorAll('.dgie-cert-return-banner').forEach(elemento=>elemento.remove());
    const acciones=hijoDirectoClase(tarjeta,'med-actions');
    if(!acciones)return;

    [...acciones.querySelectorAll('button')].forEach(elemento=>{
      if(elemento.textContent.trim()==='Gestionar')elemento.remove();
    });
    actualizarBadgeEstado(acciones,estado);

    if(estado===ESTADO_DEVUELTO){
      const meta=hijoDirectoClase(tarjeta,'med-card-meta');
      const aviso=document.createElement('div');
      aviso.className='dgie-cert-return-banner';
      aviso.innerHTML=`<strong>Motivo de devolución</strong><span>${esc(motivoDevolucion(certificado))}</span>`;
      if(meta)meta.insertAdjacentElement('afterend',aviso);

      if(rol==='empresa'){
        insertarAntesDeEliminar(
          acciones,
          boton('Corregir y reenviar','primary-btn',()=>window.abrirReenvioCertificado(idCertificado(certificado)))
        );
      }else{
        const espera=document.createElement('span');
        espera.className='dgie-cert-waiting';
        espera.dataset.certWorkflowAction='1';
        espera.textContent='Esperando corrección de la empresa';
        insertarAntesDeEliminar(acciones,espera);
      }
      return;
    }

    if(rol==='inspector'){
      insertarAntesDeEliminar(
        acciones,
        boton(
          'Devolver',
          'secondary-btn dgie-cert-action-return',
          ()=>window.abrirDevolucionCertificado(idCertificado(certificado))
        )
      );
      insertarAntesDeEliminar(
        acciones,
        boton(
          'Pasar a medición',
          'primary-btn',
          ()=>window.revisarCertificadoInspector(idCertificado(certificado))
        )
      );
    }
  }
  function tarjetasCola(contenedor){
    const directas=[];
    [...(contenedor?.children||[])].forEach(hijo=>{
      [...(hijo?.children||[])].forEach(nieto=>{
        if(nieto.classList?.contains('med-card')&&hijoDirectoClase(nieto,'med-card-title')){
          directas.push(nieto);
        }
      });
    });
    return directas;
  }
  function crearVacio(texto){
    const vacio=document.createElement('div');
    vacio.className='dgie-cert-empty';
    vacio.textContent=texto;
    return vacio;
  }
  function claveTab(rol){
    const zona=Number(usuario()?.zona||0);
    return `dgie_certificacion_tab_${rol}_${zona}`;
  }
  function leerTab(rol){
    try{
      const guardada=sessionStorage.getItem(claveTab(rol));
      if([ESTADO_PENDIENTE,ESTADO_DEVUELTO].includes(guardada))return guardada;
    }catch(_){}
    return tabsActivas[rol]||ESTADO_PENDIENTE;
  }
  function guardarTab(rol,tab){
    tabsActivas[rol]=tab;
    try{sessionStorage.setItem(claveTab(rol),tab)}catch(_){}
  }
  function aplicarTab(rol,tab){
    if(![ESTADO_PENDIENTE,ESTADO_DEVUELTO].includes(tab))return;
    guardarTab(rol,tab);
    document.querySelectorAll(`.dgie-cert-queue[data-cert-role="${rol}"]`).forEach(cola=>{
      cola.querySelectorAll('.dgie-cert-queue-tab').forEach(control=>{
        control.setAttribute('aria-selected',String(control.dataset.tab===tab));
        control.tabIndex=control.dataset.tab===tab?0:-1;
      });
      cola.querySelectorAll('.dgie-cert-queue-panel').forEach(panel=>{
        panel.hidden=panel.dataset.tab!==tab;
      });
    });
  }
  window.cambiarPestanaCertificados=function(rol,tab){
    aplicarTab(String(rol||''),String(tab||''));
  };
  function armarCola(contenedor,rol,filas){
    if(!contenedor)return;
    if(contenedor.dataset.certWorkflow==='1'){
      contenedor.querySelectorAll('[data-cert-card]').forEach(tarjeta=>{
        mejorarTarjeta(tarjeta,certificadoPorId(tarjeta.dataset.certCard),rol);
      });
      aplicarTab(rol,leerTab(rol));
      return;
    }

    const tarjetas=tarjetasCola(contenedor);
    const filasCola=(filas||[]).filter(certificado=>estadoFlujo(certificado)!==ESTADO_MEDIDO);
    const porClave=new Map(filasCola.map(certificado=>[claveCertificado(certificado),certificado]));
    const pendientes=[];
    const devueltos=[];
    const filasVisibles=[];

    tarjetas.forEach((tarjeta,index)=>{
      const clave=tarjeta.dataset.certCard||'';
      const certificado=porClave.get(clave)||filasCola[index]||null;
      if(!certificado)return;
      filasVisibles.push(certificado);
      mejorarTarjeta(tarjeta,certificado,rol);
      const item={tarjeta,certificado};
      if(estadoFlujo(certificado)===ESTADO_DEVUELTO)devueltos.push(item);
      else pendientes.push(item);
    });
    const porActividad=(a,b)=>{
      const fechaA=new Date(a.certificado?.updated_at||a.certificado?.created_at||0).getTime()||0;
      const fechaB=new Date(b.certificado?.updated_at||b.certificado?.created_at||0).getTime()||0;
      return fechaB-fechaA;
    };
    pendientes.sort(porActividad);
    devueltos.sort(porActividad);

    const totalModulos=filasVisibles.reduce((total,certificado)=>total+numero(certificado?.modulos_original),0);
    const titulo=rol==='empresa'?'Seguimiento de certificados':'Certificados recibidos';
    const descripcion=rol==='empresa'
      ? 'Corregí y reenviá los certificados devueltos. Los pendientes están siendo revisados por el inspector.'
      : `Los pendientes requieren devolver o pasar a medición. ${modulos(totalModulos)} módulos de empresa en esta cola.`;

    const cabecera=document.createElement('div');
    cabecera.className='dgie-cert-queue-header';
    cabecera.innerHTML=`<div class="dgie-cert-queue-copy"><div class="card-title">${titulo}</div><p>${esc(descripcion)}</p></div>
      <div class="dgie-cert-queue-tabs" role="tablist" aria-label="Estado de certificados">
        <button type="button" class="dgie-cert-queue-tab" role="tab" data-tab="${ESTADO_PENDIENTE}">
          Pendientes <span class="dgie-cert-tab-count">${pendientes.length}</span>
        </button>
        <button type="button" class="dgie-cert-queue-tab" role="tab" data-tab="${ESTADO_DEVUELTO}">
          Devueltos <span class="dgie-cert-tab-count">${devueltos.length}</span>
        </button>
      </div>`;
    const panelPendientes=document.createElement('div');
    panelPendientes.className='dgie-cert-queue-panel';
    panelPendientes.dataset.tab=ESTADO_PENDIENTE;
    panelPendientes.setAttribute('role','tabpanel');
    if(pendientes.length)pendientes.forEach(item=>panelPendientes.appendChild(item.tarjeta));
    else panelPendientes.appendChild(crearVacio('No hay certificados pendientes para los filtros seleccionados.'));

    const panelDevueltos=document.createElement('div');
    panelDevueltos.className='dgie-cert-queue-panel';
    panelDevueltos.dataset.tab=ESTADO_DEVUELTO;
    panelDevueltos.setAttribute('role','tabpanel');
    if(devueltos.length)devueltos.forEach(item=>panelDevueltos.appendChild(item.tarjeta));
    else panelDevueltos.appendChild(crearVacio(
      rol==='empresa'
        ? 'No hay certificados devueltos que requieran corrección.'
        : 'No hay certificados devueltos para los filtros seleccionados.'
    ));

    contenedor.replaceChildren(cabecera,panelPendientes,panelDevueltos);
    contenedor.dataset.certWorkflow='1';
    contenedor.classList.add('dgie-cert-queue');
    contenedor.dataset.certRole=rol;
    cabecera.querySelectorAll('.dgie-cert-queue-tab').forEach(control=>{
      control.addEventListener('click',()=>aplicarTab(rol,control.dataset.tab));
    });

    let activa=leerTab(rol);
    if(activa===ESTADO_PENDIENTE&&!pendientes.length&&devueltos.length)activa=ESTADO_DEVUELTO;
    if(activa===ESTADO_DEVUELTO&&!devueltos.length&&pendientes.length)activa=ESTADO_PENDIENTE;
    aplicarTab(rol,activa);
  }
  function buscarCola(raiz){
    return [...(raiz?.querySelectorAll('.med-card')||[])]
      .find(tarjeta=>/^Certificados pendientes$/i.test(tituloDirecto(tarjeta)))||null;
  }
  function mejorarVistaInspector(){
    const lista=document.getElementById('med-list');
    if(!lista)return;
    const cola=buscarCola(lista);
    const zona=Number(usuario()?.zona||0);
    armarCola(cola,'inspector',certificadosZona(zona));
  }
  function mejorarVistaEmpresa(){
    const principal=document.getElementById('main-content');
    if(!principal)return;
    const cola=buscarCola(principal);
    const zona=Number(usuario()?.zona||0);
    armarCola(cola,'empresa',certificadosZona(zona));

    [...principal.querySelectorAll('.card-title')].forEach(titulo=>{
      if(titulo.textContent.trim()!=='Seguimiento')return;
      const subtitulo=titulo.parentElement?.querySelector('div[style*="font-size:13px"]');
      if(subtitulo)subtitulo.textContent='Consultá el estado y corregí los certificados que fueron devueltos.';
    });
  }
  function mejorarFormularioMedicion(){
    const archivo=document.getElementById('insp-cert-file');
    const tarjeta=archivo?.closest('.card');
    if(!tarjeta)return;
    const etiqueta=document.querySelector('#main-content > .section-label');
    if(etiqueta)etiqueta.textContent='Inspector · Pasar certificado a medición';
    if(!tarjeta.querySelector('.dgie-cert-flow-intro')){
      const cabecera=hijoDirectoClase(tarjeta,'card-header');
      const aviso=document.createElement('div');
      aviso.className='dgie-cert-flow-intro';
      aviso.textContent='Completá la versión corregida, la orden de servicio y el número de medición. Para solicitar una corrección a la empresa, usá “Devolver a empresa”.';
      cabecera?.insertAdjacentElement('afterend',aviso);
    }
    const observaciones=document.getElementById('insp-cert-obs');
    const label=observaciones?.closest('.form-field')?.querySelector('.form-label');
    if(label)label.textContent='Observaciones de la medición';
    const acciones=hijoDirectoClase(tarjeta,'modal-actions');
    [...(acciones?.querySelectorAll('button')||[])].forEach(control=>{
      if(/guardar revisión/i.test(control.textContent)){
        control.textContent='Devolver a empresa';
        control.classList.add('dgie-cert-action-return');
      }
      if(/guardar y pasar a medición/i.test(control.textContent)){
        control.textContent='Pasar a medición';
      }
    });
  }
  async function volverAListado(rol,tab){
    guardarTab(rol,tab);
    const principal=document.getElementById('main-content');
    const zona=Number(usuario()?.zona||0);
    if(rol==='empresa'&&typeof window.renderMedicionesEmpresa==='function'){
      await window.renderMedicionesEmpresa(principal,zona);
    }else if(typeof window.renderMedicionesInspector==='function'){
      await window.renderMedicionesInspector(principal,zona);
    }
  }
  function resumenCertificado(certificado){
    return `<div class="dgie-cert-flow-summary">
      <div><span class="dgie-cert-flow-kicker">Establecimiento</span><div class="dgie-cert-flow-value">${esc(certificado?.establecimiento_nombre||'Sin establecimiento')}</div></div>
      <div><span class="dgie-cert-flow-kicker">Módulos informados</span><div class="dgie-cert-flow-value">${modulos(certificado?.modulos_original)}</div></div>
      <div><span class="dgie-cert-flow-kicker">Archivo vigente</span><div class="dgie-cert-flow-value">${enlaceOriginal(certificado)}</div></div>
      <div><span class="dgie-cert-flow-kicker">Última actualización</span><div class="dgie-cert-flow-value">${esc(fecha(certificado?.updated_at||certificado?.created_at)||'Sin fecha')}</div></div>
    </div>`;
  }
  window.abrirDevolucionCertificado=function(id){
    const certificado=certificadoPorId(id);
    const principal=document.getElementById('main-content');
    if(!certificado||!principal||usuario()?.role!=='inspector')return;
    if(Number(zonaCertificado(certificado))!==Number(usuario()?.zona||0))return;
    if(estadoFlujo(certificado)===ESTADO_MEDIDO){
      alert('El certificado ya pertenece a una medición.');
      return;
    }
    principal.innerHTML=`<div class="section-label">Inspector · Devolver certificado</div>
      <div class="card">
        <button type="button" class="back-btn" id="dgie-cert-return-back">‹ Volver a certificación</button>
        <div class="card-header">
          <div><div class="card-title">Solicitar corrección a la empresa</div><div style="font-size:13px;color:var(--muted);margin-top:4px">El certificado pasará a Devueltos y la empresa deberá reemplazar el archivo para reenviarlo.</div></div>
          <span class="badge b-danger">Devuelto</span>
        </div>
        ${resumenCertificado(certificado)}
        <div class="form-field">
          <label class="form-label" for="dgie-cert-return-reason">Motivo de devolución *</label>
          <textarea class="form-textarea" id="dgie-cert-return-reason" rows="5" maxlength="1500" placeholder="Indicá con precisión qué debe corregir la empresa."></textarea>
          <div class="dgie-cert-required-note">Este motivo quedará visible en el historial del certificado.</div>
          <div class="dgie-cert-inline-error" id="dgie-cert-return-error">Escribí un motivo de al menos 5 caracteres.</div>
        </div>
        <div class="modal-actions">
          <span class="dgie-cert-submit-status" id="dgie-cert-return-status" role="status" aria-live="polite"></span>
          <button type="button" class="secondary-btn" id="dgie-cert-return-cancel">Cancelar</button>
          <button type="button" class="primary-btn dgie-cert-action-return" id="dgie-cert-return-submit">Confirmar devolución</button>
        </div>
      </div>`;
    const volver=()=>volverAListado('inspector',ESTADO_PENDIENTE);
    document.getElementById('dgie-cert-return-back')?.addEventListener('click',volver);
    document.getElementById('dgie-cert-return-cancel')?.addEventListener('click',volver);
    document.getElementById('dgie-cert-return-submit')?.addEventListener('click',()=>window.confirmarDevolucionCertificado(id));
    document.getElementById('dgie-cert-return-reason')?.focus();
  };
  window.confirmarDevolucionCertificado=async function(id){
    const certificado=certificadoPorId(id);
    const motivo=(document.getElementById('dgie-cert-return-reason')?.value||'').trim();
    const error=document.getElementById('dgie-cert-return-error');
    const estado=document.getElementById('dgie-cert-return-status');
    const enviar=document.getElementById('dgie-cert-return-submit');
    if(!certificado||usuario()?.role!=='inspector')return;
    if(Number(zonaCertificado(certificado))!==Number(usuario()?.zona||0))return;
    if(motivo.length<5){
      error?.classList.add('is-visible');
      document.getElementById('dgie-cert-return-reason')?.focus();
      return;
    }
    error?.classList.remove('is-visible');
    if(enviar)enviar.disabled=true;
    if(estado)estado.textContent='Guardando devolución...';

    const mensajes=conversaciones(certificado).slice();
    mensajes.push({
      tipo:'devolucion',
      motivo,
      texto:`Devolución: ${motivo}`,
      autor:usuario()?.name||'Inspector',
      rol:'inspector',
      fecha:new Date().toISOString()
    });
    const observaciones=observacionConConversacion(
      motivo,
      etiquetasTecnicas(certificado?.observaciones_inspector),
      mensajes
    );
    const patch={
      estado:ESTADO_DEVUELTO,
      medicion_numero:null,
      periodo:null,
      grupo_finalizado:false,
      observaciones_inspector:observaciones,
      conversacion:mensajes,
      actualizado_por:usuario()?.name||'Inspector'
    };
    try{
      await actualizarConCompatibilidad(id,patch);
      if(estado)estado.textContent='Devuelto correctamente.';
      await volverAListado('inspector',ESTADO_DEVUELTO);
    }catch(excepcion){
      if(estado)estado.textContent='';
      alert(mensajeError(excepcion,'devolver el certificado'));
      if(enviar)enviar.disabled=false;
    }
  };
  window.abrirReenvioCertificado=function(id){
    const certificado=certificadoPorId(id);
    const principal=document.getElementById('main-content');
    if(!certificado||!principal||usuario()?.role!=='empresa')return;
    if(Number(zonaCertificado(certificado))!==Number(usuario()?.zona||0))return;
    if(estadoFlujo(certificado)!==ESTADO_DEVUELTO){
      alert('Este certificado ya no está pendiente de corrección.');
      return;
    }
    principal.innerHTML=`<div class="section-label">Empresa · Corregir certificado</div>
      <div class="card">
        <button type="button" class="back-btn" id="dgie-cert-resubmit-back">‹ Volver a certificación</button>
        <div class="card-header">
          <div><div class="card-title">Corregir y reenviar</div><div style="font-size:13px;color:var(--muted);margin-top:4px">El archivo corregido reemplazará la versión vigente y volverá a Pendientes.</div></div>
          <span class="badge b-danger">Requiere corrección</span>
        </div>
        ${resumenCertificado(certificado)}
        <div class="dgie-cert-return-reason"><strong>Motivo indicado por el inspector</strong><p>${esc(motivoDevolucion(certificado))}</p></div>
        <div class="form-grid">
          <div class="form-field full">
            <label class="form-label" for="dgie-cert-resubmit-file">Certificado Excel corregido *</label>
            <input class="form-input" id="dgie-cert-resubmit-file" type="file" accept=".xls,.xlsx">
            <div class="dgie-cert-required-note">Tamaño máximo: 5 MB.</div>
          </div>
          <div class="form-field">
            <label class="form-label" for="dgie-cert-resubmit-modules">Módulos</label>
            <input class="form-input" id="dgie-cert-resubmit-modules" type="number" step="0.001" readonly placeholder="Se completa al seleccionar el archivo">
          </div>
          <div class="form-field full">
            <label class="form-label" for="dgie-cert-resubmit-detail">Corrección realizada *</label>
            <textarea class="form-textarea" id="dgie-cert-resubmit-detail" rows="4" maxlength="1500" placeholder="Explicá brevemente qué se corrigió."></textarea>
            <div class="dgie-cert-inline-error" id="dgie-cert-resubmit-error">Seleccioná el archivo corregido y explicá la corrección realizada.</div>
          </div>
        </div>
        <div class="modal-actions">
          <span class="dgie-cert-submit-status" id="dgie-cert-resubmit-status" role="status" aria-live="polite"></span>
          <button type="button" class="secondary-btn" id="dgie-cert-resubmit-cancel">Cancelar</button>
          <button type="button" class="primary-btn" id="dgie-cert-resubmit-submit">Reenviar certificado</button>
        </div>
      </div>`;
    const volver=()=>volverAListado('empresa',ESTADO_DEVUELTO);
    document.getElementById('dgie-cert-resubmit-back')?.addEventListener('click',volver);
    document.getElementById('dgie-cert-resubmit-cancel')?.addEventListener('click',volver);
    document.getElementById('dgie-cert-resubmit-file')?.addEventListener('change',()=>{
      if(typeof window.validarYAutocompletarCertificado==='function'){
        window.validarYAutocompletarCertificado('dgie-cert-resubmit-file','dgie-cert-resubmit-modules');
      }
    });
    document.getElementById('dgie-cert-resubmit-submit')?.addEventListener('click',()=>window.confirmarReenvioCertificado(id));
  };
  window.confirmarReenvioCertificado=async function(id){
    const certificado=certificadoPorId(id);
    const archivo=document.getElementById('dgie-cert-resubmit-file')?.files?.[0];
    const modulosCorregidos=numero(document.getElementById('dgie-cert-resubmit-modules')?.value);
    const detalle=(document.getElementById('dgie-cert-resubmit-detail')?.value||'').trim();
    const error=document.getElementById('dgie-cert-resubmit-error');
    const estado=document.getElementById('dgie-cert-resubmit-status');
    const enviar=document.getElementById('dgie-cert-resubmit-submit');
    if(!certificado||usuario()?.role!=='empresa')return;
    if(Number(zonaCertificado(certificado))!==Number(usuario()?.zona||0))return;
    if(estadoFlujo(certificado)!==ESTADO_DEVUELTO){
      alert('Este certificado ya fue actualizado. Volvé al listado para ver su estado.');
      return;
    }
    if(!archivo||!modulosCorregidos||detalle.length<5){
      error?.classList.add('is-visible');
      return;
    }
    if(typeof window.validarTamanoCertificado==='function'&&!window.validarTamanoCertificado(archivo))return;
    error?.classList.remove('is-visible');
    if(enviar)enviar.disabled=true;
    if(estado)estado.textContent='Subiendo archivo corregido...';

    try{
      const subida=typeof window.subirCertFile==='function'
        ? await window.subirCertFile(archivo)
        : {url:'',publicId:null};
      const mensajes=conversaciones(certificado).slice();
      const observacionInicial=limpiarObservacion(certificado?.observaciones_empresa);
      if(observacionInicial&&!mensajes.some(mensaje=>String(mensaje?.tipo||'')==='presentacion_inicial')){
        mensajes.unshift({
          tipo:'presentacion_inicial',
          texto:`Presentación inicial: ${observacionInicial}`,
          autor:certificado?.creado_por||'Empresa',
          rol:'empresa',
          fecha:certificado?.created_at||new Date().toISOString()
        });
      }
      mensajes.push({
        tipo:'reenvio',
        texto:`Certificado corregido y reenviado (${archivo.name}). ${detalle}`,
        detalle,
        archivo_anterior:certificado?.archivo_original||'',
        archivo_nuevo:archivo.name,
        autor:usuario()?.name||'Empresa',
        rol:'empresa',
        fecha:new Date().toISOString()
      });
      const observacionesEmpresa=[
        detalle,
        ...etiquetasTecnicas(certificado?.observaciones_empresa,{empresa:true})
      ].filter(Boolean).join('\n');
      const observacionesInspector=observacionConConversacion(
        '',
        etiquetasTecnicas(certificado?.observaciones_inspector),
        mensajes
      );
      const patch={
        archivo_original:archivo.name,
        url_original:subida?.url||'',
        public_id_original:subida?.publicId||null,
        modulos_original:modulosCorregidos,
        monto_empresa:modulosCorregidos,
        observaciones_empresa:observacionesEmpresa,
        archivo_inspector:null,
        url_inspector:null,
        public_id_inspector:null,
        modulos_inspector:0,
        monto_inspeccion:0,
        observaciones_inspector:observacionesInspector,
        medicion_numero:null,
        periodo:null,
        grupo_finalizado:false,
        estado:ESTADO_PENDIENTE,
        conversacion:mensajes,
        actualizado_por:usuario()?.name||'Empresa'
      };
      if(estado)estado.textContent='Guardando reenvío...';
      await actualizarConCompatibilidad(id,patch);
      if(estado)estado.textContent='Reenviado correctamente.';
      await volverAListado('empresa',ESTADO_PENDIENTE);
    }catch(excepcion){
      if(estado)estado.textContent='';
      alert(mensajeError(excepcion,'reenviar el certificado'));
      if(enviar)enviar.disabled=false;
    }
  };

  const guardarRevisionAnterior=window.guardarRevisionCertificado;
  if(typeof guardarRevisionAnterior==='function'){
    window.guardarRevisionCertificado=function(id,medir){
      if(medir!==true){
        window.abrirDevolucionCertificado(id);
        return Promise.resolve();
      }
      return guardarRevisionAnterior.apply(this,arguments);
    };
  }
  const revisarAnterior=window.revisarCertificadoInspector;
  if(typeof revisarAnterior==='function'){
    window.revisarCertificadoInspector=function(){
      const resultado=revisarAnterior.apply(this,arguments);
      setTimeout(mejorarFormularioMedicion,0);
      return resultado;
    };
  }
  const filtrarInspectorAnterior=window.filtrarMedicionesInspector;
  if(typeof filtrarInspectorAnterior==='function'){
    window.filtrarMedicionesInspector=function(){
      const resultado=filtrarInspectorAnterior.apply(this,arguments);
      setTimeout(mejorarVistaInspector,0);
      return resultado;
    };
  }
  const renderInspectorAnterior=window.renderMedicionesInspector;
  if(typeof renderInspectorAnterior==='function'){
    window.renderMedicionesInspector=async function(){
      const resultado=await renderInspectorAnterior.apply(this,arguments);
      mejorarVistaInspector();
      return resultado;
    };
  }
  const renderEmpresaAnterior=window.renderMedicionesEmpresa;
  if(typeof renderEmpresaAnterior==='function'){
    window.renderMedicionesEmpresa=async function(){
      const resultado=await renderEmpresaAnterior.apply(this,arguments);
      mejorarVistaEmpresa();
      return resultado;
    };
  }

  window.DGIE_CERTIFICACION_FLUJO={
    estadoFlujo,
    motivoDevolucion,
    mejorarVistaInspector,
    mejorarVistaEmpresa
  };
})();
