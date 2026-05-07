// Copiar este archivo como supabase-config.js y completar con los datos del proyecto.
// No compartir la service_role key en el navegador.

window.DGIE_SUPABASE = {
  url: "https://TU-PROYECTO.supabase.co",
  anonKey: "TU_ANON_KEY_PUBLICA"
};

// Opcional: completar para subir fotos y adjuntos pesados a Cloudinary.
// Usar un upload preset UNSIGNED creado en Cloudinary.
window.DGIE_CLOUDINARY = {
  cloudName: "TU_CLOUD_NAME",
  uploadPreset: "TU_UPLOAD_PRESET_UNSIGNED",
  folder: "dgie"
};
