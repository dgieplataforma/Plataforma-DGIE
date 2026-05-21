begin;

create table if not exists public.certificados_medicion (
  id bigserial primary key,
  establecimiento_id integer references public.establecimientos(id) on delete set null,
  establecimiento_nombre text not null,
  zona integer not null,
  archivo_original text,
  url_original text,
  public_id_original text,
  modulos_original numeric default 0,
  monto_empresa numeric default 0,
  observaciones_empresa text,
  archivo_inspector text,
  url_inspector text,
  public_id_inspector text,
  modulos_inspector numeric default 0,
  monto_inspeccion numeric default 0,
  observaciones_inspector text,
  medicion_numero integer,
  periodo text,
  estado text not null default 'pendiente',
  creado_por text,
  actualizado_por text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.certificados_medicion
  add column if not exists establecimiento_id integer,
  add column if not exists establecimiento_nombre text,
  add column if not exists zona integer,
  add column if not exists archivo_original text,
  add column if not exists url_original text,
  add column if not exists public_id_original text,
  add column if not exists modulos_original numeric default 0,
  add column if not exists monto_empresa numeric default 0,
  add column if not exists observaciones_empresa text,
  add column if not exists archivo_inspector text,
  add column if not exists url_inspector text,
  add column if not exists public_id_inspector text,
  add column if not exists modulos_inspector numeric default 0,
  add column if not exists monto_inspeccion numeric default 0,
  add column if not exists observaciones_inspector text,
  add column if not exists medicion_numero integer,
  add column if not exists periodo text,
  add column if not exists estado text not null default 'pendiente',
  add column if not exists creado_por text,
  add column if not exists actualizado_por text,
  add column if not exists conversacion jsonb not null default '[]',
  add column if not exists ordenes_servicio_certificado text,
  add column if not exists ordenes_certificado text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.certificados_medicion
set
  conversacion = coalesce(conversacion, '[]'::jsonb),
  estado = coalesce(nullif(trim(estado), ''), 'pendiente'),
  created_at = coalesce(created_at, now()),
  updated_at = coalesce(updated_at, now());

create index if not exists idx_certificados_medicion_zona on public.certificados_medicion(zona);
create index if not exists idx_certificados_medicion_estado on public.certificados_medicion(estado);
create index if not exists idx_certificados_medicion_medicion on public.certificados_medicion(medicion_numero);
create index if not exists idx_certificados_medicion_created_at on public.certificados_medicion(created_at desc);
create index if not exists idx_certificados_medicion_establecimiento on public.certificados_medicion(establecimiento_id);

alter table public.certificados_medicion enable row level security;

do $$
declare
  p record;
begin
  for p in
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'certificados_medicion'
  loop
    execute format('drop policy if exists %I on public.certificados_medicion', p.policyname);
  end loop;
end $$;

create policy "certificados lectura autenticados"
on public.certificados_medicion for select
to authenticated, anon
using (true);

create policy "certificados alta autenticados"
on public.certificados_medicion for insert
to authenticated, anon
with check (true);

create policy "certificados actualizacion autenticados"
on public.certificados_medicion for update
to authenticated, anon
using (true)
with check (true);

create policy "certificados borrado autenticados"
on public.certificados_medicion for delete
to authenticated, anon
using (true);

grant select, insert, update, delete on public.certificados_medicion to authenticated;
grant select, insert, update, delete on public.certificados_medicion to anon;

do $$
begin
  if to_regclass('public.certificados_medicion_id_seq') is not null then
    grant usage, select on sequence public.certificados_medicion_id_seq to authenticated;
    grant usage, select on sequence public.certificados_medicion_id_seq to anon;
  end if;
end $$;

create or replace function public.touch_certificados_medicion()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_touch_certificados_medicion on public.certificados_medicion;
create trigger trg_touch_certificados_medicion
before update on public.certificados_medicion
for each row execute function public.touch_certificados_medicion();

analyze public.certificados_medicion;

commit;

-- Verificacion: deberia devolver la cantidad real sin timeout.
select
  count(*) as certificados_total,
  count(*) filter (where estado <> 'eliminado') as certificados_activos
from public.certificados_medicion;
