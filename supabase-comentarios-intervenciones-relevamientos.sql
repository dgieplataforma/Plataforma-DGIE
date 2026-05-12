-- DGIE - comentarios de coordinacion e inspectores en intervenciones
-- Ejecutar una sola vez en Supabase SQL Editor.

-- 1. Columna para guardar comentarios (coordinacion) y respuestas (inspectores)
alter table public.intervenciones
  add column if not exists comentarios_coordinacion jsonb not null default '[]'::jsonb;

-- 2. Permitir que el inspector actualice intervenciones de su zona
--    (necesario para guardar su respuesta al comentario del coordinador)
drop policy if exists "inspector actualiza intervenciones de zona" on public.intervenciones;
create policy "inspector actualiza intervenciones de zona" on public.intervenciones
for update using (
  public.mi_rol() = 'inspector' and zona = public.mi_zona()
) with check (
  public.mi_rol() = 'inspector' and zona = public.mi_zona()
);

-- 3. Permitir que director/direccion tambien agreguen comentarios
drop policy if exists "direccion actualiza intervenciones" on public.intervenciones;
create policy "direccion actualiza intervenciones" on public.intervenciones
for update using (
  public.mi_rol() in ('director', 'direccion')
) with check (
  public.mi_rol() in ('director', 'direccion')
);

-- Verificacion rapida
select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'intervenciones'
  and column_name = 'comentarios_coordinacion';
