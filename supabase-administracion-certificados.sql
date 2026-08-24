-- DGIE - Sesion "Administracion" para revisar certificados.
-- Idempotente: se puede correr varias veces sin efecto adicional.
-- NO crea usuarios ni contrasenas: eso se hace desde el panel de autenticacion.
--
-- Que hace:
--   1) permite el rol 'administracion' en perfiles, conservando los que ya existian;
--   2) agrega a certificados_medicion las columnas de revision administrativa;
--   3) crea el indice de la bandeja;
--   4) crea las politicas de lectura y escritura para ese rol;
--   5) vincula el perfil si el usuario administracion@dgie.local ya existe en auth.users.

begin;

-- ============================================================
-- 1) Rol 'administracion' permitido en perfiles
-- ============================================================
alter table public.perfiles drop constraint if exists perfiles_rol_check;
alter table public.perfiles
  add constraint perfiles_rol_check
  check (rol in (
    'director',
    'coordinador',
    'inspector',
    'empresa',
    'callcenter',
    'prensa',
    'tableros',
    'administracion'
  ));

-- ============================================================
-- 2) Columnas de revision administrativa
-- ============================================================
alter table public.certificados_medicion
  add column if not exists revision_admin_estado          text default 'pendiente',
  add column if not exists revision_admin_version         integer default 1,
  add column if not exists revision_admin_historial       jsonb default '[]'::jsonb,
  add column if not exists revision_admin_actualizado_at  timestamptz,
  add column if not exists revision_admin_actualizado_por text,
  add column if not exists modulos_aprobados              numeric,
  add column if not exists aprobado_at                    timestamptz,
  add column if not exists aprobado_por                   text;

comment on column public.certificados_medicion.revision_admin_estado is
  'Estado administrativo, independiente del estado tecnico: pendiente | observado | aprobado.';
comment on column public.certificados_medicion.revision_admin_version is
  'Version vigente del certificado. Sube cada vez que el inspector presenta una correccion.';
comment on column public.certificados_medicion.revision_admin_historial is
  'Historial completo: observaciones, aprobaciones y foto de cada version anterior (archivo, url, public_id, modulos y observaciones del inspector).';
comment on column public.certificados_medicion.modulos_aprobados is
  'Cantidad de modulos que aprobo Administracion. Es la cifra oficial.';

-- Las filas que ya existian quedan en 'pendiente' con version 1.
update public.certificados_medicion
   set revision_admin_estado = coalesce(nullif(trim(revision_admin_estado), ''), 'pendiente'),
       revision_admin_version = coalesce(revision_admin_version, 1),
       revision_admin_historial = coalesce(revision_admin_historial, '[]'::jsonb)
 where revision_admin_estado is null
    or trim(coalesce(revision_admin_estado, '')) = ''
    or revision_admin_version is null
    or revision_admin_historial is null;

alter table public.certificados_medicion drop constraint if exists certificados_revision_admin_estado_check;
alter table public.certificados_medicion
  add constraint certificados_revision_admin_estado_check
  check (revision_admin_estado in ('pendiente', 'observado', 'aprobado'));

-- ============================================================
-- 3) Indice de la bandeja
-- ============================================================
create index if not exists idx_certificados_revision_admin
  on public.certificados_medicion (revision_admin_estado, zona, revision_admin_actualizado_at desc);

-- ============================================================
-- 4) Politicas para el rol administracion
-- ============================================================
-- Lee todos los certificados de todas las zonas.
drop policy if exists "administracion lee certificados" on public.certificados_medicion;
create policy "administracion lee certificados"
  on public.certificados_medicion
  for select
  to authenticated
  using (public.mi_rol() = 'administracion');

-- Actualiza cualquier certificado (revision administrativa).
drop policy if exists "administracion actualiza certificados" on public.certificados_medicion;
create policy "administracion actualiza certificados"
  on public.certificados_medicion
  for update
  to authenticated
  using (public.mi_rol() = 'administracion')
  with check (public.mi_rol() = 'administracion');

-- Necesita leer establecimientos para mostrar nombres y zonas.
drop policy if exists "administracion lee establecimientos" on public.establecimientos;
create policy "administracion lee establecimientos"
  on public.establecimientos
  for select
  to authenticated
  using (public.mi_rol() = 'administracion');

grant select, update on public.certificados_medicion to authenticated;

-- ============================================================
-- 5) Perfil de Administracion
-- ============================================================
-- Solo vincula el perfil si el usuario YA existe en autenticacion.
-- Si no existe todavia, no hace nada y hay que crearlo a mano primero.
insert into public.perfiles (id, nombre, rol, activo)
select u.id, 'Administración', 'administracion', true
  from auth.users u
 where lower(u.email) = 'administracion@dgie.local'
on conflict (id) do update
  set nombre = excluded.nombre,
      rol    = excluded.rol,
      activo = true;

commit;

-- ============================================================
-- Verificacion
-- ============================================================
select 'perfil' as dato,
       coalesce((select nombre || ' · ' || rol from public.perfiles p
                  join auth.users u on u.id = p.id
                 where lower(u.email) = 'administracion@dgie.local'),
                'FALTA: crear administracion@dgie.local en autenticacion') as detalle
union all
select 'columnas',
       string_agg(column_name, ', ' order by column_name)
  from information_schema.columns
 where table_schema = 'public' and table_name = 'certificados_medicion'
   and column_name in ('revision_admin_estado','revision_admin_version','revision_admin_historial',
                       'revision_admin_actualizado_at','revision_admin_actualizado_por',
                       'modulos_aprobados','aprobado_at','aprobado_por')
union all
select 'certificados por estado administrativo',
       string_agg(revision_admin_estado || ': ' || n::text, ' · ')
  from (select revision_admin_estado, count(*) as n
          from public.certificados_medicion
         group by revision_admin_estado) t;
