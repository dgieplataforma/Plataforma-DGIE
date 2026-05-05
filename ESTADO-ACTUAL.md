# Estado actual de la plataforma DGIE

Fecha: 2026-05-05

## Carpeta local

`C:\Users\Nazareno\Documents\New project\plataforma-dgie-lanzamiento`

La carpeta local contiene una version mas avanzada que la publicada actualmente en Netlify.

Evidencias locales:

- Existe `.git`.
- Remoto configurado en `.git/config`:
  `https://github.com/nazarenobazadgie/plataforma-dgie-lanzamiento.git`
- Rama local: `main`.
- Ultimo commit local registrado en `.git/refs/heads/main`:
  `72a09f203812fd8124ee7c2c79e08303e855bda6`

## Supabase

Proyecto:
`https://gvejicxbavveqrrxicen.supabase.co`

Archivo local de configuracion:
`supabase-config.js`

El frontend local ya carga:

- `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2`
- `supabase-config.js`
- `dgie-supabase.js`

El archivo `index.html` local ya contiene login real con Supabase:

- Modo demo.
- Modo real.
- Usuario + contrasena.
- `window.DGIE_DB.signIn(...)`.
- `window.DGIE_DB.currentProfile()`.

## Base de datos

Confirmado por SQL Editor:

```sql
select count(*) from public.establecimientos;
```

Resultado: `759`.

## Problema detectado

La URL publicada en Netlify:

`https://dgie.netlify.app/`

todavia muestra la version vieja del login:

- No aparece la pestana o modo `Acceso real`.
- Muestra solo rol/zona demo.

Esto significa que Netlify no esta publicando la version local actual o GitHub todavia no recibio el ultimo estado.

## Proximo paso

Sincronizar la carpeta local con GitHub y luego verificar deploy en Netlify.

Comandos sugeridos en una terminal donde `git` funcione:

```powershell
cd "C:\Users\Nazareno\Documents\New project\plataforma-dgie-lanzamiento"
git status
git add .
git commit -m "Integra login real Supabase y flujo multiusuario"
git push origin main
```

Luego en Netlify:

1. Entrar al sitio.
2. Ir a `Deploys`.
3. Confirmar que aparezca un nuevo deploy desde GitHub.
4. Abrir la URL publicada.
5. Verificar que el modal de acceso tenga modo demo y modo real.

## Nota

En esta terminal, `git` no esta disponible en PATH, por eso no se pudo ejecutar `git status` ni `git push` desde Codex.
