(function(){
  'use strict';

  const ESTADO_PENDIENTE='pendiente';
  const ESTADO_OBSERVADO='revision';
  const ESTADO_DEVUELTO='devuelto';
  const ESTADO_MEDIDO='medido';
  const ESTADO_BORRADO='eliminado';
  const META_VERSIONES_EMPRESA='VERSIONES_EMPRESA';
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
    if(estado===ESTADO_BORRADO)return ESTADO_BORRADO;
    if(estado===ESTADO_DEVUELTO)return ESTADO_DEVUELTO;
    if(estado===ESTADO_OBSERVADO)return ESTADO_OBSERVADO;
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
    return certificados().filter(certificado=>Number(zonaCertificado(certificado))===Number(zona));
  }
  function versionActualDesdeCertificado(certificado){
    if(!certificado?.archivo_original&&!certificado?.url_original)return null;
    return {
      numero:1,
      archivo:String(certificado?.archivo_original||'Archivo certificado'),
      url:String(certificado?.url_original||''),
      public_id:certificado?.public_id_original||null,
      modulos_empresa:numero(certificado?.modulos_original),
      monto_empresa:numero(certificado?.monto_empresa??certificado?.modulos_original),
      fecha:String(certificado?.created_at||certificado?.updated_at||''),
      autor:String(certificado?.creado_por||'Empresa'),
      vigente:true
    };
  }
  function versionesEmpresa(certificado){
    const patron=new RegExp(`\\[${META_VERSIONES_EMPRESA}:([^\\]]*)\\]`);
    const coincidencia=String(certificado?.observaciones_empresa||'').match(patron);
    let versiones=[];
    if(coincidencia){
      try{
        const parsed=JSON.parse(decodeURIComponent(coincidencia[1]));
        if(Array.isArray(parsed))versiones=parsed.filter(item=>item&&typeof item==='object');
      }catch(_){
        versiones=[];
      }
    }
    if(!versiones.length){
      const actual=versionActualDesdeCertificado(certificado);
      return actual?[actual]:[];
    }
    let vigente=versiones.findIndex(item=>item.vigente===true);
    if(vigente<0)vigente=versiones.length-1;
    return versiones.map((item,index)=>({
      numero:Number(item.numero)||index+1,
      archivo:String(item.archivo||'Archivo certificado'),
      url:String(item.url||''),
      public_id:item.public_id||null,
      modulos_empresa:numero(item.modulos_empresa),
      monto_empresa:numero(item.monto_empresa??item.modulos_empresa),
      fecha:String(item.fecha||''),
      autor:String(item.autor||'Empresa'),
      vigente:index===vigente
    }));
  }
  function observacionesConVersionesEmpresa(observaciones,versiones){
    const patron=new RegExp(`\\s*\\[${META_VERSIONES_EMPRESA}:[^\\]]*\\]`,'g');
    const base=String(observaciones||'').replace(patron,'').trim();
    const meta=`[${META_VERSIONES_EMPRESA}:${encodeURIComponent(JSON.stringify(versiones||[]))}]`;
    return [base,meta].filter(Boolean).join('\n');
  }
  function historialVersionesHTML(certificado){
    const anteriores=versionesEmpresa(certificado).filter(item=>!item.vigente).reverse();
    if(!anteriores.length)return '';
    return `<details class="dgie-cert-versions" data-cert-versiones>
      <summary>Versiones anteriores <span>${anteriores.length}</span></summary>
      <div class="dgie-cert-versions-list">
        ${anteriores.map(version=>`<div class="dgie-cert-version-row">
          <div class="dgie-cert-version-file"><strong>Versión ${esc(version.numero)}</strong>${version.url?`<a href="${esc(version.url)}" target="_blank" rel="noopener">${esc(version.archivo)}</a>`:`<span>${esc(version.archivo)}</span>`}</div>
          <div class="dgie-cert-version-meta">${modulos(version.modulos_empresa)} módulos empresa${version.fecha?` · Cargada ${esc(fecha(version.fecha))}`:''}</div>
        </div>`).join('')}
      </div>
    </details>`;
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
  function quitarEstadoVisible(acciones){
    [...(acciones?.children||[])].filter(elemento=>elemento.classList?.contains('badge')).forEach(elemento=>elemento.remove());
  }
  function mejorarTarjeta(tarjeta,certificado,rol){
    if(!tarjeta||!certificado)return;
    const estado=estadoFlujo(certificado),id=idCertificado(certificado);
    tarjeta.dataset.certCard=claveCertificado(certificado);tarjeta.dataset.certId=String(id);tarjeta.dataset.certEstado=estado;
    tarjeta.querySelectorAll('[data-cert-workflow-action]').forEach(elemento=>elemento.remove());
    tarjeta.querySelectorAll('[data-cert-versiones]').forEach(elemento=>elemento.remove());
    const meta=hijoDirectoClase(tarjeta,'med-card-meta'),historial=historialVersionesHTML(certificado);
    if(meta&&historial)meta.insertAdjacentHTML('afterend',historial);
    const acciones=hijoDirectoClase(tarjeta,'med-actions');if(!acciones)return;
    quitarEstadoVisible(acciones);
    if(rol==='empresa'){
      if(estado===ESTADO_OBSERVADO)acciones.appendChild(boton('Enviar a pendientes','secondary-btn',()=>window.enviarCertificadoObservadoAPendientes(id)));
      if(estado===ESTADO_DEVUELTO)acciones.appendChild(boton('Corregir y reenviar','primary-btn',()=>window.abrirReenvioCertificado(id)));
      return;
    }
    [...acciones.querySelectorAll('button')].filter(control=>/^(Análisis de precios|PDF\/JPG análisis|Quitar análisis)$/i.test(control.textContent.trim())).forEach(control=>control.remove());
    const gestionar=[...acciones.querySelectorAll('button')].find(control=>control.textContent.trim()==='Gestionar');
    const eliminar=[...acciones.querySelectorAll('button')].find(control=>/^(Eliminar|Anular)$/i.test(control.textContent.trim()));
    if(eliminar){eliminar.textContent='Anular';eliminar.onclick=()=>window.archivarCertificado(id);eliminar.style.color='var(--danger)'}
    const extras=[];
    if(estado===ESTADO_BORRADO){[...acciones.querySelectorAll('button')].forEach(control=>control.remove());acciones.appendChild(boton('Restaurar','primary-btn',()=>window.restaurarCertificado(id)));return}
    if(estado===ESTADO_PENDIENTE)extras.push(boton('Observar','secondary-btn dgie-cert-action-observe',()=>window.observarCertificado(id)));
    if(estado===ESTADO_OBSERVADO)extras.push(boton('Volver a pendientes','secondary-btn',()=>window.volverCertificadoDeObservado(id)));
    if(estado!==ESTADO_DEVUELTO)extras.push(boton('Devolver','secondary-btn dgie-cert-action-return',evento=>window.devolverCertificado(id,evento.currentTarget)));
    [gestionar,...extras,eliminar].filter(Boolean).forEach(control=>acciones.appendChild(control));
  }  function tarjetasCola(contenedor){
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
      if([ESTADO_PENDIENTE,ESTADO_OBSERVADO,ESTADO_DEVUELTO,ESTADO_BORRADO].includes(guardada))return guardada;
    }catch(_){}
    return tabsActivas[rol]||ESTADO_PENDIENTE;
  }
  function guardarTab(rol,tab){
    tabsActivas[rol]=tab;
    try{sessionStorage.setItem(claveTab(rol),tab)}catch(_){}
  }
  function aplicarTab(rol,tab){
    if(![ESTADO_PENDIENTE,ESTADO_OBSERVADO,ESTADO_DEVUELTO,ESTADO_BORRADO].includes(tab))return;
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
  function tarjetaAnulado(certificado){
    const tarjeta=document.createElement('div');
    tarjeta.className='med-card';
    tarjeta.innerHTML=`<div class="med-card-title">${esc(certificado?.establecimiento_nombre||'Establecimiento')}</div><div class="med-card-meta">Original: ${enlaceOriginal(certificado)} · Módulos empresa: ${modulos(certificado?.modulos_original)}<br>${certificado?.archivo_inspector?`Inspector: ${esc(certificado.archivo_inspector)} · Módulos inspección: ${modulos(certificado?.modulos_inspector)}<br>`:''}<span style="color:#64748b">Anulado por ${esc(certificado?.actualizado_por||'Inspector')} · ${esc(fecha(certificado?.updated_at)||'Sin fecha')}</span></div>${historialVersionesHTML(certificado)}${historialMensajesHTML(certificado)}<div class="med-actions"></div>`;
    return tarjeta;
  }
  function panelCola(tab,items,vacio){
    const panel=document.createElement('div');panel.className='dgie-cert-queue-panel';panel.dataset.tab=tab;panel.setAttribute('role','tabpanel');
    if(items.length)items.forEach(item=>panel.appendChild(item.tarjeta));else panel.appendChild(crearVacio(vacio));
    return panel;
  }
  function armarCola(contenedor,rol,filas){
    if(!contenedor)return;
    const tarjetas=tarjetasCola(contenedor),filasCola=(filas||[]).filter(c=>estadoFlujo(c)!==ESTADO_MEDIDO);
    const porClave=new Map(filasCola.map(c=>[claveCertificado(c),c]));
    const grupos={[ESTADO_PENDIENTE]:[],[ESTADO_OBSERVADO]:[],[ESTADO_DEVUELTO]:[],[ESTADO_BORRADO]:[]};
    const usados=new Set();
    tarjetas.forEach((tarjeta,index)=>{
      const certificado=porClave.get(tarjeta.dataset.certCard||'')||filasCola.filter(c=>estadoFlujo(c)!==ESTADO_BORRADO)[index]||null;
      if(!certificado)return;usados.add(claveCertificado(certificado));mejorarTarjeta(tarjeta,certificado,rol);
      const estado=estadoFlujo(certificado);
      if(rol==='empresa'&&estado===ESTADO_BORRADO)return;
      grupos[estado].push({tarjeta,certificado});
    });
    if(rol==='inspector')filasCola.filter(c=>estadoFlujo(c)===ESTADO_BORRADO&&!usados.has(claveCertificado(c))).forEach(certificado=>{const tarjeta=tarjetaAnulado(certificado);mejorarTarjeta(tarjeta,certificado,rol);grupos[ESTADO_BORRADO].push({tarjeta,certificado})});
    const porActividad=(a,b)=>(new Date(b.certificado?.updated_at||b.certificado?.created_at||0).getTime()||0)-(new Date(a.certificado?.updated_at||a.certificado?.created_at||0).getTime()||0);
    Object.values(grupos).forEach(items=>items.sort(porActividad));
    const tabs=rol==='inspector'?[ESTADO_PENDIENTE,ESTADO_OBSERVADO,ESTADO_DEVUELTO,ESTADO_BORRADO]:[ESTADO_PENDIENTE,ESTADO_OBSERVADO,ESTADO_DEVUELTO];
    const nombres={[ESTADO_PENDIENTE]:'Pendientes',[ESTADO_OBSERVADO]:'Observados',[ESTADO_DEVUELTO]:'Devueltos',[ESTADO_BORRADO]:'Anulados'};
    const titulo=rol==='empresa'?'Seguimiento de certificados':'Certificados recibidos';
    const descripcion=rol==='empresa'?'Consultá el estado, respondé observaciones y corregí los certificados devueltos.':'Clasificá los certificados sin perder archivos, comentarios ni versiones.';
    const cabecera=document.createElement('div');cabecera.className='dgie-cert-queue-header';
    cabecera.innerHTML=`<div class="dgie-cert-queue-copy"><div class="card-title">${titulo}</div><p>${descripcion}</p></div><div class="dgie-cert-queue-tabs" role="tablist" aria-label="Estado de certificados">${tabs.map(tab=>`<button type="button" class="dgie-cert-queue-tab" role="tab" data-tab="${tab}">${nombres[tab]} <span class="dgie-cert-tab-count">${grupos[tab].length}</span></button>`).join('')}</div>`;
    const vacios={[ESTADO_PENDIENTE]:'No hay certificados pendientes.',[ESTADO_OBSERVADO]:'No hay certificados observados.',[ESTADO_DEVUELTO]:rol==='empresa'?'No hay certificados devueltos que requieran corrección.':'No hay certificados devueltos.',[ESTADO_BORRADO]:'No hay certificados en Anulados.'};
    const panels=tabs.map(tab=>panelCola(tab,grupos[tab],vacios[tab]));
    contenedor.replaceChildren(cabecera,...panels);contenedor.dataset.certWorkflow='1';contenedor.classList.add('dgie-cert-queue');contenedor.dataset.certRole=rol;
    cabecera.querySelectorAll('.dgie-cert-queue-tab').forEach(control=>control.addEventListener('click',()=>aplicarTab(rol,control.dataset.tab)));
    let activa=leerTab(rol);if(!tabs.includes(activa)||!grupos[activa].length)activa=tabs.find(tab=>grupos[tab].length)||tabs[0];aplicarTab(rol,activa);
  }  function buscarCola(raiz){
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
      if(subtitulo)subtitulo.textContent='Consultá el estado, respondé observaciones y corregí los certificados devueltos.';
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
  async function cambiarEstadoInspector(id,estado,tab,accion){
    const certificado=certificadoPorId(id);
    if(!certificado||usuario()?.role!=='inspector'||Number(zonaCertificado(certificado))!==Number(usuario()?.zona||0))return;
    try{await actualizarConCompatibilidad(id,{estado,actualizado_por:usuario()?.name||'Inspector'});await volverAListado('inspector',tab)}
    catch(error){alert(mensajeError(error,accion))}
  }
  window.observarCertificado=id=>cambiarEstadoInspector(id,ESTADO_OBSERVADO,ESTADO_OBSERVADO,'observar el certificado');
  window.volverCertificadoDeObservado=id=>cambiarEstadoInspector(id,ESTADO_PENDIENTE,ESTADO_PENDIENTE,'volver el certificado a pendientes');
  window.enviarCertificadoObservadoAPendientes=async function(id){
    const certificado=certificadoPorId(id);
    if(!certificado||usuario()?.role!=='empresa'||estadoFlujo(certificado)!==ESTADO_OBSERVADO)return;
    if(Number(zonaCertificado(certificado))!==Number(usuario()?.zona||0))return;
    try{
      await actualizarConCompatibilidad(id,{
        estado:ESTADO_PENDIENTE,
        actualizado_por:usuario()?.name||'Empresa'
      });
      await volverAListado('empresa',ESTADO_PENDIENTE);
    }catch(error){
      alert(mensajeError(error,'enviar el certificado a pendientes'));
    }
  };
  window.archivarCertificado=async function(id){
    const certificado=certificadoPorId(id);if(!certificado||usuario()?.role!=='inspector')return;
    if(!confirm('¿Anular este certificado? Se conservarán todos los archivos, comentarios y versiones.'))return;
    const anterior=estadoFlujo(certificado);
    const base=String(certificado?.observaciones_inspector||'').replace(/\s*\[BORRADO_DESDE:[^\]]*\]/g,'').trim();
    try{await actualizarConCompatibilidad(id,{estado:ESTADO_BORRADO,observaciones_inspector:[base,`[BORRADO_DESDE:${anterior}]`].filter(Boolean).join('\n'),actualizado_por:usuario()?.name||'Inspector'});await volverAListado('inspector',ESTADO_BORRADO)}catch(error){alert(mensajeError(error,'anular el certificado'))}
  };
  window.restaurarCertificado=async function(id){
    const certificado=certificadoPorId(id);if(!certificado||usuario()?.role!=='inspector')return;
    if(!confirm('¿Restaurar este certificado a Pendientes?'))return;
    const obs=String(certificado?.observaciones_inspector||''),match=obs.match(/\[BORRADO_DESDE:([^\]]+)\]/);
    const destino=[ESTADO_PENDIENTE,ESTADO_OBSERVADO,ESTADO_DEVUELTO,ESTADO_MEDIDO].includes(match?.[1])?match[1]:ESTADO_PENDIENTE;
    const limpio=obs.replace(/\s*\[BORRADO_DESDE:[^\]]*\]/g,'').trim();
    try{await actualizarConCompatibilidad(id,{estado:destino,observaciones_inspector:limpio,actualizado_por:usuario()?.name||'Inspector'});await volverAListado('inspector',destino===ESTADO_MEDIDO?ESTADO_PENDIENTE:destino)}catch(error){alert(mensajeError(error,'restaurar el certificado'))}
  };
  window.eliminarCertificadoInspector=window.archivarCertificado;
  window.devolverCertificado=async function(id,control){
    const certificado=certificadoPorId(id);
    if(!certificado||usuario()?.role!=='inspector')return;
    if(Number(zonaCertificado(certificado))!==Number(usuario()?.zona||0))return;
    if(estadoFlujo(certificado)===ESTADO_MEDIDO){
      alert('El certificado ya pertenece a una medición.');
      return;
    }
    if(estadoFlujo(certificado)===ESTADO_DEVUELTO){
      await volverAListado('inspector',ESTADO_DEVUELTO);
      return;
    }
    const textoAnterior=control?.textContent||'Devolver';
    if(control){
      control.disabled=true;
      control.setAttribute('aria-busy','true');
      control.textContent='Devolviendo...';
    }
    const patch={
      estado:ESTADO_DEVUELTO,
      medicion_numero:null,
      periodo:null,
      grupo_finalizado:false,
      actualizado_por:usuario()?.name||'Inspector'
    };
    try{
      await actualizarConCompatibilidad(id,patch);
      await volverAListado('inspector',ESTADO_DEVUELTO);
    }catch(excepcion){
      alert(mensajeError(excepcion,'devolver el certificado'));
      if(control){
        control.disabled=false;
        control.removeAttribute('aria-busy');
        control.textContent=textoAnterior;
      }
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
          <div><div class="card-title">Corregir y reenviar</div><div style="font-size:13px;color:var(--muted);margin-top:4px">La nueva versión quedará vigente y la anterior se conservará en el historial.</div></div>
        </div>
        ${resumenCertificado(certificado)}
        ${historialVersionesHTML(certificado)}
        <div class="form-grid">
          <div class="form-field full">
            <label class="form-label" for="dgie-cert-resubmit-file">Certificado Excel corregido *</label>
            <input class="form-input" id="dgie-cert-resubmit-file" type="file" accept=".xls,.xlsx">
            <div class="dgie-cert-required-note">Tamaño máximo: 10 MB.</div>
          </div>
          <div class="form-field">
            <label class="form-label" for="dgie-cert-resubmit-modules">Módulos</label>
            <input class="form-input" id="dgie-cert-resubmit-modules" type="number" step="0.001" readonly placeholder="Se completa al seleccionar el archivo">
          </div>
          <div class="form-field full"><div class="dgie-cert-inline-error" id="dgie-cert-resubmit-error">Seleccioná un archivo corregido válido.</div></div>
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
    const error=document.getElementById('dgie-cert-resubmit-error');
    const estado=document.getElementById('dgie-cert-resubmit-status');
    const enviar=document.getElementById('dgie-cert-resubmit-submit');
    if(!certificado||usuario()?.role!=='empresa')return;
    if(Number(zonaCertificado(certificado))!==Number(usuario()?.zona||0))return;
    if(estadoFlujo(certificado)!==ESTADO_DEVUELTO){
      alert('Este certificado ya fue actualizado. Volvé al listado para ver su estado.');
      return;
    }
    if(!archivo||!modulosCorregidos){
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
      const ahora=new Date().toISOString();
      const anteriores=versionesEmpresa(certificado).map(version=>({...version,vigente:false}));
      const versiones=[...anteriores,{
        numero:anteriores.length+1,
        archivo:archivo.name,
        url:subida?.url||'',
        public_id:subida?.publicId||null,
        modulos_empresa:modulosCorregidos,
        monto_empresa:modulosCorregidos,
        fecha:ahora,
        autor:usuario()?.name||'Empresa',
        vigente:true
      }];
      const patch={
        archivo_original:archivo.name,
        url_original:subida?.url||'',
        public_id_original:subida?.publicId||null,
        modulos_original:modulosCorregidos,
        monto_empresa:modulosCorregidos,
        observaciones_empresa:observacionesConVersionesEmpresa(certificado?.observaciones_empresa,versiones),
        archivo_inspector:null,
        url_inspector:null,
        public_id_inspector:null,
        modulos_inspector:0,
        monto_inspeccion:0,
        medicion_numero:null,
        periodo:null,
        grupo_finalizado:false,
        estado:ESTADO_PENDIENTE,
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

  function mejorarGestionInspector(id){
    const certificado=certificadoPorId(id),tarjeta=document.getElementById('insp-cert-file')?.closest('.card');
    if(!certificado||!tarjeta)return;
    tarjeta.querySelector('.card-header .badge')?.remove();
    tarjeta.querySelectorAll('[data-cert-versiones]').forEach(elemento=>elemento.remove());
    tarjeta.querySelectorAll('[data-cert-analysis-manage]').forEach(elemento=>elemento.remove());
    const cabecera=hijoDirectoClase(tarjeta,'card-header'),historial=historialVersionesHTML(certificado);
    if(cabecera&&historial)cabecera.insertAdjacentHTML('afterend',historial);
    const idSeguro=String(id).replace(/'/g,"\\'");
    const existe=window.analisisPrecioCertificadoExiste?.(id);
    const bloque=document.createElement('div');bloque.dataset.certAnalysisManage='1';bloque.className='dgie-cert-analysis-manage';
    bloque.innerHTML=`<div><strong>Análisis de precios</strong><span>Gestioná el análisis asociado a este certificado.</span></div><div class="med-actions"><button class="secondary-btn" onclick="seleccionarAnalisisPrecioCertificado('${idSeguro}')">Abrir análisis de precios</button>${existe?`<button class="secondary-btn" onclick="imprimirAnalisisPrecioCertificado('${idSeguro}')">PDF/JPG análisis</button><button class="secondary-btn" style="color:var(--danger)" onclick="desanexarAnalisisPrecioCertificado('${idSeguro}')">Quitar análisis</button>`:''}</div>`;
    const form=tarjeta.querySelector('.form-grid');if(form)form.insertAdjacentElement('beforebegin',bloque);
  }
  const revisarAnterior=window.revisarCertificadoInspector;
  if(typeof revisarAnterior==='function'){
    window.revisarCertificadoInspector=function(id){
      const resultado=revisarAnterior.apply(this,arguments);
      setTimeout(()=>mejorarGestionInspector(id),0);
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

  function historialMensajesHTML(certificado){
    const mensajes=typeof window.conversacionCert==='function'?(window.conversacionCert(certificado)||[]):(Array.isArray(certificado?.conversacion)?certificado.conversacion:[]);
    if(!mensajes.length)return '';
    return `<details class="dgie-cert-versions dgie-cert-exchange"><summary>Comentarios e intercambio <span>${mensajes.length}</span></summary><div class="dgie-cert-versions-list">${mensajes.map(m=>`<div class="dgie-cert-version-row"><div class="dgie-cert-version-file"><strong>${esc(m?.autor||m?.rol||'Usuario')}</strong><span>${esc(m?.texto||'')}</span></div><div class="dgie-cert-version-meta">${esc(fecha(m?.fecha)||'')}</div></div>`).join('')}</div></details>`;
  }
  function compactarMedicion(numero){
    const detalle=document.getElementById('med-detalle');if(!detalle||detalle.querySelector('.dgie-med-cert-details'))return;
    const filas=[...detalle.querySelectorAll('.med-version-row')];if(!filas.length)return;
    const zona=Number(usuario()?.zona||0);
    const data=certificados().filter(c=>estadoFlujo(c)===ESTADO_MEDIDO&&String(c?.medicion_numero)===String(numero)&&Number(zonaCertificado(c))===zona);
    filas.forEach((fila,index)=>{const c=data[index];if(!c)return;const meta=fila.querySelector('.med-card-meta');const versiones=historialVersionesHTML(c),mensajes=historialMensajesHTML(c);if(meta&&(versiones||mensajes))meta.insertAdjacentHTML('afterend',versiones+mensajes)});
    const parent=filas[0].parentElement;if(!parent)return;
    const details=document.createElement('details');details.className='dgie-med-cert-details';details.innerHTML=`<summary>Ver certificados <span>${filas.length}</span></summary><div class="dgie-med-cert-list"></div>`;
    const tabla=detalle.querySelector('table.med-table'),tablaWrap=tabla?.parentElement;
    if(tablaWrap)tablaWrap.insertAdjacentElement('afterend',details);else parent.insertBefore(details,filas[0]);
    const list=details.querySelector('.dgie-med-cert-list');filas.forEach(fila=>list.appendChild(fila));
  }
  const abrirMedicionFlujoPrev=window.abrirMedicionInspector;
  if(typeof abrirMedicionFlujoPrev==='function')window.abrirMedicionInspector=function(numero){const result=abrirMedicionFlujoPrev.apply(this,arguments);[0,80,250,700].forEach(delay=>setTimeout(()=>compactarMedicion(numero),delay));return result};
  window.DGIE_CERTIFICACION_FLUJO={
    estadoFlujo,
    versionesEmpresa,
    historialVersionesHTML,
    mejorarVistaInspector,
    mejorarVistaEmpresa
  };
})();
