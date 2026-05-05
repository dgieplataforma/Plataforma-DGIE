-- DGIE - Preparar establecimientos para mapa real con coordenadas
-- Ejecutar en Supabase SQL Editor.
-- Despues se pueden cargar lat/lng reales por planilla o geocodificacion.

alter table public.establecimientos
  add column if not exists lat numeric,
  add column if not exists lng numeric;

comment on column public.establecimientos.lat is 'Latitud real del establecimiento para mapa interactivo.';
comment on column public.establecimientos.lng is 'Longitud real del establecimiento para mapa interactivo.';

select id, zona, nombre, direccion, barrio, lat, lng
from public.establecimientos
order by zona, nombre
limit 20;
