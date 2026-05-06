-- Deja en cero todos los relevamientos.
-- No borra establecimientos, usuarios, zonas ni coordenadas.

begin;

delete from public.fotos
where entidad_tipo = 'relevamiento';

delete from public.relevamientos;

commit;

-- Verificacion: estos valores deben devolver 0.
select 'relevamientos' as tabla, count(*) as cantidad from public.relevamientos
union all
select 'fotos_relevamientos' as tabla, count(*) as cantidad
from public.fotos
where entidad_tipo = 'relevamiento';
