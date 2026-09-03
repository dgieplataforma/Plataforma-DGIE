-- DGIE - Aviso a Administracion de que una medicion ya tiene todos sus certificados.
-- Idempotente: se puede correr varias veces sin efecto adicional.
--
-- El inspector marca "carga completa" cuando ya no va a subir mas certificados.
-- Eso queda guardado en los propios certificados y Administracion lo ve en su
-- pantalla sin necesidad de este script. Lo que agrega esto es la notificacion:
-- que a Administracion le suene, en vez de tener que ir a mirar.
--
-- Usa la misma cola que el resto. El `kind` es 'certificado' porque la columna
-- tiene una restriccion cerrada de valores; el `source_id` lleva zona, medicion
-- y marca de tiempo, para que un aviso repetido no quede anulado por el indice
-- unico. El lector separa el id real cortando por ':'.

begin;

create or replace function public.dgie_avisar_carga_completa(
  p_zona integer,
  p_medicion text
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rol text;
  v_zona_perfil integer;
  v_marca text := extract(epoch from clock_timestamp())::bigint::text;
  v_cuantos integer;
  v_avisados integer := 0;
begin
  select lower(trim(rol)), zona into v_rol, v_zona_perfil
    from public.perfiles
   where id = auth.uid();

  if v_rol is null or v_rol <> 'inspector' then
    raise exception 'Solo el inspector de la zona puede avisar la carga completa.';
  end if;

  if coalesce(v_zona_perfil, 0) <> coalesce(p_zona, -1) then
    raise exception 'La zona de la sesión no coincide con la de la medición.';
  end if;

  select count(*) into v_cuantos
    from public.certificados_medicion
   where zona = p_zona
     and medicion_numero::text = p_medicion
     and estado = 'medido';

  insert into public.push_notifications (user_id, kind, source_id, title, body, url)
  select profile.id,
         'certificado',
         'carga-completa:' || p_zona::text || ':' || p_medicion || ':' || v_marca,
         'Zona ' || p_zona::text || ' · Medición ' || p_medicion || ' completa',
         'El inspector avisó que ya no se cargan más certificados. Son ' ||
           v_cuantos::text || ' en total y se pueden revisar.',
         '/?dgiePush=certificado&sourceId=carga-completa'
    from public.perfiles profile
   where profile.id is distinct from auth.uid()
     and lower(trim(profile.rol)) in ('administracion','coordinador')
  on conflict (user_id, kind, source_id) do nothing;

  get diagnostics v_avisados = row_count;
  return v_avisados;
end;
$$;

revoke all on function public.dgie_avisar_carga_completa(integer, text) from public;
revoke all on function public.dgie_avisar_carga_completa(integer, text) from anon;
grant execute on function public.dgie_avisar_carga_completa(integer, text) to authenticated;

commit;

-- ============================================================
-- Verificacion
-- ============================================================
select 'función' as dato,
       case when exists (
         select 1 from pg_proc p
           join pg_namespace n on n.oid = p.pronamespace
          where n.nspname = 'public' and p.proname = 'dgie_avisar_carga_completa')
       then 'creada' else 'FALTA' end as detalle;
