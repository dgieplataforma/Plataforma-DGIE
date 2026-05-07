-- DGIE - elimina comunicaciones generadas por comentarios de intervencion
-- Usar si quedaron pruebas anteriores en la seccion Comunicaciones.

delete from public.comunicaciones
where titulo = 'Comentario sobre intervención';

