# Timeline de Cachy-caOS

**Estado:** Vigente — registro histórico  
**Última revisión:** 2026-07-18

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

## 2026-07 — Integración de temas GTK de Noctalia

- Se investiga de extremo a extremo el sistema oficial de plantillas y temas de Noctalia v5.
- Se comprueba que `gtk3.css` genera una paleta semántica, pero no implementa reglas visuales de widgets.
- Se confirma que `apply.sh` delega el renderizado GTK3 en `adw-gtk3` o `adw-gtk3-dark` cuando el tema está disponible.
- Se determina que `adw-gtk-theme` es una dependencia funcional opcional de la integración GTK, no del núcleo de la shell.
- Se instala `adw-gtk-theme 6.5-1`, protegido por los snapshots 51 y 52.
- Se aplica el hook completo de Noctalia y el tema activo cambia de `Adwaita` a `adw-gtk3-dark`.
- Nemo adopta correctamente el modo oscuro, el fondo negro y el acento de la paleta activa.
- Se fija para Nest el modelo `paleta → adaptador del toolkit → extensión específica`, evitando inicialmente un fork completo de tema GTK.

Fuente técnica: `docs/integraciones/noctalia-temas-y-plantillas.md`.

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
