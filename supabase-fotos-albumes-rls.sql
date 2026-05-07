-- DGIE - Permitir albumes/fotos de establecimiento desde gestion
-- Ejecutar en Supabase SQL Editor si coordinador/director deben crear albumes.

drop policy if exists "usuarios cargan fotos segun rol" on public.fotos;

create policy "usuarios cargan fotos segun rol" on public.fotos
for insert with check (
  public.mi_rol() in ('director','coordinador','callcenter')
  or (public.mi_rol() in ('inspector','empresa') and zona = public.mi_zona())
);
