-- DGIE - comentarios de coordinacion dentro de intervenciones
-- Ejecutar una sola vez en Supabase SQL Editor.

alter table public.intervenciones
  add column if not exists comentarios_coordinacion jsonb not null default '[]'::jsonb;

