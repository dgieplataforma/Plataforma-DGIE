create table if not exists public.comunicaciones (
  id uuid primary key default gen_random_uuid(),
  tipo text not null default 'comunicado' check (tipo in ('comunicado','tarea','notificacion')),
  titulo text not null,
  mensaje text not null,
  alcance text not null default 'general' check (alcance in ('general','zona')),
  zonas integer[] not null default '{}',
  creado_por uuid references public.perfiles(id) default auth.uid(),
  creado_por_nombre text,
  estados jsonb not null default '{}'::jsonb,
  validaciones jsonb not null default '{}'::jsonb,
  encuesta jsonb not null default '[]'::jsonb,
  archivos jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.comunicaciones enable row level security;

alter table public.comunicaciones add column if not exists encuesta jsonb not null default '[]'::jsonb;
alter table public.comunicaciones add column if not exists archivos jsonb not null default '[]'::jsonb;
alter table public.comunicaciones drop column if exists inspectores;

drop policy if exists "comunicaciones lectura por rol" on public.comunicaciones;
drop policy if exists "gestion crea comunicaciones" on public.comunicaciones;
drop policy if exists "gestion o inspector actualiza comunicaciones" on public.comunicaciones;

create policy "comunicaciones lectura por rol" on public.comunicaciones
for select using (
  public.mi_rol() in ('director','coordinador')
  or (
    public.mi_rol() = 'inspector'
    and (
      alcance = 'general'
      or public.mi_zona() = any(zonas)
    )
  )
);

create policy "gestion crea comunicaciones" on public.comunicaciones
for insert with check (
  public.mi_rol() in ('director','coordinador')
);

create policy "gestion o inspector actualiza comunicaciones" on public.comunicaciones
for update using (
  public.mi_rol() in ('director','coordinador')
  or (
    public.mi_rol() = 'inspector'
    and (
      alcance = 'general'
      or public.mi_zona() = any(zonas)
    )
  )
)
with check (
  public.mi_rol() in ('director','coordinador')
  or (
    public.mi_rol() = 'inspector'
    and (
      alcance = 'general'
      or public.mi_zona() = any(zonas)
    )
  )
);
