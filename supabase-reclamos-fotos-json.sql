alter table public.reclamos
  add column if not exists fotos jsonb not null default '[]'::jsonb;

-- Verificacion: debe devolver la columna fotos.
select column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'reclamos'
  and column_name = 'fotos';
