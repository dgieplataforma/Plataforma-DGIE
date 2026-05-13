alter table public.certificados_medicion
add column if not exists conversacion jsonb not null default '[]';
