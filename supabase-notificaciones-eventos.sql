begin;

alter table public.push_notifications
  drop constraint if exists push_notifications_kind_check;

alter table public.push_notifications
  add constraint push_notifications_kind_check
  check (kind in (
    'comunicado',
    'reclamo',
    'certificado',
    'comentario_intervencion',
    'comentario_relevamiento'
  ));

create or replace function public.dgie_marcar_notificaciones_push_leidas(p_kind text default null)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_count integer;
begin
  if v_user_id is null then
    raise exception 'Se requiere una sesion valida.' using errcode = '42501';
  end if;
  if p_kind is not null and p_kind not in (
    'comunicado',
    'reclamo',
    'certificado',
    'comentario_intervencion',
    'comentario_relevamiento'
  ) then
    raise exception 'Tipo de notificacion invalido.' using errcode = '22023';
  end if;

  update public.push_notifications
     set read_at = now()
   where user_id = v_user_id
     and read_at is null
     and (p_kind is null or kind = p_kind);
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.dgie_marcar_notificaciones_push_leidas(text) from public;
grant execute on function public.dgie_marcar_notificaciones_push_leidas(text) to authenticated;

commit;
