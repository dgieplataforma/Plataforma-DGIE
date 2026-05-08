-- Política RLS: inspectores pueden eliminar intervenciones de su propia zona.
-- Ejecutar una sola vez en Supabase SQL Editor.

create policy "inspector elimina intervenciones de zona" on public.intervenciones
for delete using (
  public.mi_rol() = 'inspector' and zona = public.mi_zona()
);
