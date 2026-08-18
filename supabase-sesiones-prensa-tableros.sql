-- Habilita los perfiles Prensa y Tableros sin modificar usuarios existentes.

begin;

do $$
declare
  restriccion record;
  columna_rol smallint;
begin
  select attnum
    into columna_rol
    from pg_attribute
   where attrelid = 'public.perfiles'::regclass
     and attname = 'rol'
     and not attisdropped;

  for restriccion in
    select conname
      from pg_constraint
     where conrelid = 'public.perfiles'::regclass
       and contype = 'c'
       and conkey = array[columna_rol]::smallint[]
  loop
    execute format('alter table public.perfiles drop constraint %I', restriccion.conname);
  end loop;
end
$$;

alter table public.perfiles
  add constraint perfiles_rol_check
  check (rol in ('director','coordinador','inspector','empresa','callcenter','prensa','tableros'))
  not valid;

alter table public.perfiles validate constraint perfiles_rol_check;

insert into public.perfiles (id, nombre, rol, zona)
select id, 'Prensa DGIE', 'prensa', null
  from auth.users
 where lower(email) = 'prensadgie@dgie.netlify.app'
on conflict (id) do update
  set nombre = excluded.nombre,
      rol = excluded.rol,
      zona = excluded.zona;

insert into public.perfiles (id, nombre, rol, zona)
select id, 'Tableros DGIE', 'tableros', null
  from auth.users
 where lower(email) = 'tablerosdgie@dgie.netlify.app'
on conflict (id) do update
  set nombre = excluded.nombre,
      rol = excluded.rol,
      zona = excluded.zona;

commit;
