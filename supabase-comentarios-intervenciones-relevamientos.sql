alter table public.intervenciones
  add column if not exists comentarios_coordinacion jsonb not null default '[]'::jsonb;

-- Verificacion rapida
select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'intervenciones'
  and column_name = 'comentarios_coordinacion';
