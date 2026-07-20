# Nest — roadmap arquitectónico

Fecha de consolidación: 2026-07-16

Este roadmap describe la dirección actual del proyecto. No representa todavía una promesa de versiones ni fechas cerradas.

## Etapa 0 — independencia y base propia

Objetivo: separar Cachy-caOS de la dependencia estructural de Omarchy.

- Inventariar qué elementos vale la pena conservar como referencia.
- Reemplazar rutas, scripts y supuestos heredados.
- Mantener CachyOS + Hyprland como base limpia.
- Definir la estructura estable del Core y sus módulos.
- Documentar reconstrucción, decisiones y estado real del sistema.

## Etapa 1 — Nest UI y registro de módulos

Objetivo: consolidar Nest como aplicación del sistema.

- Hub principal de administración.
- Registro declarativo de módulos.
- Lanzamiento desde `.desktop` con icono propio.
- Separación clara entre Core, módulos e interfaz.
- Módulos iniciales: WebApps y keybinds.
- Instalador capaz de registrar iconos, accesos, dependencias y rutas sin asumir directorios XDG mal configurados.

## Etapa 2 — diagnóstico y mantenimiento

Objetivo: convertir conocimiento manual en verificaciones reproducibles.

- System Doctor.
- revisión post-update;
- `.pacnew`;
- mirrors;
- snapshots;
- kernel y paquetes;
- servicios fallidos;
- backups y restauración;
- logs relevantes;
- validación de integraciones.

## Etapa 3 — adaptadores de escritorio

Objetivo: desacoplar la experiencia visual del Core.

- Shell Adapter.
- Display Manager Adapter.
- Launcher Adapter.
- Theme Adapter.
- Appearance / System Icons con manifiesto declarativo.
- adaptadores `gtk-gsettings`, `qt6ct`, `hyprqt6engine`, entorno de Hyprland y `papirus-folders`.
- reparación post-update de variantes de iconos y carpetas.
- mecanismos para detectar capacidades en vez de asumir herramientas concretas.

El módulo de iconos debe conservar la identidad visual aunque cambie la shell y debe editar solamente las claves que administra. Noctalia v5 es la shell actual, pero no debe convertirse en una dependencia crítica. Otras shells podrán integrarse mediante adaptadores cuando exista una necesidad real.

## Etapa 4 — integraciones administradas

Objetivo: adoptar proyectos externos sólidos y aportar facilidad, diagnóstico y recuperación.

Primer caso validado:

- Noctalia Greeter + greetd.

Posibles funciones:

- instalar sin activar;
- verificar binarios, PAM, Polkit y configuración;
- sincronizar apariencia;
- seleccionar sesión válida;
- alternar display manager;
- restaurar SDDM;
- abrir logs;
- detectar errores de `TryExec`.

## Etapa 5 — instalador y reconstrucción

Objetivo: reproducir Cachy-caOS desde una instalación limpia.

- instalación por fases;
- validación de dependencias;
- estructura XDG correcta;
- registro de aplicaciones;
- selección opcional de shell e integraciones;
- backups previos;
- pruebas posteriores;
- rollback claro.

## Horizonte futuro

Nest debe evolucionar como plataforma de administración y no como una shell monolítica. Puede llegar a incluir una interfaz visual propia más avanzada, pero el Core debe seguir siendo utilizable aunque esa interfaz sea sustituida.

La prioridad será siempre:

1. estabilidad;
2. comprensión del sistema;
3. reversibilidad;
4. experiencia de usuario;
5. expansión de funciones.