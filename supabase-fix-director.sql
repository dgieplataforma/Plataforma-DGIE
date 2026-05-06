create extension if not exists pgcrypto with schema extensions;

do $$
declare
  v uuid;
begin
  select id into v from auth.users where email = 'dgiedirector@dgie.local';

  if v is null then
    v := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000',
      v,
      'authenticated',
      'authenticated',
      'dgiedirector@dgie.local',
      extensions.crypt('INFRAESTRUCTURA123', extensions.gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{}'::jsonb,
      now(),
      now(),
      '',
      '',
      '',
      ''
    );
  else
    update auth.users
    set encrypted_password = extensions.crypt('INFRAESTRUCTURA123', extensions.gen_salt('bf')),
        email_confirmed_at = coalesce(email_confirmed_at, now()),
        updated_at = now()
    where id = v;
  end if;

  insert into auth.identities (
    id, user_id, identity_data, provider, provider_id,
    last_sign_in_at, created_at, updated_at, email
  ) values (
    gen_random_uuid(),
    v,
    jsonb_build_object('sub', v::text, 'email', 'dgiedirector@dgie.local'),
    'email',
    'dgiedirector@dgie.local',
    now(),
    now(),
    now(),
    'dgiedirector@dgie.local'
  )
  on conflict (provider, provider_id) do update
  set user_id = excluded.user_id,
      identity_data = excluded.identity_data,
      updated_at = now();

  insert into public.perfiles (id, nombre, rol, zona, activo)
  values (v, 'Franco Dardati', 'director', null, true)
  on conflict (id) do update
  set nombre = excluded.nombre,
      rol = 'director',
      zona = null,
      activo = true;
end $$;

select u.email, p.nombre, p.rol, p.zona, p.activo
from auth.users u
join public.perfiles p on p.id = u.id
where u.email = 'dgiedirector@dgie.local';
