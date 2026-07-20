-- DGIE - Comunicaciones operativas con RLS.
-- Ejecutar completo en Supabase SQL Editor.

begin;

alter table public.comunicaciones enable row level security;

-- Las instalaciones anteriores de la tabla pueden no tener este default.
-- Tambien se envia explicitamente desde el cliente por compatibilidad.
alter table public.comunicaciones
  alter column creado_por set default auth.uid();

alter table public.comunicaciones drop constraint if exists comunicaciones_alcance_check;
alter table public.comunicaciones add constraint comunicaciones_alcance_check
  check (alcance in ('general','zona','empresas','empresa_zona','coordinador'));

grant select, insert, update, delete on public.comunicaciones to authenticated;

drop policy if exists "comunicaciones lectura por rol" on public.comunicaciones;
drop policy if exists "gestion crea comunicaciones" on public.comunicaciones;
drop policy if exists "gestion o inspector actualiza comunicaciones" on public.comunicaciones;
drop policy if exists "gestion elimina comunicaciones" on public.comunicaciones;

create policy "comunicaciones lectura por rol" on public.comunicaciones
for select using (
  public.mi_rol() in ('director','coordinador')
  or (
    public.mi_rol() = 'inspector'
    and (
      alcance = 'general'
      or public.mi_zona() = any(zonas)
      or creado_por = auth.uid()
    )
  )
  or (
    public.mi_rol() = 'empresa'
    and (
      alcance = 'empresas'
      or (
        alcance = 'empresa_zona'
        and public.mi_zona() = any(zonas)
      )
    )
  )
);

create policy "gestion crea comunicaciones" on public.comunicaciones
for insert with check (
  public.mi_rol() in ('director','coordinador')
  or (
    public.mi_rol() = 'inspector'
    and creado_por = auth.uid()
    and alcance in ('empresa_zona','coordinador')
    and public.mi_zona() = any(zonas)
  )
);

create policy "gestion o inspector actualiza comunicaciones" on public.comunicaciones
for update using (
  public.mi_rol() in ('director','coordinador')
  or (
    public.mi_rol() = 'inspector'
    and (
      alcance = 'general'
      or public.mi_zona() = any(zonas)
      or creado_por = auth.uid()
    )
  )
  or (
    public.mi_rol() = 'empresa'
    and (
      alcance = 'empresas'
      or (
        alcance = 'empresa_zona'
        and public.mi_zona() = any(zonas)
      )
    )
  )
)
with check (
  public.mi_rol() in ('director','coordinador')
  or (
    public.mi_rol() = 'inspector'
    and (
      alcance = 'general'
      or public.mi_zona() = any(zonas)
      or creado_por = auth.uid()
    )
  )
  or (
    public.mi_rol() = 'empresa'
    and (
      alcance = 'empresas'
      or (
        alcance = 'empresa_zona'
        and public.mi_zona() = any(zonas)
      )
    )
  )
);

create policy "gestion elimina comunicaciones" on public.comunicaciones
for delete using (
  public.mi_rol() in ('director','coordinador')
);

-- Limpieza de las dos filas creadas durante el diagnóstico del rechazo RLS.
delete from public.comunicaciones
where id in (
  'afb8b826-72e7-4f1b-8375-16b561c02b57',
  '1964ff47-cfda-4156-af09-467e720648c6'
);

commit;
