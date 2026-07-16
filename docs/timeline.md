# Timeline de Cachy-caOS

**Estado:** Vigente — registro histórico  
**Última revisión:** 2026-07-16

## Propósito

Registrar cronológicamente la evolución de Cachy-caOS sin confundir decisiones históricas con la arquitectura vigente.

## 2026-05 — Migración Ubuntu → CachyOS

- Abandono de Ubuntu como sistema principal.
- Adopción de CachyOS por rendimiento, control y personalización.
- Inicio de la cultura de documentación y snapshots.

## 2026-05 — Era Omarchy

- Omarchy se adopta como base inicial del escritorio.
- Hyprland, Waybar y Walker pasan a formar el entorno principal.
- Se traducen y personalizan componentes al español.
- Se crean temas, wallpapers, PWAs y ajustes de teclado/audio.

Esta etapa queda preservada en `docs/historico/era-omarchy/`.

## 2026-06 — Formalización del proyecto

- Creación del repositorio Cachy-caOS.
- Registro de decisiones, configuraciones y guía de reconstrucción.
- Consolidación de Btrfs + Snapper como mecanismo de recuperación.
- Pruebas y posterior eliminación de Waydroid.
- Personalización de SDDM.

## 2026-06 / 2026-07 — Herramientas propias

- Creación del repositorio Liss para contexto y memoria del proyecto.
- Nacimiento del concepto BFG Control Center.
- Desarrollo de módulos propios para WebApps y keybinds.
- Inicio de Nest UI como centro de administración.

## 2026-07 — Independencia de Omarchy

- Decisión de abandonar Omarchy como dependencia estructural.
- CachyOS limpio + Hyprland limpio pasan a ser la base oficial.
- Se conservan aprendizajes y componentes útiles, pero bajo control propio.
- Nest se redefine como plataforma estable y modular, no como shell.

## 2026-07 — Noctalia v5

- Noctalia se adopta como shell actual.
- Se establece que la shell debe ser reemplazable y no formar parte del Core.
- Se investigan otras shells y la dirección futura del ecosistema Wayland.

## 2026-07 — Noctalia Greeter

- Se estudia su arquitectura antes de instalarlo.
- Se compila e instala Noctalia Greeter.
- Se migra de SDDM a greetd.
- Se resuelven requisitos de PAM y Polkit.
- Se detecta una sesión `Hyprland (uwsm-managed)` inválida cuando `uwsm` no está instalado.
- Se valida el inicio exitoso mediante la sesión `Hyprland`.

## 2026-07 — Refactorización documental

- README actualizado con la dirección independiente de Omarchy.
- Creación de documentación canónica de Nest, metodología, roadmap, research e integraciones.
- Separación explícita entre documentación vigente e histórica.
- Inicio de una política de estados y revisiones documentales.

## Regla de mantenimiento

Los eventos nuevos deben añadirse aquí solo cuando cambien el estado, la dirección o el conocimiento reproducible del proyecto. Los detalles diarios deben vivir en documentos técnicos o changelogs específicos.