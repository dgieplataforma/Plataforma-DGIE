-- Corrige las ordenes de servicio cargadas con anio 2020 y las pasa a 2026
-- conservando dia y mes.

begin;

update public.ordenes_servicio
set fecha_envio = (fecha_envio + interval '6 years')::date
where fecha_envio is not null
  and extract(year from fecha_envio) = 2020;

update public.ordenes_servicio
set fecha_finalizacion = (fecha_finalizacion + interval '6 years')::date
where fecha_finalizacion is not null
  and extract(year from fecha_finalizacion) = 2020;

commit;

-- Verificacion: deberia devolver 0.
select count(*) as ordenes_con_fecha_2020
from public.ordenes_servicio
where extract(year from fecha_envio) = 2020
   or extract(year from fecha_finalizacion) = 2020;
