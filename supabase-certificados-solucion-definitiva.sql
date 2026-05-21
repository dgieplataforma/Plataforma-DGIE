-- Solucion definitiva para certificados_medicion.
-- Mantiene seguridad RLS por rol/zona y no borra certificados existentes.
--
-- Ejecutar completo en Supabase > SQL Editor.

begin;

create table if not exists public.certificados_medicion (
  id bigserial primary key,
  establecimiento_id integer references public.establecimientos(id) on delete set null,
  establecimiento_nombre text,
  zona integer,
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
  conversacion jsonb not null default '[]'::jsonb,
  ordenes_servicio_certificado text,
  ordenes_certificado text,
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
  add column if not exists estado text default 'pendiente',
  add column if not exists creado_por text,
  add column if not exists actualizado_por text,
  add column if not exists conversacion jsonb default '[]'::jsonb,
  add column if not exists ordenes_servicio_certificado text,
  add column if not exists ordenes_certificado text,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

update public.certificados_medicion
set
  estado = coalesce(nullif(trim(estado), ''), 'pendiente'),
  conversacion = coalesce(conversacion, '[]'::jsonb),
  modulos_original = coalesce(modulos_original, 0),
  monto_empresa = coalesce(monto_empresa, modulos_original, 0),
  modulos_inspector = coalesce(modulos_inspector, 0),
  monto_inspeccion = coalesce(monto_inspeccion, modulos_inspector, 0),
  created_at = coalesce(created_at, now()),
  updated_at = coalesce(updated_at, now());

alter table public.certificados_medicion
  alter column estado set default 'pendiente',
  alter column conversacion set default '[]'::jsonb,
  alter column created_at set default now(),
  alter column updated_at set default now();

create index if not exists idx_perfiles_id_activo on public.perfiles(id, activo);
create index if not exists idx_perfiles_rol_zona_activo on public.perfiles(rol, zona, activo);

create index if not exists idx_certificados_medicion_zona on public.certificados_medicion(zona);
create index if not exists idx_certificados_medicion_created_at on public.certificados_medicion(created_at desc);
create index if not exists idx_certificados_medicion_zona_created_at on public.certificados_medicion(zona, created_at desc);
create index if not exists idx_certificados_medicion_estado on public.certificados_medicion(estado);
create index if not exists idx_certificados_medicion_medicion on public.certificados_medicion(medicion_numero);
create index if not exists idx_certificados_medicion_establecimiento on public.certificados_medicion(establecimiento_id);

create or replace function public.certificados_puede_gestionar(p_zona integer)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.perfiles p
    where p.id = auth.uid()
      and p.activo = true
      and (
        p.rol in ('director', 'coordinador')
        or (p.rol in ('inspector', 'empresa') and p.zona = p_zona)
      )
  )
$$;

create or replace function public.certificados_puede_borrar(p_zona integer)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.perfiles p
    where p.id = auth.uid()
      and p.activo = true
      and (
        p.rol in ('director', 'coordinador')
        or (p.rol = 'inspector' and p.zona = p_zona)
      )
  )
$$;

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

create policy "certificados lectura por rol y zona"
on public.certificados_medicion
for select
to authenticated
using (public.certificados_puede_gestionar(zona));

create policy "certificados alta por rol y zona"
on public.certificados_medicion
for insert
to authenticated
with check (public.certificados_puede_gestionar(zona));

create policy "certificados actualizacion por rol y zona"
on public.certificados_medicion
for update
to authenticated
using (public.certificados_puede_gestionar(zona))
with check (public.certificados_puede_gestionar(zona));

create policy "certificados borrado por inspector o gestion"
on public.certificados_medicion
for delete
to authenticated
using (public.certificados_puede_borrar(zona));

grant select, insert, update, delete on public.certificados_medicion to authenticated;
grant execute on function public.certificados_puede_gestionar(integer) to authenticated;
grant execute on function public.certificados_puede_borrar(integer) to authenticated;

do $$
begin
  if to_regclass('public.certificados_medicion_id_seq') is not null then
    grant usage, select on sequence public.certificados_medicion_id_seq to authenticated;
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

analyze public.perfiles;
analyze public.certificados_medicion;

commit;

-- Verificacion general. Debe devolver rapido.
select
  zona,
  count(*) as certificados
from public.certificados_medicion
group by zona
order by zona;
