(function(){
  const cfg = window.DGIE_SUPABASE || {};
  const supabaseLib = window.supabase;

  function notReady(reason){
    window.DGIE_DB = {
      isConfigured: false,
      reason,
      async health(){ return { ok:false, error:reason }; }
    };
  }

  if(!cfg.url || !cfg.anonKey){
    notReady('Falta configurar Supabase.');
    return;
  }

  if(!supabaseLib || typeof supabaseLib.createClient !== 'function'){
    notReady('No se pudo cargar supabase-js.');
    return;
  }

  const client = supabaseLib.createClient(cfg.url, cfg.anonKey);
  function cloudinaryConfig(){
    const cc = window.DGIE_CLOUDINARY || {};
    return {
      cloudName: String(cc.cloudName || '').trim(),
      uploadPreset: String(cc.uploadPreset || '').trim(),
      folder: String(cc.folder || 'dgie').trim() || 'dgie'
    };
  }
  function cloudinaryHabilitado(){
    const cc = cloudinaryConfig();
    return !!(cc.cloudName && cc.uploadPreset);
  }
  async function subirCloudinary(file, carpeta, resourceType){
    const cc = cloudinaryConfig();
    const rt = resourceType || 'auto';
    const form = new FormData();
    form.append('file', file);
    form.append('upload_preset', cc.uploadPreset);
    form.append('folder', `${cc.folder}/${carpeta}`);
    const res = await fetch(`https://api.cloudinary.com/v1_1/${encodeURIComponent(cc.cloudName)}/${encodeURIComponent(rt)}/upload`, {
      method: 'POST',
      body: form
    });
    if(!res.ok) throw new Error(`Cloudinary ${res.status}`);
    return res.json();
  }
  async function selectAll(table, options = {}){
    const {
      columns = '*',
      orderBy = 'created_at',
      ascending = false,
      filters = []
    } = options;
    const pageSize = 1000;
    let from = 0;
    const all = [];
    while(true){
      let query = client.from(table).select(columns);
      filters.forEach(fn => { query = fn(query); });
      if(orderBy) query = query.order(orderBy, { ascending });
      const { data, error } = await query.range(from, from + pageSize - 1);
      if(error) return { data:null, error };
      const rows = Array.isArray(data) ? data : [];
      all.push(...rows);
      if(rows.length < pageSize) return { data:all, error:null };
      from += pageSize;
    }
  }

  window.DGIE_DB = {
    isConfigured: true,
    client,
    async health(){
      const { error } = await client.from('establecimientos').select('id').limit(1);
      return { ok: !error, error: error ? error.message : null };
    },
    async signIn(email, password){
      return client.auth.signInWithPassword({ email, password });
    },
    async signOut(){
      return client.auth.signOut();
    },
    async currentProfile(){
      const { data: sessionData, error: sessionError } = await client.auth.getSession();
      if(sessionError || !sessionData.session) return { data:null, error:sessionError };
      const userId = sessionData.session.user.id;
      return client.from('perfiles').select('*').eq('id', userId).single();
    },
    async listarEstablecimientos(){
      return client.from('establecimientos').select('*').order('zona', { ascending:true }).order('nombre', { ascending:true });
    },
    async crearEstablecimiento(row){
      return client.from('establecimientos').insert(row).select('*').single();
    },
    async actualizarEstablecimiento(id, row){
      const { error } = await client.from('establecimientos').update(row).eq('id', id);
      if(error) return { data:null, error };
      const { data, error:selectError } = await client.from('establecimientos').select('*').eq('id', id).limit(1);
      return { data:Array.isArray(data) ? data[0] || null : data, error:selectError };
    },
    async eliminarEstablecimiento(id){
      return client.from('establecimientos').delete().eq('id', id);
    },
    async actualizarUbicacionEstablecimiento(payload){
      return client.rpc('actualizar_ubicacion_establecimiento', payload);
    },
    async listarReclamos(){
      return selectAll('reclamos', { orderBy:'created_at', ascending:false });
    },
    async buscarReclamoPorNumero(numero){
      return client.from('reclamos').select('id,numero').eq('numero', numero).limit(1);
    },
    async crearReclamo(row){
      return client.from('reclamos').insert(row).select('*').single();
    },
    async actualizarReclamo(id, row){
      return client.from('reclamos').update(row).eq('id', id).select('*').single();
    },
    async listarOrdenes(){
      return selectAll('ordenes_servicio', { orderBy:'created_at', ascending:false });
    },
    async crearOrden(row){
      return client.from('ordenes_servicio').insert(row).select('*').single();
    },
    async actualizarOrden(id, row){
      return client.from('ordenes_servicio').update(row).eq('id', id).select('*').single();
    },
    async actualizarEmpresaFinalizo(ordenId, valor){
      return client.rpc('marcar_empresa_finalizo', { p_orden_id: String(ordenId), p_valor: !!valor });
    },
    async eliminarOrden(id){
      return client.from('ordenes_servicio').delete().eq('id', id);
    },
    async listarIntervenciones(){
      return selectAll('intervenciones', { orderBy:'created_at', ascending:false });
    },
    async crearIntervencion(row){
      return client.from('intervenciones').insert(row).select('*').single();
    },
    async actualizarIntervencion(id, row){
      return client.from('intervenciones').update(row).eq('id', id).select('*').single();
    },
    async eliminarIntervencion(id){
      return client.from('intervenciones').delete().eq('id', id);
    },
    async listarRelevamientos(){
      return selectAll('relevamientos', { orderBy:'created_at', ascending:false });
    },
    async crearRelevamiento(row){
      return client.from('relevamientos').insert(row).select('*').single();
    },
    async actualizarRelevamiento(id, row){
      return client.from('relevamientos').update(row).eq('id', id).select('*').single();
    },
    async eliminarRelevamiento(id){
      return client.from('relevamientos').delete().eq('id', id);
    },
    async listarComunicaciones(){
      return selectAll('comunicaciones', { orderBy:'created_at', ascending:false });
    },
    async crearComunicacion(row){
      return client.from('comunicaciones').insert(row).select('*').single();
    },
    async actualizarComunicacion(id, row){
      const { error } = await client.from('comunicaciones').update(row).eq('id', id);
      if(error) return { data:null, error };
      const { data, error:selectError } = await client.from('comunicaciones').select('*').eq('id', id).limit(1);
      return { data:Array.isArray(data) ? data[0] || null : data, error:selectError };
    },
    async listarFotos(){
      return selectAll('fotos', { orderBy:'created_at', ascending:false });
    },
    async crearFoto(row){
      return client.from('fotos').insert(row).select('*').single();
    },
    async listarPlanos(establecimientoId){
      return client.from('planos').select('*').eq('establecimiento_id', establecimientoId).order('piso').order('created_at', { ascending: true });
    },
    async subirPlano(file, establecimientoId, zona, nombre, piso, tipo, descripcion){
      const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
      const path = `${establecimientoId}/${Date.now()}_${piso}_${safeName}`;
      if(cloudinaryHabilitado()){
        try{
          const resourceType = tipo === 'pdf' || tipo === 'dwg' ? 'raw' : 'auto';
          const uploaded = await subirCloudinary(file, 'planos', resourceType);
          return client.from('planos').insert({
            establecimiento_id: establecimientoId,
            zona,
            nombre,
            piso,
            tipo,
            url: uploaded.secure_url,
            path: uploaded.public_id || path,
            descripcion: descripcion || null
          }).select().single();
        }catch(error){
          return { data: null, error };
        }
      }
      const { error: uploadError } = await client.storage.from('dgie-planos').upload(path, file, { upsert: false });
      if(uploadError) return { data: null, error: uploadError };
      const { data: urlData } = client.storage.from('dgie-planos').getPublicUrl(path);
      return client.from('planos').insert({
        establecimiento_id: establecimientoId,
        zona,
        nombre,
        piso,
        tipo,
        url: urlData.publicUrl,
        path,
        descripcion: descripcion || null
      }).select().single();
    },
    async eliminarPlano(id, path){
      if(path && !String(path).includes('/')) {
        // Los archivos nuevos pueden estar en Cloudinary; con preset unsigned no se borran desde el navegador.
      } else {
        await client.storage.from('dgie-planos').remove([path]);
      }
      return client.from('planos').delete().eq('id', id);
    },
    async listarInspectores(){
      return client.from('inspectores_zona').select('*').order('zona', { ascending:true });
    },
    async actualizarInspector(zona, row){
      return client.from('inspectores_zona').upsert({ zona, ...row }, { onConflict:'zona' }).select('*').single();
    },
    async listarEmpresas(){
      return client.from('empresas_zona').select('*').order('zona', { ascending:true });
    },
    async actualizarEmpresa(zona, row){
      return client.from('empresas_zona').upsert({ zona, ...row }, { onConflict:'zona' }).select('*').single();
    },
    async listarCertificadosMedicion(zona){
      const filters = [];
      if(zona !== undefined && zona !== null && zona !== ''){
        filters.push(query => query.eq('zona', Number(zona)));
      }
      return selectAll('certificados_medicion', { orderBy:'created_at', ascending:false, filters });
    },
    async crearCertificadoMedicion(row){
      return client.from('certificados_medicion').insert(row).select('*').single();
    },
    async actualizarCertificadoMedicion(id, row){
      return client.from('certificados_medicion').update(row).eq('id', id).select('*').single();
    },
    async listarAnalisisPrecios(zona){
      const filters = [];
      if(zona !== undefined && zona !== null && zona !== ''){
        filters.push(query => query.eq('zona', Number(zona)));
      }
      return selectAll('analisis_precios', { orderBy:'updated_at', ascending:false, filters });
    },
    async guardarAnalisisPrecio(row){
      return client.from('analisis_precios').upsert(row, { onConflict:'id' }).select('*').single();
    },
    async eliminarAnalisisPrecio(id){
      return client.from('analisis_precios').delete().eq('id', id);
    },
    async eliminarCertificadoMedicion(id){
      return client.from('certificados_medicion').delete().eq('id', id);
    }
  };
})();
