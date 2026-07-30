-- Importacion de ordenes de servicio - Zona 14
-- Fuente: "Base de datos para APP (1).xlsx" (hoja Hoja1, 33 filas)
--
-- Datos tomados tal cual del Excel: numero de O.S., reclamo/s, establecimiento,
-- tarea, fecha de envio y estado (finalizado / trabajando).
--
-- Supuestos, porque el Excel no informa esas columnas:
--   rubro                -> null (la columna RUBRO vino vacia en todas las filas)
--   prioridad            -> medio
--   fecha_finalizacion   -> null
--   monto / presupuesto  -> null / []
--
-- El script es reejecutable: no vuelve a insertar un numero de O.S. existente.
-- No usa tablas temporales, para que funcione en el editor SQL de Supabase.

with import_os (
  numero,
  reclamo_numero,
  establecimiento_id,
  tarea,
  estado,
  fecha_envio
) as (
values
  (
    'Z14-128',
    '2026010858',
    595,
    'Arreglo de un fuelle de mingitorio. + cambio de fuelle en mingitorio',
    'finalizado',
    date '2026-07-30'
  ),
  (
    'Z14-129',
    '2026012927',
    605,
    'Reposición de vidrios rotos en aulas. Retirar los paños dañados, verificar el estado de los marcos y colocar nuevos vidrios de iguales características a los existentes, asegurando su correcta fijación y sellado, dejando el sector en condiciones seguras para su uso.',
    'finalizado',
    date '2026-07-30'
  ),
  (
    'Z14-130',
    '2026013948',
    617,
    'Acudir al establecimiento para reparar la pérdida en el fuelle del inodoro del baño de docentes. Asimismo, reponer la tecla de accionamiento del depósito del baño para personas con discapacidad, dejando ambos artefactos en correcto funcionamiento. Finalmente, realizar una revisión integral del núcleo sanitario, verificando el estado y funcionamiento de las instalaciones sanitarias, detectando y corrigiendo posibles pérdidas o anomalías que afecten su normal uso.',
    'finalizado',
    date '2026-07-30'
  ),
  (
    'Z14-131',
    '2026013988',
    610,
    'Se deberá ejecutar un alambrado perimetral exterior de aproximadamente 15,00 metros lineales, conforme a las indicaciones de la Inspección.
Los trabajos comprenderán la provisión de la totalidad de los materiales, mano de obra, herramientas y equipos necesarios para la correcta ejecución de la tarea, incluyendo, entre otros:
Replanteo del sector de intervención.
Excavación de pozos para la colocación de postes.
Provisión y colocación de postes de hormigón armado, terminales e intermedios, con sus respectivos puntales y accesorios.
Ejecución de bases de hormigón para el empotramiento de los postes.
Provisión, colocación y tensado de tejido romboidal galvanizado, alambres tensores y alambre de púas superior, conforme a las especificaciones técnicas.
Alineación, aplomado y tensado del cerramiento, garantizando su correcta estabilidad y terminación.
Limpieza del sector de trabajo y retiro de la totalidad de los materiales sobrantes y residuos generados.
La contratista deberá garantizar que el cerramiento quede correctamente ejecutado, firme, nivelado y tensado, cumpliendo con las reglas del buen arte y las indicaciones impartidas por la Inspección, quedando a su cargo la reposición o corrección de cualquier deficiencia que pudiera detectarse durante la ejecución o al momento de la recepción de los trabajos.',
    'trabajando',
    date '2026-07-30'
  ),
  (
    'Z14-132',
    '2026014107',
    590,
    'Colocación de puerta en el baño de alumnos, reponiendo y fijando correctamente el marco, el cual se desprendió. Asimismo, intervenir el resto de las puertas de los baños de alumnos, realizando un corte inferior de aproximadamente 10 a 15 cm para eliminar el sector deteriorado por corrosión, reacondicionando los cantos tratados y verificando el correcto funcionamiento de cada hoja, a fin de prolongar su vida útil y garantizar su adecuada utilización.',
    'finalizado',
    date '2026-07-30'
  ),
  (
    'Z14-133',
    null,
    619,
    'Relevamiento electrico- informe de la situacion de la instalacion electrica +reacondicionamiento de la instalacion electrica para 3 aires acondicionados.',
    'finalizado',
    date '2026-07-30'
  ),
  (
    'Z14-134',
    '2026014400',
    622,
    'ARREGLO EN NÚCLEO SANITARIO: Reponer el inodoro deteriorado del baño y reparar la cámara sanitaria existente, dejando el sistema en correcto funcionamiento. Una vez finalizada dicha intervención, reacondicionar el sector de ingreso al núcleo sanitario (sector de bachas), ejecutando el reemplazo de los revestimientos cerámicos deteriorados, la colocación de nuevas canillas y la pintura de paredes y cielorrasos con látex color blanco, dejando el ambiente en óptimas condiciones de uso y terminación.',
    'finalizado',
    date '2026-07-30'
  ),
  (
    'Z14-135',
    null,
    596,
    'NOTA OS PREPARACION DE SUPERFICIE Acudir a la institución y realizar preparación integral de superficies en los sectores afectados.
Proceder a la demolición y retiro de todo revoque suelto, flojo y/o en mal estado, tanto en muros interiores como exteriores, dejando la superficie firme y apta para su posterior reparación.
Ejecutar nuevamente los trabajos de revoque según corresponda:
Exterior: realizar revoque impermeable.
Interior: realizar revoque con terminación fina.
Dejar todas las superficies reparadas, niveladas y en condiciones adecuadas para posteriores trabajos de pintura a realizar por cooperativa.
Todo trabajo deberá ejecutarse garantizando correcta adherencia, terminaciones y limpieza final del sector intervenido.',
    'finalizado',
    date '2026-07-30'
  ),
  (
    'Z14-136',
    null,
    619,
    'AJUSTE SANITARIO',
    'finalizado',
    date '2026-07-30'
  ),
  (
    'Z14-137',
    null,
    607,
    'Amurar nuevamente la barrera de contención, restituyendo su correcta fijación mediante los anclajes y elementos de sujeción necesarios. Verificar la estabilidad de la estructura y realizar los ajustes correspondientes, dejándola firme, segura',
    'finalizado',
    date '2026-07-30'
  ),
  (
    'Z14-138',
    '2026015090 - 202615333',
    596,
    'Reposicion de luces exteriores (sobre calle cabo alfredo alejandro) y en el sector del patio',
    'finalizado',
    date '2026-07-30'
  ),
  (
    'Z14-139',
    '2026015106 - 2026015156',
    619,
    'Tapa de cemento rota + cañeria del bebedoro en planta baja',
    'finalizado',
    date '2026-07-30'
  ),
  (
    'Z14-140',
    null,
    596,
    'Prueba de hermeticidad en cañería de gas.',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-141',
    null,
    595,
    'RELEVAMIENTO ELECTRICO DESPUES DE EPEC',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-142',
    null,
    598,
    'RELEVAMIENTO ELECTRICO DESPUES DE EPEC',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-143',
    null,
    607,
    'RELEVAMIENTO ELECTRICO DESPUES DE EPEC',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-144',
    null,
    615,
    'RELEVAMIENTO ELECTRICO DESPUES DE EPEC',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-145',
    null,
    617,
    'RELEVAMIENTO ELECTRICO DESPUES DE EPEC',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-146',
    '2026015555',
    615,
    'Pérdida de agua por el flexible y pérdida de agua por la canilla de la pileta del baño nuevo de varones. + prueba de hermeticidad en cañería de gas.',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-147',
    '2026015719 - 2026015720',
    623,
    'ver hundimientos en patio e ingreso de agua + mampostería de una de las puertas del patio',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-148',
    '2026015368 - 2026015722',
    606,
    'Reitera nuevamente el reclamo - Limpieza de desague + Tapa desbordada por calle Cacheuta + EMERGENCIA 02/07 por policarbonatos rotos.',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-149',
    '2026015801',
    597,
    'Rotura de grifería de lavatorios salas de 3 y 4 años. Inundaciones en la galería *Perdida de agua de inodoros salas 4 y 5 años.',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-150',
    '2026015803',
    597,
    'Desprendimiento cielo raso. Humedad y hongos depósito y biblioteca. cerramiento arenero. Retiro de ramas secas caída en el mes de Febrero. raíces elevadas. Losetas levantadas, rampas de ingreso al Jardín y a las salas',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-151',
    '2026015929',
    605,
    'Está tapado el desagüe baño docentes se llena de agua',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-152',
    '2026015959 - 2026015960',
    596,
    'Están tapados dos baños de nenas y un inodoro se salió de su lugar + poste que sostiene el alambrado perimetral está suelto con peligro de caerse, y parte del alambrado está roto con huecos donde ingresan personas en horas de la noche',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-153',
    '2026015962',
    620,
    'Desborde de resumidero en sala de tecnología. + falla iluminación en laboratorio',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-154',
    '2026016000',
    607,
    'EMERGENCIA: NO funciona la bomba',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-155',
    null,
    595,
    'REPARACION DE CIELORRASO EN EL SECTOR SUM',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-156',
    '2026016099',
    607,
    'quisiera realizar el reclamo de un pizarrón que está por caerse',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-157',
    '2026016110',
    596,
    'no Cargan agua mochilas de los inodoros de sala de maestro y auxiliares.',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-158',
    '2026016123',
    605,
    'Baños de nenas tapados. Sale de las rejillas del piso',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-159',
    '2026016125',
    622,
    'Se inunda secretaría por el baño roto, es de suma urgencia la rotura',
    'finalizado',
    date '2026-07-31'
  ),
  (
    'Z14-160',
    '2026016151',
    614,
    'Emergencia, sin suministro electrico.',
    'finalizado',
    date '2026-07-31'
  )
)

insert into public.ordenes_servicio (
  numero,
  reclamo_numero,
  establecimiento_id,
  zona,
  rubro,
  tarea,
  prioridad,
  estado,
  fecha_envio,
  fecha_finalizacion,
  monto,
  presupuesto
)
select
  i.numero,
  i.reclamo_numero,
  i.establecimiento_id,
  14,
  null,
  i.tarea,
  'medio',
  i.estado,
  i.fecha_envio,
  null,
  null,
  '[]'::jsonb
from import_os i
join public.establecimientos e
  on e.id = i.establecimiento_id
 and e.zona = 14
where not exists (
  select 1
  from public.ordenes_servicio existente
  where upper(trim(existente.numero)) = upper(trim(i.numero))
)
order by i.numero;

-- Resultado esperado luego de la primera ejecucion: 33 filas.
select
  os.numero,
  os.reclamo_numero,
  e.nombre as establecimiento,
  os.estado,
  os.fecha_envio,
  left(os.tarea, 60) as tarea
from public.ordenes_servicio os
join public.establecimientos e on e.id = os.establecimiento_id
where os.numero = any (array[
    'Z14-128', 'Z14-129', 'Z14-130', 'Z14-131', 'Z14-132', 'Z14-133',
    'Z14-134', 'Z14-135', 'Z14-136', 'Z14-137', 'Z14-138', 'Z14-139',
    'Z14-140', 'Z14-141', 'Z14-142', 'Z14-143', 'Z14-144', 'Z14-145',
    'Z14-146', 'Z14-147', 'Z14-148', 'Z14-149', 'Z14-150', 'Z14-151',
    'Z14-152', 'Z14-153', 'Z14-154', 'Z14-155', 'Z14-156', 'Z14-157',
    'Z14-158', 'Z14-159', 'Z14-160'
])
order by os.numero;
