create temp table if not exists reset_plataforma_resultado (
  tabla text primary key,
  restantes integer not null
) on commit drop;

truncate reset_plataforma_resultado;

do $$
declare
  tablas text[] := array[
    'reclamos',
    'ordenes_servicio',
    'intervenciones',
    'relevamientos',
    'comunicaciones'
  ];
  t text;
  c integer;
begin
  -- Reset para salir a produccion.
  -- Borra datos de uso/prueba y conserva usuarios, perfiles, establecimientos y planos.
  -- Es seguro si alguna tabla todavia no existe.

  if to_regclass('public.fotos') is not null then
    delete from public.fotos
    where entidad_tipo in ('reclamo','orden_servicio','intervencion','relevamiento');
  end if;

  if to_regclass('public.comunicaciones') is not null then
    delete from public.comunicaciones;
  end if;

  if to_regclass('public.intervenciones') is not null then
    delete from public.intervenciones;
  end if;

  if to_regclass('public.relevamientos') is not null then
    delete from public.relevamientos;
  end if;

  if to_regclass('public.ordenes_servicio') is not null then
    delete from public.ordenes_servicio;
  end if;

  if to_regclass('public.reclamos') is not null then
    delete from public.reclamos;
  end if;

  foreach t in array tablas loop
    if to_regclass('public.' || t) is not null then
      execute format('select count(*) from public.%I', t) into c;
    else
      c := 0;
    end if;
    insert into reset_plataforma_resultado(tabla, restantes)
    values (t, c)
    on conflict (tabla) do update set restantes = excluded.restantes;
  end loop;

  if to_regclass('public.fotos') is not null then
    select count(*) into c
    from public.fotos
    where entidad_tipo in ('reclamo','orden_servicio','intervencion','relevamiento');
  else
    c := 0;
  end if;
  insert into reset_plataforma_resultado(tabla, restantes)
  values ('fotos_operativas', c)
  on conflict (tabla) do update set restantes = excluded.restantes;
end $$;

select * from reset_plataforma_resultado order by tabla;
