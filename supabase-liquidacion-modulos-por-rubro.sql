-- DGIE - Desglose de modulos por rubro, para armar la planilla de liquidacion.
-- Idempotente: se puede correr varias veces sin efecto adicional.
--
-- Que hace:
--   1) agrega a certificados_medicion el desglose de modulos por rubro;
--   2) agrega el precio del modulo con el que se emitio el certificado.
--
-- No modifica ninguna fila existente ni borra nada.
--
-- Por que hace falta: hasta ahora se guardaba cuantos modulos tiene un
-- certificado en total, pero no como se reparten entre los cinco rubros del
-- pliego. Ese dato existe solo dentro del Excel del certificado, en la celda
-- de total de cada rubro. La planilla de liquidacion mensual necesita ese
-- desglose, asi que se extrae al subir el archivo y se guarda aca.

begin;

alter table public.certificados_medicion
  add column if not exists modulos_por_rubro jsonb,
  add column if not exists precio_modulo     numeric;

comment on column public.certificados_medicion.modulos_por_rubro is
  'Modulos discriminados por los cinco rubros del pliego, leidos del Excel del certificado: {"cubierta":0,"electricidad":0,"albanileria":0,"sanitaria":0,"gas":0}. Null si todavia no se pudo leer.';
comment on column public.certificados_medicion.precio_modulo is
  'Precio unitario del modulo con el que se emitio el certificado. Se guarda por certificado para que las mediciones viejas no se recalculen si el precio cambia.';

commit;

-- ============================================================
-- Verificacion
-- ============================================================
select 'columnas' as dato,
       string_agg(column_name, ', ' order by column_name) as detalle
  from information_schema.columns
 where table_schema = 'public'
   and table_name = 'certificados_medicion'
   and column_name in ('modulos_por_rubro', 'precio_modulo')
union all
select 'certificados con desglose',
       count(*)::text
  from public.certificados_medicion
 where modulos_por_rubro is not null;
