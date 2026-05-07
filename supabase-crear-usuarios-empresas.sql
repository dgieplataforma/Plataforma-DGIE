-- DGIE - Crear/actualizar usuarios EMPRESA Zona 1 a Zona 17
-- Copiar TODO este archivo en Supabase SQL Editor y ejecutar.
-- Acceso en la plataforma:
-- Usuario: Empresa 1 / Empresa 2 / ... / Empresa 17
-- Clave:   Empresa_Zona1 / Empresa_Zona2 / ... / Empresa_Zona17

create extension if not exists pgcrypto;

create or replace function public.dgie_upsert_auth_user(
  p_email text,
  p_password text,
  p_nombre text,
  p_rol text,
  p_zona integer
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v uuid;
begin
  select id into v from auth.users where email = p_email;

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
      p_email,
      extensions.crypt(p_password, extensions.gen_salt('bf')),
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
    set encrypted_password = extensions.crypt(p_password, extensions.gen_salt('bf')),
        email_confirmed_at = coalesce(email_confirmed_at, now()),
        updated_at = now()
    where id = v;
  end if;

  insert into auth.identities (
    id, user_id, identity_data, provider, provider_id,
    last_sign_in_at, created_at, updated_at
  )
  values (
    gen_random_uuid(),
    v,
    jsonb_build_object('sub', v::text, 'email', p_email),
    'email',
    p_email,
    now(),
    now(),
    now()
  )
  on conflict (provider, provider_id) do update
  set user_id = excluded.user_id,
      identity_data = excluded.identity_data,
      updated_at = now();

  insert into public.perfiles (id, nombre, rol, zona, activo)
  values (v, p_nombre, p_rol, p_zona, true)
  on conflict (id) do update
  set nombre = excluded.nombre,
      rol = excluded.rol,
      zona = excluded.zona,
      activo = true;

  return v;
end;
$$;

select public.dgie_upsert_auth_user('empresa1@dgie.local', 'Empresa_Zona1', 'Empresa Zona 1', 'empresa', 1);
select public.dgie_upsert_auth_user('empresa2@dgie.local', 'Empresa_Zona2', 'Empresa Zona 2', 'empresa', 2);
select public.dgie_upsert_auth_user('empresa3@dgie.local', 'Empresa_Zona3', 'Empresa Zona 3', 'empresa', 3);
select public.dgie_upsert_auth_user('empresa4@dgie.local', 'Empresa_Zona4', 'Empresa Zona 4', 'empresa', 4);
select public.dgie_upsert_auth_user('empresa5@dgie.local', 'Empresa_Zona5', 'Empresa Zona 5', 'empresa', 5);
select public.dgie_upsert_auth_user('empresa6@dgie.local', 'Empresa_Zona6', 'Empresa Zona 6', 'empresa', 6);
select public.dgie_upsert_auth_user('empresa7@dgie.local', 'Empresa_Zona7', 'Empresa Zona 7', 'empresa', 7);
select public.dgie_upsert_auth_user('empresa8@dgie.local', 'Empresa_Zona8', 'Empresa Zona 8', 'empresa', 8);
select public.dgie_upsert_auth_user('empresa9@dgie.local', 'Empresa_Zona9', 'Empresa Zona 9', 'empresa', 9);
select public.dgie_upsert_auth_user('empresa10@dgie.local', 'Empresa_Zona10', 'Empresa Zona 10', 'empresa', 10);
select public.dgie_upsert_auth_user('empresa11@dgie.local', 'Empresa_Zona11', 'Empresa Zona 11', 'empresa', 11);
select public.dgie_upsert_auth_user('empresa12@dgie.local', 'Empresa_Zona12', 'Empresa Zona 12', 'empresa', 12);
select public.dgie_upsert_auth_user('empresa13@dgie.local', 'Empresa_Zona13', 'Empresa Zona 13', 'empresa', 13);
select public.dgie_upsert_auth_user('empresa14@dgie.local', 'Empresa_Zona14', 'Empresa Zona 14', 'empresa', 14);
select public.dgie_upsert_auth_user('empresa15@dgie.local', 'Empresa_Zona15', 'Empresa Zona 15', 'empresa', 15);
select public.dgie_upsert_auth_user('empresa16@dgie.local', 'Empresa_Zona16', 'Empresa Zona 16', 'empresa', 16);
select public.dgie_upsert_auth_user('empresa17@dgie.local', 'Empresa_Zona17', 'Empresa Zona 17', 'empresa', 17);

select u.email, p.nombre, p.rol, p.zona, p.activo
from auth.users u
join public.perfiles p on p.id = u.id
where p.rol = 'empresa'
order by p.zona;
