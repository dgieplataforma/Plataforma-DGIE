-- DGIE - Permitir que inspectores corrijan ubicacion de establecimientos de su zona
-- Ejecutar en Supabase SQL Editor.

alter table public.establecimientos
  add column if not exists lat numeric,
  add column if not exists lng numeric;

create or replace function public.actualizar_ubicacion_establecimiento(
  p_id bigint,
  p_direccion text,
  p_barrio text,
  p_lat numeric,
  p_lng numeric
)
returns public.establecimientos
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user public.perfiles;
  v_est public.establecimientos;
begin
  select * into v_user
  from public.perfiles
  where id = auth.uid() and activo = true;

  if v_user.id is null then
    raise exception 'Usuario no autenticado';
  end if;

  select * into v_est
  from public.establecimientos
  where id = p_id;

  if v_est.id is null then
    raise exception 'Establecimiento inexistente';
  end if;

  if v_user.rol not in ('director','coordinador')
     and not (v_user.rol = 'inspector' and v_user.zona = v_est.zona) then
    raise exception 'No autorizado para modificar este establecimiento';
  end if;

  update public.establecimientos
  set direccion = coalesce(nullif(trim(p_direccion), ''), direccion),
      barrio = coalesce(nullif(trim(p_barrio), ''), barrio),
      lat = p_lat,
      lng = p_lng
  where id = p_id
  returning * into v_est;

  return v_est;
end;
$$;

grant execute on function public.actualizar_ubicacion_establecimiento(bigint,text,text,numeric,numeric) to authenticated;
