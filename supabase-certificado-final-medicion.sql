alter table public.certificados_medicion
  add column if not exists archivo_final text,
  add column if not exists url_final text,
  add column if not exists public_id_final text,
  add column if not exists modulos_final numeric default 0,
  add column if not exists monto_final numeric default 0,
  add column if not exists fecha_medicion date;
