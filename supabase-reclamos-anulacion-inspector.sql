alter table public.reclamos
  add column if not exists estado text not null default 'pendiente',
  add column if not exists anulado_comentario text,
  add column if not exists anulado_en timestamptz,
  add column if not exists anulado_por text;

alter table public.reclamos drop constraint if exists reclamos_estado_check;
alter table public.reclamos add constraint reclamos_estado_check
  check (estado in ('pendiente','anulado'));
