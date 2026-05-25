# Plataforma DGIE - paquete de produccion

Este paquete contiene la version web publicable de la plataforma para control, gestion y trazabilidad del mantenimiento de la infraestructura educativa de Cordoba Capital.

## Archivos de produccion

- `index.html`: plataforma completa lista para abrir en navegador o subir a hosting.
- `assets/`: imagenes y recursos usados por la plataforma.
- `netlify.toml`: configuracion minima para publicar en Netlify.
- `supabase-config.js`: conexion publica al proyecto Supabase.
- `supabase-config.example.js`: plantilla para configurar otro entorno.
- `dgie-supabase.js`: cliente inicial para consultar Supabase desde la plataforma.

## Archivo de trabajo

Los archivos historicos, SQL, datos de carga, prototipos y backups fueron movidos a `_archivo_trabajo/`.
No son necesarios para servir el sitio, pero se conservan para auditoria, recuperacion y mantenimiento.

## Publicacion estatica

Se puede subir la raiz de esta carpeta a Netlify, Vercel o un servidor institucional.
Para un deploy limpio, excluir `_archivo_trabajo/`.

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

Si al probar la API aparece `stack depth limit exceeded`, revisar `_archivo_trabajo/sql/supabase-fix-rls-recursion.sql` y ejecutarlo en Supabase SQL Editor.
