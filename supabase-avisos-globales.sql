create table if not exists public.avisos_globales (
  id text primary key,
  fecha date not null,
  mensaje text not null default '',
  destino text[] not null default array['inspector'],
  activo boolean not null default true,
  creado_por uuid references auth.users(id),
  creado_por_nombre text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.avisos_globales enable row level security;

drop policy if exists "avisos lectura coordinador inspectores" on public.avisos_globales;
drop policy if exists "avisos gestion crea" on public.avisos_globales;
drop policy if exists "avisos gestion actualiza" on public.avisos_globales;

create policy "avisos lectura coordinador inspectores" on public.avisos_globales
for select using (
  public.mi_rol() in ('director','coordinador','inspector')
  and (
    activo = true
    or public.mi_rol() in ('director','coordinador')
  )
);

create policy "avisos gestion crea" on public.avisos_globales
for insert with check (
  public.mi_rol() in ('director','coordinador')
);

create policy "avisos gestion actualiza" on public.avisos_globales
for update using (
  public.mi_rol() in ('director','coordinador')
)
with check (
  public.mi_rol() in ('director','coordinador')
);
