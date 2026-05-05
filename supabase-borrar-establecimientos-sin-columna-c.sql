-- DGIE - Borrar establecimientos sin numero en columna C
-- Excepcion conservada: Escuela Alegria Ahora
-- Ejecutar completo en Supabase SQL Editor.

begin;

create temp table dgie_establecimientos_a_borrar (id bigint primary key);

insert into dgie_establecimientos_a_borrar (id) values
  (38),
  (39),
  (40),
  (41),
  (42),
  (43),
  (80),
  (81),
  (82),
  (83),
  (84),
  (85),
  (86),
  (87),
  (88),
  (125),
  (126),
  (127),
  (128),
  (129),
  (130),
  (131),
  (132),
  (133),
  (134),
  (135),
  (136),
  (137),
  (138),
  (176),
  (177),
  (178),
  (179),
  (180),
  (181),
  (182),
  (183),
  (184),
  (185),
  (186),
  (233),
  (271),
  (272),
  (273),
  (274),
  (275),
  (276),
  (277),
  (278),
  (279),
  (316),
  (317),
  (318),
  (319),
  (320),
  (321),
  (322),
  (323),
  (324),
  (325),
  (364),
  (365),
  (366),
  (367),
  (368),
  (369),
  (370),
  (371),
  (372),
  (373),
  (374),
  (411),
  (412),
  (413),
  (414),
  (415),
  (416),
  (453),
  (454),
  (455),
  (456),
  (457),
  (458),
  (459),
  (460),
  (497),
  (498),
  (499),
  (500),
  (501),
  (502),
  (503),
  (504),
  (505),
  (542),
  (543),
  (544),
  (545),
  (546),
  (547),
  (548),
  (585),
  (586),
  (587),
  (624),
  (625),
  (626),
  (627),
  (628),
  (629),
  (630),
  (631),
  (632),
  (633),
  (634),
  (671),
  (672),
  (674),
  (675),
  (676),
  (677),
  (751),
  (752),
  (753),
  (754),
  (755),
  (756),
  (758),
  (759);

-- Borrar registros dependientes para que no queden reclamos/ordenes/fotos sueltos.
delete from public.fotos
where establecimiento_id in (select id from dgie_establecimientos_a_borrar);

delete from public.ordenes_servicio
where establecimiento_id in (select id from dgie_establecimientos_a_borrar);

delete from public.reclamos
where establecimiento_id in (select id from dgie_establecimientos_a_borrar);

delete from public.intervenciones
where establecimiento_id in (select id from dgie_establecimientos_a_borrar);

delete from public.relevamientos
where establecimiento_id in (select id from dgie_establecimientos_a_borrar);

delete from public.establecimientos
where id in (select id from dgie_establecimientos_a_borrar);

commit;

-- Verificacion: estos ids no deberian existir.
select count(*) as establecimientos_restantes_de_la_lista
from public.establecimientos
where id in (select id from dgie_establecimientos_a_borrar);
