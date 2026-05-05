-- ============================================================
-- INSTRUCCIONES PARA CREAR USUARIOS EN SUPABASE
-- ============================================================
--
-- PASO 1: Crear usuarios en Authentication (Auth)
-- Ir a: Supabase Dashboard → Authentication → Users → "Add user"
-- Crear los siguientes usuarios con email y contraseña:
--
--   director@dgie.edu.ar       / DgieDir2024!
--   coordinador1@dgie.edu.ar   / DgieCoord2024!
--   coordinador2@dgie.edu.ar   / DgieCoord2024!
--   inspector15@dgie.edu.ar    / DgieInsp2024!
--   callcenter@dgie.edu.ar     / DgieCC2024!
--
-- (Marcar "Auto Confirm User" = true al crear cada uno)
--
-- PASO 2: Obtener los UUIDs de cada usuario creado
-- Ejecutar esto para ver los IDs:
SELECT id, email FROM auth.users ORDER BY email;

-- ============================================================
-- PASO 3: Insertar perfiles en public.perfiles
-- REEMPLAZAR los UUIDs que devuelve el SELECT anterior
-- ============================================================

-- Perfil: Director (Franco Dardati)
INSERT INTO public.perfiles (id, nombre, rol, zona)
SELECT id, 'Franco Dardati', 'director', NULL
FROM auth.users WHERE email = 'director@dgie.edu.ar'
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;

-- Perfil: Coordinadora (Rocio Peralta)
INSERT INTO public.perfiles (id, nombre, rol, zona)
SELECT id, 'Rocio Peralta', 'coordinador', NULL
FROM auth.users WHERE email = 'coordinador1@dgie.edu.ar'
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;

-- Perfil: Coordinador (Augusto Zamora)
INSERT INTO public.perfiles (id, nombre, rol, zona)
SELECT id, 'Augusto Zamora', 'coordinador', NULL
FROM auth.users WHERE email = 'coordinador2@dgie.edu.ar'
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;

-- Perfil: Inspector Zona 15 (Nazareno Baza)
INSERT INTO public.perfiles (id, nombre, rol, zona)
SELECT id, 'Nazareno Baza', 'inspector', 15
FROM auth.users WHERE email = 'inspector15@dgie.edu.ar'
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;

-- Perfil: Call Center
INSERT INTO public.perfiles (id, nombre, rol, zona)
SELECT id, 'Call Center', 'callcenter', NULL
FROM auth.users WHERE email = 'callcenter@dgie.edu.ar'
ON CONFLICT (id) DO UPDATE SET nombre=EXCLUDED.nombre, rol=EXCLUDED.rol, zona=EXCLUDED.zona;

-- Verificar perfiles insertados:
SELECT p.id, p.nombre, p.rol, p.zona, u.email
FROM public.perfiles p
JOIN auth.users u ON p.id = u.id
ORDER BY p.rol, p.nombre;
