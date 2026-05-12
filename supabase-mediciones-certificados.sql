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

alter table public.certificados_medicion enable row level security;

drop policy if exists "certificados lectura autenticados" on public.certificados_medicion;
create policy "certificados lectura autenticados"
on public.certificados_medicion for select
to authenticated
using (true);

drop policy if exists "certificados alta autenticados" on public.certificados_medicion;
create policy "certificados alta autenticados"
on public.certificados_medicion for insert
to authenticated
with check (true);

drop policy if exists "certificados actualizacion autenticados" on public.certificados_medicion;
create policy "certificados actualizacion autenticados"
on public.certificados_medicion for update
to authenticated
using (true)
with check (true);

drop policy if exists "certificados borrado autenticados" on public.certificados_medicion;
create policy "certificados borrado autenticados"
on public.certificados_medicion for delete
to authenticated
using (true);

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

-- Deja la base lista para empezar sin certificados cargados.
truncate table public.certificados_medicion restart identity;
