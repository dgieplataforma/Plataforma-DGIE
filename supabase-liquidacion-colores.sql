-- DGIE - Color de cada medicion en la planilla de liquidacion.
-- Idempotente: se puede correr varias veces sin efecto adicional.
--
-- Cada zona elige el color de sus mediciones. Se guarda en la base y no en el
-- navegador para que la planilla salga igual para el inspector, coordinacion y
-- quien la imprima.
--
-- Si una zona no elige nada, la plataforma usa los colores de la planilla
-- firmada (1ra amarillo, 2da celeste, 3ra naranja, 4ta verde) y sigue con el
-- mismo juego de ahi en adelante. Esta tabla solo guarda lo que se cambia.

begin;

create table if not exists public.liquidacion_colores (
  zona      integer     not null,
  medicion  integer     not null,
  color     text        not null,
  creado_at timestamptz not null default now(),
  creado_por text,
  primary key (zona, medicion)
);

comment on table public.liquidacion_colores is
  'Color con el que cada zona pinta cada medicion en la planilla de liquidacion.';
comment on column public.liquidacion_colores.color is
  'Color en formato #RRGGBB.';

alter table public.liquidacion_colores drop constraint if exists liquidacion_colores_color_check;
alter table public.liquidacion_colores
  add constraint liquidacion_colores_color_check
  check (color ~* '^#[0-9a-f]{6}$');

alter table public.liquidacion_colores enable row level security;

-- Lo lee cualquier sesion iniciada: la planilla tiene que verse igual para todos.
drop policy if exists "colores liquidacion lectura" on public.liquidacion_colores;
create policy "colores liquidacion lectura"
  on public.liquidacion_colores
  for select
  to authenticated
  using (true);

-- Lo edita quien trabaja esa zona, mas coordinacion, direccion y administracion.
drop policy if exists "colores liquidacion escritura" on public.liquidacion_colores;
create policy "colores liquidacion escritura"
  on public.liquidacion_colores
  for all
  to authenticated
  using (
    public.mi_rol() in ('coordinador','director','direccion','administracion')
    or public.mi_zona() = zona
  )
  with check (
    public.mi_rol() in ('coordinador','director','direccion','administracion')
    or public.mi_zona() = zona
  );

grant select, insert, update, delete on public.liquidacion_colores to authenticated;

commit;

-- ============================================================
-- Verificacion
-- ============================================================
select 'tabla' as dato,
       case when to_regclass('public.liquidacion_colores') is null
            then 'FALTA' else 'creada' end as detalle
union all
select 'colores elegidos', count(*)::text from public.liquidacion_colores;
