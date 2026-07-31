-- DGIE - Conversaciones bidireccionales entre inspector y empresa.
-- Ejecutar completo en el SQL Editor. No modifica ni elimina comunicaciones existentes.

begin;

alter table public.comunicaciones enable row level security;
grant select, insert, update on public.comunicaciones to authenticated;

drop policy if exists "comunicaciones lectura por rol" on public.comunicaciones;
drop policy if exists "gestion crea comunicaciones" on public.comunicaciones;
drop policy if exists "gestion o inspector actualiza comunicaciones" on public.comunicaciones;

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
      or (
        creado_por = auth.uid()
        and alcance = 'zona'
        and cardinality(zonas) = 1
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
    and cardinality(zonas) = 1
    and public.mi_zona() = any(zonas)
  )
  or (
    public.mi_rol() = 'empresa'
    and creado_por = auth.uid()
    and alcance = 'zona'
    and cardinality(zonas) = 1
    and public.mi_zona() = any(zonas)
    and coalesce(encuesta->'meta'->>'clase','') = 'conversacion_inspector_empresa'
    and coalesce(encuesta->'meta'->>'origenRol','') = 'empresa'
    and coalesce(encuesta->'meta'->>'origenZona','') = public.mi_zona()::text
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
      or (
        creado_por = auth.uid()
        and alcance = 'zona'
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
      or (
        creado_por = auth.uid()
        and alcance = 'zona'
        and cardinality(zonas) = 1
        and public.mi_zona() = any(zonas)
        and coalesce(encuesta->'meta'->>'clase','') = 'conversacion_inspector_empresa'
        and coalesce(encuesta->'meta'->>'origenRol','') = 'empresa'
        and coalesce(encuesta->'meta'->>'origenZona','') = public.mi_zona()::text
      )
    )
  )
);

commit;
