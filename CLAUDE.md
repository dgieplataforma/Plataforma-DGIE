# Plataforma DGIE

Este proyecto se trabaja indistintamente con Claude Code y con Codex, sobre el
mismo repositorio. Para que las dos herramientas sigan las mismas reglas, el
contrato es uno solo y vive en otro archivo.

**Antes de tocar nada, leer los dos:**

1. `AGENTS.md` — cómo está armado el proyecto, las reglas críticas sobre datos
   reales, la validación obligatoria y el protocolo para cada pedido.
2. `ESTADO.md` — en qué se está trabajando, qué quedó pendiente y qué se hizo
   último. Se actualiza al cerrar cada tarea, en el mismo commit del cambio.

Lo más importante, para que no se pase por alto:

- La aplicación en desarrollo local **apunta a la base de datos real**. No hay
  entorno de prueba. Nada de escribir datos reales al probar.
- Validar con `npm run verificar` antes de dar algo por terminado. Si devuelve 2
  no hay navegador: dejar el cambio sin comitear y decirlo explícitamente.
- En la interfaz nunca se mencionan nombres de tecnologías internas.
