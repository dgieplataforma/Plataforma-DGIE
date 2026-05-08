-- Política RLS: coordinadores pueden actualizar intervenciones (para guardar comentarios).
-- Ejecutar una sola vez en Supabase SQL Editor.

create policy "coordinador actualiza intervenciones" on public.intervenciones
for update using (
  public.mi_rol() = 'coordinador'
) with check (
  public.mi_rol() = 'coordinador'
);
