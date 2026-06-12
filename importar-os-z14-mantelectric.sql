-- Importacion de ordenes de servicio historicas
-- Fuente: "Base de datos para APP Z14 - MANTELECTRIC.xlsx"
--
-- Supuestos tomados porque el Excel no informa dia ni estado:
--   MARZO -> 2026-03-01
--   ABRIL -> 2026-04-01
--   Estado -> finalizado
--   Prioridad -> medio
--
-- El script es reejecutable: no vuelve a insertar un numero de O.S. existente.
-- No utiliza tablas temporales, para que funcione correctamente en el editor de Supabase.

with import_os (
  numero,
  reclamo_numero,
  establecimiento_id,
  tarea,
  rubro,
  fecha_envio
) as (
values
  (
    'Z14-001',
    null,
    605,
    'Impermeabilizacion en cubierta del sector de pasillo',
    'Cubierta',
    date '2026-03-01'
  ),
  (
    'Z14-002',
    null,
    596,
    'Impermeabilizacion de la cubierta (sector este)',
    'Cubierta',
    date '2026-03-01'
  ),
  (
    'Z14-003',
    null,
    598,
    'Toma de junta en ultima aula del primer piso',
    'Albañilería',
    date '2026-04-01'
  ),
  (
    'Z14-004',
    '2026011136 - 2026011307 - 2026011560 - 2026011809',
    606,
    'Baño de primer ciclo: desague tapado, conector del mingitorio, mochila sanitaria en mal estado, colocacion de marco en baño de docentes y colocacion de un vidrio en aula',
    'Sanitarios',
    date '2026-04-01'
  ),
  (
    'Z14-005',
    '2026011184 - 2026011233 - 2026011521',
    605,
    'Limpieza de mochilas por poca presion de agua',
    'Sanitarios',
    date '2026-04-01'
  ),
  (
    'Z14-006',
    '2026011774',
    597,
    'Arreglo en las mochilas de dos baños de sala de 4 años',
    'Sanitarios',
    date '2026-04-01'
  ),
  (
    'Z14-007',
    '2026011930',
    604,
    'Baño de sala de profesores: perdida de agua del fuelle',
    'Sanitarios',
    date '2026-04-01'
  ),
  (
    'Z14-008',
    null,
    611,
    'Emergencia: colocar tapon en una canilla del baño de varones, colocar canillas y llave en baños de varones, y arreglar tecla en baño de personas con discapacidad',
    'Sanitarios',
    date '2026-04-01'
  ),
  (
    'Z14-009',
    null,
    621,
    'Ajuste en sanitarios: colocacion de cadena en deposito de mochila del baño de mujeres y flotante',
    'Sanitarios',
    date '2026-04-01'
  ),
  (
    'Z14-010',
    null,
    604,
    'Arreglo de caño pluvial subsuelo 25-26',
    'Sanitarios',
    date '2026-04-01'
  ),
  (
    'Z14-011',
    null,
    614,
    'Arreglo del sistema de mochila de baño',
    'Sanitarios',
    date '2026-04-01'
  ),
  (
    'Z14-012',
    null,
    591,
    'Colocacion de tres pizarrones',
    'Albañilería',
    date '2026-04-01'
  ),
  (
    'Z14-013',
    '2026012442',
    602,
    'Desagote en camara de PAICOR',
    'Sanitarios',
    date '2026-04-01'
  ),
  (
    'Z14-014',
    null,
    596,
    'Reparacion, colocacion de bomba inteligente y colocacion de tapa de tanque atornillada',
    'Sanitarios',
    date '2026-04-01'
  ),
  (
    'Z14-015',
    null,
    604,
    'Colocacion de tapa de hormigon en camara de inspeccion',
    'Albañilería',
    date '2026-04-01'
  ),
  (
    'Z14-016',
    null,
    596,
    'Limpieza de escombros',
    'Albañilería',
    date '2026-04-01'
  ),
  (
    'Z14-019',
    '2026012943',
    599,
    'Emergencia: verificar desbordes cloacales en el sector del comedor',
    'Sanitarios',
    date '2026-04-01'
  ),
  (
    'Z14-020',
    '2026013009',
    605,
    'Emergencia: arreglo de luminaria en el baño docente',
    'Electricidad',
    date '2026-04-01'
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
  i.rubro,
  i.tarea,
  'medio',
  'finalizado',
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

-- Resultado esperado luego de la primera ejecucion: 18 filas.
select
  os.numero,
  os.reclamo_numero,
  e.nombre as establecimiento,
  os.rubro,
  os.tarea,
  os.fecha_envio,
  os.estado
from public.ordenes_servicio os
join public.establecimientos e on e.id = os.establecimiento_id
where os.numero = any (array[
  'Z14-001', 'Z14-002', 'Z14-003', 'Z14-004', 'Z14-005', 'Z14-006',
  'Z14-007', 'Z14-008', 'Z14-009', 'Z14-010', 'Z14-011', 'Z14-012',
  'Z14-013', 'Z14-014', 'Z14-015', 'Z14-016', 'Z14-019', 'Z14-020'
])
order by os.numero;
