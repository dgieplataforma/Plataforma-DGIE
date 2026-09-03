-- DGIE - Recordatorio de cierre de una comunicacion.
-- Idempotente: se puede correr varias veces sin efecto adicional.
--
-- Coordinacion necesita poder empujar una comunicacion que ya mando, sin volver
-- a crearla. Se puede mandar cuando haga falta y las veces que haga falta: para
-- apurar un cierre, para insistir, o para agregar algo.
--
-- Le llega solo a quien todavia no respondio: a quien ya cumplio no se lo
-- molesta, y asi el aviso se sigue leyendo cuando hay que repetirlo.
--
-- Se apoya en la misma cola de notificaciones que usa el resto de la plataforma.
-- El `kind` sigue siendo 'comunicado' porque la columna tiene una restriccion
-- cerrada de valores; lo que cambia es el `source_id`, que lleva una marca de
-- tiempo para que dos recordatorios seguidos no se pisen entre si. El lector ya
-- separa el id real cortando por ':'.

begin;

create or replace function public.dgie_recordar_comunicacion(
  p_comunicacion_id uuid,
  p_mensaje text default null
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_com public.comunicaciones%rowtype;
  v_rol text;
  v_scope text;
  v_marca text := extract(epoch from clock_timestamp())::bigint::text;
  v_limite text;
  v_cuerpo text;
  v_avisados integer := 0;
begin
  select lower(trim(rol)) into v_rol
    from public.perfiles
   where id = auth.uid();

  if v_rol is null or v_rol not in ('coordinador','director','direccion') then
    raise exception 'Solo coordinación puede mandar recordatorios.';
  end if;

  select * into v_com
    from public.comunicaciones
   where id = p_comunicacion_id;

  if not found then
    raise exception 'No se encontró la comunicación.';
  end if;

  v_scope := lower(coalesce(trim(v_com.alcance), ''));
  v_limite := nullif(trim(coalesce(to_jsonb(v_com.encuesta) #>> '{meta,fechaLimite}', '')), '');

  -- Si no se escribio un mensaje propio, se arma uno con la fecha de cierre.
  v_cuerpo := coalesce(
    nullif(trim(p_mensaje), ''),
    case
      when v_limite is not null
        then 'Cierra el ' || to_char(v_limite::date, 'DD/MM/YYYY') || ' y todavía no registramos tu respuesta.'
      else 'Todavía no registramos tu respuesta.'
    end
  );

  insert into public.push_notifications (user_id, kind, source_id, title, body, url)
  select profile.id,
         'comunicado',
         p_comunicacion_id::text || ':recordatorio:' || v_marca,
         left('Recordatorio: ' || coalesce(nullif(trim(v_com.titulo), ''), 'comunicación'), 120),
         left(v_cuerpo, 300),
         '/?dgiePush=comunicado&sourceId=' || p_comunicacion_id::text
    from public.perfiles profile
   where profile.id is distinct from auth.uid()
     -- Los mismos destinatarios que recibieron la comunicacion original.
     and (
       (v_scope = 'general' and lower(trim(profile.rol)) = 'inspector')
       or (v_scope = 'zona' and lower(trim(profile.rol)) = 'inspector' and profile.zona = any(v_com.zonas))
       or (v_scope = 'empresas' and lower(trim(profile.rol)) = 'empresa')
       or (v_scope = 'empresa_zona' and lower(trim(profile.rol)) = 'empresa' and profile.zona = any(v_com.zonas))
       or (v_scope = 'coordinador' and lower(trim(profile.rol)) = 'coordinador')
     )
     -- Y de esos, solo los que todavia no cerraron su respuesta. La clave con la
     -- que cada destinatario guarda su estado depende de su rol.
     and coalesce(
           v_com.estados #>> ARRAY[
             case lower(trim(profile.rol))
               when 'empresa' then 'empresa-' || profile.zona::text
               when 'coordinador' then 'coordinacion'
               else profile.zona::text
             end,
             'estado'
           ],
           'pendiente'
         ) not in ('completado','visto','cerrada')
  on conflict (user_id, kind, source_id) do nothing;

  get diagnostics v_avisados = row_count;
  return v_avisados;
end;
$$;

revoke all on function public.dgie_recordar_comunicacion(uuid, text) from public;
revoke all on function public.dgie_recordar_comunicacion(uuid, text) from anon;
grant execute on function public.dgie_recordar_comunicacion(uuid, text) to authenticated;

commit;

-- ============================================================
-- Verificacion
-- ============================================================
select 'función' as dato,
       case when exists (
         select 1 from pg_proc p
           join pg_namespace n on n.oid = p.pronamespace
          where n.nspname = 'public' and p.proname = 'dgie_recordar_comunicacion')
       then 'creada' else 'FALTA' end as detalle;
