-- Reparacion para evitar recursion en politicas RLS de perfiles.
-- Ejecutar en Supabase > SQL Editor si aparece:
-- "stack depth limit exceeded"

create or replace function public.mi_rol()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select rol from public.perfiles where id = auth.uid() and activo = true
$$;

create or replace function public.mi_zona()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select zona from public.perfiles where id = auth.uid() and activo = true
$$;

