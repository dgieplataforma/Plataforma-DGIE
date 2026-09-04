create table if not exists public.saludos_cumpleanios (
  id uuid primary key default gen_random_uuid(),
  -- La zona del homenajeado. El 0 es coordinacion, que no tiene zona propia.
  homenajeado_zona integer not null check (homenajeado_zona between 0 and 17),
  homenajeado_apodo text not null check (length(trim(homenajeado_apodo)) between 1 and 80),
  fecha_evento date not null,
  mensaje text not null check (length(trim(mensaje)) between 1 and 500),
  autor_id uuid not null default auth.uid() references auth.users(id),
  autor_nombre text not null check (length(trim(autor_nombre)) between 1 and 120),
  created_at timestamptz not null default now()
);

-- La primera version de esta tabla solo aceptaba zonas del 1 al 17, y el
-- `create table if not exists` de arriba no toca una tabla que ya existe. Se
-- rehace la restriccion para que entre tambien el 0, que es coordinacion.
do $$
begin
  alter table public.saludos_cumpleanios
    drop constraint if exists saludos_cumpleanios_homenajeado_zona_check;
  alter table public.saludos_cumpleanios
    add constraint saludos_cumpleanios_homenajeado_zona_check
    check (homenajeado_zona between 0 and 17);
end $$;

create index if not exists saludos_cumpleanios_evento_idx
  on public.saludos_cumpleanios(homenajeado_zona, fecha_evento, created_at desc);

alter table public.saludos_cumpleanios enable row level security;

-- Quien puede leer y escribir saludos: inspectores y coordinación, de cualquier
-- zona. Es el mismo alcance que muestra la pantalla el día del festejo, porque
-- son justamente los que van a saludar. Empresa, dirección, tableros,
-- administración y call center quedan afuera por las dos vías.
--
-- La sorpresa no la cuida la base sino la fecha: el cartel aparece únicamente el
-- día que corresponde.

drop policy if exists "saludos lectura inspectores coordinacion" on public.saludos_cumpleanios;
create policy "saludos lectura inspectores coordinacion" on public.saludos_cumpleanios
for select to authenticated using (
  exists (
    select 1
    from public.perfiles p
    where p.id = auth.uid()
      and p.rol in ('inspector','coordinador')
  )
);

drop policy if exists "saludos crear inspectores coordinacion" on public.saludos_cumpleanios;
create policy "saludos crear inspectores coordinacion" on public.saludos_cumpleanios
for insert to authenticated with check (
  autor_id = auth.uid()
  and exists (
    select 1
    from public.perfiles p
    where p.id = auth.uid()
      and p.rol in ('inspector','coordinador')
  )
);

grant select, insert on public.saludos_cumpleanios to authenticated;
