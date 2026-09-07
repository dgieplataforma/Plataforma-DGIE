-- DGIE - Nombre actual del inspector y autor historico de cada orden.
-- Idempotente: se puede ejecutar nuevamente sin perder datos.

begin;

alter table public.ordenes_servicio
  add column if not exists inspector_nombre text;

-- Primero se congela el nombre anterior en las ordenes existentes. Se prioriza
-- el perfil porque es el dato con el que el inspector inicio sesion hasta hoy.
update public.ordenes_servicio orden
   set inspector_nombre = coalesce(
     (select perfil.nombre
        from public.perfiles perfil
       where lower(trim(perfil.rol)) = 'inspector'
         and perfil.zona = orden.zona
       order by perfil.id
       limit 1),
     (select inspector.nombre
        from public.inspectores_zona inspector
       where inspector.zona = orden.zona),
     'Inspector Zona ' || orden.zona::text
   )
 where nullif(trim(orden.inspector_nombre), '') is null;

create or replace function public.dgie_asignar_inspector_orden()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if nullif(trim(new.inspector_nombre), '') is null then
    select inspector.nombre into new.inspector_nombre
      from public.inspectores_zona inspector
     where inspector.zona = new.zona;
  end if;
  return new;
end;
$$;

drop trigger if exists dgie_asignar_inspector_orden on public.ordenes_servicio;
create trigger dgie_asignar_inspector_orden
before insert on public.ordenes_servicio
for each row execute function public.dgie_asignar_inspector_orden();

create or replace function public.dgie_actualizar_inspector_zona(
  p_zona integer,
  p_nombre text,
  p_email text default null,
  p_telefono text default null,
  p_cuit text default null
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rol text;
  v_anterior text;
  v_perfiles integer := 0;
begin
  select lower(trim(perfil.rol)) into v_rol
    from public.perfiles perfil
   where perfil.id = auth.uid();

  if v_rol is null or v_rol not in ('coordinador', 'director', 'direccion') then
    raise exception 'Solo coordinación puede actualizar inspectores.';
  end if;
  if p_zona not between 1 and 17 then
    raise exception 'La zona no es válida.';
  end if;
  if nullif(trim(p_nombre), '') is null then
    raise exception 'El nombre es obligatorio.';
  end if;

  select perfil.nombre into v_anterior
    from public.perfiles perfil
   where lower(trim(perfil.rol)) = 'inspector' and perfil.zona = p_zona
   order by perfil.id
   limit 1;
  if v_anterior is null then
    select inspector.nombre into v_anterior
      from public.inspectores_zona inspector where inspector.zona = p_zona;
  end if;

  update public.ordenes_servicio
     set inspector_nombre = coalesce(nullif(trim(v_anterior), ''), 'Inspector Zona ' || p_zona::text)
   where zona = p_zona and nullif(trim(inspector_nombre), '') is null;

  -- Los saludos muestran la identidad actual del autor. El texto y la fecha no
  -- cambian; solo se corrige el nombre visible si esa persona cambio de nombre.
  if to_regclass('public.saludos_cumpleanios') is not null then
    execute 'update public.saludos_cumpleanios saludo
                set autor_nombre = $2
               from public.perfiles perfil
              where saludo.autor_id = perfil.id
                and lower(trim(perfil.rol)) = ''inspector''
                and perfil.zona = $1'
      using p_zona, trim(p_nombre);
  end if;

  -- La tabla no admite nulos en estos campos. Un inspector puede no tener email
  -- cargado todavia, asi que lo que falta se guarda como texto vacio y no como
  -- nulo, que hacia fallar el guardado entero.
  insert into public.inspectores_zona (zona, nombre, email, telefono, cuit)
  values (p_zona, trim(p_nombre), coalesce(p_email, ''), coalesce(p_telefono, ''), coalesce(p_cuit, ''))
  on conflict (zona) do update set
    nombre = excluded.nombre,
    email = excluded.email,
    telefono = excluded.telefono,
    cuit = excluded.cuit;

  update public.perfiles
     set nombre = trim(p_nombre)
   where lower(trim(rol)) = 'inspector' and zona = p_zona;
  get diagnostics v_perfiles = row_count;
  return v_perfiles;
end;
$$;

-- Corrige tambien cualquier nombre que ya se haya cambiado solo en la ficha de
-- zona antes de instalar esta mejora (por ejemplo, la Zona 16).
update public.perfiles perfil
   set nombre = inspector.nombre
  from public.inspectores_zona inspector
 where lower(trim(perfil.rol)) = 'inspector'
   and perfil.zona = inspector.zona
   and perfil.nombre is distinct from inspector.nombre;

-- Repara saludos ya guardados con el nombre anterior. Se usa SQL dinamico para
-- que la migracion siga funcionando si el modulo de cumpleaños no esta creado.
do $$
begin
  if to_regclass('public.saludos_cumpleanios') is not null then
    execute 'update public.saludos_cumpleanios saludo
                set autor_nombre = perfil.nombre
               from public.perfiles perfil
              where saludo.autor_id = perfil.id
                and saludo.autor_nombre is distinct from perfil.nombre';
  end if;
end $$;

revoke all on function public.dgie_actualizar_inspector_zona(integer,text,text,text,text) from public;
revoke all on function public.dgie_actualizar_inspector_zona(integer,text,text,text,text) from anon;
grant execute on function public.dgie_actualizar_inspector_zona(integer,text,text,text,text) to authenticated;

commit;

select count(*) filter (where nullif(trim(inspector_nombre), '') is null) as ordenes_sin_inspector
  from public.ordenes_servicio;
