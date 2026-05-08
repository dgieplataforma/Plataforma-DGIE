-- Tablas para persistir datos de inspectores y empresas por zona.
-- Ejecutar una sola vez en Supabase SQL Editor.

-- ─── INSPECTORES POR ZONA ─────────────────────────────────────────────────────
create table if not exists public.inspectores_zona (
  id          serial primary key,
  zona        int    unique not null,
  nombre      text   not null default '',
  email       text   not null default '',
  telefono    text   not null default '',
  cuit        text   not null default '',
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

alter table public.inspectores_zona enable row level security;

create policy "todos leen inspectores" on public.inspectores_zona
  for select using (auth.role() = 'authenticated');

create policy "coordinador escribe inspectores" on public.inspectores_zona
  for all using (public.mi_rol() = 'coordinador')
  with check (public.mi_rol() = 'coordinador');

-- ─── EMPRESAS POR ZONA ────────────────────────────────────────────────────────
create table if not exists public.empresas_zona (
  id           serial primary key,
  zona         int    unique not null,
  razon_social text   not null default '',
  cuit         text   not null default '',
  expediente   text   not null default '',
  representante text  not null default '',
  domicilio    text   not null default '',
  telefono     text   not null default '',
  email        text   not null default '',
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

alter table public.empresas_zona enable row level security;

create policy "todos leen empresas" on public.empresas_zona
  for select using (auth.role() = 'authenticated');

create policy "coordinador escribe empresas" on public.empresas_zona
  for all using (public.mi_rol() = 'coordinador')
  with check (public.mi_rol() = 'coordinador');

-- ─── TRIGGER updated_at ───────────────────────────────────────────────────────
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger trg_inspectores_zona_updated
  before update on public.inspectores_zona
  for each row execute function public.set_updated_at();

create trigger trg_empresas_zona_updated
  before update on public.empresas_zona
  for each row execute function public.set_updated_at();
