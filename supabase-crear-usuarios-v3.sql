-- ============================================================
-- DGIE - Usuarios reales para Supabase Auth
-- Ejecutar en Supabase Dashboard > SQL Editor
-- Incluye director, coordinador, call center, 17 inspectores y 17 empresas.
-- ============================================================

DO $$
DECLARE v uuid;
BEGIN

-- DIRECTOR | Usuario: DGIEDIRECTOR | Contraseña: INFRAESTRUCTURA123
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'dgiedirector@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'dgiedirector@dgie.local', crypt('INFRAESTRUCTURA123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"dgiedirector@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('INFRAESTRUCTURA123', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Franco Dardati', 'director', NULL, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- COORDINADOR | Usuario: DGIECoord | Contraseña: 111213
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'dgiecoord@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'dgiecoord@dgie.local', crypt('111213', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"dgiecoord@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('111213', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Rocio Peralta', 'coordinador', NULL, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- CALL CENTER | Usuario: CallCenter | Contraseña: CALLCENTER123
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'callcenter@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'callcenter@dgie.local', crypt('CALLCENTER123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"callcenter@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('CALLCENTER123', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Call Center', 'callcenter', NULL, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 1 | Usuario: Zona 1 | Contraseña: Inspector_Zona1
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona1@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona1@dgie.local', crypt('Inspector_Zona1', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona1@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona1', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Mailen Moreno', 'inspector', 1, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 2 | Usuario: Zona 2 | Contraseña: Inspector_Zona2
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona2@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona2@dgie.local', crypt('Inspector_Zona2', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona2@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona2', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Camila Floreano', 'inspector', 2, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 3 | Usuario: Zona 3 | Contraseña: Inspector_Zona3
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona3@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona3@dgie.local', crypt('Inspector_Zona3', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona3@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona3', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Belen Caballero', 'inspector', 3, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 4 | Usuario: Zona 4 | Contraseña: Inspector_Zona4
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona4@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona4@dgie.local', crypt('Inspector_Zona4', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona4@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona4', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Valentin Carrizo', 'inspector', 4, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 5 | Usuario: Zona 5 | Contraseña: Inspector_Zona5
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona5@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona5@dgie.local', crypt('Inspector_Zona5', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona5@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona5', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Tomas Veron', 'inspector', 5, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 6 | Usuario: Zona 6 | Contraseña: Inspector_Zona6
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona6@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona6@dgie.local', crypt('Inspector_Zona6', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona6@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona6', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Agustina Llanos', 'inspector', 6, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 7 | Usuario: Zona 7 | Contraseña: Inspector_Zona7
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona7@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona7@dgie.local', crypt('Inspector_Zona7', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona7@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona7', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Camila Mattos', 'inspector', 7, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 8 | Usuario: Zona 8 | Contraseña: Inspector_Zona8
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona8@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona8@dgie.local', crypt('Inspector_Zona8', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona8@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona8', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Ian Johnson', 'inspector', 8, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 9 | Usuario: Zona 9 | Contraseña: Inspector_Zona9
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona9@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona9@dgie.local', crypt('Inspector_Zona9', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona9@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona9', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Lucia Cerino', 'inspector', 9, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 10 | Usuario: Zona 10 | Contraseña: Inspector_Zona10
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona10@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona10@dgie.local', crypt('Inspector_Zona10', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona10@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona10', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Nicolas Festa', 'inspector', 10, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 11 | Usuario: Zona 11 | Contraseña: Inspector_Zona11
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona11@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona11@dgie.local', crypt('Inspector_Zona11', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona11@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona11', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Matias Soler', 'inspector', 11, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 12 | Usuario: Zona 12 | Contraseña: Inspector_Zona12
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona12@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona12@dgie.local', crypt('Inspector_Zona12', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona12@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona12', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Barbara Ledesma', 'inspector', 12, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 13 | Usuario: Zona 13 | Contraseña: Inspector_Zona13
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona13@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona13@dgie.local', crypt('Inspector_Zona13', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona13@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona13', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Ana Iglesias', 'inspector', 13, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 14 | Usuario: Zona 14 | Contraseña: Inspector_Zona14
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona14@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona14@dgie.local', crypt('Inspector_Zona14', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona14@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona14', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Celina Lepez Glaria', 'inspector', 14, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 15 | Usuario: Zona 15 | Contraseña: Inspector_Zona15
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona15@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona15@dgie.local', crypt('Inspector_Zona15', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona15@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona15', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Nazareno Baza', 'inspector', 15, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 16 | Usuario: Zona 16 | Contraseña: Inspector_Zona16
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona16@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona16@dgie.local', crypt('Inspector_Zona16', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona16@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona16', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Federico Cezar', 'inspector', 16, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- INSPECTOR ZONA 17 | Usuario: Zona 17 | Contraseña: Inspector_Zona17
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'zona17@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona17@dgie.local', crypt('Inspector_Zona17', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona17@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Inspector_Zona17', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Omar Sanchez', 'inspector', 17, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 1 | Usuario: Empresa 1 | Contraseña: Empresa_Zona1
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa1@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa1@dgie.local', crypt('Empresa_Zona1', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa1@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona1', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 1', 'empresa', 1, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 2 | Usuario: Empresa 2 | Contraseña: Empresa_Zona2
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa2@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa2@dgie.local', crypt('Empresa_Zona2', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa2@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona2', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 2', 'empresa', 2, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 3 | Usuario: Empresa 3 | Contraseña: Empresa_Zona3
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa3@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa3@dgie.local', crypt('Empresa_Zona3', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa3@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona3', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 3', 'empresa', 3, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 4 | Usuario: Empresa 4 | Contraseña: Empresa_Zona4
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa4@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa4@dgie.local', crypt('Empresa_Zona4', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa4@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona4', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 4', 'empresa', 4, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 5 | Usuario: Empresa 5 | Contraseña: Empresa_Zona5
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa5@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa5@dgie.local', crypt('Empresa_Zona5', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa5@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona5', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 5', 'empresa', 5, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 6 | Usuario: Empresa 6 | Contraseña: Empresa_Zona6
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa6@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa6@dgie.local', crypt('Empresa_Zona6', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa6@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona6', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 6', 'empresa', 6, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 7 | Usuario: Empresa 7 | Contraseña: Empresa_Zona7
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa7@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa7@dgie.local', crypt('Empresa_Zona7', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa7@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona7', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 7', 'empresa', 7, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 8 | Usuario: Empresa 8 | Contraseña: Empresa_Zona8
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa8@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa8@dgie.local', crypt('Empresa_Zona8', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa8@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona8', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 8', 'empresa', 8, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 9 | Usuario: Empresa 9 | Contraseña: Empresa_Zona9
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa9@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa9@dgie.local', crypt('Empresa_Zona9', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa9@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona9', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 9', 'empresa', 9, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 10 | Usuario: Empresa 10 | Contraseña: Empresa_Zona10
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa10@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa10@dgie.local', crypt('Empresa_Zona10', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa10@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona10', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 10', 'empresa', 10, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 11 | Usuario: Empresa 11 | Contraseña: Empresa_Zona11
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa11@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa11@dgie.local', crypt('Empresa_Zona11', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa11@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona11', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 11', 'empresa', 11, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 12 | Usuario: Empresa 12 | Contraseña: Empresa_Zona12
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa12@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa12@dgie.local', crypt('Empresa_Zona12', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa12@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona12', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 12', 'empresa', 12, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 13 | Usuario: Empresa 13 | Contraseña: Empresa_Zona13
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa13@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa13@dgie.local', crypt('Empresa_Zona13', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa13@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona13', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 13', 'empresa', 13, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 14 | Usuario: Empresa 14 | Contraseña: Empresa_Zona14
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa14@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa14@dgie.local', crypt('Empresa_Zona14', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa14@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona14', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 14', 'empresa', 14, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 15 | Usuario: Empresa 15 | Contraseña: Empresa_Zona15
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa15@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa15@dgie.local', crypt('Empresa_Zona15', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa15@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona15', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 15', 'empresa', 15, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 16 | Usuario: Empresa 16 | Contraseña: Empresa_Zona16
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa16@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa16@dgie.local', crypt('Empresa_Zona16', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa16@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona16', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 16', 'empresa', 16, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

-- EMPRESA ZONA 17 | Usuario: Empresa 17 | Contraseña: Empresa_Zona17
v := null;
SELECT id INTO v FROM auth.users WHERE email = 'empresa17@dgie.local';
IF v IS NULL THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'empresa17@dgie.local', crypt('Empresa_Zona17', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"empresa17@dgie.local"}', v)::jsonb, 'email', now(), now(), now())
  ON CONFLICT DO NOTHING;
ELSE
  UPDATE auth.users SET encrypted_password = crypt('Empresa_Zona17', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()), updated_at = now() WHERE id = v;
END IF;
INSERT INTO public.perfiles (id, nombre, rol, zona, activo) VALUES (v, 'Empresa Zona 17', 'empresa', 17, true)
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona, activo=true;

END $$;

SELECT u.email, p.nombre, p.rol, p.zona, p.activo
FROM auth.users u
JOIN public.perfiles p ON p.id = u.id
WHERE u.email LIKE '%@dgie.local'
ORDER BY p.rol, p.zona NULLS FIRST, p.nombre;
