-- DGIE - Borrar establecimientos sin georreferencia
-- Borra cualquier establecimiento con lat o lng nulo, y sus datos vinculados.
-- Ejecutar completo en Supabase SQL Editor.

begin;

create temp table dgie_sin_georef as
select id from public.establecimientos
where lat is null or lng is null;

delete from public.fotos
where establecimiento_id in (select id from dgie_sin_georef);

delete from public.ordenes_servicio
where establecimiento_id in (select id from dgie_sin_georef);

delete from public.reclamos
where establecimiento_id in (select id from dgie_sin_georef);

delete from public.intervenciones
where establecimiento_id in (select id from dgie_sin_georef);

delete from public.relevamientos
where establecimiento_id in (select id from dgie_sin_georef);

delete from public.establecimientos
where id in (select id from dgie_sin_georef);

commit;

select count(*) as establecimientos_sin_georreferencia
from public.establecimientos
where lat is null or lng is null;
