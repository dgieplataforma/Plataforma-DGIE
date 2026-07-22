begin;

create extension if not exists pgcrypto;

create table if not exists public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  endpoint text not null,
  p256dh text not null,
  auth text not null,
  user_agent text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  constraint push_subscriptions_endpoint_key unique (endpoint)
);

create table if not exists public.push_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('comunicado','reclamo')),
  source_id text not null,
  title text not null,
  body text,
  url text not null default '/',
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  read_at timestamptz,
  constraint push_notifications_source_key unique (user_id, kind, source_id)
);

create index if not exists push_subscriptions_user_idx
  on public.push_subscriptions (user_id);

create index if not exists push_notifications_unread_idx
  on public.push_notifications (user_id, created_at desc)
  where read_at is null;

alter table public.push_subscriptions enable row level security;
alter table public.push_notifications enable row level security;

revoke all on table public.push_subscriptions from anon, authenticated;
revoke all on table public.push_notifications from anon, authenticated;

drop policy if exists push_subscriptions_select_own on public.push_subscriptions;
create policy push_subscriptions_select_own
  on public.push_subscriptions
  for select
  to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists push_notifications_select_own on public.push_notifications;
create policy push_notifications_select_own
  on public.push_notifications
  for select
  to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists push_notifications_update_own on public.push_notifications;

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
    raise exception 'Se requiere una sesion valida.' using errcode = '42501';
  end if;
  if nullif(trim(p_endpoint), '') is null
     or nullif(trim(p_p256dh), '') is null
     or nullif(trim(p_auth), '') is null then
    raise exception 'La suscripcion esta incompleta.' using errcode = '22023';
  end if;

  insert into public.push_subscriptions (
    user_id, endpoint, p256dh, auth, user_agent, updated_at, last_seen_at
  ) values (
    v_user_id, p_endpoint, p_p256dh, p_auth, nullif(p_user_agent, ''), now(), now()
  )
  on conflict (endpoint) do update set
    user_id = excluded.user_id,
    p256dh = excluded.p256dh,
    auth = excluded.auth,
    user_agent = excluded.user_agent,
    updated_at = now(),
    last_seen_at = now()
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.dgie_eliminar_push_subscription(p_endpoint text)
returns boolean
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
  delete from public.push_subscriptions
   where user_id = v_user_id
     and endpoint = p_endpoint;
  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$$;

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
  if p_kind is not null and p_kind not in ('comunicado','reclamo') then
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

revoke all on function public.dgie_registrar_push_subscription(text,text,text,text) from public;
revoke all on function public.dgie_eliminar_push_subscription(text) from public;
revoke all on function public.dgie_marcar_notificaciones_push_leidas(text) from public;

grant execute on function public.dgie_registrar_push_subscription(text,text,text,text) to authenticated;
grant execute on function public.dgie_eliminar_push_subscription(text) to authenticated;
grant execute on function public.dgie_marcar_notificaciones_push_leidas(text) to authenticated;

grant select on public.push_notifications to authenticated;

commit;
