-- ============================================================
-- DGIE - Crear todos los usuarios con login por nombre de usuario
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- ============================================================

DO $$
DECLARE v uuid;
BEGIN

-- ----------------------------------------------------------------
-- DIRECTOR  |  Usuario: DGIEDIRECTOR  |  Contraseña: INFRAESTRUCTURA123
-- ----------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'dgiedirector@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'dgiedirector@dgie.local', crypt('INFRAESTRUCTURA123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"dgiedirector@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Franco Dardati', 'director', NULL)
  ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- ----------------------------------------------------------------
-- COORDINADOR  |  Usuario: DGIECoord  |  Contraseña: 111213
-- ----------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'dgiecoord@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'dgiecoord@dgie.local', crypt('111213', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"dgiecoord@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Rocio Peralta', 'coordinador', NULL)
  ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- ----------------------------------------------------------------
-- INSPECTORES  |  Usuario: Zona N  |  Contraseña: Inspector_ZonaN
-- ----------------------------------------------------------------

-- Zona 1 - Mailen Moreno
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona1@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona1@dgie.local', crypt('Inspector_Zona1', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona1@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Mailen Moreno', 'inspector', 1) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 2 - Camila Floreano
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona2@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona2@dgie.local', crypt('Inspector_Zona2', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona2@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Camila Floreano', 'inspector', 2) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 3 - Belen Caballero
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona3@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona3@dgie.local', crypt('Inspector_Zona3', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona3@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Belen Caballero', 'inspector', 3) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 4 - Valentin Carrizo
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona4@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona4@dgie.local', crypt('Inspector_Zona4', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona4@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Valentin Carrizo', 'inspector', 4) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 5 - Tomas Veron
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona5@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona5@dgie.local', crypt('Inspector_Zona5', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona5@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Tomas Veron', 'inspector', 5) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 6 - Agustina Llanos
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona6@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona6@dgie.local', crypt('Inspector_Zona6', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona6@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Agustina Llanos', 'inspector', 6) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 7 - Camila Mattos
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona7@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona7@dgie.local', crypt('Inspector_Zona7', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona7@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Camila Mattos', 'inspector', 7) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 8 - Ian Johnson
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona8@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona8@dgie.local', crypt('Inspector_Zona8', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona8@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Ian Johnson', 'inspector', 8) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 9 - Lucia Cerino
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona9@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona9@dgie.local', crypt('Inspector_Zona9', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona9@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Lucia Cerino', 'inspector', 9) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 10 - Nicolas Festa
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona10@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona10@dgie.local', crypt('Inspector_Zona10', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona10@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Nicolas Festa', 'inspector', 10) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 11 - Matias Soler
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona11@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona11@dgie.local', crypt('Inspector_Zona11', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona11@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Matias Soler', 'inspector', 11) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 12 - Barbara Ledesma
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona12@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona12@dgie.local', crypt('Inspector_Zona12', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona12@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Barbara Ledesma', 'inspector', 12) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 13 - Ana Iglesias
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona13@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona13@dgie.local', crypt('Inspector_Zona13', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona13@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Ana Iglesias', 'inspector', 13) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 14 - Celina Lepez Glaria
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona14@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona14@dgie.local', crypt('Inspector_Zona14', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona14@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Celina Lepez Glaria', 'inspector', 14) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 15 - Nazareno Baza
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona15@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona15@dgie.local', crypt('Inspector_Zona15', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona15@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Nazareno Baza', 'inspector', 15) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 16 - Federico Cezar
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona16@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona16@dgie.local', crypt('Inspector_Zona16', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona16@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Federico Cezar', 'inspector', 16) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

-- Zona 17 - Omar Sanchez
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'zona17@dgie.local') THEN
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'zona17@dgie.local', crypt('Inspector_Zona17', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '')
  RETURNING id INTO v;
  INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) VALUES (gen_random_uuid(), v, format('{"sub":"%s","email":"zona17@dgie.local"}', v)::jsonb, 'email', now(), now(), now());
  INSERT INTO public.perfiles (id, nombre, rol, zona) VALUES (v, 'Omar Sanchez', 'inspector', 17) ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;
END IF;

END $$;

-- Verificar usuarios creados:
SELECT u.email, p.nombre, p.rol, p.zona
FROM auth.users u
JOIN public.perfiles p ON p.id = u.id
WHERE u.email LIKE '%@dgie.local'
ORDER BY p.rol, p.zona NULLS FIRST;
