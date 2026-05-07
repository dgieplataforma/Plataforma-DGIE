-- DGIE - marca informativa de finalizacion por empresa
-- Ejecutar una sola vez en Supabase SQL Editor.
-- No cambia el estado oficial de la orden: el inspector lo sigue definiendo desde el desplegable.

alter table public.ordenes_servicio
  add column if not exists empresa_finalizo boolean not null default false,
  add column if not exists empresa_finalizo_fecha timestamptz,
  add column if not exists empresa_finalizo_por uuid references public.perfiles(id);

