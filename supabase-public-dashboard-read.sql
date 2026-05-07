-- DGIE - Lectura pública para pantalla inicial
-- Ejecutar en Supabase SQL Editor si la pantalla pública debe cargar sin iniciar sesión.

drop policy if exists "publico lee establecimientos dashboard" on public.establecimientos;
create policy "publico lee establecimientos dashboard"
on public.establecimientos for select
using (true);

drop policy if exists "publico lee reclamos dashboard" on public.reclamos;
create policy "publico lee reclamos dashboard"
on public.reclamos for select
using (true);

drop policy if exists "publico lee ordenes dashboard" on public.ordenes_servicio;
create policy "publico lee ordenes dashboard"
on public.ordenes_servicio for select
using (true);

drop policy if exists "publico lee intervenciones dashboard" on public.intervenciones;
create policy "publico lee intervenciones dashboard"
on public.intervenciones for select
using (true);

drop policy if exists "publico lee relevamientos dashboard" on public.relevamientos;
create policy "publico lee relevamientos dashboard"
on public.relevamientos for select
using (true);
