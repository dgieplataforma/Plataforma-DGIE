-- Evita que dos respuestas simultaneas reemplacen el JSON completo de la otra.
-- Las funciones se ejecutan con los permisos del usuario y respetan las politicas RLS.

create or replace function public.dgie_actualizar_respuesta_comunicacion(
  p_comunicacion_id text,
  p_clave text,
  p_respuesta jsonb
)
returns setof public.comunicaciones
language sql
security invoker
set search_path = public
as $$
  update public.comunicaciones
  set estados = coalesce(estados, '{}'::jsonb)
    || jsonb_build_object(p_clave, coalesce(p_respuesta, '{}'::jsonb))
  where id::text = p_comunicacion_id
  returning *;
$$;

create or replace function public.dgie_actualizar_validacion_comunicacion(
  p_comunicacion_id text,
  p_clave text,
  p_validacion jsonb
)
returns setof public.comunicaciones
language sql
security invoker
set search_path = public
as $$
  update public.comunicaciones
  set validaciones = coalesce(validaciones, '{}'::jsonb)
    || jsonb_build_object(p_clave, coalesce(p_validacion, '{}'::jsonb))
  where id::text = p_comunicacion_id
  returning *;
$$;

revoke all on function public.dgie_actualizar_respuesta_comunicacion(text, text, jsonb) from public;
revoke all on function public.dgie_actualizar_validacion_comunicacion(text, text, jsonb) from public;
grant execute on function public.dgie_actualizar_respuesta_comunicacion(text, text, jsonb) to authenticated;
grant execute on function public.dgie_actualizar_validacion_comunicacion(text, text, jsonb) to authenticated;
