# Estado del trabajo

Libreta compartida entre las herramientas con las que se trabaja la plataforma
(Claude Code y Codex). **Quien la abre, la lee primero. Quien termina algo, la
actualiza en el mismo commit del cambio.**

No decide nada ni dispara trabajo solo: sirve para que cualquiera de las dos
sepa dónde quedó todo sin tener que preguntar.

Última actualización: **2026-09-01** · commit `este commit`

---

## En qué se está trabajando ahora

**Planilla de liquidación mensual.** Regla consolidada para todas las mediciones.

- La planilla se arma siempre y dinámicamente con el archivo vigente de cada
  certificado, sin distinción por número de medición.
- El PDF firmado queda como respaldo visible y es obligatorio para finalizar la
  medición, pero no aporta módulos, rubros ni montos: de él no se lee nada.
- **El total de módulos de la medición se carga a mano, al lado del PDF**, y es
  el que manda para el presupuesto y para "consumo por medición". El papel es el
  documento exacto; sumar los certificados da una aproximación, porque en el
  Excel el total y los subtotales por rubro son cuentas distintas, cada una con
  su redondeo. Mientras ese total no esté cargado se estima con los
  certificados y el panel lo dice.
- **El desglose por rubro sigue saliendo de los certificados y se muestra como
  aproximado.** El panel avisa cuánto difiere contra el total consumido y no
  toca ninguno de los dos para forzar que cierren.
- Necesita la columna nueva: correr una vez
  `supabase-medicion-modulos-firmados.sql`. Hasta entonces, guardar el total
  avisa que falta ese script.
- Una medición abierta muestra su liquidación preliminar y se actualiza al
  asignar, mover, reemplazar o quitar certificados. No consume presupuesto.
- Antes de finalizar se leen y guardan el total exacto, el precio y los cinco
  rubros del pliego de todos los certificados. Si falta el PDF o un archivo no
  se puede leer, la finalización queda bloqueada.
- Los indicadores, gráficos, comparativos, presupuesto por rubro y exportaciones
  de coordinación usan la misma función de liquidación. Sólo computan mediciones
  finalizadas, con PDF y certificados completos.
- Se eliminó la carga manual de módulos en todas las mediciones. En pantalla se
  muestra el valor leído del archivo vigente.
- Al reemplazar un archivo se invalidan los números de la versión anterior; si
  la lectura asíncrona todavía no terminó, la liquidación relee el archivo nuevo.
- Las cuentas se hacen con todos los decimales del certificado y se redondean
  únicamente al mostrar.
- El total y los subtotales por rubro son cálculos independientes del Excel.
  Diferencias de hasta 0,01 módulos se consideran redondeo normal: no bloquean
  el cierre ni provocan relecturas. Las diferencias mayores se informan con
  medición, establecimiento y O.S. para que el inspector sepa qué revisar.
- Validado con datos simulados e interceptando toda escritura: escritorio 1280
  px, móvil 375 y 450 px, inspector, coordinación, empresa y call center,
  medición abierta, sin PDF, completa e incompleta; sin errores de consola.
- Armar una liquidación recorre los 623 establecimientos y los ordena. Los
  tableros la piden una vez por zona y por medición, así que **el resultado se
  recuerda** (`window.dgieOlvidarLiquidaciones()` lo borra). Medido: 7,8 ms por
  llamada sin memoria contra 0,005 ms con memoria, y eso con seis certificados
  de prueba. Se olvida al actualizar un certificado, al finalizar una medición
  y al revertir una finalización.
- Las zonas de los tableros salen de los propios certificados
  (`window.dgieZonasConCertificados()`), no de una lista fija.
- En la ficha del certificado, si todavía no se leyó el archivo se muestra
  "Pendiente de lectura", no el valor viejo cargado a mano. Decir "leído del
  archivo" sobre un número escrito a mano sería mentir justo en el dato que
  ahora manda.

#### Ojo con la transición

Esto cambia de dónde salen los números de **todo lo ya cargado**, así que hasta
que se relean los archivos los indicadores van a mostrar de menos:

- Un certificado sólo cuenta si tiene `modulos_exacto` y `modulos_por_rubro`
  leídos de su Excel. Los históricos no los tienen todavía.
- **Se completan solos al abrir la liquidación**, que lee los archivos de todas
  las mediciones hasta la que se abre. Basta con abrir la última medición de
  cada zona, con perfil inspector, y dejar que termine.
- Las **13 mediciones finalizadas sin PDF** (zona 4 la 1 a la 3, zona 7 la 4 y
  5, zona 9 la 2, 4 y 5, zona 13 la 4 y 5, zona 14 la 4 y 5) no van a consumir
  presupuesto hasta que se suba el papel, aunque sus certificados se lean bien.

### Lo que hay que hacer a continuación

0. **Correr `supabase-medicion-modulos-firmados.sql`** (está en el repo). Sin eso
   no se puede cargar el total de módulos de la planilla firmada.
1. Correr supabase-liquidacion-modulos-por-rubro.sql si todavía no se ejecutó.
2. Correr supabase-liquidacion-colores.sql si todavía no se ejecutó.
3. Borrar la medición 7 de práctica de zona 15 (26 certificados con
   PRÁCTICA ·), verificando primero que no haya registros reales mezclados.
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
- Presupuesto: sus familias y coeficientes **no se tocaron**. El consumo general y por
  rubro se computa exclusivamente desde la liquidación de cada medición finalizada, que
  sale de los archivos vigentes de certificado en todas las mediciones; las mediciones
  abiertas, sin PDF o con certificados sin leer no consumen.

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
| 2026-09-01 | `este commit` | Liquidación: tolerancia al redondeo entre total y rubros; los avisos reales identifican medición, establecimiento y O.S.; un archivo completo ya no se relee indefinidamente | Codex |
| 2026-08-31 | `este commit` | Liquidación única desde certificados en todas las mediciones; PDF obligatorio sólo como respaldo; indicadores al finalizar; sin carga manual. Terminado y verificado: memoria de liquidaciones, zonas desde los datos, ficha sin valores a mano disfrazados | Codex + Claude Code |
| 2026-08-31 | `1675496` | De la medición 7 en adelante la liquidación vuelve a armarse con los archivos de certificado, con el mismo formato de planilla. El PDF deja de ser obligatorio para finalizar. El presupuesto pasa a usar la misma cuenta que la planilla, sea cual sea su origen. Revierte `4f95396` | Claude Code |
| 2026-08-28 | `4f95396` | Se probó que la liquidación saliera del PDF firmado en todas las mediciones y que sin PDF no se pudiera finalizar. Revertido el 31/08 | Claude Code |
| 2026-08-28 | `d875668` | Presupuesto de módulos: el consumo total y por rubro sale únicamente de mediciones finalizadas con PDF vigente reconocido y liquidación armada | Codex |
| 2026-08-28 | `38757f0` | Primera versión del desglose por rubro; tomaba certificados finalizados y fue reemplazada por la fuente correcta de liquidaciones reconocidas | Codex |
| 2026-08-27 | `ac867b8` | Planilla de liquidación mensual automática, desde la medición 7. Se empieza a guardar el desglose de módulos por rubro | Claude Code |
| 2026-08-27 | `cd02025` | Los certificados toman los módulos tal como se ven en la planilla, no con todos los decimales de fondo. Rige en toda carga nueva; lo ya guardado no se toca | Claude Code |
| 2026-08-27 | `b1c93f0` | Primera versión de lo anterior, condicionada a la medición 6. No servía: la empresa sube sin número de medición | Claude Code |
| 2026-08-27 | `408e74a` | Cerrajería como rubro detallado y filtros de rubro con el catálogo completo; en certificados el filtro ofrecía combinaciones y escondía registros | Claude Code |
| 2026-08-27 | `e15747c` | Nueva clasificación de rubros en toda la plataforma; se corrigió el promedio del estado edilicio, que había caído de 65% a 54% por contar como cero un rubro que nadie midió | Claude Code (terminó lo que venía haciendo Codex) |
| 2026-08-27 | `24d8aee` | Tableros: CUE antes del establecimiento en los listados de Reclamos y O.S., incluidos PDF y Excel | Codex |
| 2026-08-26 | `96f3bef` | Historial de certificados: descarga directa de Original, Inspector y Observado, sin abrir el visor | Codex |
| 2026-08-26 | `589db0d` | Certificados observados: etapas Original/Inspector/Observado, módulos de la versión vigente y descarga funcional desde el historial | Codex |

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
