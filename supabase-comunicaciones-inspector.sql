alter table public.comunicaciones drop constraint if exists comunicaciones_alcance_check;
alter table public.comunicaciones add constraint comunicaciones_alcance_check
  check (alcance in ('general','zona','empresas','empresa_zona','coordinador'));

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
      or public.mi_zona() = any(zonas)
    )
  )
);

create policy "gestion crea comunicaciones" on public.comunicaciones
for insert with check (
  public.mi_rol() in ('director','coordinador')
  or (
    public.mi_rol() = 'inspector'
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
      or public.mi_zona() = any(zonas)
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
      or public.mi_zona() = any(zonas)
    )
  )
);
