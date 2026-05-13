-- Permite que un inspector vea las fotos de intervenciones cargadas por otras zonas.
-- Mantiene restringidas las demas fotos segun el rol/zona existente.

drop policy if exists "fotos lectura por rol" on public.fotos;

create policy "fotos lectura por rol" on public.fotos
for select using (
  public.mi_rol() in ('director','coordinador')
  or zona = public.mi_zona()
  or (
    public.mi_rol() = 'inspector'
    and entidad_tipo = 'intervencion'
  )
);
