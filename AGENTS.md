# Plataforma DGIE — instrucciones para trabajar en este repo

Plataforma web de gestión de infraestructura educativa (reclamos, órdenes de servicio,
intervenciones, certificaciones) para la Dirección de Jurisdicción de Infraestructura y
Equipamiento (DGIE), Córdoba.

## Ubicación y publicación

- Repositorio local válido: `I:\Mi unidad\PLATAFORMA DGIE`. No trabajar sobre ninguna otra
  copia (pueden existir copias viejas en Documentos u otras carpetas; ignoralas).
- Repositorio GitHub: https://github.com/dgieplataforma/Plataforma-DGIE — remote `origin`.
  Puede existir un remote `origen-viejo` apuntando a un repo personal descartado: no usar.
- Rama principal: `main`.
- Producción: https://dgie.netlify.app — se publica automáticamente al hacer push a `main`
  (GitHub → Netlify). Después de cada push, verificar que Netlify haya publicado ESE commit
  exacto (por ejemplo descargando el HTML servido y buscando algún texto único del cambio).
- Base de datos y autenticación: Supabase (proyecto `gvejicxbavveqrrxicen`). Archivos de
  configuración: `supabase-config.js`, lógica de cliente en `dgie-supabase.js`.
- Almacenamiento de archivos (fotos, PDFs, Excel): Cloudinary.
- Nunca expongas ni escribas claves secretas en archivos, commits o respuestas.
- En la interfaz nunca menciones nombres de tecnologías internas ("Supabase", "Cloudinary",
  etc.). Usá textos genéricos como "Guardado", "Actualizado" o "Sincronizado".

## Estructura del código — MUY IMPORTANTE

- `index.html` es un archivo monolítico enorme (~1,8M de caracteres, ~24.000 líneas) que
  contiene HTML, CSS y decenas de bloques `<script>`.
- El archivo acumuló años de parches: es muy común que una función se defina una vez cerca
  del principio y luego se **reasigne varias veces más abajo** (patrón
  `const prev = window.miFuncion; window.miFuncion = function(){ ...; return prev(...) }`),
  cada capa envolviendo a la anterior. La ÚLTIMA reasignación en orden de aparición en el
  archivo es la que realmente se ejecuta en runtime — no la primera definición.
- **Antes de editar cualquier función:** buscá TODAS las reasignaciones de ese nombre en el
  archivo (`grep`/búsqueda de texto) para identificar cuál es la versión activa. Si vas a
  agregar comportamiento nuevo sin tocar el existente, seguí el mismo patrón del proyecto:
  agregá un nuevo bloque `<script>` al final del `<body>` (antes de
  `<script src="./dgie-file-viewer.js">`) que capture `window.miFuncion` como `prev`, haga lo
  suyo y delegue a `prev` — así no rompés ninguna de las capas anteriores.
- Cuidado con variables globales: cosas como `RECLAMOS_ZONA`, `OS_ZONA`, `currentUser` están
  declaradas con `let`/`const` a nivel superior de un `<script>`, así que son accesibles como
  identificador libre (`RECLAMOS_ZONA`) en cualquier otro `<script>` clásico del documento,
  pero **NO** existen como `window.RECLAMOS_ZONA` (eso da `undefined`). Usá el nombre bare,
  no `window.`.
- Otros archivos relevantes:
  - `dgie-supabase.js` — funciones de acceso a datos (listar/crear/actualizar por tabla).
  - `dgie-notificaciones.js`, `service-worker.js` — notificaciones push.
  - `dgie-file-viewer.js` — visor de archivos dentro de la app (intercepta clicks en links
    a archivos vistos y los abre en un panel interno en vez de navegar).
  - `netlify/functions/*.mjs` — funciones serverless (dispatch/retry de notificaciones push).
  - Scripts SQL sueltos en la raíz (`supabase-*.sql`) — migraciones idempotentes que se van
    acumulando; no hay carpeta `supabase/migrations` formal.

## Validación obligatoria después de cada cambio en index.html

Antes de dar nada por terminado:

```
npm run verificar
```

Valida la sintaxis de todos los `<script>` embebidos y después abre la aplicación en un
navegador, en ancho de escritorio y de celular, y revisa que la información cargue y que no
haya errores de consola. No escribe nada en la base: sólo lee.

Lo que devuelve:

| Salida | Qué significa | Qué hacer |
|---|---|---|
| `0` | Todo bien | Seguir con el protocolo |
| `1` | Algo falló | Arreglarlo. No publicar |
| `2` | **No hay navegador en este entorno** | Ver abajo |

`git diff --check` también, antes de comitear.

### Si no hay navegador (salida 2)

Pasa en entornos aislados que no pueden instalar Chromium. No es un motivo para abandonar el
trabajo ni para publicar a ciegas:

1. Dejar el cambio implementado y **sin comitear**.
2. Decirlo de forma explícita al cerrar: qué se cambió, qué quedó sin probar y qué habría que
   ejercitar en el navegador.
3. Que lo verifique y publique quien sí tenga navegador.

Un cambio que sólo se leyó no está probado. Ya pasó que un armado de páginas parecía correcto
leyendo el código y en el navegador ordenaba mal las secciones.

### Instalar el navegador

Sólo hace falta una vez por máquina. **Global, nunca dentro del repo**: la carpeta está en
Google Drive y npm no puede escribir `node_modules` ahí — la sincronización pisa los archivos
a mitad de la instalación y falla con `EBADF`/`EPERM`.

```
npm install -g playwright
npx playwright install chromium --only-shell
```

El verificador busca Playwright primero en el proyecto y después en la instalación global, así
que con eso alcanza.

## Protocolo para cada pedido

1. Entrar al repo y correr `git status` + revisar los últimos commits (`git log --oneline`)
   para saber en qué estado está todo — especialmente si empezás sin contexto previo.
2. Localizar el flujo afectado y sus variantes por rol (inspector, coordinador, empresa,
   call center, dirección) — los permisos y la UI difieren bastante entre roles.
3. Si el pedido es claro, implementar directamente. Si hay ambigüedad real sobre el
   comportamiento esperado, preguntar antes de tocar código (no hace falta preguntar para
   confirmar cosas obvias).
4. Implementar conservando las demás funciones — no reemplazar ni simplificar flujos
   existentes que no fueron pedidos, no borrar botones/permisos/comentarios/formularios.
5. Correr `npm run verificar` y después probar como usuario real: iniciar sesión con un usuario
   de prueba del rol correspondiente, ejercitar el flujo, revisar consola del navegador por
   errores. Probar tanto en ancho de escritorio como en un ancho angosto (~375–450px) — la app
   se usa mucho como PWA instalada en Windows y como app en el celular, así que el layout
   angosto importa tanto como el ancho. Si `verificar` devuelve 2, seguir lo que dice la
   sección "Si no hay navegador" en vez de publicar.
6. Confirmar que no haya regresiones en otros perfiles/roles.
7. Crear un commit descriptivo (mensaje corto, en español, explicando el motivo del cambio).
8. Subir a `main` en GitHub (`git push origin main`).
9. Verificar que Netlify haya publicado ese commit exacto en producción.
10. Cerrar con un resumen claro de qué se cambió, qué se probó, y cualquier acción manual
    pendiente del lado del usuario (por ejemplo correr un script SQL en Supabase).

El protocolo estándar actual es implementar, probar, comitear y publicar en cada pedido sin
esperar una confirmación adicional del usuario — no hace falta pedir permiso para el
commit/push salvo que el pedido en sí sea ambiguo o se trate de una operación destructiva
sobre datos reales.

## Reglas críticas sobre datos reales

- **La app en desarrollo local también apunta a la base de datos real de producción** (las
  credenciales de Supabase están fijas en `supabase-config.js`, no hay entorno de staging).
  Cualquier prueba que dispare una escritura real (crear/editar/borrar un registro) modifica
  producción de verdad. Antes de probar un flujo que escribe datos:
  - Si es posible, interceptar/simular la función de guardado (mockear
    `window.DGIE_DB.actualizarX`) para probar la lógica sin tocar la base real.
  - Si vas a probar contra datos reales igual, usar un registro de prueba conocido, anotar su
    estado original, y revertirlo explícitamente apenas termines de verificar.
  - Nunca dejar una prueba a medio revertir.
- No resetear Supabase ni borrar datos cargados. Cambios de esquema solo con
  `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` o similares, nunca `DROP TABLE` en producción.
- Cuando haga falta un cambio de esquema, preparar un script `.sql` idempotente (con
  `if not exists` / `drop constraint if exists` antes de recrear) y explicar qué toca antes
  de correrlo. Ejecutarlo en el editor SQL del panel de Supabase (no hay CLI de Supabase
  instalada en este entorno ni conexión directa a la base).
- Para operaciones destructivas sobre datos, confirmar primero qué registros se ven
  afectados.

## Criterios de interfaz

- Debe sentirse como una aplicación, sobre todo en celular / ventana angosta. No perder
  funciones en pantallas chicas.
- Evitar espacios vacíos grandes, controles desalineados, tablas imposibles de usar.
- Los archivos (fotos, PDFs, planillas) se abren dentro de la app (visor interno,
  `dgie-file-viewer.js`), no navegando a una URL externa — salvo que el pedido sea
  explícitamente "que se descargue directo" para un caso puntual.
- Los listados muestran primero lo más reciente, salvo indicación contraria.
- No agregar animaciones decorativas innecesarias.
- No mencionar nombres de tecnologías internas en textos de la UI.

## Comportamientos funcionales importantes (para no romper nada)

- Todos los usuarios autorizados ven las intervenciones de todos; se agrupan por
  intervención, con visitas adentro.
- Los certificados se agrupan por medición. Empresa e inspector tienen permisos distintos
  sobre ellos.
- Un certificado devuelto conserva versiones anteriores; la nueva versión es la vigente para
  cálculos.
- Adjuntos de certificados: límite 10 MB.
- Coordinación puede crear, analizar, exportar y eliminar comunicaciones. El inspector
  responde comunicaciones con establecimientos/comentarios estructurados, puede notificar
  empresas y poner en copia a coordinación.
- Comentarios de intervenciones: se pueden responder, solo el autor puede borrar los propios.
- Un reclamo se considera finalizado cuando finaliza la orden de servicio vinculada.
- Los datos se filtran estrictamente por zona cuando el flujo lo requiere.
- Estado de un reclamo: además de los estados automáticos ligados a su orden de servicio
  (Pendiente / Orden de servicio / Trabajando / Finalizado), el inspector puede **Anular** un
  reclamo o **Derivar**lo a un organismo externo (Obra, Obra gas, Epec, Aguas cordobesas, u
  otro texto libre). Ambas son acciones manuales que fijan el campo `estado` del reclamo
  (`anulado` / `derivado`) y tienen su propio panel con opción de editar/revertir. Estos
  estados deben reflejarse en TODOS los lugares donde se monitorean reclamos: el gráfico
  "Estado de reclamos" (hay implementaciones separadas para el dashboard del inspector, el de
  coordinación y la portada pública — buscar `estadoReclamoCanon`/`reclamoEstadoCounts` y sus
  reasignaciones), los filtros de la lista de reclamos, el PDF exportable y la vista de call
  center.

## Notificaciones push

- Se notifican nuevos reclamos y comunicados. Cada dispositivo se vincula al usuario
  autenticado. Los reclamos van a inspectores de la misma zona (todos si hay varios); si un
  usuario tiene celular y PC, reciben ambos. Cola por dispositivo con reintentos automáticos
  cada minuto; entregas pendientes se conservan hasta 7 días; las suscripciones no se borran
  al cerrar sesión.
- SQL: `supabase-notificaciones-confiables.sql`. Funciones:
  `netlify/functions/push-dispatch.mjs`, `netlify/functions/push-retry.mjs`,
  `netlify/lib/push-delivery.mjs`. Cliente: `dgie-notificaciones.js`, `dgie-supabase.js`,
  `service-worker.js`.

## Usuarios de prueba

- Coordinador: usuario `DGIECoord`, contraseña `111213`.
- Empresa zona 15: usuario `Empresa 15`, contraseña `Empresa_Zona15`.
- Inspector zona 15: usuario `Zona 15`, contraseña `Inspector_Zona15`.

## Estado reciente / avisos

- Hay un aviso en el panel de Supabase: la organización superó su cuota del ciclo anterior y
  los proyectos se restringirán a partir del 16 de agosto de 2026 si sigue así. No accionable
  desde el código; avisar al usuario si se vuelve a ver.
- El feature de "Derivar reclamo" quedó publicado junto con una migración SQL
  (`supabase-reclamos-derivacion.sql`) que agrega columnas `derivado_a`/`derivado_en`/
  `derivado_por` a `reclamos` y amplía el `check` de `estado` para aceptar `'derivado'`. Esa
  migración ya se ejecutó en producción — no volver a correrla salvo que haga falta
  (el script usa `if not exists`, así que es seguro re-ejecutarla si hay dudas).
