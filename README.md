# Plataforma DGIE - paquete de lanzamiento

Este paquete contiene la version web publicable del prototipo.

## Archivo principal

- `index.html`: plataforma completa lista para abrir en navegador o subir a hosting.
- `netlify.toml`: configuracion minima para publicar en Netlify.
- `supabase-config.js`: conexion publica al proyecto Supabase.
- `dgie-supabase.js`: cliente inicial para consultar Supabase desde la plataforma.
- `supabase-schema.sql`: tablas y politicas de seguridad para la base de datos.
- `supabase-fix-rls-recursion.sql`: reparacion si Supabase informa `stack depth limit exceeded`.

## Publicacion estatica

Se puede subir esta carpeta completa a Netlify, Vercel o un servidor institucional.

En Netlify:

1. Entrar a Netlify.
2. Ir a `Add new site`.
3. Elegir `Deploy manually`.
4. Arrastrar la carpeta `plataforma-dgie-lanzamiento`.
5. Abrir la URL publicada.

## Importante para uso real

El prototipo actual funciona como sitio web estatico. Para que 30 personas trabajen con la misma informacion, el siguiente paso es conectar una base de datos y autenticacion real.

Prioridades antes de uso operativo:

1. Base de datos compartida para reclamos, ordenes, establecimientos, relevamientos y fotos.
2. Usuarios reales por rol: inspector, coordinador, empresa y call center.
3. Copias de seguridad.
4. Prueba piloto con pocos usuarios.

## Supabase configurado

Proyecto conectado:

- URL: `https://gvejicxbavveqrrxicen.supabase.co`
- Key usada: `anon/publishable key` publica para navegador.

No usar nunca la `service_role key` dentro de archivos publicos.

Si al probar la API aparece `stack depth limit exceeded`, ejecutar `supabase-fix-rls-recursion.sql` en Supabase SQL Editor.
