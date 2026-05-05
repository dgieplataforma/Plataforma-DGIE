-- DGIE - Usuarios principales para probar login real
-- Ejecutar completo en Supabase > SQL Editor.

create extension if not exists pgcrypto;

do $dgie$
declare
  v uuid;
begin
  -- Coordinador | Usuario: DGIECoord | Contraseña: 111213
  select id into v from auth.users where email = 'dgiecoord@dgie.local';
  if v is null then
    v := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000', v, 'authenticated', 'authenticated',
      'dgiecoord@dgie.local', crypt('111213', gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(),
      '', '', '', ''
    );
  else
    update auth.users
    set encrypted_password = crypt('111213', gen_salt('bf')),
        email_confirmed_at = coalesce(email_confirmed_at, now()),
        updated_at = now()
    where id = v;
  end if;
  insert into auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
  values (gen_random_uuid(), v, jsonb_build_object('sub', v::text, 'email', 'dgiecoord@dgie.local'), 'email', 'dgiecoord@dgie.local', now(), now(), now())
  on conflict (provider, provider_id) do update
  set user_id = excluded.user_id,
      identity_data = excluded.identity_data,
      updated_at = now();
  insert into public.perfiles (id, nombre, rol, zona, activo)
  values (v, 'Rocio Peralta', 'coordinador', null, true)
  on conflict (id) do update set nombre=excluded.nombre, rol=excluded.rol, zona=excluded.zona, activo=true;

  -- Inspector Zona 15 | Usuario: Zona 15 | Contraseña: Inspector_Zona15
  select id into v from auth.users where email = 'zona15@dgie.local';
  if v is null then
    v := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000', v, 'authenticated', 'authenticated',
      'zona15@dgie.local', crypt('Inspector_Zona15', gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(),
      '', '', '', ''
    );
  else
    update auth.users
    set encrypted_password = crypt('Inspector_Zona15', gen_salt('bf')),
        email_confirmed_at = coalesce(email_confirmed_at, now()),
        updated_at = now()
    where id = v;
  end if;
  insert into auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
  values (gen_random_uuid(), v, jsonb_build_object('sub', v::text, 'email', 'zona15@dgie.local'), 'email', 'zona15@dgie.local', now(), now(), now())
  on conflict (provider, provider_id) do update
  set user_id = excluded.user_id,
      identity_data = excluded.identity_data,
      updated_at = now();
  insert into public.perfiles (id, nombre, rol, zona, activo)
  values (v, 'Nazareno Baza', 'inspector', 15, true)
  on conflict (id) do update set nombre=excluded.nombre, rol=excluded.rol, zona=excluded.zona, activo=true;

  -- Call Center | Usuario: CallCenter | Contraseña: CALLCENTER123
  select id into v from auth.users where email = 'callcenter@dgie.local';
  if v is null then
    v := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000', v, 'authenticated', 'authenticated',
      'callcenter@dgie.local', crypt('CALLCENTER123', gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(),
      '', '', '', ''
    );
  else
    update auth.users
    set encrypted_password = crypt('CALLCENTER123', gen_salt('bf')),
        email_confirmed_at = coalesce(email_confirmed_at, now()),
        updated_at = now()
    where id = v;
  end if;
  insert into auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
  values (gen_random_uuid(), v, jsonb_build_object('sub', v::text, 'email', 'callcenter@dgie.local'), 'email', 'callcenter@dgie.local', now(), now(), now())
  on conflict (provider, provider_id) do update
  set user_id = excluded.user_id,
      identity_data = excluded.identity_data,
      updated_at = now();
  insert into public.perfiles (id, nombre, rol, zona, activo)
  values (v, 'Call Center', 'callcenter', null, true)
  on conflict (id) do update set nombre=excluded.nombre, rol=excluded.rol, zona=excluded.zona, activo=true;
end
$dgie$;

select u.email, p.nombre, p.rol, p.zona, p.activo
from auth.users u
join public.perfiles p on p.id = u.id
where u.email in ('dgiecoord@dgie.local','zona15@dgie.local','callcenter@dgie.local')
order by p.rol, p.zona nulls first;
