-- ============================================================
-- Fix: empresa_finalizo en ordenes_servicio
-- Ejecutar en Supabase > SQL Editor
-- ============================================================

-- 1. Agregar columnas si no existen (idempotente)
ALTER TABLE public.ordenes_servicio
  ADD COLUMN IF NOT EXISTS empresa_finalizo boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS empresa_finalizo_fecha timestamptz,
  ADD COLUMN IF NOT EXISTS empresa_finalizo_por text;

-- 2. Función RPC con SECURITY DEFINER para que empresa pueda marcar finalización
--    sin necesitar UPDATE directo sobre la tabla (que RLS le bloquea).
--    Valida internamente que el usuario sea de la zona correcta.
CREATE OR REPLACE FUNCTION public.marcar_empresa_finalizo(p_orden_id uuid, p_valor boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_zona integer;
  v_rol  text;
  v_mi_zona integer;
BEGIN
  v_rol     := public.mi_rol();
  v_mi_zona := public.mi_zona();

  IF v_rol IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado o sin perfil activo';
  END IF;

  SELECT zona INTO v_zona
    FROM public.ordenes_servicio
   WHERE id = p_orden_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Orden no encontrada: %', p_orden_id;
  END IF;

  -- Empresa solo puede marcar órdenes de su propia zona
  IF v_rol = 'empresa' AND v_zona IS DISTINCT FROM v_mi_zona THEN
    RAISE EXCEPTION 'Sin permiso: la orden pertenece a otra zona';
  END IF;

  -- Inspector, coordinador y director también pueden llamar esta función
  IF v_rol NOT IN ('empresa','inspector','coordinador','director') THEN
    RAISE EXCEPTION 'Rol sin permiso para esta operación: %', v_rol;
  END IF;

  UPDATE public.ordenes_servicio
     SET empresa_finalizo      = p_valor,
         empresa_finalizo_fecha = CASE WHEN p_valor THEN now() ELSE NULL END,
         updated_at            = now()
   WHERE id = p_orden_id;
END;
$$;

-- 3. Dar acceso a usuarios autenticados para llamar la función
GRANT EXECUTE ON FUNCTION public.marcar_empresa_finalizo(uuid, boolean) TO authenticated;
