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
    async actualizarUbicacionEstablecimiento(payload){
      return client.rpc('actualizar_ubicacion_establecimiento', payload);
    },
    async listarReclamos(){
      return client.from('reclamos').select('*').order('created_at', { ascending:false });
    },
    async listarOrdenes(){
      return client.from('ordenes_servicio').select('*').order('created_at', { ascending:false });
    },
    async listarPlanos(establecimientoId){
      return client.from('planos').select('*').eq('establecimiento_id', establecimientoId).order('piso').order('created_at', { ascending: true });
    },
    async subirPlano(file, establecimientoId, zona, nombre, piso, tipo, descripcion){
      const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
      const path = `${establecimientoId}/${Date.now()}_${piso}_${safeName}`;
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
      await client.storage.from('dgie-planos').remove([path]);
      return client.from('planos').delete().eq('id', id);
    }
  };
})();
