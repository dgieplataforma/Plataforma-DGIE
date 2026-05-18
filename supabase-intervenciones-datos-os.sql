alter table public.intervenciones
add column if not exists datos jsonb not null default '{}'::jsonb;

comment on column public.intervenciones.datos is
'Datos complementarios de la intervencion: intervencionId, osVinculadas, fechaHora, inspector y archivos.';
