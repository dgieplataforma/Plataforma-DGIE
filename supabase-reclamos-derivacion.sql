alter table public.reclamos
  add column if not exists derivado_a text,
  add column if not exists derivado_en timestamptz,
  add column if not exists derivado_por text;

alter table public.reclamos drop constraint if exists reclamos_estado_check;
alter table public.reclamos add constraint reclamos_estado_check
  check (estado in ('pendiente','anulado','derivado'));
