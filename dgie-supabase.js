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
      return client.from('establecimientos').update(row).eq('id', id).select('*').single();
    },
    async eliminarEstablecimiento(id){
      return client.from('establecimientos').delete().eq('id', id);
    },
    async actualizarUbicacionEstablecimiento(payload){
      return client.rpc('actualizar_ubicacion_establecimiento', payload);
    },
    async listarReclamos(){
      return client.from('reclamos').select('*').order('created_at', { ascending:false });
    },
    async crearReclamo(row){
      return client.from('reclamos').insert(row).select('*').single();
    },
    async actualizarReclamo(id, row){
      return client.from('reclamos').update(row).eq('id', id).select('*').single();
    },
    async listarOrdenes(){
      return client.from('ordenes_servicio').select('*').order('created_at', { ascending:false });
    },
    async crearOrden(row){
      return client.from('ordenes_servicio').insert(row).select('*').single();
    },
    async actualizarOrden(id, row){
      return client.from('ordenes_servicio').update(row).eq('id', id).select('*').single();
    },
    async eliminarOrden(id){
      return client.from('ordenes_servicio').delete().eq('id', id);
    },
    async listarIntervenciones(){
      return client.from('intervenciones').select('*').order('created_at', { ascending:false });
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
      return client.from('relevamientos').select('*').order('created_at', { ascending:false });
    },
    async crearRelevamiento(row){
      return client.from('relevamientos').insert(row).select('*').single();
    },
    async actualizarRelevamiento(id, row){
      return client.from('relevamientos').update(row).eq('id', id).select('*').single();
    },
    async listarComunicaciones(){
      return client.from('comunicaciones').select('*').order('created_at', { ascending:false });
    },
    async crearComunicacion(row){
      return client.from('comunicaciones').insert(row).select('*').single();
    },
    async actualizarComunicacion(id, row){
      return client.from('comunicaciones').update(row).eq('id', id).select('*').single();
    },
    async listarFotos(){
      return client.from('fotos').select('*').order('created_at', { ascending:false });
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
    async listarCertificadosMedicion(){
      return client.from('certificados_medicion').select('*').order('created_at', { ascending:false });
    },
    async crearCertificadoMedicion(row){
      return client.from('certificados_medicion').insert(row).select('*').single();
    },
    async actualizarCertificadoMedicion(id, row){
      return client.from('certificados_medicion').update(row).eq('id', id).select('*').single();
    },
    async eliminarCertificadoMedicion(id){
      return client.from('certificados_medicion').delete().eq('id', id);
    }
  };
})();
