-- DGIE - Modulos sin redondear, para calcular los montos de la liquidacion.
-- Idempotente: se puede correr varias veces sin efecto adicional.
--
-- Por que hace falta: la planilla de liquidacion muestra los modulos
-- redondeados a dos decimales, pero el monto en pesos de cada certificado se
-- calcula con el numero completo, tal como lo hace la planilla que se firma.
-- Un certificado que dice 28,46 modulos puede tener 28,4636 por debajo, y esa
-- diferencia son casi quinientos pesos.
--
-- Se guardan los dos: el redondeado, que es el que se muestra y ya vive en
-- modulos_final / modulos_inspector, y este, que es el que manda para la plata.

begin;

alter table public.certificados_medicion
  add column if not exists modulos_exacto numeric;

comment on column public.certificados_medicion.modulos_exacto is
  'Total de modulos del certificado sin redondear, leido del Excel. El monto en pesos de la liquidacion se calcula con este numero; en pantalla se muestra el redondeado.';

commit;

-- ============================================================
-- Verificacion
-- ============================================================
select 'columna' as dato,
       case when exists (
         select 1 from information_schema.columns
          where table_schema = 'public' and table_name = 'certificados_medicion'
            and column_name = 'modulos_exacto')
       then 'creada' else 'FALTA' end as detalle
union all
select 'certificados con el valor exacto', count(*)::text
  from public.certificados_medicion
 where modulos_exacto is not null;
