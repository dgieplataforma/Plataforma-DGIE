-- DGIE - Crear/actualizar inspectores de Zona 1 a Zona 17
-- Copiar TODO este archivo en Supabase SQL Editor y ejecutar.

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

select public.dgie_upsert_auth_user('zona1@dgie.local', 'Inspector_Zona1', 'Mailen Moreno', 'inspector', 1);
select public.dgie_upsert_auth_user('zona2@dgie.local', 'Inspector_Zona2', 'Camila Floreano', 'inspector', 2);
select public.dgie_upsert_auth_user('zona3@dgie.local', 'Inspector_Zona3', 'Belen Caballero', 'inspector', 3);
select public.dgie_upsert_auth_user('zona4@dgie.local', 'Inspector_Zona4', 'Valentin Carrizo', 'inspector', 4);
select public.dgie_upsert_auth_user('zona5@dgie.local', 'Inspector_Zona5', 'Tomas Veron', 'inspector', 5);
select public.dgie_upsert_auth_user('zona6@dgie.local', 'Inspector_Zona6', 'Agustina Llanos', 'inspector', 6);
select public.dgie_upsert_auth_user('zona7@dgie.local', 'Inspector_Zona7', 'Camila Mattos', 'inspector', 7);
select public.dgie_upsert_auth_user('zona8@dgie.local', 'Inspector_Zona8', 'Ian Johnson', 'inspector', 8);
select public.dgie_upsert_auth_user('zona9@dgie.local', 'Inspector_Zona9', 'Lucia Cerino', 'inspector', 9);
select public.dgie_upsert_auth_user('zona10@dgie.local', 'Inspector_Zona10', 'Nicolas Festa', 'inspector', 10);
select public.dgie_upsert_auth_user('zona11@dgie.local', 'Inspector_Zona11', 'Matias Soler', 'inspector', 11);
select public.dgie_upsert_auth_user('zona12@dgie.local', 'Inspector_Zona12', 'Barbara Ledesma', 'inspector', 12);
select public.dgie_upsert_auth_user('zona13@dgie.local', 'Inspector_Zona13', 'Ana Iglesias', 'inspector', 13);
select public.dgie_upsert_auth_user('zona14@dgie.local', 'Inspector_Zona14', 'Celina Lepez Glaria', 'inspector', 14);
select public.dgie_upsert_auth_user('zona15@dgie.local', 'Inspector_Zona15', 'Nazareno Baza', 'inspector', 15);
select public.dgie_upsert_auth_user('zona16@dgie.local', 'Inspector_Zona16', 'Federico Cezar', 'inspector', 16);
select public.dgie_upsert_auth_user('zona17@dgie.local', 'Inspector_Zona17', 'Omar Sanchez', 'inspector', 17);

select u.email, p.nombre, p.rol, p.zona, p.activo
from auth.users u
join public.perfiles p on p.id = u.id
where p.rol = 'inspector'
order by p.zona;
