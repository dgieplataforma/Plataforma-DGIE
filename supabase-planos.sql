-- DGIE - Módulo de Planos
-- Ejecutar completo en Supabase SQL Editor.
-- Luego crear manualmente el bucket "dgie-planos" en Supabase > Storage
-- y marcarlo como PÚBLICO.

-- 1. Tabla de planos
create table if not exists public.planos (
  id uuid primary key default gen_random_uuid(),
  establecimiento_id bigint not null references public.establecimientos(id) on delete cascade,
  zona integer not null check (zona between 1 and 17),
  nombre text not null,
  piso text not null default 'PB',
  tipo text not null check (tipo in ('pdf', 'dwg', 'otro')),
  url text not null,
  path text not null,
  descripcion text,
  creado_por uuid references public.perfiles(id),
  created_at timestamptz not null default now()
);

alter table public.planos enable row level security;

-- Lectura: usuarios autenticados de la zona o gestión
create policy "planos lectura" on public.planos
for select using (
  public.mi_rol() in ('director', 'coordinador')
  or zona = public.mi_zona()
);

-- Carga: inspector (solo su zona) y coordinador
create policy "planos insertar" on public.planos
for insert with check (
  public.mi_rol() = 'coordinador'
  or (public.mi_rol() = 'inspector' and zona = public.mi_zona())
);

-- Borrar: solo coordinador
create policy "planos borrar" on public.planos
for delete using (
  public.mi_rol() = 'coordinador'
);

-- Verificación: debe devolver "Tabla planos OK"
select case when exists (
  select 1 from information_schema.tables
  where table_schema = 'public' and table_name = 'planos'
) then 'Tabla planos OK' else 'ERROR' end as resultado;
