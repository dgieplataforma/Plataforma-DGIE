# Plan multiusuario DGIE

## Objetivo

Que inspectores, coordinadores, empresas y call center trabajen sobre la misma informacion, no sobre datos locales del navegador.

## Etapa 1 - Supabase

1. Crear proyecto en Supabase.
2. Ejecutar `supabase-schema.sql` en SQL Editor.
3. Ejecutar `supabase-seed-establecimientos.sql` para cargar los 759 establecimientos.
4. Crear bucket privado `dgie-fotos`.
5. Crear usuarios desde Supabase Auth.
6. Completar la tabla `perfiles` con rol y zona.

## Etapa 2 - Integracion frontend

1. Agregar `supabase-config.js` con URL y anon key.
2. Cargar Supabase JS en `index.html`.
3. Reemplazar login simulado por login real.
4. Reemplazar arrays locales por consultas a Supabase.
5. Guardar nuevos reclamos, ordenes, intervenciones y relevamientos en Supabase.

## Etapa 3 - Prueba piloto

1. Crear 1 coordinador, 1 inspector, 1 empresa y 1 usuario call center.
2. Cargar 3 reclamos reales de prueba.
3. Crear 1 orden de servicio desde inspector.
4. Verificar que coordinador vea todo y que inspector solo vea su zona.
5. Verificar fotos y permisos.
