-- DGIE - Total de modulos de la medicion segun el papel firmado.
-- Idempotente: se puede correr varias veces sin efecto adicional.
--
-- Por que hace falta: el conteo de modulos consumidos tiene que ser exacto, y
-- el numero exacto es el de la planilla que se firma. Armar ese total sumando
-- los certificados da una aproximacion: los subtotales por rubro y el total del
-- Excel son calculos distintos, con su propio redondeo, y no siempre cierran
-- contra el papel.
--
-- Entonces el total lo carga el inspector a mano, junto con el PDF firmado, y
-- ese numero manda para el presupuesto. El reparto por rubro se sigue armando
-- con los certificados, y por eso se muestra como aproximado.
--
-- Se guarda en cada certificado de la medicion, igual que los datos del PDF
-- firmado, para no depender de una tabla aparte.

begin;

alter table public.certificados_medicion
  add column if not exists medicion_modulos_firmados numeric;

comment on column public.certificados_medicion.medicion_modulos_firmados is
  'Total de modulos de la medicion segun la planilla firmada, cargado a mano por el inspector. Manda para el conteo de modulos consumidos; el reparto por rubro sale de los certificados y es aproximado.';

commit;

-- ============================================================
-- Verificacion
-- ============================================================
select 'columna' as dato,
       case when exists (
         select 1 from information_schema.columns
          where table_schema = 'public' and table_name = 'certificados_medicion'
            and column_name = 'medicion_modulos_firmados')
       then 'creada' else 'FALTA' end as detalle
union all
select 'mediciones con el total firmado cargado',
       count(distinct (zona::text || '-' || medicion_numero::text))::text
  from public.certificados_medicion
 where medicion_modulos_firmados is not null;
