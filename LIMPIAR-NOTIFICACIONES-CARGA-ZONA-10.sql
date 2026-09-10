-- Limpieza de notificaciones generadas por la carga inicial de certificados de ZONA 10.
--
-- Al correr CARGAR-CERTIFICADOS-ZONA-10.sql, el trigger AFTER INSERT
-- 'dgie_certificado_push' sobre public.certificados_medicion encolo una notificacion
-- 'certificado' por cada uno de los 119 certificados para el/los inspector(es) de zona 10.
-- Esos certificados son historicos y ya estan medidos: la notificacion no corresponde.
--
-- Este script borra SOLO esas notificaciones (kind = 'certificado' cuyo source_id
-- apunta a un certificado de zona 10 creado por la 'Carga inicial'). No toca ninguna
-- otra notificacion ni ningun certificado.
--
-- Primero mira que va a borrar; despues descomenta el DELETE y volve a correr.

-- 1) Previsualizacion: cuantas y cuales notificaciones matchean
select count(*) as notificaciones_a_borrar
from public.push_notifications p
where p.kind = 'certificado'
  and p.source_id in (
    select c.id::text
    from public.certificados_medicion c
    where c.zona = 10 and c.creado_por = 'Carga inicial'
  );

-- 2) Borrado (descomentar para ejecutar)
-- delete from public.push_notifications p
-- where p.kind = 'certificado'
--   and p.source_id in (
--     select c.id::text
--     from public.certificados_medicion c
--     where c.zona = 10 and c.creado_por = 'Carga inicial'
--   );
