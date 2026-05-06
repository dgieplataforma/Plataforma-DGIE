-- Permite que coordinadores y directores borren comunicaciones desde la app
drop policy if exists "gestion elimina comunicaciones" on public.comunicaciones;

create policy "gestion elimina comunicaciones" on public.comunicaciones
for delete using (
  public.mi_rol() in ('director','coordinador')
);

-- Ejecutar esto para borrar todas las comunicaciones existentes:
-- DELETE FROM public.comunicaciones;
