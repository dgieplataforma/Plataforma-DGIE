create table if not exists public.saludos_cumpleanios (
  id uuid primary key default gen_random_uuid(),
  homenajeado_zona integer not null check (homenajeado_zona between 1 and 17),
  homenajeado_apodo text not null check (length(trim(homenajeado_apodo)) between 1 and 80),
  fecha_evento date not null,
  mensaje text not null check (length(trim(mensaje)) between 1 and 500),
  autor_id uuid not null default auth.uid() references auth.users(id),
  autor_nombre text not null check (length(trim(autor_nombre)) between 1 and 120),
  created_at timestamptz not null default now()
);

create index if not exists saludos_cumpleanios_evento_idx
  on public.saludos_cumpleanios(homenajeado_zona, fecha_evento, created_at desc);

alter table public.saludos_cumpleanios enable row level security;

-- Etapa de prueba: sólo la zona del festejo, igual que lo que muestra la
-- pantalla. Si la base dejara entrar a coordinación mientras el cartel no se le
-- muestra, se podría leer el saludo por acceso directo y se pierde la sorpresa.
-- Para el lanzamiento general están, comentadas, las líneas que suman a
-- coordinación: se descomentan y se vuelve a correr este mismo archivo.

drop policy if exists "saludos lectura inspectores coordinacion" on public.saludos_cumpleanios;
create policy "saludos lectura inspectores coordinacion" on public.saludos_cumpleanios
for select to authenticated using (
  exists (
    select 1
    from public.perfiles p
    where p.id = auth.uid()
      and (
        -- p.rol = 'coordinador' or          -- lanzamiento general
        (p.rol = 'inspector' and p.zona = saludos_cumpleanios.homenajeado_zona)
      )
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
      and (
        -- p.rol = 'coordinador' or          -- lanzamiento general
        (p.rol = 'inspector' and p.zona = saludos_cumpleanios.homenajeado_zona)
      )
  )
);

grant select, insert on public.saludos_cumpleanios to authenticated;
