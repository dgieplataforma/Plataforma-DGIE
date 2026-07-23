begin;

create extension if not exists pgcrypto;

alter table public.push_subscriptions
  add column if not exists disabled_at timestamptz;

create table if not exists public.push_deliveries (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.push_notifications(id) on delete cascade,
  subscription_id uuid not null references public.push_subscriptions(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending','processing','delivered','failed','stale')),
  attempts integer not null default 0,
  next_attempt_at timestamptz not null default now(),
  locked_at timestamptz,
  delivered_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint push_deliveries_notification_subscription_key
    unique (notification_id, subscription_id)
);

create index if not exists push_deliveries_pending_idx
  on public.push_deliveries (next_attempt_at, created_at)
  where status in ('pending','failed','processing');

alter table public.push_deliveries enable row level security;
revoke all on table public.push_deliveries from anon, authenticated;

create or replace function public.dgie_crear_entregas_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.push_deliveries (notification_id, subscription_id)
  select new.id, subscription.id
    from public.push_subscriptions subscription
   where subscription.user_id = new.user_id
     and subscription.disabled_at is null
  on conflict (notification_id, subscription_id) do nothing;
  return new;
end;
$$;

drop trigger if exists dgie_push_notification_deliveries on public.push_notifications;
create trigger dgie_push_notification_deliveries
after insert on public.push_notifications
for each row execute function public.dgie_crear_entregas_push();

create or replace function public.dgie_encolar_reclamo_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_establecimiento text;
  v_detalle text;
begin
  select nullif(trim(est.nombre), '')
    into v_establecimiento
    from public.establecimientos est
   where est.id = new.establecimiento_id;

  v_detalle := coalesce(nullif(trim(new.titulo), ''), nullif(trim(new.descripcion), ''), 'Nuevo reclamo');

  insert into public.push_notifications (user_id, kind, source_id, title, body, url)
  select profile.id,
         'reclamo',
         new.id::text,
         'Nuevo reclamo - Zona ' || new.zona::text,
         left(concat_ws(': ', v_establecimiento, v_detalle), 300),
         '/?dgiePush=reclamo&sourceId=' || new.id::text
    from public.perfiles profile
   where lower(trim(profile.rol)) = 'inspector'
     and profile.zona = new.zona
     and profile.id is distinct from new.creado_por
  on conflict (user_id, kind, source_id) do nothing;

  return new;
end;
$$;

drop trigger if exists dgie_reclamo_push_queue on public.reclamos;
create trigger dgie_reclamo_push_queue
after insert on public.reclamos
for each row execute function public.dgie_encolar_reclamo_push();

create or replace function public.dgie_encolar_comunicacion_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_scope text := lower(coalesce(trim(new.alcance), ''));
  v_copy_coordination boolean :=
    coalesce((to_jsonb(new.encuesta) #>> '{meta,copiaCoordinacion}')::boolean, false);
begin
  insert into public.push_notifications (user_id, kind, source_id, title, body, url)
  select profile.id,
         'comunicado',
         new.id::text,
         'Nuevo comunicado',
         left(coalesce(nullif(trim(new.titulo), ''), nullif(trim(new.mensaje), ''), 'Tenés un nuevo comunicado.'), 300),
         '/?dgiePush=comunicado&sourceId=' || new.id::text
    from public.perfiles profile
   where profile.id is distinct from new.creado_por
     and (
       (v_scope = 'general' and lower(trim(profile.rol)) = 'inspector')
       or (v_scope = 'zona' and lower(trim(profile.rol)) = 'inspector' and profile.zona = any(new.zonas))
       or (v_scope = 'empresas' and lower(trim(profile.rol)) = 'empresa')
       or (v_scope = 'empresa_zona' and lower(trim(profile.rol)) = 'empresa' and profile.zona = any(new.zonas))
       or (v_scope = 'coordinador' and lower(trim(profile.rol)) = 'coordinador')
       or (v_copy_coordination and lower(trim(profile.rol)) = 'coordinador')
     )
  on conflict (user_id, kind, source_id) do nothing;

  return new;
end;
$$;

drop trigger if exists dgie_comunicacion_push_queue on public.comunicaciones;
create trigger dgie_comunicacion_push_queue
after insert on public.comunicaciones
for each row execute function public.dgie_encolar_comunicacion_push();

create or replace function public.dgie_reclamar_push_deliveries(
  p_limite integer default 100,
  p_notificacion_ids text[] default null
)
returns table (
  delivery_id uuid,
  notification_id uuid,
  subscription_id uuid,
  endpoint text,
  p256dh text,
  auth text,
  kind text,
  source_id text,
  title text,
  body text,
  url text,
  unread_count bigint
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  return query
  with candidates as (
    select delivery.id
      from public.push_deliveries delivery
      join public.push_notifications notification on notification.id = delivery.notification_id
      join public.push_subscriptions subscription on subscription.id = delivery.subscription_id
     where subscription.disabled_at is null
       and notification.created_at >= now() - interval '7 days'
       and delivery.attempts < 50
       and (
         (delivery.status in ('pending','failed') and delivery.next_attempt_at <= now())
         or (delivery.status = 'processing' and delivery.locked_at < now() - interval '10 minutes')
       )
       and (p_notificacion_ids is null or notification.id::text = any(p_notificacion_ids))
     order by delivery.next_attempt_at, delivery.created_at
     for update of delivery skip locked
     limit least(greatest(coalesce(p_limite,100),1),200)
  ),
  claimed as (
    update public.push_deliveries delivery
       set status = 'processing',
           attempts = delivery.attempts + 1,
           locked_at = now(),
           updated_at = now()
      from candidates
     where delivery.id = candidates.id
    returning delivery.*
  )
  select claimed.id,
         notification.id,
         subscription.id,
         subscription.endpoint,
         subscription.p256dh,
         subscription.auth,
         notification.kind,
         notification.source_id,
         notification.title,
         notification.body,
         notification.url,
         (
           select count(*)
             from public.push_notifications unread
            where unread.user_id = notification.user_id
              and unread.read_at is null
         )::bigint
    from claimed
    join public.push_notifications notification on notification.id = claimed.notification_id
    join public.push_subscriptions subscription on subscription.id = claimed.subscription_id;
end;
$$;

create or replace function public.dgie_finalizar_push_delivery(
  p_delivery_id uuid,
  p_resultado text,
  p_error text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_notification_id uuid;
  v_subscription_id uuid;
  v_attempts integer;
begin
  if p_resultado not in ('delivered','failed','stale') then
    raise exception 'Resultado de entrega inválido.' using errcode = '22023';
  end if;

  select delivery.notification_id, delivery.subscription_id, delivery.attempts
    into v_notification_id, v_subscription_id, v_attempts
    from public.push_deliveries delivery
   where delivery.id = p_delivery_id
   for update;

  if v_notification_id is null then
    return false;
  end if;

  update public.push_deliveries
     set status = p_resultado,
         delivered_at = case when p_resultado = 'delivered' then now() else delivered_at end,
         next_attempt_at = case
           when p_resultado = 'failed' then now() + (
             case
               when v_attempts <= 1 then interval '1 minute'
               when v_attempts <= 3 then interval '5 minutes'
               when v_attempts <= 6 then interval '15 minutes'
               when v_attempts <= 12 then interval '1 hour'
               else interval '6 hours'
             end
           )
           else next_attempt_at
         end,
         locked_at = null,
         last_error = nullif(left(coalesce(p_error,''),500),''),
         updated_at = now()
   where id = p_delivery_id;

  if p_resultado = 'stale' then
    update public.push_subscriptions
       set disabled_at = now(), updated_at = now()
     where id = v_subscription_id;
  end if;

  if not exists (
    select 1
      from public.push_deliveries delivery
     where delivery.notification_id = v_notification_id
       and delivery.status not in ('delivered','stale')
  ) then
    update public.push_notifications
       set sent_at = coalesce(sent_at,now())
     where id = v_notification_id;
  end if;

  return true;
end;
$$;

create or replace function public.dgie_registrar_push_subscription(
  p_endpoint text,
  p_p256dh text,
  p_auth text,
  p_user_agent text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_id uuid;
begin
  if v_user_id is null then
    raise exception 'Se requiere una sesión válida.' using errcode = '42501';
  end if;
  if nullif(trim(p_endpoint), '') is null
     or nullif(trim(p_p256dh), '') is null
     or nullif(trim(p_auth), '') is null then
    raise exception 'La suscripción está incompleta.' using errcode = '22023';
  end if;

  insert into public.push_subscriptions (
    user_id, endpoint, p256dh, auth, user_agent, updated_at, last_seen_at, disabled_at
  ) values (
    v_user_id, p_endpoint, p_p256dh, p_auth, nullif(p_user_agent, ''), now(), now(), null
  )
  on conflict (endpoint) do update set
    user_id = excluded.user_id,
    p256dh = excluded.p256dh,
    auth = excluded.auth,
    user_agent = excluded.user_agent,
    updated_at = now(),
    last_seen_at = now(),
    disabled_at = null
  returning id into v_id;

  insert into public.push_deliveries (notification_id, subscription_id)
  select notification.id, v_id
    from public.push_notifications notification
   where notification.user_id = v_user_id
     and notification.read_at is null
     and notification.sent_at is null
     and notification.created_at >= now() - interval '7 days'
  on conflict (notification_id, subscription_id) do nothing;

  return v_id;
end;
$$;

insert into public.push_deliveries (notification_id, subscription_id)
select notification.id, subscription.id
  from public.push_notifications notification
  join public.push_subscriptions subscription on subscription.user_id = notification.user_id
 where notification.sent_at is null
   and notification.created_at >= now() - interval '7 days'
   and subscription.disabled_at is null
on conflict (notification_id, subscription_id) do nothing;

revoke all on function public.dgie_reclamar_push_deliveries(integer,text[]) from public;
revoke all on function public.dgie_finalizar_push_delivery(uuid,text,text) from public;
grant execute on function public.dgie_reclamar_push_deliveries(integer,text[]) to service_role;
grant execute on function public.dgie_finalizar_push_delivery(uuid,text,text) to service_role;

commit;

select
  to_regclass('public.push_deliveries') is not null as cola_por_dispositivo_activa,
  to_regprocedure('public.dgie_reclamar_push_deliveries(integer,text[])') is not null as reintentos_activos,
  exists (
    select 1
      from pg_trigger
     where tgname = 'dgie_reclamo_push_queue'
       and not tgisinternal
  ) as reclamos_automaticos,
  exists (
    select 1
      from pg_trigger
     where tgname = 'dgie_comunicacion_push_queue'
       and not tgisinternal
  ) as comunicaciones_automaticas;
