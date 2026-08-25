# Estado del trabajo

Libreta compartida entre las herramientas con las que se trabaja la plataforma
(Claude Code y Codex). **Quien la abre, la lee primero. Quien termina algo, la
actualiza en el mismo commit del cambio.**

No decide nada ni dispara trabajo solo: sirve para que cualquiera de las dos
sepa dónde quedó todo sin tener que preguntar.

Última actualización: **2026-08-25** · commit `a5e7b03`

---

## En qué se está trabajando ahora

### Sesión Administración — navegación por fichas

La sesión existe y funciona, pero muestra los certificados en una lista plana.
Falta reorganizarla en tres niveles, igual que la sesión de inspector:

1. fichas de zona
2. dentro de cada zona, fichas de medición
3. dentro de cada medición, los certificados en Pendientes / Observados / Aceptados

Con botón de volver en cada nivel.

- Hay que reescribir `renderBandeja`, en el bloque
  `<script id="dgie-administracion-certificados-2026-08-21">` de `index.html`.
- **No tocar** `tarjeta()`, `dgieAdmObservar`, `dgieAdmAprobar`, el versionado del
  inspector ni el bloqueo de módulos manuales: ya están probados y funcionando.
- El patrón a copiar es el del inspector: `renderBotonesMediciones`, que usa la
  grilla `med-btn-grid` con botones `secondary-btn med-btn` y renderiza el detalle
  abajo en un contenedor propio.

---

## Pendiente, sin empezar

### Base de datos — scripts listos para correr a mano

Están en `Downloads`, no en el repo. Los corre el usuario en el editor SQL.

| Script | Qué hace | Estado |
|---|---|---|
| `UNIFICAR-GARZON-AGULLA.sql` | Pasa todo lo cargado en los Garzón Agulla (J.I) y (SEC) a la escuela (ESC) | Esperar a que termine la carga de órdenes de zona 7 |
| `CARGAR-CERTIFICADOS-ZONA-6.sql` | 53 certificados | Sin correr |
| `CARGAR-OS-ZONA-7.sql` | 117 órdenes | Sin correr / puede estar corriéndose |

Además: falta crear el establecimiento `CENMA N° 70 OBISPO ANGELELLI`. Ojo que
`establecimientos.id` no tiene valor por defecto: hay que pasarlo explícito.

### Garzón Agulla — lo que tiene que resolver el inspector

Detalle completo en `Downloads/AVISO-INSPECTOR-GARZON-AGULLA.md`.

- Las O.S. **014, 015, 066 y 067** están certificadas pero no existen en zona 7.
  Son del Agulla y quedaron afuera cuando se pidió excluirlo de la carga.
- Faltan cargar también las O.S. **126, 135, 136 y 137** del mismo establecimiento.
- Van a quedar dos certificados en la medición 1 (212,55 y 881,55 módulos). Ya
  conviven así hoy; hay que confirmar si son dos o uno.

### Zona 6 — 10 certificados sin cargar

Cinco pesan más de 10 MB (hay que comprimirlos) y cinco tienen datos a corregir.
Detalle en `Downloads/ZONA-6-PENDIENTES-INSPECTOR.md`.

### Rendimiento — urgente

Cada carga de la plataforma baja 26,85 MB y 9.355 filas, incluso sin iniciar
sesión. Los certificados solos son 19 MB. Eso agotó el presupuesto de disco y
tiró el proyecto el 21/08. Falta:

- que la portada pública no baje datos operativos;
- filtrar por zona en las consultas;
- que el listado de certificados no traiga las conversaciones.

### Otros

- La política `reclamos actualizacion operativa` tiene una rama `mi_zona() = zona`
  sin chequeo de rol: una empresa puede modificar cualquier reclamo de su zona.
  Falta revisar qué flujos dependen de eso antes de cerrarla.
- Regenerar `dgie-orden-establecimientos.js` desde el pliego, ahora que los
  establecimientos quedaron alineados.

---

## Hecho recientemente

| Fecha | Commit | Qué | Con qué |
|---|---|---|---|
| 2026-08-25 | `a5e7b03` | `npm run verificar`: un solo comando de validación, con navegador | Claude Code |
| 2026-08-25 | `faf15fc` | La orden de servicio se descarga completa y en orden | Claude Code (terminó algo empezado por Codex) |
| 2026-08-24 | `a9db973` | Anexar análisis al PDF de la orden | Codex |
| 2026-08-21 | `71a95bf` | Sesión Administración: revisar, observar y aprobar certificados | Claude Code |
| 2026-08-20 | `c52bdd6` | El selector de O.S. del certificado no ofrece las ya certificadas | Claude Code |

---

## Cómo se mantiene esta libreta

Al cerrar una tarea, en el mismo commit del cambio:

1. Mover lo terminado a "Hecho recientemente", con fecha, commit, qué y con qué
   herramienta. Dejar como mucho las últimas 10 filas.
2. Actualizar "En qué se está trabajando ahora".
3. Agregar a "Pendiente" lo que haya aparecido en el camino.
4. Actualizar la fecha y el commit del encabezado.

Si algo quedó a medias, decirlo acá con todas las letras: qué se cambió, qué
quedó sin probar y qué falta. Es preferible una nota incómoda a que la próxima
sesión lo descubra sola.
