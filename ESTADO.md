# Estado del trabajo

Libreta compartida entre las herramientas con las que se trabaja la plataforma
(Claude Code y Codex). **Quien la abre, la lee primero. Quien termina algo, la
actualiza en el mismo commit del cambio.**

No decide nada ni dispara trabajo solo: sirve para que cualquiera de las dos
sepa dónde quedó todo sin tener que preguntar.

Última actualización: **2026-08-27** · commit `este commit`

---

## En qué se está trabajando ahora

**Planilla de liquidación mensual.** Primera versión publicada, se sigue afinando.

- Botón "Liquidación" en la medición, a partir de la **medición 7**.
- Necesitaba un dato que no existía: los módulos por rubro. Se lee del Excel al subir
  el certificado y se guarda en `modulos_por_rubro`. Falta correr
  `supabase-liquidacion-modulos-por-rubro.sql`.
- Los cinco rubros de la liquidación son los del pliego (cubierta, electricidad,
  albañilería, sanitaria, gas) y **no** son los doce de la plataforma.
- El precio del módulo sale del Excel; mientras no haya certificados con ese dato, se
  carga a mano en el panel y queda recordado por zona.
- Pendiente de definir con el usuario: si el acumulado debe arrastrar los montos de las
  mediciones anteriores tal como figuran en la planilla firmada.

La nueva clasificación de rubros quedó aplicada en toda la plataforma. La regla es
una sola: **el dato detallado siempre se guarda como está; agrupar es solo una forma
de mostrar.**

- Inspector, coordinación, dirección y portada: **doce rubros detallados** (incluye
  cerrajería, agregada el 27/08).
- Tableros: **seis rubros generales**. Pluvial entra en sanitaria; herrería, vidrios,
  poda y pintura entran en albañilería.
- Estado edilicio: **seis generales en todas las sesiones**, tanto para cargar los
  porcentajes como para consultarlos.
- Presupuesto: **no se tocó**, y no debe tocarse. Sus familias están atadas a
  coeficientes y módulos.

Verificado contra los datos reales: los totales coinciden en los dos niveles
(3.668 reclamos y 3.687 órdenes), así que agrupar no pierde ningún registro.

Los filtros de rubro ofrecen el catálogo completo de cada sesión, no sólo lo que ya
está cargado, así un rubro nuevo se puede filtrar desde el día uno.

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
| 2026-08-27 | `este commit` | Planilla de liquidación mensual automática, desde la medición 7. Se empieza a guardar el desglose de módulos por rubro | Claude Code |
| 2026-08-27 | `cd02025` | Los certificados toman los módulos tal como se ven en la planilla, no con todos los decimales de fondo. Rige en toda carga nueva; lo ya guardado no se toca | Claude Code |
| 2026-08-27 | `b1c93f0` | Primera versión de lo anterior, condicionada a la medición 6. No servía: la empresa sube sin número de medición | Claude Code |
| 2026-08-27 | `408e74a` | Cerrajería como rubro detallado y filtros de rubro con el catálogo completo; en certificados el filtro ofrecía combinaciones y escondía registros | Claude Code |
| 2026-08-27 | `e15747c` | Nueva clasificación de rubros en toda la plataforma; se corrigió el promedio del estado edilicio, que había caído de 65% a 54% por contar como cero un rubro que nadie midió | Claude Code (terminó lo que venía haciendo Codex) |
| 2026-08-27 | `24d8aee` | Tableros: CUE antes del establecimiento en los listados de Reclamos y O.S., incluidos PDF y Excel | Codex |
| 2026-08-26 | `este commit` | Historial de certificados: descarga directa de Original, Inspector y Observado, sin abrir el visor | Codex |
| 2026-08-26 | `589db0d` | Certificados observados: etapas Original/Inspector/Observado, módulos de la versión vigente y descarga funcional desde el historial | Codex |
| 2026-08-26 | `d998bfc` | Administración: avisos de novedades cuando el inspector responde, deja una versión vigente o finaliza una observación | Codex |
| 2026-08-26 | `72770d0` | Certificados observados: se eliminó el formulario duplicado y se separaron los botones de antecedentes del bloque operativo | Codex |
| 2026-08-26 | `46262b0` | Certificados observados: mensajes ilimitados, versión vigente y cierre independientes; historiales de conversaciones y archivos preservados según el rol | Codex |
| 2026-08-25 | `a5e7b03` | `npm run verificar`: un solo comando de validación, con navegador | Claude Code |
| 2026-08-25 | `faf15fc` | La orden de servicio se descarga completa y en orden | Claude Code (terminó algo empezado por Codex) |
| 2026-08-24 | `a9db973` | Anexar análisis al PDF de la orden | Codex |
| 2026-08-21 | `71a95bf` | Sesión Administración: revisar, observar y aprobar certificados | Claude Code |


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
