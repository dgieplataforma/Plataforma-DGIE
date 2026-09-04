# Estado del trabajo

Libreta compartida entre las herramientas con las que se trabaja la plataforma
(Claude Code y Codex). **Quien la abre, la lee primero. Quien termina algo, la
actualiza en el mismo commit del cambio.**

No decide nada ni dispara trabajo solo: sirve para que cualquiera de las dos
sepa dónde quedó todo sin tener que preguntar.

Última actualización: **2026-09-04** · commit `este commit`

---

## En qué se está trabajando ahora

**Aprobaciones de certificados.** Corregida la identidad de las filas del inspector.

- Se conserva el ID del certificado en la fila aun después de retirar la carga manual de módulos.
- Marcas, contadores y seguimiento usan esa identidad; las marcas y filtros se recalculan sin duplicarse.
- Validado con aprobados/observados/pendientes simulados, cambios de estado y filtros en 1280/450/375 px; sin escrituras reales.


**Cumpleaños de inspectores.** Cargado y **andando** desde el 04/09/2026.

- **15 cargados** en `CUMPLEANIOS`, con lo que cada uno respondió en el pedido "Fechas de
  cumpleaños". `zona:0` es coordinación, que no tiene zona propia.
- **No están** las zonas 9, 12 y 17, que no contestaron.
- La **zona 7 respondió que NO autoriza** a que se informe su cumpleaños. Se agrega igual,
  por decisión de coordinación del 04/09/2026. Queda anotado acá y en el código: es un dato
  que ella no dio.
- Para sumar a alguien: una línea más, `{zona, apodo, fecha:'MM-DD', color}`. La fecha va
  en mes-día sin año, así se repite sola; el color es opcional.
- **El cartel lleva texto blanco sobre el color**, así que los tonos claros no sirven tal
  cual. El amarillo de Toti y el celeste de Cuchillo se oscurecieron hasta que se leyeran
  (mínimo 4,5 de contraste). Si mañana alguien elige un pastel, hay que hacer lo mismo.
- **Belu (zona 3) y Valen (zona 4) cumplen los dos el 25 de noviembre**: es el caso que
  cubre el cartel de varios festejados a la vez.
- **El día del cumpleaños lo ven todas las sesiones de inspector y de coordinación**, de
  cualquier zona: la plataforma toma acento rojo y aparece una franja festiva debajo del
  encabezado, “Feliz cumpleaños <apodo>”. Son los que van a saludar, así que son los que
  lo ven. Empresa, dirección, tableros, administración y call center no.
- **Si el cumpleaños cae sábado, domingo o feriado, el homenaje se corre al primer día
  hábil siguiente**, y el cartel aclara la fecha real: “Cumplió el sábado 14 de marzo, lo
  festejamos hoy”. Cuando cae en día hábil dice “Cumple hoy, martes 17 de marzo”.
- **Puede haber más de un festejado el mismo día** —típico: uno cumple sábado y otro
  domingo, y los dos caen el lunes—. El cartel los saluda a los dos y aparece un par de
  botones por cada uno, para no mezclar los saludos.
- Los feriados fijos y los que dependen de Pascua (Carnaval y Viernes Santo) se calculan
  solos, no hay que cargarlos. Los **puentes turísticos y los feriados trasladables, que
  se definen por decreto cada año, van en `FERIADOS_CARGADOS`**, en formato año-mes-día.
  Si falta cargarlos, lo peor que pasa es que el homenaje caiga un día que no se trabaja.
- Todos ellos tienen los botones para mandar y consultar saludos, con autor y fecha. Los
  saludos se agrupan por el homenajeado, no por quien escribe.
- **La sorpresa la cuida la fecha, no el alcance.** El primer intento la arruinó al revés:
  se restringió quién lo veía, pero con `prueba:true` puesto se veía todos los días.
- El fondo de esas ventanas necesita la clase `visible`; sin ella se arman pero quedan en
  `display:none` y parece que el botón no hiciera nada. Ya pasó una vez.
- Para habilitar el guardado compartido hay que correr una vez
  `supabase-saludos-cumpleanios.sql`. Sus políticas dan lectura y escritura a inspectores y
  coordinación, el mismo alcance que la pantalla.
- Para probar sin esperar a la fecha, se le agrega `prueba:true` a una línea y queda activa
  todos los días. **Hay que acordarse de sacarlo**: con eso puesto, el festejo se ve a
  diario.

**Estado edilicio.** Cada rubro admite ahora una problemática o aclaración propia.

- Desde el 04/09, Otros queda fuera del catálogo de Estado Edilicio y de todos sus
  promedios, fichas, gráficos, filtros y exportaciones. Los datos históricos se conservan.
- La ficha usa el mismo promedio de rubros activos con dato que los indicadores generales.
  Probado en 1280/450/375 px, con edificios compartidos, datos parciales y exportaciones.

- El inspector carga el porcentaje y un texto independiente para cada uno de los cinco rubros;
  las observaciones generales siguen disponibles y no se reemplazan.
- La ficha muestra las problemáticas agrupadas por rubro. Si dos establecimientos comparten
  edificio, el vinculado toma porcentajes y aclaraciones del establecimiento principal.
- Coordinación tiene una pestaña "Estado edilicio" con toda la información desglosada por
  establecimiento y rubro, filtros combinables por texto, zona, rubro, estado, porcentaje y
  fechas, y exportación a PDF o Excel de las filas visibles.
- Las observaciones generales se muestran una sola vez por establecimiento, en la primera
  fila visible, tanto en pantalla como en las exportaciones.
- Se guarda dentro de los datos existentes del relevamiento, por lo que no requiere script SQL.
- Validado con datos simulados, sin escrituras reales: inspector y coordinación en 1280, 450 y
  375 px, persistencia de textos, filtros, consola y desborde horizontal.

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

**Recordatorio de comunicaciones.** Coordinación tiene un botón "Recordar (n)" en cada
comunicación que mandó, al lado de Eliminar.

- Se puede usar **cuando haga falta y las veces que haga falta**: para apurar un cierre,
  para insistir, o para agregar algo. No cierra la comunicación ni cambia su estado.
- **Le llega sólo a quien todavía no respondió.** A quien ya cumplió no se lo molesta, y
  así el aviso se sigue leyendo cuando hay que repetirlo. El número del botón es cuántos
  faltan; si no falta nadie, el botón no aparece.
- El mensaje se escribe en el momento, con una sugerencia armada según la fecha límite.
- Usa la misma cola de notificaciones que el resto. El `kind` sigue siendo `comunicado`
  porque la columna tiene una restricción cerrada de valores; lo que cambia es el
  `source_id`, que lleva marca de tiempo para que dos recordatorios seguidos no se pisen.
  El lector ya separa el id real cortando por `:`.
- Necesita correr una vez `supabase-comunicaciones-recordatorio.sql`. Sin eso, el botón
  avisa que falta ese script.

**Aviso de carga completa.** El inspector avisa que una medición ya tiene todos sus
certificados, sin cerrarla.

- Botón **"Avisar carga completa"** en la medición abierta, al lado de "Marcar
  certificación finalizada". Se puede deshacer si aparece otro certificado. Una vez
  finalizada la medición el botón desaparece: ya no aporta nada.
- **Administración lo ve en su grilla de mediciones**, con la marca "Carga completa"; las
  que no avisaron dicen "el inspector todavía puede sumar más".
- Se guarda como `[CARGA_COMPLETA:Z<zona>:<fecha>]` dentro de `observaciones_inspector`,
  igual que la finalización, y `limpiarObsCert` lo saca de lo que se muestra. **Por eso
  esta parte no necesita ningún script.**
- La **notificación** a Administración sí: `supabase-carga-completa-medicion.sql`. Sin
  correrlo el aviso igual queda marcado y visible, sólo no suena.

### Lo que hay que hacer a continuación

0. **Correr `supabase-carga-completa-medicion.sql`** para que a Administración le suene
   el aviso de carga completa. Sin eso el aviso se ve igual, pero no notifica.
0. **Correr `supabase-comunicaciones-recordatorio.sql`** para habilitar el botón
   “Recordar” de coordinación. Sin eso el botón aparece pero avisa que falta el script.
0. **Correr `supabase-saludos-cumpleanios.sql`** para habilitar el guardado de
   saludos de la zona del festejo. Sin eso, los botones aparecen pero avisan que el
   historial no está habilitado. Puede esperar hasta que se carguen los cumpleaños.
1. **Correr `supabase-medicion-modulos-firmados.sql`** (está en el repo). Sin eso
   no se puede cargar el total de módulos de la planilla firmada.
2. Correr supabase-liquidacion-modulos-por-rubro.sql si todavía no se ejecutó.
3. Correr supabase-liquidacion-colores.sql si todavía no se ejecutó.
4. Borrar la medición 7 de práctica de zona 15 (26 certificados con
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
- Estado edilicio: **cinco rubros en todas las sesiones, sin Otros**, tanto para cargar los
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
| 2026-09-04 | `este commit` | Certificados: conservar ID al retirar módulos manuales para mostrar aprobación, contadores y seguimiento | Codex |
| 2026-09-04 | `este commit` | Estado edilicio: quitar Otros de catálogo y cálculos; unificar promedio de ficha y conservar históricos | Codex |
| 2026-09-03 | `este commit` | Estado edilicio: evitar repetir las observaciones generales en cada fila y exportación de rubro | Codex |
| 2026-09-03 | `este commit` | Estado edilicio: problemática por cada rubro y vista integral filtrable y exportable para Coordinación | Codex |
| 2026-09-02 | `este commit` | Cumpleaños: saludos compartidos con autor y fecha, visibles y habilitados únicamente para el inspector de Zona 15 y coordinación | Codex |
| 2026-09-02 | `este commit` | Cumpleaños: motor configurable por fecha, apodo y color; prueba activa de Zona 15 en rojo para inspector y coordinación; franja fija responsive y limpieza al cerrar sesión | Codex |
| 2026-09-01 | `este commit` | Liquidación: tolerancia al redondeo entre total y rubros; los avisos reales identifican medición, establecimiento y O.S.; un archivo completo ya no se relee indefinidamente | Codex |
| 2026-08-31 | `este commit` | Liquidación única desde certificados en todas las mediciones; PDF obligatorio sólo como respaldo; indicadores al finalizar; sin carga manual. Terminado y verificado: memoria de liquidaciones, zonas desde los datos, ficha sin valores a mano disfrazados | Codex + Claude Code |
| 2026-08-31 | `1675496` | De la medición 7 en adelante la liquidación vuelve a armarse con los archivos de certificado, con el mismo formato de planilla. El PDF deja de ser obligatorio para finalizar. El presupuesto pasa a usar la misma cuenta que la planilla, sea cual sea su origen. Revierte `4f95396` | Claude Code |
| 2026-08-28 | `4f95396` | Se probó que la liquidación saliera del PDF firmado en todas las mediciones y que sin PDF no se pudiera finalizar. Revertido el 31/08 | Claude Code |

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
