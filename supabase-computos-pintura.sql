-- Cómputos de pintura: herramienta de la sección "Herramientas" (inspector y empresa).
-- Cada fila es un cómputo con nombre propio; no tiene relación con órdenes de servicio.
-- El detalle (locales, muros, cielorrasos, carpinterías, pintura en altura, obra, fecha)
-- viaja completo en la columna jsonb `datos`.
--
-- Idempotente: create table / policy / grant con IF NOT EXISTS o drop-and-create.
-- Sólo ALTER ... ADD COLUMN IF NOT EXISTS para cambios futuros. Nunca DROP TABLE.

create table if not exists public.computos_pintura (
  id text primary key,
  zona integer not null,
  nombre text not null default 'Cómputo de pintura',
  establecimiento_id bigint,
  establecimiento_nombre text,
  obra text,
  fecha text,
  datos jsonb not null default '{}'::jsonb,
  creado_por text,
  actualizado_por text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.computos_pintura add column if not exists establecimiento_id bigint;
alter table public.computos_pintura add column if not exists establecimiento_nombre text;
alter table public.computos_pintura add column if not exists obra text;
alter table public.computos_pintura add column if not exists fecha text;
alter table public.computos_pintura add column if not exists actualizado_por text;

create index if not exists computos_pintura_zona_idx
  on public.computos_pintura (zona);
create index if not exists computos_pintura_establecimiento_idx
  on public.computos_pintura (establecimiento_id);

alter table public.computos_pintura enable row level security;

grant select, insert, update, delete on public.computos_pintura to authenticated;

drop policy if exists "computos_pintura lectura por zona" on public.computos_pintura;
drop policy if exists "computos_pintura carga por zona" on public.computos_pintura;
drop policy if exists "computos_pintura edicion por zona" on public.computos_pintura;
drop policy if exists "computos_pintura borrado por zona" on public.computos_pintura;

create policy "computos_pintura lectura por zona" on public.computos_pintura
for select using (
  public.mi_rol() in ('director','coordinador')
  or public.mi_zona() = zona
);

create policy "computos_pintura carga por zona" on public.computos_pintura
for insert with check (
  public.mi_rol() in ('director','coordinador')
  or (
    public.mi_rol() in ('inspector','empresa')
    and public.mi_zona() = zona
  )
);

create policy "computos_pintura edicion por zona" on public.computos_pintura
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

create policy "computos_pintura borrado por zona" on public.computos_pintura
for delete using (
  public.mi_rol() in ('director','coordinador')
  or (
    public.mi_rol() in ('inspector','empresa')
    and public.mi_zona() = zona
  )
);
