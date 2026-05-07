begin;

-- Reset para salir a produccion.
-- Borra datos de uso/prueba y conserva usuarios, perfiles, establecimientos y planos.

delete from public.fotos
where entidad_tipo in ('reclamo','orden_servicio','intervencion','relevamiento');

delete from public.comunicaciones;
delete from public.intervenciones;
delete from public.relevamientos;
delete from public.ordenes_servicio;
delete from public.reclamos;

commit;

select 'reclamos' as tabla, count(*) as restantes from public.reclamos
union all select 'ordenes_servicio', count(*) from public.ordenes_servicio
union all select 'intervenciones', count(*) from public.intervenciones
union all select 'relevamientos', count(*) from public.relevamientos
union all select 'comunicaciones', count(*) from public.comunicaciones
union all select 'fotos_operativas', count(*) from public.fotos
where entidad_tipo in ('reclamo','orden_servicio','intervencion','relevamiento');
