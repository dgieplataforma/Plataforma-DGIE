-- Certificacion: habilita el estado "devuelto" sin modificar registros existentes.

begin;

do $$
declare
  restriccion record;
  columna_estado smallint;
begin
  select attnum
  into columna_estado
  from pg_attribute
  where attrelid = 'public.certificados_medicion'::regclass
    and attname = 'estado'
    and not attisdropped;

  for restriccion in
    select conname
    from pg_constraint
    where conrelid = 'public.certificados_medicion'::regclass
      and contype = 'c'
      and conkey = array[columna_estado]::smallint[]
  loop
    execute format(
      'alter table public.certificados_medicion drop constraint %I',
      restriccion.conname
    );
  end loop;
end
$$;

alter table public.certificados_medicion
  add constraint certificados_medicion_estado_check
  check (estado in ('pendiente','revision','devuelto','medido','eliminado'))
  not valid;

alter table public.certificados_medicion
  validate constraint certificados_medicion_estado_check;

create index if not exists certificados_medicion_zona_estado_actualizado_idx
  on public.certificados_medicion (zona, estado, updated_at desc);

commit;
