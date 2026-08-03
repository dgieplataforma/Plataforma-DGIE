create table if not exists public.agenda_recordatorios (
 id uuid primary key default gen_random_uuid(),
 zona integer not null check (zona between 1 and 17),
 texto text not null check (length(trim(texto)) > 0),
 establecimiento_id bigint references public.establecimientos(id) on delete set null,
 inspector_nombre text not null,
 completado boolean not null default false,
 completado_en timestamptz,
 creado_por uuid not null default auth.uid(),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists agenda_recordatorios_zona_created_idx on public.agenda_recordatorios(zona,created_at desc);
create index if not exists agenda_recordatorios_establecimiento_idx on public.agenda_recordatorios(establecimiento_id,created_at desc) where establecimiento_id is not null;
alter table public.agenda_recordatorios enable row level security;
drop policy if exists "agenda_lectura_por_zona" on public.agenda_recordatorios;
create policy "agenda_lectura_por_zona" on public.agenda_recordatorios for select to authenticated using (
 exists(select 1 from public.perfiles p where p.id=auth.uid() and (
   (p.rol='inspector' and p.zona=agenda_recordatorios.zona) or
   p.rol in ('coordinador','direccion','director')
 ))
);
drop policy if exists "agenda_crear_propios" on public.agenda_recordatorios;
create policy "agenda_crear_propios" on public.agenda_recordatorios for insert to authenticated with check (
 creado_por=auth.uid() and exists(select 1 from public.perfiles p where p.id=auth.uid() and p.rol='inspector' and p.zona=agenda_recordatorios.zona)
);
drop policy if exists "agenda_editar_propios" on public.agenda_recordatorios;
create policy "agenda_editar_propios" on public.agenda_recordatorios for update to authenticated using (creado_por=auth.uid()) with check (creado_por=auth.uid());
drop policy if exists "agenda_eliminar_propios" on public.agenda_recordatorios;
create policy "agenda_eliminar_propios" on public.agenda_recordatorios for delete to authenticated using (creado_por=auth.uid());
create or replace function public.dgie_touch_agenda_recordatorios() returns trigger language plpgsql security invoker set search_path=public as $$ begin new.updated_at=now(); return new; end; $$;
drop trigger if exists agenda_recordatorios_touch_updated_at on public.agenda_recordatorios;
create trigger agenda_recordatorios_touch_updated_at before update on public.agenda_recordatorios for each row execute function public.dgie_touch_agenda_recordatorios();
grant select,insert,update,delete on public.agenda_recordatorios to authenticated;
