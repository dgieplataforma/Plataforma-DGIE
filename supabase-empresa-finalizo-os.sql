alter table public.ordenes_servicio
  add column if not exists empresa_finalizo boolean not null default false,
  add column if not exists empresa_finalizo_fecha timestamptz,
  add column if not exists empresa_finalizo_por text;

create or replace function public.marcar_empresa_finalizo(
  p_orden_id uuid,
  p_valor boolean
)
returns public.ordenes_servicio
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.ordenes_servicio;
begin
  update public.ordenes_servicio
     set empresa_finalizo = coalesce(p_valor, false),
         empresa_finalizo_fecha = case when coalesce(p_valor, false) then now() else null end,
         empresa_finalizo_por = auth.uid()::text,
         updated_at = now()
   where id = p_orden_id
   returning * into v_row;

  if v_row.id is null then
    raise exception 'No se encontró la orden de servicio %', p_orden_id;
  end if;

  return v_row;
end;
$$;

grant execute on function public.marcar_empresa_finalizo(uuid, boolean) to anon, authenticated;
