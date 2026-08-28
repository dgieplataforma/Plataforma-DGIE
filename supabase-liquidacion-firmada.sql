-- DGIE - La planilla de liquidacion firmada, pasada a tabla.
-- Idempotente: se puede correr varias veces sin efecto adicional.
--
-- Las mediciones anteriores a la septima ya se liquidaron y se firmaron en
-- papel. Recalcularlas daria numeros que no son los que se cobraron, asi que
-- para esas la fuente de verdad es el PDF firmado: se lee su planilla, se pasa
-- a tabla y queda guardada tal cual. Desde la septima, la liquidacion se arma
-- directamente con los certificados.
--
-- Cada fila de la planilla firmada queda como una fila de esta tabla, con sus
-- modulos abiertos por rubro, para poder consultarla y cruzarla despues.

begin;

create table if not exists public.liquidacion_firmada (
  id             bigserial primary key,
  zona           integer not null,
  medicion       integer not null,
  orden          integer not null,          -- posicion dentro de la planilla
  nro            integer,                   -- numero del establecimiento en la zona
  establecimiento text,
  orden_servicio text,
  cubierta       numeric default 0,
  electricidad   numeric default 0,
  albanileria    numeric default 0,
  sanitaria      numeric default 0,
  gas            numeric default 0,
  modulos        numeric default 0,
  monto          numeric default 0,
  archivo        text,                      -- de que PDF se leyo
  creado_at      timestamptz not null default now()
);

comment on table public.liquidacion_firmada is
  'Planilla de liquidacion tal como fue firmada, leida del PDF. Es la fuente de verdad de las mediciones anteriores a la septima.';

create unique index if not exists liquidacion_firmada_unica
  on public.liquidacion_firmada (zona, medicion, orden);
create index if not exists liquidacion_firmada_zona_medicion
  on public.liquidacion_firmada (zona, medicion);

-- Totales de cada medicion, tal como figuran al pie de la planilla firmada.
create table if not exists public.liquidacion_firmada_totales (
  zona         integer not null,
  medicion     integer not null,
  cubierta     numeric default 0,
  electricidad numeric default 0,
  albanileria  numeric default 0,
  sanitaria    numeric default 0,
  gas          numeric default 0,
  modulos      numeric default 0,
  monto        numeric default 0,
  archivo      text,
  creado_at    timestamptz not null default now(),
  primary key (zona, medicion)
);

alter table public.liquidacion_firmada         enable row level security;
alter table public.liquidacion_firmada_totales enable row level security;

drop policy if exists "liquidacion firmada lectura" on public.liquidacion_firmada;
create policy "liquidacion firmada lectura"
  on public.liquidacion_firmada for select to authenticated using (true);

drop policy if exists "liquidacion firmada escritura" on public.liquidacion_firmada;
create policy "liquidacion firmada escritura"
  on public.liquidacion_firmada for all to authenticated
  using (public.mi_rol() in ('coordinador','director','direccion','administracion') or public.mi_zona() = zona)
  with check (public.mi_rol() in ('coordinador','director','direccion','administracion') or public.mi_zona() = zona);

drop policy if exists "liquidacion firmada totales lectura" on public.liquidacion_firmada_totales;
create policy "liquidacion firmada totales lectura"
  on public.liquidacion_firmada_totales for select to authenticated using (true);

drop policy if exists "liquidacion firmada totales escritura" on public.liquidacion_firmada_totales;
create policy "liquidacion firmada totales escritura"
  on public.liquidacion_firmada_totales for all to authenticated
  using (public.mi_rol() in ('coordinador','director','direccion','administracion') or public.mi_zona() = zona)
  with check (public.mi_rol() in ('coordinador','director','direccion','administracion') or public.mi_zona() = zona);

grant select, insert, update, delete on public.liquidacion_firmada to authenticated;
grant select, insert, update, delete on public.liquidacion_firmada_totales to authenticated;
grant usage, select on sequence public.liquidacion_firmada_id_seq to authenticated;

commit;

-- ============================================================
-- Verificacion
-- ============================================================
select 'tablas' as dato,
       coalesce(string_agg(table_name, ', ' order by table_name), 'FALTAN') as detalle
  from information_schema.tables
 where table_schema = 'public'
   and table_name in ('liquidacion_firmada', 'liquidacion_firmada_totales')
union all
select 'filas cargadas', count(*)::text from public.liquidacion_firmada;
