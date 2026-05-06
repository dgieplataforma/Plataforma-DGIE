begin;

-- Limpia datos operativos de prueba.
-- No borra usuarios, perfiles ni establecimientos.

delete from public.fotos
where reclamo_id is not null
   or orden_servicio_id is not null
   or intervencion_id is not null
   or relevamiento_id is not null;

delete from public.comunicaciones;
delete from public.intervenciones;
delete from public.relevamientos;
delete from public.ordenes_servicio;
delete from public.reclamos;

commit;

select 'reclamos' as tabla, count(*) as restantes from public.reclamos
union all
select 'ordenes_servicio', count(*) from public.ordenes_servicio
union all
select 'intervenciones', count(*) from public.intervenciones
union all
select 'relevamientos', count(*) from public.relevamientos
union all
select 'comunicaciones', count(*) from public.comunicaciones;
