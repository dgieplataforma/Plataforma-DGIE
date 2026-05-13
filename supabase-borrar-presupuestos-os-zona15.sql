begin;

-- Limpia solo el presupuesto de las ordenes de servicio de Zona 15.
-- No borra ordenes, reclamos, estados, fechas ni tareas.
update public.ordenes_servicio
set
  presupuesto = '[]'::jsonb,
  monto = null,
  updated_at = now()
where zona = 15;

commit;

-- Verificacion: presupuesto debe quedar vacio y monto en null para Zona 15.
select
  count(*) as ordenes_zona_15,
  count(*) filter (
    where presupuesto is not null
      and presupuesto <> '[]'::jsonb
  ) as ordenes_con_presupuesto,
  count(*) filter (
    where monto is not null
      and trim(monto) <> ''
      and trim(monto) <> '—'
  ) as ordenes_con_monto
from public.ordenes_servicio
where zona = 15;
