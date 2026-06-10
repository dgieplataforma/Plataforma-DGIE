create table if not exists public.analisis_precios (
  id text primary key,
  zona integer not null,
  establecimiento_id bigint,
  establecimiento_nombre text,
  certificado_id text,
  os_numero text,
  concepto text not null default 'Análisis de precios',
  observaciones text,
  valor_modulo numeric not null default 136603.56,
  materiales jsonb not null default '[]'::jsonb,
  mano_obra jsonb not null default '{}'::jsonb,
  equipos jsonb not null default '[]'::jsonb,
  calculo jsonb not null default '{}'::jsonb,
  creado_por text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists analisis_precios_zona_idx
  on public.analisis_precios (zona);

create index if not exists analisis_precios_establecimiento_idx
  on public.analisis_precios (establecimiento_id);

create index if not exists analisis_precios_certificado_idx
  on public.analisis_precios (certificado_id);

alter table public.analisis_precios enable row level security;

grant select, insert, update, delete on public.analisis_precios to authenticated;

drop policy if exists "analisis_precios lectura por zona" on public.analisis_precios;
drop policy if exists "analisis_precios carga por zona" on public.analisis_precios;
drop policy if exists "analisis_precios edicion por zona" on public.analisis_precios;
drop policy if exists "analisis_precios borrado por zona" on public.analisis_precios;

create policy "analisis_precios lectura por zona" on public.analisis_precios
for select using (
  public.mi_rol() in ('director','coordinador')
  or public.mi_zona() = zona
);

create policy "analisis_precios carga por zona" on public.analisis_precios
for insert with check (
  public.mi_rol() in ('director','coordinador')
  or (
    public.mi_rol() in ('inspector','empresa')
    and public.mi_zona() = zona
  )
);

create policy "analisis_precios edicion por zona" on public.analisis_precios
for update using (
  public.mi_rol() in ('director','coordinador')
  or (
    public.mi_rol() in ('inspector','empresa')
    and public.mi_zona() = zona
  )
)
with check (
  public.mi_rol() in ('director','coordinador')
  or (
    public.mi_rol() in ('inspector','empresa')
    and public.mi_zona() = zona
  )
);

create policy "analisis_precios borrado por zona" on public.analisis_precios
for delete using (
  public.mi_rol() in ('director','coordinador')
  or (
    public.mi_rol() in ('inspector','empresa')
    and public.mi_zona() = zona
  )
);
