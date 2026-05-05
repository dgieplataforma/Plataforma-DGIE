-- Plataforma DGIE - esquema inicial Supabase
-- Ejecutar en Supabase > SQL Editor.

create extension if not exists "pgcrypto";

create table if not exists public.perfiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text not null,
  rol text not null check (rol in ('director','coordinador','inspector','empresa','callcenter')),
  zona integer check (zona between 1 and 17),
  activo boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.establecimientos (
  id bigint primary key,
  zona integer not null check (zona between 1 and 17),
  nombre text not null,
  cue text,
  direccion text,
  barrio text,
  nivel text,
  tipo text,
  estado text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reclamos (
  id uuid primary key default gen_random_uuid(),
  numero text unique not null,
  establecimiento_id bigint references public.establecimientos(id) on delete set null,
  zona integer not null check (zona between 1 and 17),
  titulo text not null,
  descripcion text,
  prioridad text not null default 'medio' check (prioridad in ('critico','alto','medio','bajo')),
  rubro text,
  fecha date not null default current_date,
  creado_por uuid references public.perfiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ordenes_servicio (
  id uuid primary key default gen_random_uuid(),
  numero text unique not null,
  reclamo_numero text,
  establecimiento_id bigint references public.establecimientos(id) on delete set null,
  zona integer not null check (zona between 1 and 17),
  rubro text,
  tarea text not null,
  prioridad text not null default 'medio' check (prioridad in ('critico','alto','medio','bajo')),
  estado text not null default 'pendiente' check (estado in ('pendiente','trabajando','finalizado','anulado')),
  fecha_envio date not null default current_date,
  fecha_finalizacion date,
  monto text,
  presupuesto jsonb not null default '[]'::jsonb,
  creado_por uuid references public.perfiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.intervenciones (
  id uuid primary key default gen_random_uuid(),
  establecimiento_id bigint references public.establecimientos(id) on delete cascade,
  zona integer not null check (zona between 1 and 17),
  descripcion text not null,
  avance integer not null default 0 check (avance between 0 and 100),
  fecha date not null default current_date,
  creado_por uuid references public.perfiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.relevamientos (
  id uuid primary key default gen_random_uuid(),
  establecimiento_id bigint references public.establecimientos(id) on delete cascade,
  zona integer not null check (zona between 1 and 17),
  datos jsonb not null default '{}'::jsonb,
  promedio numeric,
  creado_por uuid references public.perfiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.fotos (
  id uuid primary key default gen_random_uuid(),
  entidad_tipo text not null check (entidad_tipo in ('reclamo','orden_servicio','intervencion','relevamiento','establecimiento')),
  entidad_id text not null,
  establecimiento_id bigint references public.establecimientos(id) on delete set null,
  zona integer check (zona between 1 and 17),
  bucket text not null default 'dgie-fotos',
  path text not null,
  descripcion text,
  creado_por uuid references public.perfiles(id),
  created_at timestamptz not null default now()
);

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

alter table public.perfiles enable row level security;
alter table public.establecimientos enable row level security;
alter table public.reclamos enable row level security;
alter table public.ordenes_servicio enable row level security;
alter table public.intervenciones enable row level security;
alter table public.relevamientos enable row level security;
alter table public.fotos enable row level security;

create policy "perfiles leen propio o gestion" on public.perfiles
for select using (
  id = auth.uid() or public.mi_rol() in ('director','coordinador')
);

create policy "gestion administra perfiles" on public.perfiles
for all using (public.mi_rol() in ('director','coordinador'))
with check (public.mi_rol() in ('director','coordinador'));

create policy "establecimientos lectura autenticada" on public.establecimientos
for select using (auth.uid() is not null);

create policy "gestion edita establecimientos" on public.establecimientos
for all using (public.mi_rol() in ('director','coordinador'))
with check (public.mi_rol() in ('director','coordinador'));

create policy "reclamos lectura por rol" on public.reclamos
for select using (
  public.mi_rol() in ('director','coordinador','callcenter')
  or zona = public.mi_zona()
);

create policy "callcenter e inspector crean reclamos" on public.reclamos
for insert with check (
  public.mi_rol() = 'callcenter'
  or (public.mi_rol() = 'inspector' and zona = public.mi_zona())
);

create policy "inspector modifica reclamos de su zona" on public.reclamos
for update using (
  public.mi_rol() in ('director','coordinador','callcenter')
  or (public.mi_rol() = 'inspector' and zona = public.mi_zona())
)
with check (
  public.mi_rol() in ('director','coordinador','callcenter')
  or (public.mi_rol() = 'inspector' and zona = public.mi_zona())
);

create policy "ordenes lectura por rol" on public.ordenes_servicio
for select using (
  public.mi_rol() in ('director','coordinador')
  or zona = public.mi_zona()
);

create policy "solo inspector crea ordenes" on public.ordenes_servicio
for insert with check (
  public.mi_rol() = 'inspector' and zona = public.mi_zona()
);

create policy "inspector actualiza ordenes propias de zona" on public.ordenes_servicio
for update using (
  public.mi_rol() in ('director','coordinador')
  or (public.mi_rol() = 'inspector' and zona = public.mi_zona())
)
with check (
  public.mi_rol() in ('director','coordinador')
  or (public.mi_rol() = 'inspector' and zona = public.mi_zona())
);

create policy "intervenciones lectura por rol" on public.intervenciones
for select using (
  public.mi_rol() in ('director','coordinador')
  or zona = public.mi_zona()
);

create policy "inspector crea intervenciones de zona" on public.intervenciones
for insert with check (
  public.mi_rol() = 'inspector' and zona = public.mi_zona()
);

create policy "relevamientos lectura por rol" on public.relevamientos
for select using (
  public.mi_rol() in ('director','coordinador')
  or zona = public.mi_zona()
);

create policy "inspector crea relevamientos de zona" on public.relevamientos
for insert with check (
  public.mi_rol() = 'inspector' and zona = public.mi_zona()
);

create policy "fotos lectura por rol" on public.fotos
for select using (
  public.mi_rol() in ('director','coordinador')
  or zona = public.mi_zona()
);

create policy "usuarios cargan fotos segun rol" on public.fotos
for insert with check (
  public.mi_rol() in ('callcenter')
  or (public.mi_rol() in ('inspector','empresa') and zona = public.mi_zona())
);
