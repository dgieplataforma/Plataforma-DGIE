-- Carga inicial de certificados historicos - ZONA 10
-- Origen: carpeta del usuario 'CERTIFICADOS PLATAFORMA - ZONA 10' (Escritorio),
--   mediciones 1 a 5 (38 + 14 + 26 + 10 + 31 = 119 certificados, un archivo .xlsx por fila)
--   + PLANTILLA_CARGA_INICIAL_CERTIFICADOS.xlsx (hoja 'Mediciones', 119 filas).
-- Verificado contra produccion el 2026-09-10:
--   * 119 archivos <-> 119 filas de la planilla, 1:1.
--   * 36 establecimientos, todos resueltos a ids reales de zona 10 (417-452, incl. 451 J.DE INF. REGINO MADERS).
--   * 136 numeros de O.S. referenciados; 134 ya existen como Z10-XXX en ordenes_servicio.
--     Faltan solo Z10-101 y Z10-357 (esos dos certificados quedan ligados a su O.S. hermana).
--   * 23 certificados con O.S. compuesta (marcador multiple, p. ej. 50-51, 278-292-357).
--   * Modulos: se cargan los de la planilla en modulos_original y modulos_inspector.
--     El usuario los ajusta a mano en la liquidacion (siempre hay diferencia, es normal).
--
-- estado = 'medido' y revision_admin_estado = 'aprobado': son certificados historicos ya
--   medidos y firmados. NO entran al circuito de Administracion ni a pendientes/observados/devueltos.
--
-- NO sube los .xlsx ni los PDF de medicion firmada: carga solo metadatos (url_original = '').
--
-- Idempotente: una segunda corrida no duplica (se saltea si ya existe un certificado con
--   misma zona + medicion_numero + establecimiento_id + archivo_original).
-- Una sola sentencia INSERT (atomica). No usa tablas temporales, no usa DROP,
--   no toca ordenes_servicio ni datos previos. Apto para el editor SQL que corre statement por statement.

insert into public.certificados_medicion (
  zona, medicion_numero, establecimiento_id, establecimiento_nombre,
  archivo_original, url_original, modulos_original, monto_empresa,
  rubro_certificado, rubros_certificado,
  ordenes_servicio_certificado, observaciones_inspector,
  modulos_inspector, estado, revision_admin_estado,
  creado_por, actualizado_por
)
select
  10,
  d.medicion_numero,
  d.establecimiento_id,
  coalesce((select e.nombre from public.establecimientos e where e.id = d.establecimiento_id), ''),
  d.archivo_original,
  '',
  d.modulos_original,
  d.modulos_original,
  d.rubro_certificado,
  d.rubros_certificado,
  d.ordenes_servicio_certificado,
  d.observaciones_inspector,
  d.modulos_inspector,
  'medido',
  'aprobado',
  d.creado_por,
  d.actualizado_por
from (values
  (1, 417, '01- IPEM Nº 207 - EDUARDO RAUL REQUENA - SANIT 3.xlsx', 11.81, 'Instalacion sanitaria', 'SAN', '14', E'[OS_CERT:14]\n[RUBROS_CERT:SAN]', 11.81, 'Carga inicial', 'Carga inicial'),
  (1, 420, '04- J. DE INFANTES LIBERTADOR SAN MARTIN - PODA.xlsx', 9.6, 'Albanileria', 'ALB', '49', E'[OS_CERT:49]\n[RUBROS_CERT:ALB]', 9.6, 'Carga inicial', 'Carga inicial'),
  (1, 423, '07- IPEM Nº 176 - GRANADERO JOSE MARQUEZ - SANIT 5.xlsx', 2.07, 'Instalacion sanitaria', 'SAN', '75', E'[OS_CERT:75]\n[RUBROS_CERT:SAN]', 2.07, 'Carga inicial', 'Carga inicial'),
  (1, 424, '08- ESCUELA CONSTANCIO VIGIL - SANIT 12 POL CARP.xlsx', 24.42, 'Albanileria', 'ALB-SAN', '50-51', E'[OS_CERT:50-51]\n[RUBROS_CERT:ALB-SAN]', 24.42, 'Carga inicial', 'Carga inicial'),
  (1, 425, '09- ESCUELA JUAN XXIII - BOMBA 2.xlsx', 2.32, 'Instalacion electrica', 'ELEC', '76', E'[OS_CERT:76]\n[RUBROS_CERT:ELEC]', 2.32, 'Carga inicial', 'Carga inicial'),
  (1, 425, '09- ESCUELA JUAN XXIII - SANIT 5.xlsx', 5.5, 'Instalacion sanitaria', 'SAN', '41', E'[OS_CERT:41]\n[RUBROS_CERT:SAN]', 5.5, 'Carga inicial', 'Carga inicial'),
  (1, 426, '010- J. DE INFANTES JUAN XXIII - SANIT 2.xlsx', 5.33, 'Instalacion sanitaria', 'SAN', '52', E'[OS_CERT:52]\n[RUBROS_CERT:SAN]', 5.33, 'Carga inicial', 'Carga inicial'),
  (1, 427, '011- IPEM Nº 167 - JOSE MANUEL ESTRADA - ELECT 3.xlsx', 4.73, 'Instalacion electrica', 'ELEC', '44', E'[OS_CERT:44]\n[RUBROS_CERT:ELEC]', 4.73, 'Carga inicial', 'Carga inicial'),
  (1, 430, '012- ESCUELA José hernandez - SANIT 6.xlsx', 6.68, 'Albanileria', 'ALB-SAN', '2', E'[OS_CERT:2]\n[RUBROS_CERT:ALB-SAN]', 6.68, 'Carga inicial', 'Carga inicial'),
  (1, 428, '012- ESCUELA PEDRO GOYENA - CARP 4 POL 3 SANIT.xlsx', 11.86, 'Instalacion electrica', 'ELEC-ALB', '89-90', E'[OS_CERT:89-90]\n[RUBROS_CERT:ELEC-ALB]', 11.86, 'Carga inicial', 'Carga inicial'),
  (1, 429, '012- ESCUELA PEDRO GOYENA - ELECT 4 CARP.xlsx', 1.74, 'Instalacion electrica', 'ELEC', '53', E'[OS_CERT:53]\n[RUBROS_CERT:ELEC]', 1.74, 'Carga inicial', 'Carga inicial'),
  (1, 429, '013- JARDIN DE I. MERCEDES DE SAN MARTIN - ELECT 3.xlsx', 2.18, 'Instalacion sanitaria', 'SAN', '78', E'[OS_CERT:78]\n[RUBROS_CERT:SAN]', 2.18, 'Carga inicial', 'Carga inicial'),
  (1, 430, '014- ESCUELA JOSE HERNANDEZ - SANIT 4.xlsx', 10.56, 'Instalacion sanitaria', 'SAN', '77', E'[OS_CERT:77]\n[RUBROS_CERT:SAN]', 10.56, 'Carga inicial', 'Carga inicial'),
  (1, 431, '015- ESCUELA HILARIO ASCASUBI - SANIT 4.xlsx', 12.53, 'Instalacion electrica', 'ELEC-SAN', '54-55', E'[OS_CERT:54-55]\n[RUBROS_CERT:ELEC-SAN]', 12.53, 'Carga inicial', 'Carga inicial'),
  (1, 436, '020- ESCUELA BARTOLOME HIDALGO - CARP.xlsx', 2.85, 'Albanileria', 'ALB', '79', E'[OS_CERT:79]\n[RUBROS_CERT:ALB]', 2.85, 'Carga inicial', 'Carga inicial'),
  (1, 436, '020- ESCUELA BARTOLOME HIDALGO - ELECT 3 POL CARP.xlsx', 20.13, 'Instalacion electrica', 'ELEC-ALB', '43-43A', E'[OS_CERT:43-43A]\n[RUBROS_CERT:ELEC-ALB]', 20.13, 'Carga inicial', 'Carga inicial'),
  (1, 437, '021- ESCUELA RUBEN DARIO - CARP 3 POL2.xlsx', 12.27, 'Albanileria', 'ALB', '80', E'[OS_CERT:80]\n[RUBROS_CERT:ALB]', 12.27, 'Carga inicial', 'Carga inicial'),
  (1, 437, '021- ESCUELA RUBEN DARIO - SANIT 5 ELECT POL.xlsx', 2.27, 'Instalacion electrica', 'ELEC-ALB-SAN', '83-84', E'[OS_CERT:83-84]\n[RUBROS_CERT:ELEC-ALB-SAN]', 2.27, 'Carga inicial', 'Carga inicial'),
  (1, 438, '022- JARDIN DE I. HILARIO ASCASUBI - PODA.xlsx', 12.7, 'Albanileria', 'ALB', '81', E'[OS_CERT:81]\n[RUBROS_CERT:ALB]', 12.7, 'Carga inicial', 'Carga inicial'),
  (1, 440, '024- JARDIN DE I. JUAN RAMON JIMENEZ - CARP 2.xlsx', 13.05, 'Albanileria', 'ALB', '45', E'[OS_CERT:45]\n[RUBROS_CERT:ALB]', 13.05, 'Carga inicial', 'Carga inicial'),
  (1, 440, '024- JARDIN DE I. JUAN RAMON JIMENEZ - SANIT 4 ELECT.xlsx', 67.74, 'Instalacion electrica', 'ELEC-ALB-SAN', '278-292-357', E'[OS_CERT:278-292-357]\n[RUBROS_CERT:ELEC-ALB-SAN]', 67.74, 'Carga inicial', 'Carga inicial'),
  (1, 440, '024- JARDIN DE I. JUAN RAMON JIMENEZ - SANIT 5.xlsx', 4.51, 'Instalacion sanitaria', 'SAN', '85', E'[OS_CERT:85]\n[RUBROS_CERT:SAN]', 4.51, 'Carga inicial', 'Carga inicial'),
  (1, 442, '026- IPEM Nº13 - DR. PEDRO ESCUDERO - CARP.xlsx', 20.17, 'Instalacion electrica', 'ELEC-ALB', '46', E'[OS_CERT:46]\n[RUBROS_CERT:ELEC-ALB]', 20.17, 'Carga inicial', 'Carga inicial'),
  (1, 442, '026- IPEM Nº13 - DR. PEDRO ESCUDERO - ELECT 4 SANIT CARP.xlsx', 34.22, 'Instalacion electrica', 'ELEC-ALB-SAN', '86-87-88', E'[OS_CERT:86-87-88]\n[RUBROS_CERT:ELEC-ALB-SAN]', 34.22, 'Carga inicial', 'Carga inicial'),
  (1, 442, '026- IPEM Nº13 - DR. PEDRO ESCUDERO - SANIT 3.xlsx', 24.7, 'Instalacion sanitaria', 'SAN', '91', E'[OS_CERT:91]\n[RUBROS_CERT:SAN]', 24.7, 'Carga inicial', 'Carga inicial'),
  (1, 443, '027- IPEM Nº11 ALBERTO PIO COGNINI - CARP.xlsx', 24.17, 'Albanileria', 'ALB', '47', E'[OS_CERT:47]\n[RUBROS_CERT:ALB]', 24.17, 'Carga inicial', 'Carga inicial'),
  (1, 443, '027- IPEM Nº11 ALBERTO PIO COGNINI - CUB 3.xlsx', 6.45, 'Cubierta de techos', 'CUB', '92', E'[OS_CERT:92]\n[RUBROS_CERT:CUB]', 6.45, 'Carga inicial', 'Carga inicial'),
  (1, 445, '029- JARDIN DE I. MARIA EVA DUARTE - SANIT.xlsx', 6.55, 'Instalacion sanitaria', 'SAN', '93', E'[OS_CERT:93]\n[RUBROS_CERT:SAN]', 6.55, 'Carga inicial', 'Carga inicial'),
  (1, 446, '030- JARDIN DE I. MALVINAS ARGENTINAS - SANIT 5.xlsx', 4.7, 'Instalacion sanitaria', 'SAN', '94', E'[OS_CERT:94]\n[RUBROS_CERT:SAN]', 4.7, 'Carga inicial', 'Carga inicial'),
  (1, 446, '030- JARDIN DE I. MALVINAS ARGENTINAS - SANIT 6.xlsx', 7.18, 'Instalacion sanitaria', 'SAN', '95', E'[OS_CERT:95]\n[RUBROS_CERT:SAN]', 7.18, 'Carga inicial', 'Carga inicial'),
  (1, 447, '031- ESCUELA MARIA EVA DUARTE - SANIT 2.xlsx', 10.14, 'Instalacion electrica', 'ELEC-SAN', '95-96A', E'[OS_CERT:95-96A]\n[RUBROS_CERT:ELEC-SAN]', 10.14, 'Carga inicial', 'Carga inicial'),
  (1, 448, '032- ESCUELA HEROES DE MALVINAS - ELECT.xlsx', 4.82, 'Instalacion electrica', 'ELEC', '97', E'[OS_CERT:97]\n[RUBROS_CERT:ELEC]', 4.82, 'Carga inicial', 'Carga inicial'),
  (1, 448, '032- ESCUELA HEROES DE MALVINAS - SANIT 6.xlsx', 25.76, 'Instalacion sanitaria', 'SAN', '98', E'[OS_CERT:98]\n[RUBROS_CERT:SAN]', 25.76, 'Carga inicial', 'Carga inicial'),
  (1, 451, '035- JARDIN DE I.REGINO MADERS - SANIT 5.xlsx', 2.07, 'Instalacion sanitaria', 'SAN', '99', E'[OS_CERT:99]\n[RUBROS_CERT:SAN]', 2.07, 'Carga inicial', 'Carga inicial'),
  (1, 451, '035- JARDIN DE I.REGINO MADERS - SANIT 6.xlsx', 4.79, 'Instalacion sanitaria', 'SAN', '100', E'[OS_CERT:100]\n[RUBROS_CERT:SAN]', 4.79, 'Carga inicial', 'Carga inicial'),
  (1, 452, '036- IPEM Nº 312 - DALMASIO VELEZ SARFIELD - ALB.xlsx', 2.91, 'Albanileria', 'ALB', '20', E'[OS_CERT:20]\n[RUBROS_CERT:ALB]', 2.91, 'Carga inicial', 'Carga inicial'),
  (1, 452, '036- IPEM Nº 312 - DALMASIO VELEZ SARFIELD - SANIT 3.xlsx', 4.86, 'Instalacion sanitaria', 'SAN', '48', E'[OS_CERT:48]\n[RUBROS_CERT:SAN]', 4.86, 'Carga inicial', 'Carga inicial'),
  (1, 452, '036- IPEM Nº 312 - DALMASIO VELEZ SARFIELD - SANIT 4 ELECT 3.xlsx', 6.61, 'Instalacion electrica', 'ELEC-SAN', '101-102', E'[OS_CERT:101-102]\n[RUBROS_CERT:ELEC-SAN]', 6.61, 'Carga inicial', 'Carga inicial'),
  (2, 417, '01- IPEM Nº 207 - EDUARDO RAUL REQUENA - ELECT 4 CIELOR.xlsx', 105.39, 'Instalacion electrica', 'ELEC-ALB', '13-15', E'[OS_CERT:13-15]\n[RUBROS_CERT:ELEC-ALB]', 105.39, 'Carga inicial', 'Carga inicial'),
  (2, 418, '02- ESCUELA EJERCITO ARGENTINO - ELECT 4 HERR SANIT 6.xlsx', 142.45, 'Instalacion electrica', 'ELEC-ALB-SAN', '119-120', E'[OS_CERT:119-120]\n[RUBROS_CERT:ELEC-ALB-SAN]', 142.45, 'Carga inicial', 'Carga inicial'),
  (2, 419, '03- J. DE INFANTES EJERCITO ARGENTINO - VENT 1 SANIT 3.xlsx', 42.32, 'Instalacion electrica', 'ELEC-ALB-SAN', '121-122', E'[OS_CERT:121-122]\n[RUBROS_CERT:ELEC-ALB-SAN]', 42.32, 'Carga inicial', 'Carga inicial'),
  (2, 421, '05- IPET Nº77 - GOB. S. DEL CASTILLO - ELECT.xlsx', 6.4, 'Instalacion electrica', 'ELEC', '123', E'[OS_CERT:123]\n[RUBROS_CERT:ELEC]', 6.4, 'Carga inicial', 'Carga inicial'),
  (2, 421, '05- IPET Nº77 - GOB. S. DEL CASTILLO - SANIT 4.xlsx', 14.33, 'Instalacion sanitaria', 'SAN', '35', E'[OS_CERT:35]\n[RUBROS_CERT:SAN]', 14.33, 'Carga inicial', 'Carga inicial'),
  (2, 426, '010- J. DE INFANTES JUAN XXIII - CUB.xlsx', 211.17, 'Cubierta de techos', 'CUB-ALB', '120', E'[OS_CERT:120]\n[RUBROS_CERT:CUB-ALB]', 211.17, 'Carga inicial', 'Carga inicial'),
  (2, 427, '011- IPEM Nº 167 - JOSE MANUEL ESTRADA - SANIT 7 ELECT 4.xlsx', 2.45, 'Instalacion electrica', 'ELEC-SAN', '85-110', E'[OS_CERT:85-110]\n[RUBROS_CERT:ELEC-SAN]', 2.45, 'Carga inicial', 'Carga inicial'),
  (2, 432, '016- IPET Nº48 PRESIDENTE ROCA - BOMBA 2 SANIT 7 PODA.xlsx', 128.75, 'Instalacion electrica', 'ELEC-ALB-SAN', '8-36', E'[OS_CERT:8-36]\n[RUBROS_CERT:ELEC-ALB-SAN]', 128.75, 'Carga inicial', 'Carga inicial'),
  (2, 433, '017- JARDIN DE I. JOSE HERNANDEZ - AIRE ACOND.xlsx', 36.11, 'Instalacion electrica', 'ELEC', '132', E'[OS_CERT:132]\n[RUBROS_CERT:ELEC]', 36.11, 'Carga inicial', 'Carga inicial'),
  (2, 437, '021- ESCUELA RUBEN DARIO - CARP 4 POL 3 PLUV.xlsx', 38.81, 'Instalacion electrica', 'ELEC-ALB-SAN', '127-128-129', E'[OS_CERT:127-128-129]\n[RUBROS_CERT:ELEC-ALB-SAN]', 38.81, 'Carga inicial', 'Carga inicial'),
  (2, 441, '025- ESCUELA ING. REGINO MADERS - SANIT 5.xlsx', 4.72, 'Instalacion sanitaria', 'SAN', '60', E'[OS_CERT:60]\n[RUBROS_CERT:SAN]', 4.72, 'Carga inicial', 'Carga inicial'),
  (2, 443, '027- IPEM Nº11 ALBERTO PIO COGNINI - SANIT 3 POL 2.xlsx', 21.06, 'Albanileria', 'ALB-SAN', '125-126', E'[OS_CERT:125-126]\n[RUBROS_CERT:ALB-SAN]', 21.06, 'Carga inicial', 'Carga inicial'),
  (2, 448, '032- ESCUELA HEROES DE MALVINAS - CARP.xlsx', 15.23, 'Albanileria', 'ALB', '124', E'[OS_CERT:124]\n[RUBROS_CERT:ALB]', 15.23, 'Carga inicial', 'Carga inicial'),
  (2, 449, '033- ESCUELA USANDIVARAS - CARP 2 PLOM POL.xlsx', 110.45, 'Albanileria', 'ALB-SAN', '130-131', E'[OS_CERT:130-131]\n[RUBROS_CERT:ALB-SAN]', 110.45, 'Carga inicial', 'Carga inicial'),
  (3, 417, '01- IPEM Nº 207 - EDUARDO RAUL REQUENA - ELECT 5....xlsx', 9.74, 'Instalacion electrica', 'ELEC', '176', E'[OS_CERT:176]\n[RUBROS_CERT:ELEC]', 9.74, 'Carga inicial', 'Carga inicial'),
  (3, 417, '01- IPEM Nº 207 - EDUARDO RAUL REQUENA - ELECT 6 POL..xlsx', 70.71, 'Instalacion electrica', 'ELEC-ALB', '179-180', E'[OS_CERT:179-180]\n[RUBROS_CERT:ELEC-ALB]', 70.71, 'Carga inicial', 'Carga inicial'),
  (3, 418, '02- ESCUELA EJERCITO ARGENTINO - BOMBA.xlsx', 5.26, 'Instalacion electrica', 'ELEC-SAN', '149', E'[OS_CERT:149]\n[RUBROS_CERT:ELEC-SAN]', 5.26, 'Carga inicial', 'Carga inicial'),
  (3, 419, '03- J. DE INFANTES EJERCITO ARGENTINO - ELECT.xlsx', 5.1, 'Instalacion electrica', 'ELEC', '150', E'[OS_CERT:150]\n[RUBROS_CERT:ELEC]', 5.1, 'Carga inicial', 'Carga inicial'),
  (3, 421, '05- IPET Nº77 - GOB. S. DEL CASTILLO - ELECT 2 CUB..xlsx', 261.21, 'Cubierta de techos', 'CUB-ELEC-ALB', '123', E'[OS_CERT:123]\n[RUBROS_CERT:CUB-ELEC-ALB]', 261.21, 'Carga inicial', 'Carga inicial'),
  (3, 423, '07- IPEM Nº 176 - GRANADERO JOSE MARQUEZ - POL 3.xlsx', 16.94, 'Albanileria', 'ALB', '151', E'[OS_CERT:151]\n[RUBROS_CERT:ALB]', 16.94, 'Carga inicial', 'Carga inicial'),
  (3, 424, '08- ESCUELA CONSTANCIO VIGIL - SANIT 13.xlsx', 3.95, 'Instalacion sanitaria', 'SAN', '152', E'[OS_CERT:152]\n[RUBROS_CERT:SAN]', 3.95, 'Carga inicial', 'Carga inicial'),
  (3, 427, '011- IPEM Nº 167 - JOSE MANUEL ESTRADA - SANIT 8....xlsx', 11.29, 'Instalacion sanitaria', 'SAN', '140', E'[OS_CERT:140]\n[RUBROS_CERT:SAN]', 11.29, 'Carga inicial', 'Carga inicial'),
  (3, 428, '012- ESCUELA PEDRO GOYENA - SANIT 7.xlsx', 8.13, 'Instalacion sanitaria', 'SAN', '62', E'[OS_CERT:62]\n[RUBROS_CERT:SAN]', 8.13, 'Carga inicial', 'Carga inicial'),
  (3, 428, '012- ESCUELA PEDRO GOYENA - VENT.xlsx', 25.26, 'Instalacion electrica', 'ELEC', '63', E'[OS_CERT:63]\n[RUBROS_CERT:ELEC]', 25.26, 'Carga inicial', 'Carga inicial'),
  (3, 429, '013- JARDIN DE I. MERCEDES DE SAN MARTIN - SANIT 3.xlsx', 3.71, 'Instalacion sanitaria', 'SAN', '68', E'[OS_CERT:68]\n[RUBROS_CERT:SAN]', 3.71, 'Carga inicial', 'Carga inicial'),
  (3, 430, '014- ESCUELA JOSE HERNANDEZ - SANIT 5 BOMBA.xlsx', 5.48, 'Instalacion electrica', 'ELEC-SAN', '153', E'[OS_CERT:153]\n[RUBROS_CERT:ELEC-SAN]', 5.48, 'Carga inicial', 'Carga inicial'),
  (3, 437, '021- ESCUELA RUBEN DARIO - ELECT 4.xlsx', 16, 'Instalacion sanitaria', 'SAN', '155', E'[OS_CERT:155]\n[RUBROS_CERT:SAN]', 16, 'Carga inicial', 'Carga inicial'),
  (3, 437, '021- ESCUELA RUBEN DARIO - SANIT 6.xlsx', 1.2, 'Instalacion electrica', 'ELEC', '181', E'[OS_CERT:181]\n[RUBROS_CERT:ELEC]', 1.2, 'Carga inicial', 'Carga inicial'),
  (3, 440, '024- JARDIN DE I. JUAN RAMON JIMENEZ - ELECT 2..xlsx', 36.68, 'Instalacion electrica', 'ELEC', '165', E'[OS_CERT:165]\n[RUBROS_CERT:ELEC]', 36.68, 'Carga inicial', 'Carga inicial'),
  (3, 441, '025- ESCUELA ING. REGINO MADERS - ARBOL.xlsx', 7.4, 'Albanileria', 'ALB', '61', E'[OS_CERT:61]\n[RUBROS_CERT:ALB]', 7.4, 'Carga inicial', 'Carga inicial'),
  (3, 443, '027- IPEM Nº11 ALBERTO PIO COGNINI - POL 3.xlsx', 3.73, 'Albanileria', 'ALB', '154', E'[OS_CERT:154]\n[RUBROS_CERT:ALB]', 3.73, 'Carga inicial', 'Carga inicial'),
  (3, 444, '028- IPEM Nº 309 PROF. CARLOS FUENTEALBA - SANIT 5 BOMBA.xlsx', 6.42, 'Instalacion sanitaria', 'SAN', '66', E'[OS_CERT:66]\n[RUBROS_CERT:SAN]', 6.42, 'Carga inicial', 'Carga inicial'),
  (3, 444, '028- IPEM Nº 309 PROF. CARLOS FUENTEALBA - SANIT 6.xlsx', 4.18, 'Instalacion sanitaria', 'SAN', '106', E'[OS_CERT:106]\n[RUBROS_CERT:SAN]', 4.18, 'Carga inicial', 'Carga inicial'),
  (3, 445, '029- JARDIN DE I. MARIA EVA DUARTE - ELECT.xlsx', 9.66, 'Instalacion electrica', 'ELEC', '156', E'[OS_CERT:156]\n[RUBROS_CERT:ELEC]', 9.66, 'Carga inicial', 'Carga inicial'),
  (3, 447, '031- ESCUELA MARIA EVA DUARTE - ELECT 3.xlsx', 34.19, 'Instalacion electrica', 'ELEC-SAN', '100-176', E'[OS_CERT:100-176]\n[RUBROS_CERT:ELEC-SAN]', 34.19, 'Carga inicial', 'Carga inicial'),
  (3, 447, '031- ESCUELA MARIA EVA DUARTE - SANIT 3.xlsx', 12.81, 'Instalacion sanitaria', 'SAN', '134', E'[OS_CERT:134]\n[RUBROS_CERT:SAN]', 12.81, 'Carga inicial', 'Carga inicial'),
  (3, 448, '032- ESCUELA HEROES DE MALVINAS - SANIT 7.xlsx', 12.42, 'Instalacion sanitaria', 'SAN', '107', E'[OS_CERT:107]\n[RUBROS_CERT:SAN]', 12.42, 'Carga inicial', 'Carga inicial'),
  (3, 448, '032- ESCUELA HEROES DE MALVINAS - SANIT 8.xlsx', 3.09, 'Instalacion sanitaria', 'SAN', '135', E'[OS_CERT:135]\n[RUBROS_CERT:SAN]', 3.09, 'Carga inicial', 'Carga inicial'),
  (3, 449, '033- ESCUELA USANDIVARAS - CARP 3 POL2.xlsx', 55.38, 'Albanileria', 'ALB', '182', E'[OS_CERT:182]\n[RUBROS_CERT:ALB]', 55.38, 'Carga inicial', 'Carga inicial'),
  (3, 452, '036- IPEM Nº 312 - DALMASIO VELEZ SARFIELD - SANIT 5.xlsx', 4.18, 'Instalacion sanitaria', 'SAN', '157', E'[OS_CERT:157]\n[RUBROS_CERT:SAN]', 4.18, 'Carga inicial', 'Carga inicial'),
  (4, 422, '06- J. DE INFANTES CONSTANCIO C. VIGIL - SANIT 4 CARP.xlsx', 9.03, 'Albanileria', 'ALB-SAN', '209-221', E'[OS_CERT:209-221]\n[RUBROS_CERT:ALB-SAN]', 9.03, 'Carga inicial', 'Carga inicial'),
  (4, 425, '09- ESCUELA JUAN XXIII - HERR 2.xlsx', 44.7, 'Albanileria', 'ALB', '235', E'[OS_CERT:235]\n[RUBROS_CERT:ALB]', 44.7, 'Carga inicial', 'Carga inicial'),
  (4, 427, '011- IPEM Nº 167 - JOSE MANUEL ESTRADA - ELECT 4.xlsx', 47.63, 'Instalacion electrica', 'ELEC', '136', E'[OS_CERT:136]\n[RUBROS_CERT:ELEC]', 47.63, 'Carga inicial', 'Carga inicial'),
  (4, 432, '016- IPET Nº48 PRESIDENTE ROCA - BOMBA.xlsx', 67.78, 'Instalacion electrica', 'ELEC-SAN', '222-223', E'[OS_CERT:222-223]\n[RUBROS_CERT:ELEC-SAN]', 67.78, 'Carga inicial', 'Carga inicial'),
  (4, 437, '021- ESCUELA RUBEN DARIO - SANIT 7 BOMBA 2.xlsx', 4.35, 'Instalacion electrica', 'ELEC-SAN', '173', E'[OS_CERT:173]\n[RUBROS_CERT:ELEC-SAN]', 4.35, 'Carga inicial', 'Carga inicial'),
  (4, 440, '024- JARDIN DE I. JUAN RAMON JIMENEZ - SANIT 6.xlsx', 5.16, 'Instalacion sanitaria', 'SAN', '171', E'[OS_CERT:171]\n[RUBROS_CERT:SAN]', 5.16, 'Carga inicial', 'Carga inicial'),
  (4, 441, '025- ESCUELA ING. REGINO MADERS - SANIT 6.xlsx', 15.92, 'Albanileria', 'ALB-SAN', '224', E'[OS_CERT:224]\n[RUBROS_CERT:ALB-SAN]', 15.92, 'Carga inicial', 'Carga inicial'),
  (4, 443, '027- IPEM Nº11 ALBERTO PIO COGNINI - ELECT 2.xlsx', 35.4, 'Instalacion electrica', 'ELEC', '137', E'[OS_CERT:137]\n[RUBROS_CERT:ELEC]', 35.4, 'Carga inicial', 'Carga inicial'),
  (4, 449, '033- ESCUELA USANDIVARAS - CARP 4 PLOM 3.xlsx', 27.14, 'Albanileria', 'ALB-SAN', '231-231A', E'[OS_CERT:231-231A]\n[RUBROS_CERT:ALB-SAN]', 27.14, 'Carga inicial', 'Carga inicial'),
  (4, 449, '033- ESCUELA USANDIVARAS - CARP 5.xlsx', 22.02, 'Albanileria', 'ALB', '238', E'[OS_CERT:238]\n[RUBROS_CERT:ALB]', 22.02, 'Carga inicial', 'Carga inicial'),
  (5, 418, '02- ESCUELA EJERCITO ARGENTINO - ELECT 5.xlsx', 2.32, 'Instalacion electrica', 'ELEC', '192', E'[OS_CERT:192]\n[RUBROS_CERT:ELEC]', 2.32, 'Carga inicial', 'Carga inicial'),
  (5, 419, '03- J. DE INFANTES EJERCITO ARGENTINO - GAS 3.xlsx', 9.99, 'Instalacion de gas', 'GAS', '194', E'[OS_CERT:194]\n[RUBROS_CERT:GAS]', 9.99, 'Carga inicial', 'Carga inicial'),
  (5, 420, '04- J. DE INFANTES LIBERTADOR SAN MARTIN - GAS 2.xlsx', 25.42, 'Instalacion de gas', 'GAS', '148', E'[OS_CERT:148]\n[RUBROS_CERT:GAS]', 25.42, 'Carga inicial', 'Carga inicial'),
  (5, 421, '05- IPET Nº77 - GOB. S. DEL CASTILLO - ALB.xlsx', 116.52, 'Albanileria', 'ALB', '166', E'[OS_CERT:166]\n[RUBROS_CERT:ALB]', 116.52, 'Carga inicial', 'Carga inicial'),
  (5, 421, '05- IPET Nº77 - GOB. S. DEL CASTILLO - CUBIERTA.xlsx', 72.34, 'Cubierta de techos', 'CUB', '242', E'[OS_CERT:242]\n[RUBROS_CERT:CUB]', 72.34, 'Carga inicial', 'Carga inicial'),
  (5, 421, '05- IPET Nº77 - GOB. S. DEL CASTILLO - ELECT 3.xlsx', 25.14, 'Instalacion electrica', 'ELEC', '288', E'[OS_CERT:288]\n[RUBROS_CERT:ELEC]', 25.14, 'Carga inicial', 'Carga inicial'),
  (5, 422, '06- J. DE INFANTES CONSTANCIO C. VIGIL - SANIT 5.xlsx', 2.63, 'Instalacion sanitaria', 'SAN', '260', E'[OS_CERT:260]\n[RUBROS_CERT:SAN]', 2.63, 'Carga inicial', 'Carga inicial'),
  (5, 423, '07- IPEM Nº 176 - GRANADERO JOSE MARQUEZ - GAS 2.xlsx', 6.43, 'Instalacion de gas', 'GAS', '263', E'[OS_CERT:263]\n[RUBROS_CERT:GAS]', 6.43, 'Carga inicial', 'Carga inicial'),
  (5, 424, '08- ESCUELA CONSTANCIO VIGIL - ALB Completar v.xlsx', 321.32, 'Albanileria', 'ALB', '213', E'[OS_CERT:213]\n[RUBROS_CERT:ALB]', 321.32, 'Carga inicial', 'Carga inicial'),
  (5, 427, '011- IPEM Nº 167 - JOSE MANUEL ESTRADA - ALB 2.xlsx', 8.8, 'Albanileria', 'ALB', '227', E'[OS_CERT:227]\n[RUBROS_CERT:ALB]', 8.8, 'Carga inicial', 'Carga inicial'),
  (5, 427, '011- IPEM Nº 167 - JOSE MANUEL ESTRADA - ELECT 5.xlsx', 6.59, 'Instalacion electrica', 'ELEC', '117', E'[OS_CERT:117]\n[RUBROS_CERT:ELEC]', 6.59, 'Carga inicial', 'Carga inicial'),
  (5, 427, '011- IPEM Nº 167 - JOSE MANUEL ESTRADA - SANIT9.xlsx', 31.4, 'Albanileria', 'ALB-SAN', '217', E'[OS_CERT:217]\n[RUBROS_CERT:ALB-SAN]', 31.4, 'Carga inicial', 'Carga inicial'),
  (5, 428, '012- ESCUELA PEDRO GOYENA - CARP 5.xlsx', 2.63, 'Albanileria', 'ALB', '230', E'[OS_CERT:230]\n[RUBROS_CERT:ALB]', 2.63, 'Carga inicial', 'Carga inicial'),
  (5, 428, '012- ESCUELA PEDRO GOYENA - SANIT 8.xlsx', 1.31, 'Instalacion sanitaria', 'SAN', '203', E'[OS_CERT:203]\n[RUBROS_CERT:SAN]', 1.31, 'Carga inicial', 'Carga inicial'),
  (5, 432, '016- IPET Nº48 PRESIDENTE ROCA - SANIT 6.xlsx', 18.28, 'Instalacion sanitaria', 'SAN', '243', E'[OS_CERT:243]\n[RUBROS_CERT:SAN]', 18.28, 'Carga inicial', 'Carga inicial'),
  (5, 433, '017- JARDIN DE I. JOSE HERNANDEZ - GAS.xlsx', 4.21, 'Instalacion de gas', 'GAS', '275', E'[OS_CERT:275]\n[RUBROS_CERT:GAS]', 4.21, 'Carga inicial', 'Carga inicial'),
  (5, 433, '017- JARDIN DE I. JOSE HERNANDEZ - SANIT 4.xlsx', 5.87, 'Instalacion sanitaria', 'SAN', '144', E'[OS_CERT:144]\n[RUBROS_CERT:SAN]', 5.87, 'Carga inicial', 'Carga inicial'),
  (5, 439, '023- ESCUELA LIBERTADOR GRAL SAN MARTIN - SANIT5.xlsx', 5.13, 'Cubierta de techos', 'CUB-SAN', '261-262', E'[OS_CERT:261-262]\n[RUBROS_CERT:CUB-SAN]', 5.13, 'Carga inicial', 'Carga inicial'),
  (5, 442, '026- IPEM Nº13 - DR. PEDRO ESCUDERO - CARP 2 POL.xlsx', 41.6, 'Albanileria', 'ALB', '139A', E'[OS_CERT:139A]\n[RUBROS_CERT:ALB]', 41.6, 'Carga inicial', 'Carga inicial'),
  (5, 442, '026- IPEM Nº13 - DR. PEDRO ESCUDERO - HERR PINT.xlsx', 36.95, 'Albanileria', 'ALB', '146', E'[OS_CERT:146]\n[RUBROS_CERT:ALB]', 36.95, 'Carga inicial', 'Carga inicial'),
  (5, 442, '026- IPEM Nº13 - DR. PEDRO ESCUDERO - HERR.xlsx', 51.72, 'Albanileria', 'ALB', '139', E'[OS_CERT:139]\n[RUBROS_CERT:ALB]', 51.72, 'Carga inicial', 'Carga inicial'),
  (5, 442, '026- IPEM Nº13 - DR. PEDRO ESCUDERO - SANIT 4.xlsx', 12.94, 'Instalacion sanitaria', 'SAN', '252', E'[OS_CERT:252]\n[RUBROS_CERT:SAN]', 12.94, 'Carga inicial', 'Carga inicial'),
  (5, 443, '027- IPEM Nº11 ALBERTO PIO COGNINI - ELECT 3.xlsx', 23.32, 'Instalacion electrica', 'ELEC', '251', E'[OS_CERT:251]\n[RUBROS_CERT:ELEC]', 23.32, 'Carga inicial', 'Carga inicial'),
  (5, 448, '032- ESCUELA HEROES DE MALVINAS - SANIT 7.xlsx', 11.06, 'Instalacion sanitaria', 'SAN', '133', E'[OS_CERT:133]\n[RUBROS_CERT:SAN]', 11.06, 'Carga inicial', 'Carga inicial'),
  (5, 449, '033- ESCUELA USANDIVARAS - ELECT 5.xlsx', 38.39, 'Instalacion electrica', 'ELEC', '299', E'[OS_CERT:299]\n[RUBROS_CERT:ELEC]', 38.39, 'Carga inicial', 'Carga inicial'),
  (5, 449, '033- ESCUELA USANDIVARAS - PLOM 5.xlsx', 3.79, 'Instalacion sanitaria', 'SAN', '229', E'[OS_CERT:229]\n[RUBROS_CERT:SAN]', 3.79, 'Carga inicial', 'Carga inicial'),
  (5, 449, '033- ESCUELA USANDIVARAS - PLOM 6.xlsx', 5.17, 'Instalacion sanitaria', 'SAN', '237', E'[OS_CERT:237]\n[RUBROS_CERT:SAN]', 5.17, 'Carga inicial', 'Carga inicial'),
  (5, 450, '034- JARDIN DE I.TERESA DE CALCUTA - ELECT 3.xlsx', 20.28, 'Instalacion electrica', 'ELEC', '300', E'[OS_CERT:300]\n[RUBROS_CERT:ELEC]', 20.28, 'Carga inicial', 'Carga inicial'),
  (5, 450, '034- JARDIN DE I.TERESA DE CALCUTA - GAS.xlsx', 9.51, 'Instalacion de gas', 'GAS', '199', E'[OS_CERT:199]\n[RUBROS_CERT:GAS]', 9.51, 'Carga inicial', 'Carga inicial'),
  (5, 451, '035- JARDIN DE I.REGINO MADERS - ELECT 3.xlsx', 23.41, 'Instalacion electrica', 'ELEC', '281', E'[OS_CERT:281]\n[RUBROS_CERT:ELEC]', 23.41, 'Carga inicial', 'Carga inicial'),
  (5, 451, '035- JARDIN DE I.REGINO MADERS - SANIT 7.xlsx', 4.07, 'Instalacion sanitaria', 'SAN', '301', E'[OS_CERT:301]\n[RUBROS_CERT:SAN]', 4.07, 'Carga inicial', 'Carga inicial')
) as d (
  medicion_numero, establecimiento_id, archivo_original, modulos_original,
  rubro_certificado, rubros_certificado, ordenes_servicio_certificado,
  observaciones_inspector, modulos_inspector, creado_por, actualizado_por
)
where not exists (
  select 1 from public.certificados_medicion x
  where x.zona = 10
    and x.medicion_numero = d.medicion_numero
    and x.establecimiento_id = d.establecimiento_id
    and x.archivo_original = d.archivo_original
);


-- ── Verificacion (correr despues; son solo lecturas) ───────────────────────────

-- 1) Total de certificados de zona 10 cargados con este proceso (esperado: 119)
select count(*) as certificados_carga_inicial_z10
from public.certificados_medicion
where zona = 10 and creado_por = 'Carga inicial';

-- 2) Total de certificados de zona 10 en la tabla
select count(*) as certificados_zona10_total
from public.certificados_medicion
where zona = 10;

-- 3) Certificados de la carga cuyo numero de O.S. no tiene orden real Z10-XXX
--    (esperado: solo los que referencian 101 y 357)
select archivo_original, ordenes_servicio_certificado
from public.certificados_medicion c
where c.zona = 10
  and c.creado_por = 'Carga inicial'
  and exists (
    select 1
    from regexp_split_to_table(regexp_replace(c.ordenes_servicio_certificado, '[^0-9-]', '', 'g'), '-') t(n)
    where t.n <> ''
      and not exists (
        select 1 from public.ordenes_servicio o
        where o.zona = 10 and o.numero = 'Z10-' || lpad(t.n, 3, '0')
      )
  )
order by c.medicion_numero, c.archivo_original;

-- Notas por fila:
--   020- ESCUELA BARTOLOME HIDALGO - ELECT 3 POL CARP.xlsx : O.S. con sufijo bis (43 43A); se conserva en el marcador, liga al numero base
--   024- JARDIN DE I. JUAN RAMON JIMENEZ - SANIT 4 ELECT.xlsx : O.S. 357 no existe en ordenes_servicio; el certificado se liga igual por 278-292-357
--   026- IPEM Nº13 - DR. PEDRO ESCUDERO - CARP 2 POL.xlsx : O.S. con sufijo bis (139 A); se conserva en el marcador, liga al numero base
--   031- ESCUELA MARIA EVA DUARTE - SANIT 2.xlsx : O.S. con sufijo bis (95 96A); se conserva en el marcador, liga al numero base
--   033- ESCUELA USANDIVARAS - CARP 4 PLOM 3.xlsx : O.S. con sufijo bis (231 231A); se conserva en el marcador, liga al numero base
--   036- IPEM Nº 312 - DALMASIO VELEZ SARFIELD - SANIT 4 ELECT 3.xlsx : O.S. 101 no existe en ordenes_servicio; el certificado se liga igual por 101-102
