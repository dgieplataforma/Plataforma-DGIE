# Estado del trabajo

Libreta compartida entre las herramientas con las que se trabaja la plataforma
(Claude Code y Codex). **Quien la abre, la lee primero. Quien termina algo, la
actualiza en el mismo commit del cambio.**

No decide nada ni dispara trabajo solo: sirve para que cualquiera de las dos
sepa dónde quedó todo sin tener que preguntar.

Última actualización: **2026-08-28** · commit `este commit`

---

## En qué se está trabajando ahora

**Planilla de liquidación mensual.** Primera versión publicada, se sigue afinando.

- Botón "Liquidación" en la medición, a partir de la **medición 7**.
- Necesitaba un dato que no existía: los módulos por rubro. Se lee del Excel al subir
  el certificado y se guarda en `modulos_por_rubro`. Falta correr
  `supabase-liquidacion-modulos-por-rubro.sql`.
- Los cinco rubros de la liquidación son los del pliego (cubierta, electricidad,
  albañilería, sanitaria, gas) y **no** son los doce de la plataforma.
- El panel **Presupuesto de módulos** muestra ahora cuánto se consumió en cada uno de
  esos cinco rubros. Conserva el total vigente anterior; usa `modulos_por_rubro`, asigna
  el total sólo si el certificado tiene un único rubro y deja explícitamente sin distribuir
  los certificados multirrubro que todavía no tienen desglose.
- El precio del módulo sale del Excel; mientras no haya certificados con ese dato, se
  carga a mano en el panel y queda recordado por zona.
- **De la medición 6 para atrás, en todas las zonas, la planilla es la del PDF firmado.**
  Se reconoce al subir el papel, y también la primera vez que se abre la liquidación si
  ya estaba cargado. Se lee fila por fila a `liquidacion_firmada`, con los módulos y el
  monto tal como figuran, incluidos los del pie. Se valida contra los totales del propio
  papel: si no coinciden, no guarda nada.
- **Sin PDF cargado no se muestra ninguna planilla** para esas mediciones: se pide el
  papel. Mostrar una calculada daría números distintos a los que se cobraron.
- **Desde la medición 7 la liquidación se arma con los certificados**, que es el
  procedimiento nuevo. En una misma planilla conviven las dos formas: las columnas de las
  mediciones 1 a 6 traen los montos del papel firmado, y la 7 en adelante se calcula.
- **Desde la medición 7 no se pueden cargar módulos a mano.** El campo "módulos
  certificado final" desaparece y se muestra el número del certificado. Si el número está
  mal, se corrige el certificado y se vuelve a subir.
- Las cuentas de la 7 en adelante van **en bruto**: los rubros y el total salen del Excel
  con todos sus decimales, el monto se calcula con el valor de módulo del propio
  certificado, y sólo se redondea al mostrar. Si los rubros no suman el total, el
  certificado se relee solo.
- Hay **35 mediciones finalizadas con PDF firmado y 13 sin PDF**. Las que no lo tienen no
  van a poder mostrar la planilla histórica hasta que se cargue.
- **Las cuentas se hacen en bruto y la pantalla muestra dos decimales.** Los módulos, el
  total y la multiplicación por el valor del módulo usan el número completo del
  certificado; el redondeo es sólo al mostrar. Cada fila usa el valor de módulo de su
  propio certificado, así el monto da exactamente el que figura ahí.
- Cada zona elige el color de sus mediciones. Falta correr
  `supabase-liquidacion-colores.sql`.
- **Sólo se liquidan las mediciones finalizadas.** Una medición abierta todavía puede
  cambiar, así que no entra ni en la planilla ni en el acumulado.
- **El desglose por rubro se fija al marcar la certificación finalizada**, que es cuando
  los certificados quedan quietos. No hay botón: los certificados nuevos lo traen al
  subirse, y las mediciones cerradas antes de esto se completan solas la primera vez que
  se mira su liquidación.

### Lo que hay que hacer a continuación

1. **Correr el borrado** para que la planilla firmada se relea con la última versión del
   lector, que toma también el monto del pie:
   `delete from public.liquidacion_firmada; delete from public.liquidacion_firmada_totales;`
2. **Abrir la liquidación de zona 15, medición 4.** Lee el PDF y guarda las 68 filas.
3. **Abrir la medición 7 de zona 15**, que es la de práctica: 26 certificados copiados de
   la 4 con las órdenes con 1000 sumado y el nombre con "PRÁCTICA ·" adelante. Ahí se ve
   el procedimiento nuevo conviviendo con las cuatro columnas históricas.
4. **Faltan PDF en 13 mediciones finalizadas**: zona 4 la 1 a la 3, zona 7 la 4 y 5,
   zona 9 la 2, 4 y 5, zona 13 la 4 y 5, zona 14 la 4 y 5. Hasta que se suban, esas
   mediciones piden el papel y no muestran planilla.
5. **Borrar la práctica** cuando ya no sirva:
   `delete from public.certificados_medicion where zona=15 and medicion_numero=7 and establecimiento_nombre like 'PRÁCTICA ·%';`

### Diferencias conocidas, para no volver a investigarlas

- **Zona 15, medición 4, O.S. 166** (J. de Inf. República del Ecuador): el papel se firmó
  con 12,46247 módulos y el Excel que hoy está adjunto dice 12,465. Son $345,14. El
  certificado se reemplazó después de la firma. Los otros 25 de esa medición dan idénticos.
- **Zona 15, medición 4, O.S. 158**: el inspector había cargado 4,87 a mano contra 4,968
  del certificado; ya fue corregido a 4,97.

### Pendiente de revisar por el inspector

**Zona 15, medición 4, O.S. 158 · Escuela República Argentina.** El inspector midió
4,968 módulos, que es lo que se firmó (4,97), pero el "módulos final" quedó cargado a
mano en 4,87 con la observación "No corresponde desobstrucción manual". Esos 0,10
módulos son toda la diferencia entre la planilla firmada (484,92) y la plataforma
(484,84). Hay que definir cuál vale.

**90 certificados donde el total del Excel no coincide con el que tiene la plataforma.**
No es un error de lectura: el archivo dice una cosa y el registro otra. Los más
llamativos: Alejandro Carbó zona 2 medición 1 (Excel 52,13 / plataforma 161,61), Alas
Argentinas zona 15 medición 1 (28,98 / 25,88), Rosario Vera Peñaloza zona 15 medición 2
(10,69 / 9,71). Puede ser que el archivo vigente no sea el que corresponde, o que se
corrigió el número sin actualizar el Excel.

La nueva clasificación de rubros quedó aplicada en toda la plataforma. La regla es
una sola: **el dato detallado siempre se guarda como está; agrupar es solo una forma
de mostrar.**

- Inspector, coordinación, dirección y portada: **doce rubros detallados** (incluye
  cerrajería, agregada el 27/08).
- Tableros: **seis rubros generales**. Pluvial entra en sanitaria; herrería, vidrios,
  poda y pintura entran en albañilería.
- Estado edilicio: **seis generales en todas las sesiones**, tanto para cargar los
  porcentajes como para consultarlos.
- Presupuesto: sus familias, coeficientes y cálculo general **no se tocaron**. Sólo se
  agregó al resumen el consumo por los cinco rubros del pliego, sin estimar distribuciones
  cuando falta el desglose.

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
| 2026-08-28 | `este commit` | Presupuesto de módulos: desglose de módulos consumidos por los cinco rubros del pliego, conservando el total vigente y señalando los certificados todavía sin distribución | Codex |
| 2026-08-27 | `ac867b8` | Planilla de liquidación mensual automática, desde la medición 7. Se empieza a guardar el desglose de módulos por rubro | Claude Code |
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
