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

create or replace function public.dgie_encolar_certificado_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.push_notifications (user_id, kind, source_id, title, body, url)
  select
    perfil.id,
    'certificado',
    new.id::text,
    'Nuevo certificado - Zona ' || new.zona::text,
    coalesce(nullif(new.establecimiento_nombre, ''), 'Establecimiento') || ': ' ||
      coalesce(nullif(new.archivo_original, ''), 'Certificado pendiente de revisión'),
    '/?dgiePush=certificado&sourceId=' || new.id::text
  from public.perfiles perfil
  where lower(coalesce(perfil.rol, '')) = 'inspector'
    and perfil.zona = new.zona
  on conflict (user_id, kind, source_id) do nothing;

  return new;
end;
$$;

drop trigger if exists dgie_certificado_push on public.certificados_medicion;
create trigger dgie_certificado_push
after insert on public.certificados_medicion
for each row execute function public.dgie_encolar_certificado_push();

commit;