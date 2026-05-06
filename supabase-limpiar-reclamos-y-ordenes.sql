-- Deja la plataforma en 0 para comenzar a usarla:
-- borra todas las fotos asociadas a reclamos/ordenes, todas las ordenes de servicio
-- y todos los reclamos. No borra usuarios, establecimientos, zonas ni coordenadas.

begin;

delete from public.fotos
where entidad_tipo in ('reclamo','orden_servicio');

delete from public.ordenes_servicio;

delete from public.reclamos;

commit;

-- Verificacion: estos valores deben devolver 0.
select 'reclamos' as tabla, count(*) as cantidad from public.reclamos
union all
select 'ordenes_servicio' as tabla, count(*) as cantidad from public.ordenes_servicio
union all
select 'fotos_reclamos_ordenes' as tabla, count(*) as cantidad
from public.fotos
where entidad_tipo in ('reclamo','orden_servicio');
