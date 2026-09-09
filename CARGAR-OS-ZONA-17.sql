-- Carga de órdenes de servicio históricas - ZONA 17
-- Origen: Base de datos para APP-zona 17.xlsx, mediciones 2 a 5.
-- 105 órdenes faltantes. No incluye las 29 ya cargadas de la medición 1
-- ni el lote independiente Z17-220 a Z17-358.
--
-- Script idempotente: una segunda ejecución no duplica ni modifica órdenes.
-- Conserva literalmente los datos de origen. Z17-048 no tiene fecha y
-- Z17-116 trae 2025-06-11. Z17-110 se vincula manualmente al establecimiento
-- correcto, ESCUELA MANUEL ESTEBAN PIZARRO (id 743).

begin;

create temporary table dgie_carga_os_zona17 (
  numero text primary key,
  establecimiento_id bigint not null,
  tarea text not null,
  rubro text not null,
  fecha_envio date
) on commit drop;

insert into dgie_carga_os_zona17
  (numero, establecimiento_id, tarea, rubro, fecha_envio)
values
  ('Z17-002', 718, 'ALBAÑILERÍA/CARPINTERÍA: Reparar cortina de enrollar en Laboratorio', 'Herrería', '2026-04-09'),
  ('Z17-008', 717, 'ALBAÑILERIA /HERRERÍA: 1) Recolocar pizarrón existente - 2) Reparar portón vehicular trabado: Lubricar rodamientos - Soldar
perfiles guía
INST. SANITARIA: Reemplazar tanque de PVC de inodoro en baño', 'Albañilería', '2026-04-07'),
  ('Z17-035', 728, 'INST. SANITARIA: Reemplazar cañerías pluviales en vereda municipal - ejecutar dos cámaras de limpieza pluviales con rejas en vereda.
Albañileria: Demoler piso de hormigon de vereda - Demoler cordón de hormigón de vereda. Ejecutar mampostería de ladrillo visto de primera calidad con junta al ras -Ejecución de encadenados correspondientes en mampostería dando
continuidad a los ya ejecutados en mampostería de bloques de muro interior-Recolocar paños de valla electrosoldada. Ejecutar solado de hormigón en sector de vereda municipal intervenido y cordón de vereda de hormigón. Ejecutar zócalo cementicio en sector intervenido', 'Albañilería', '2026-04-15'),
  ('Z17-036', 718, 'INSTALACIÓN ELÉCTRICA: Reponer reflector en ingreso', 'Instalación eléctrica', '2026-04-08'),
  ('Z17-037', 741, 'Instalación Electrica: Agregar artefactos de iluminación en aulas - Reponer tubos y lámparas faltantes - Proveer bocas de alimentación a cámaras de
seguridad', 'Instalación eléctrica', '2026-04-01'),
  ('Z17-038', 728, 'Instalación Sanitaria: Reparación de válvulas de inodoros - reemplazo de fuelle - Reemplazo de canilla en pileta exterior. Herrería: Soldar bisagra y ajustar cierre de puerta de ingreso-', 'Instalación sanitaria', '2026-04-14'),
  ('Z17-039', 735, 'Instalación Eléctrica: Reemplazar artefactos de iluminación en aulas de grados 5to A y 5to B . Agregar en estos grados 2 artefactos de iluminación en
cada uno - Reparar llaves de luz sin funcionar - Reponer tubos faltantes en grados 4to y 6to', 'Instalación eléctrica', '2026-04-17'),
  ('Z17-040', 717, 'INST. ELECTRICA: Reponer ilumnación exterior', 'Instalación eléctrica', '2026-04-01'),
  ('Z17-041', 717, 'INST. SANITARIA: desobstruir 3 inodoros - Reemplazar canilla de servicio en piletón', 'Instalación sanitaria', '2026-04-06'),
  ('Z17-042', 724, 'INST ELÉCTRICA: Reemplazar tubos de iluminación qumados - Reparar toma corrientes deteriorados - Reemplazar prolongaciones eléctricas tipo "
zapatillas" por la extensión del cableado y cajas para tomacorrientes', 'Instalación sanitaria', '2026-04-10'),
  ('Z17-043', 731, 'Instalación Sanitaria: Reparar sistema de tanque elevado - Limpiar sector de bomba', 'Instalación sanitaria', '2026-04-16'),
  ('Z17-044', 743, 'CARPINTERÍA: Reparación de puerta de aula - fijación de vidrio en puerta de aula', 'Herrería', '2026-04-07'),
  ('Z17-045', 745, 'Instalación Electrica: Reemplazar tubos de iluminación sin funcionar', 'Instalación eléctrica', '2026-04-10'),
  ('Z17-046', 745, 'ALBAÑILERÍA: Demolición de piso de Hº - Excavación para cañerías cloacales y de ventilación, para cámara de inspección, y pozo absorbente - Relleno y
compactación de suelo de relleno de zanjas - ejecución de piso de HºAº - Verificación de asentamiento de suelo sector próximo a cámara séptica:
demolición de piso, compactación, reposición de piso de HºAº
INSTALACIÓN SANITARIA: Desagotar cámara séptica y pozo -Reemplazar caño de descarga de cámarta séptica a pozo existente -
Ejecución de cámara de inspección - Conexión a nuevo pozo absorbente - proveer ventilación a pozo -', 'Instalación sanitaria', '2026-04-13'),
  ('Z17-047', 745, 'Instalación Sanitaria: Reparar caño con pérdida en techo - Reemplazar flotante de sistema de tanques de reserva - Reparar mochilas y fuelles
defectuosos - Proveer llaves de paso a tanques de inodoros - Reemplazar sifones de piletas de comedor y officce de personal', 'Instalación sanitaria', '2026-04-14'),
  ('Z17-048', 748, 'INST. ELECTRICA: Reponer luminarias interiores y exteriores. INST. SANITARIA: Reponer flexible de inodoro', 'Instalación eléctrica', null),
  ('Z17-049', 744, 'Inst. Electrica: Proveer y colocar 6 ventiladores de pared industriales de 32 " en SUM - proveer y colocar
protecciones metálicas a ventiladores
Herrería: proveer y colocar protecciones metálicas a ventiladores', 'Herrería', '2026-04-09'),
  ('Z17-050', 744, 'Inst. Eléctrica: Reposición de 3 reflectores en torre de iluminación de patio', 'Instalación eléctrica', '2026-04-08'),
  ('Z17-051', 742, 'Instalación Electrica: Reparación de cortocircuitos - Reponer tubos de iluminación - Reponer reflector en hall de ingreso - Ordenar circuitos -Renovar
gabinete y reordenar tablero principal', 'Instalación eléctrica', '2026-04-06'),
  ('Z17-052', 726, 'Inst Eléctrica: Reemplazar artefactos de iluminación obsoletos - Reponer tubos y lámparas faltantes - Extraer canalizaciones por cable canal y
prolongaciones tipo "zapatilla" y reemplazar por caños de pvc rigidos y tomacorrientes aplicadas - Elevar tomacorrientes ubicados a baja altura en
salas - Reubicar tablero seccional en secretaría', 'Instalación sanitaria', '2026-04-13'),
  ('Z17-053', 715, 'INSTALACIÓN ELÉCTRICA: Extraer 3 ventiladores de techo de circulación - Colocar 3 ventiladores de pared en circulación - Proveer la instalación
eléctrica para nuevas ubicaciones de ventiadores - Reponer tubos de iluminación en aulas - Reemplazar artefacto de iluminación en archivo', 'Instalación eléctrica', '2026-05-13'),
  ('Z17-054', 737, 'INST. ELECTRICA: Renovar instalación eléctrica de casa habitación (sede de Inspección de Zona) - Se proveerá alimentación independiente desde tablero general a tablero seccional exclusivo de casa habitación - Se ejecutará la instalación con cañería de PVC rigido exterior ignifugo y cajas aplicadas - Se renovarán todos los artefactos de iluminación - Se proveerán artefactos de iluminación de emergencia - Se proveerán ciruitos para equipos de acondicionamiento de aire.', 'Instalación eléctrica', '2026-05-18'),
  ('Z17-055', 725, 'Instalación Eléctrica: Reponer tubos de iluminación , lámpara de baño y reflector de patio', 'Instalación eléctrica', '2026-05-14'),
  ('Z17-056', 725, 'Instalación Sanitaria: Reparar mochila baño de alumnos - Limpiar piletas de patio - Desobstruir cañerías', 'Instalación sanitaria', '2026-05-15'),
  ('Z17-057', 739, 'Instalación Sanitaria: Reemplazar vástagos de grifería embutida en piletones y cocina, - Desobstruir cañerías de desague de piletones y desague de
pileta de cocina', 'Instalación sanitaria', '2026-05-05'),
  ('Z17-058', 746, 'INST SANITARIA: Reparar sistemas de descarga de mochilas - regular flotantes de mochilas - Reparar válvula de descarga de inodoro - Reparar desagues
de mingitorios', 'Instalación sanitaria', '2026-05-13'),
  ('Z17-059', 741, 'Instalación Electrica: Reemplazo de artefactos de iluminación obsoletos en aula', 'Instalación eléctrica', '2026-05-06'),
  ('Z17-060', 741, 'ALBAÑILERÍA/HERRERÍA: Reparar cortina de enrollar - Reemplazar correa de accionamiento', 'Albañilería', '2026-05-07'),
  ('Z17-061', 740, 'Instalación Sanitaria: Reponer canilla de bebedero -Reparación de desague de piletón bebedero. ALBAÑILERÍA: Reponer losetones de borde de escenario', 'Instalación sanitaria', '2026-05-08'),
  ('Z17-062', 735, 'Instalación Eléctrica: Reparación de cortocircuito en iluminación exterior', 'Instalación eléctrica', '2026-05-12'),
  ('Z17-063', 735, 'Instalación Sanitaria: Desobstruir PPA en baño - Regular válvulas de mingitorios - Reparar pérdidas en inodoros', 'Instalación sanitaria', '2026-05-13'),
  ('Z17-064', 717, 'HERRERÍA: Recolocar protecciones de calefactores - Proveer y colocar protecciones para reflectores exteriores. INSTALACIÓN ELÉCTRICA: Recolocar 6 reflectores existentes', 'Herrería', '2026-05-15'),
  ('Z17-065', 717, 'INST. SANITARIA: desobstruir inodoros en baño alumnos - Reemplazar inodoro quebrado', 'Instalación sanitaria', '2026-05-18'),
  ('Z17-066', 731, 'Instalación sanitaria: Se solicita que acudan al establecimiento por falta de suministro de agua. Detectar el origen del problema y evaluar si se
determina a la bomba o ingreso de agua sanitaria', 'Instalación sanitaria', '2026-05-05'),
  ('Z17-067', 745, 'Instalación Electrica: Reparar cortocircuito . Sector sin luz . Reemplazar fusible NH en pilar de entrada de servicio eléctrico', 'Instalación eléctrica', '2026-05-08'),
  ('Z17-068', 737, 'PINTURA: Pintura de casa habitación . Sede de Inspección Nivel Medio - Ejecutar pintura interior de locales indicados en plano y paramentos exteriores. CARPINTERÍA: Reemplazar 3 persianas de enrrollar existentes en mal estado por 3 persianas de enrollar de PVC reforzadas', 'Albañilería', '2026-05-18'),
  ('Z17-069', 737, 'INST. SANITARIA: Verificar filtraciones en sector cisterna - Determinar reccorridos de provisión de agua para los distintos sectores -
reemplazar cañería en mal estado en sector de cisterna - Reparar pérdida en bacha baño de alumnos - Reemplazar mingitorio roto', 'Instalación sanitaria', '2026-05-05'),
  ('Z17-070', 747, 'ALBAÑILERÍA: Ejecutar 2 columnas de refuerzo adosadas a pared exterior existente de bloques de cemento sobre calle La Tablada', 'Albañilería', '2026-05-12'),
  ('Z17-071', 747, 'CUBIERTA: Limpiar cubierta sector laboratorio - Limpiar canaleta "U" de SUM. INST. SANITARIA: Desobstruir inodoro - Regular válvula de descarga de inodoro baño de discapacitados. ALBAÑILERIA: Retirar espejo roto en sanitario', 'Cubierta de techos', '2026-05-08'),
  ('Z17-072', 738, 'INST SANITARIA: Reemplazo de cañilla de servicio en piletón de alumnos', 'Instalación sanitaria', '2026-05-18'),
  ('Z17-073', 739, 'ALBAÑILERÍA: Extraer revestimiento de cerámicos en mal estado en piletones de salas - Ejecutar evestimientos cerámico en piletones intervenidos -
Ejecutar rampa simple de hormigón en ingreso de sala desde patio', 'Albañilería', '2026-05-04'),
  ('Z17-075', 739, 'ALBAÑILERÍA/VIDRIOS: Reemplazar vidrio en puerta de sala', 'Albañilería', '2026-05-06'),
  ('Z17-076', 742, 'Instalación Electrica: Reemplazo de artefactos de iluminación obsoletos en aula', 'Instalación eléctrica', '2026-05-12'),
  ('Z17-077', 743, 'ALBAÑILERÍA /CARPINTERÍA: Renovar mueble bajo mesada en cocina de comedor', 'Albañilería', '2026-05-06'),
  ('Z17-078', 718, 'ELECTRICIDAD: Verificar instalación por salida de servicio general - Reparar cortocircuito en sector sala de maestros', 'Instalación eléctrica', '2026-05-05'),
  ('Z17-079', 737, 'INST. ELECTRICA: Reponer tapa de caja de paso exterior en casa habitación - Verficar instalación en un sector del establecimiento sin
energía', 'Instalación eléctrica', '2026-05-04'),
  ('Z17-080', 731, 'Instalación Electrica: Revisión de instalación por falta de energía- Verificar carga de circuitos - Proveer y colocar guardamotor en sistema de bomba', 'Instalación eléctrica', '2026-05-04'),
  ('Z17-081', 750, 'Inst. Sanitaria: Desobstruir inodoros baño de alumnos - Reparar válvula de descarga de inodoro - Desobstruir cañería de desague
de lavatorio', 'Instalación sanitaria', '2026-05-14'),
  ('Z17-082', 750, 'Inst. Eléctrica: Provisión y colocación de venti ladores de 25", 2 en salón de tal ler y 1 en aula especial', 'Instalación eléctrica', '2026-05-15'),
  ('Z17-083', 743, 'INSTALACION SANITARIA:Se selló pileta de lavar doble en cocina de comedor - Se repararon 2 canillas con pérdidas - Se repararon 3 mochilas de descarga de inodoros. Se recolocó una puerta corrediza en baño', 'Instalación sanitaria', '2026-05-07'),
  ('Z17-084', 745, 'ALBAÑILERÍA: Se extrajeron piezas de mosaico granítico "levantadas" en aula de 5 to grado y losetas de Hº con la misma patología en galería exterior -
Se recuperaron las piezas y se reconstituyeron los solados originales', 'Albañilería', '2026-05-11'),
  ('Z17-085', 727, 'Cubierta: Reparación de sector de cubierta contigua a medianera con evidencias de filtraciones - Reparación parcial de imprmeabilización de parapetos. Instalación Sanitaria: Reparación de cañería embutida en piletón de salas', 'Cubierta de techos', '2026-05-11'),
  ('Z17-086', 734, 'Inst . Sanitaria: Reparar pérdida en inodoro - Reparar mochila de inodoro - Reponer canilla de servicio en espacio verde - Reparar y fijar caño de desague de pileta de conserjería adosado a pared exterior en patio - Reparar pérdida en lavatorio baño varones', 'Instalación sanitaria', '2026-05-06'),
  ('Z17-087', 722, 'INST SANITARIA: Reemplazar tapa de hormigón quebrada de cámara pluvial en patio', 'Instalación sanitaria', '2026-05-04'),
  ('Z17-088', 720, 'INST. ELECTRICA: Reponer tubos de iluminación faltantes', 'Instalación eléctrica', '2026-05-14'),
  ('Z17-089', 746, 'INST SANITARIA: Desobstruir inodoros - Reparar pérdida en inodoro - Reparar sistema de descarga de mingitorios -', 'Instalación sanitaria', '2026-05-12'),
  ('Z17-091', 743, 'Inst sanitaria: Desobstruir 2 inodoros - Desobstruir piletas de patio de baños - Reparar grifería y conexiones de lavatorio. Herrería: Reparar rejilla de hierro - Fijar tapa ciega de cámara de limpieza pluvial', 'Instalación sanitaria', '2026-05-07'),
  ('Z17-092', 728, 'HERRERÍA: Reponer 6 sistemas de apertura antipánico en puertas exteriores', 'Herrería', '2026-05-11'),
  ('Z17-093', 718, 'INST ELECTRICA: Reparar iluminación en baño de docentes', 'Instalación eléctrica', '2026-06-01'),
  ('Z17-094', 740, 'ALBAÑILERÍA /HERRERÍA: Reponer picaportes y cerraduras faltantes', 'Herrería', '2026-06-02'),
  ('Z17-095', 728, 'Instalación de Gas: Reparación de pérdida en calefactor aula 9', 'Instalación de gas', '2026-06-02'),
  ('Z17-096', 728, 'CARPINTERÍA: Reemplazo de puertas de frente y marcos de muebles bajo mesada en dos antebaños d sector de aulas', 'Herrería', '2026-06-03'),
  ('Z17-097', 750, 'Inst. Eléctrica : Provisión de circuito independiente para horno de Aula Taller', 'Instalación eléctrica', '2026-06-03'),
  ('Z17-098', 750, 'Inst. Sanitaria: Desobstruir inodoros - Regular válvula de descarga de inodoro', 'Instalación sanitaria', '2026-06-03'),
  ('Z17-099', 722, 'INST SANITARIA: Desobstruir inodoros', 'Instalación sanitaria', '2026-06-04'),
  ('Z17-100', 732, 'ALBAÑILERÍA: Ejecutar vereda perimetral faltante y, demoler y reconstruir vereda perimetral en sectores deteriorados . Todo en sector exterior sobre cal le Laguna Larga - Se ejecutará de hormigón peinado - Demoler y reconstruir parcialmente solado de hormigón en sector de cámara séptica en desuso y con aentamiento de suelo - Extraer suelo saturado , rel lenar y compactar', 'Albañilería', '2026-06-05'),
  ('Z17-101', 728, 'INSTALACIÓN DE GAS: Revisar la totalidad de los calefactores del establecimiento, verificando su estado y correcto funcionamiento. Realizar tareas de mantenimiento, limpieza, encendido y puesta en funcionamiento de los equipos existentes. En caso de detectar artefactos fuera de servicio o instalaciones y/o cañerías en mal estado, coordinar con Inspección la autorización correspondiente
para su reparación o reposición. Presentar planilla de relevamiento de artefactos intervenidos, firmada por gasista matriculado/a.', 'Instalación de gas', '2026-06-05'),
  ('Z17-102', 720, 'CUBIERTA : Reparar y limpiar canaletas, reparar uniones y soportes de canaletas', 'Cubierta de techos', '2026-06-05'),
  ('Z17-103', 717, 'INST. SANITARIA: desobstruir 4 inodoros', 'Instalación sanitaria', '2026-06-05'),
  ('Z17-104', 731, 'Instalación Sanitaria: Debido a las necesidades especiales de un alumno es necesario elevar la altura del inodoro para discapacitados- 1)
Colocar suplemento especial en la base del inodoro - 2) Proveer y colocar barral "L" de apoyo fijo con tres puntos de fijación- 3) Reparar mochila
de descarga de inodoro - 4) Reponer tapa ciega en boca de acceso', 'Instalación sanitaria', '2026-07-08'),
  ('Z17-105', 740, 'ALBAÑILERÍA/ HERRERÍA: A - Ejecutar solado de Hormigón en ingreso vehicular. B - Fabricar y colocar cerco metálico entre patios internos con portón vehicular - Se compondrá de estructura de caño cuadrado estructural y paños de
malla electrosoldada. C - Fabricar y colocar baranda de seguridad sobre cordón de vereda en ingreso principal. INSTALACIÓN ELÉCTRICA: Reconectar 2 líneas de toma a tierra existentes', 'Albañilería', '2026-06-08'),
  ('Z17-106', 715, 'CUBIERTA: Colocar membrana asfáltica con geotexti l en techos planos. INST. SANITARIA: Reemplazar cañerías antiguas de bajadas de tanque que atraviezan la losa. Se cambiaran los recorridos a sectores perimetrales a los
fines de l iberar superficie de losa para posibi l itar continuidad de impermeabi l izaciòn.', 'Cubierta de techos', '2026-06-08'),
  ('Z17-107', 727, 'Albañílería : Reparar revoques y cielorrasos deteriorados en salas de 4 y 5 años - Pintar salas de 4 y 5 años y hall de ingreso', 'Albañilería', '2026-06-09'),
  ('Z17-108', 724, 'ALBAÑILERÍA/HERRERÍA: Agregar 2 caños de diametro idem al existente a todo el perímetro de balcón en planta alta . Los distintos tramos de esta
baranda alta se fijarán a las columnas que definen estos tramos mediante planchuelas amuradas con brocas para hormigón, como así también al
parapeto de hormigón mediante planchuelas fijadas al mismo con barillas roscadas pasantes. Estas planchuellas fijadas al parapeto se continuarán
verticalmente a manera de parantes intermedios a los efectos de sostén y rigidización de cada tramo . Se pintara con esmalte sintético de triple efecto', 'Albañilería', '2026-06-26'),
  ('Z17-109', 732, 'ALBAÑILERÍA/PINTURA: Se pintarán los paramentos verticales de 4 aulas de ala antigua sobre calle Laguna Larga y los baños de esta misma ala', 'Albañilería', '2026-06-09'),
  ('Z17-110', 743, 'Inst Eléctrica: Asistir al establecimiento por falta de suministro eléctrico', 'Instalación eléctrica', '2026-06-09'),
  ('Z17-111', 726, 'INSTALACIÓN DE GAS: Revisar la totalidad de los calefactores del establecimiento, verificando su estado y correcto funcionamiento. Realizar tareas de mantenimiento, limpieza, encendido y puesta en funcionamiento de los equipos existentes. En caso de detectar artefactos fuera de servicio o instalaciones y/o cañerías en mal estado, coordinar con Inspección la autorización correspondiente
para su reparación o reposición. Presentar planilla de relevamiento de artefactos intervenidos, firmada por gasista matriculado/a.', 'Instalación de gas', '2026-06-10'),
  ('Z17-112', 726, 'Inst sanitaria: Verificar estado general de la instalación por posible emanación de gases cloacles. Verificar sifones y sellado de artefactos.
Desobstruir inodoro baño de alumnos', 'Instalación sanitaria', '2026-06-10'),
  ('Z17-114', 732, 'ALBAÑILERÍA/ CARPINTERÍA: Verificar asentamiento de suelo en espacio verde . Rellenar y compactar - Recolocar puerta de box de inodoro en batería
de baños nueva. Reponer bisagra faltante. INSTALACIÓN SANITARIA: Desagotar cámara séptica y pozo absorbente de bateria de baños antigua - Desagotar cámara séptica de 1000 lts en desuso para su anulación y relleno', 'Instalación sanitaria', '2026-06-11'),
  ('Z17-116', 748, 'INST. SANITARIA: Reemplazar grifería de pileta de cocina y de pilet{on lavamanos - reparar pérdida en termotanque - sellar bacha en mesada de cocina -
reparar accionamiento de descarga de 2 inodoros', 'Instalación sanitaria', '2025-06-11'),
  ('Z17-117', 738, 'INST SANITARIA: Reparar pérdida de agua en caño de canilla de patio en sector sala de música - Reemplazar tramo de caño bajo piso en sector sala de música', 'Instalación sanitaria', '2026-06-12'),
  ('Z17-118', 738, 'INST ELECTRICA: Reparación de instalación por cortocircuito que afecta dos salas y sector de circulación', 'Instalación eléctrica', '2026-06-12'),
  ('Z17-119', 739, 'ALBAÑILERÍA /HERRAJES: Reparar cerradura de puerta de ingreso', 'Herrería', '2026-06-12'),
  ('Z17-120', 744, 'Inst. Electrica: Reponer iluminación exterior', 'Instalación eléctrica', '2026-07-01'),
  ('Z17-121', 728, 'ALBAÑILERÍA: Pintar vallas metálicas perimetrales sector calle 27 de Abril y dos puertas de ductos sanitarios del mismo sector - Aplicar esmalte
sintético de triple acción', 'Albañilería', '2026-07-03'),
  ('Z17-122', 737, 'INST. SANITARIA: Reparar sistema descarga de inodoro baño de docentes- Reparar pérdida de fuelle - Fijar inodoro', 'Instalación sanitaria', '2026-07-08'),
  ('Z17-123', 715, 'ALBAÑILERÍA: Ejecutar pintura interior y exterior', 'Albañilería', '2026-07-17'),
  ('Z17-124', 725, 'Albañilería: Disminuir altura de mesada de lavamanos de alumnos (dosmontar y recolocar mesada) -Instalación sanitaria: Renovar desagues de lavamanos en baño de alumnos - Reemplazar PPA -', 'Instalación sanitaria', '2026-07-02'),
  ('Z17-125', 746, 'INST ELECTRICA: Provisión y colocación de 10 ventiladores industriales en SUM. HERRERÍA: fabricación y colocación de 10 protecciones metálicas para ventiladores', 'Instalación eléctrica', '2026-07-16'),
  ('Z17-126', 737, 'ALBAÑILERÍA: Extraer cielorrasos de chapa perforada en 10 aulas de planta alta - Colocar cielorraso desmontable ignífugo y
aislante térmico con perfilería vista. INSTALACIÓN ELÉCTRICA: Reemplazar artefactos de iluminacion existentes por plafones led cuadrados acordes al sistema de
modulación del nuevo cielorraso - Renovar conducciones y cableado para los nuevos artefactos', 'Albañilería', '2026-07-07'),
  ('Z17-127', 718, 'CUBIERTA: Extraer membrana existente - Impermeabilizar con membrana asfáltica con geotextil con teminación de pintura
elastomérica', 'Cubierta de techos', '2026-07-01'),
  ('Z17-128', 740, 'Instalación Sanitaria: Desobstruir inodoros y PPA en baños de alumnos. Ajustar canillas en baño de mujeres y reemplazar canillas en baño de varones.
Reponer tapa de válvula de descarga de inodoro. Reemplazar fuelles con pérdidas . En piletón-bebedero de patio reemplazar sopapa', 'Instalación sanitaria', '2026-07-02'),
  ('Z17-129', 729, 'Instalación Sanitaria: Reponer tapa de cámara de inspección en patio. Reponer tapas ciegas en baño docentes y sector comedor -
Anular y sellar tapa de PPA en desuso (sector nueva biblioteca). Albañilería / Herrería: Reparar reja de cámara pluvial en patio - Reparar cerradura, manijòn y asentar puerta de madera de ingreso', 'Instalación sanitaria', '2026-07-07'),
  ('Z17-130', 720, 'INSTALACIÓN SANITARIA: Reparar válvula de descarga de inodoro - Reemplazar flotante de tanque', 'Instalación sanitaria', '2026-07-08'),
  ('Z17-132', 731, 'Instalación Electrica: Balancear fases de instalación eléctrica', 'Instalación sanitaria', '2026-07-13'),
  ('Z17-133', 745, 'Instalación Electrica: Revisar /reparar instalación por falta de energía en un sector - Verificar funcionamiento / Reparar alimentación de equipo AA
frio-calor - Reemplazar lámpara y reflector de iluminación exterior en ingresos y sus fotocélulas -', 'Instalación eléctrica', '2026-07-14'),
  ('Z17-134', 745, 'Instalación Sanitaria: Desobstruir inodoro - Reemplazar canilla de pileton - Reparar mochilas de descarga de inodoros - Desobstruir PPA -', 'Instalación sanitaria', '2026-07-15'),
  ('Z17-135', 746, 'CUBIERTA : Impermeabilizar cubierta de techo en Sala de Educación Física (SUM) con membrana asfaltica geotextil con terminación de pintura
elastomérica. HERRERÍA : Restablecer correcto funcionamiento de puerta de baño sector norte. Corregir posición de bisagra. Reforzar soldadura de la misma', 'Cubierta de techos', '2026-07-17'),
  ('Z17-136', 744, 'INSTALACIÓN DE GAS: Revisar la totalidad de los calefactores del establecimiento, verificando su estado y correcto funcionamiento. Realizar tareas de mantenimiento, limpieza, encendido y puesta en funcionamiento de los equipos existentes. En caso de detectar artefactos fuera de servicio o instalaciones y/o cañerías en mal estado, coordinar con Inspección la autorización correspondiente
para su reparación o reposición. Presentar planilla de relevamiento de artefactos intervenidos, firmada por gasista matriculado/a.', 'Instalación de gas', '2026-07-02'),
  ('Z17-137', 744, 'Inst. Sanitaria: Reparar pérdidas en sistema de colector de bombas - Purgar cañerías - Verificar correcto funcionamiento en
todos los grupos sanitarios', 'Instalación sanitaria', '2026-07-03'),
  ('Z17-138', 747, 'Inst. Electrica: Reparar sistema de bomba - Verificar sistema eléctrico y presostato', 'Instalación eléctrica', '2026-07-13'),
  ('Z17-139', 750, 'Inst. Electrica: Verificar/ reparar instalación en sector de bomba y cisterna; y sector de quiosco por falta de energía', 'Instalación eléctrica', '2026-07-14'),
  ('Z17-140', 715, 'CUBIERTA: Reemplazar canaleta de chapa sector ingreso', 'Cubierta de techos', '2026-07-16'),
  ('Z17-141', 742, 'Instalación Sanitaria: Desobstruir inodoro - Desobstruir PPA y descarga de bachas - Reparar mochilas y fuelles - Reponer rejillas pluviales en patio', 'Instalación sanitaria', '2026-07-15'),
  ('Z17-142', 716, 'INSTLACIÓN SANITARIA: Instalar cañería de agua caliente en tres piletones de salas, pileta de cocina y lavatorio de baño de docentes. ALBAÑILERÍA: Reparar revoques y revestimientos afectados por instalación de agua ejecutada', 'Instalación sanitaria', '2026-07-01');

do $$
declare
  v_total integer;
begin
  select count(*) into v_total from dgie_carga_os_zona17;
  if v_total <> 105 then
    raise exception 'Carga Zona 17 incompleta: se esperaban 105 filas y hay %', v_total;
  end if;

  if exists (
    select 1
      from dgie_carga_os_zona17 carga
      left join public.establecimientos establecimiento
        on establecimiento.id = carga.establecimiento_id
       and establecimiento.zona = 17
     where establecimiento.id is null
  ) then
    raise exception 'Hay órdenes asociadas a establecimientos inexistentes o ajenos a Zona 17';
  end if;

  if exists (
    select 1
      from dgie_carga_os_zona17
     where numero !~ '^Z17-[0-9]{3}$'
        or substring(numero from '[0-9]{3}$')::integer between 220 and 358
  ) then
    raise exception 'La numeración contiene valores inválidos o pertenecientes al lote Z17-220 a Z17-358';
  end if;
end $$;

with insertadas as (
  insert into public.ordenes_servicio
    (id, numero, establecimiento_id, zona, tarea, rubro, estado, prioridad,
     fecha_envio, reclamo_numero, monto, presupuesto, empresa_finalizo)
  select
    gen_random_uuid(), carga.numero, carga.establecimiento_id, 17,
    carga.tarea, carga.rubro, 'finalizado', 'medio', carga.fecha_envio,
    null, '—', '[]'::jsonb, false
    from dgie_carga_os_zona17 carga
   where not exists (
     select 1
       from public.ordenes_servicio existente
      where existente.zona = 17
        and existente.numero = carga.numero
   )
  returning numero
)
select count(*) as ordenes_insertadas_en_esta_ejecucion from insertadas;

-- Verificación: deben existir las 105 y no debe haber duplicados en sus números.
select
  count(*) as ordenes_del_lote_presentes,
  count(distinct orden.numero) as numeros_unicos,
  105 - count(distinct orden.numero) as ordenes_faltantes
from public.ordenes_servicio orden
join dgie_carga_os_zona17 carga
  on carga.numero = orden.numero
 and orden.zona = 17;

select carga.numero, carga.establecimiento_id, carga.rubro, carga.fecha_envio
from dgie_carga_os_zona17 carga
left join public.ordenes_servicio orden
  on orden.zona = 17
 and orden.numero = carga.numero
where orden.id is null
order by carga.numero;

commit;
