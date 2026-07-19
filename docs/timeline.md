# Timeline de Cachy-caOS

**Estado:** Vigente — registro histórico  
**Última revisión:** 2026-07-19

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

## 2026-07 — Loupe como visualizador de imágenes

- Se comparan visores modernos y se adopta Loupe como opción oficial para Cachy-caOS.
- Se instala `loupe 50.0-1.1` desde `cachyos-extra-v4` para arquitectura `x86_64_v4`.
- Se valida su integración GTK4/libadwaita con Noctalia, su apertura inmediata y su navegación fluida.
- Nemo conserva inicialmente `gmic_qt.desktop` como aplicación predeterminada para JPEG.
- Se diagnostica la asociación mediante `xdg-mime` y `gio mime`.
- Se asigna `org.gnome.Loupe.desktop` a los MIME de imagen comunes y se valida la apertura directa desde Nemo.
- Nest adopta la separación entre instalación de aplicaciones y administración centralizada de asociaciones MIME.

Fuente técnica: `docs/modulos/visor-imagenes.md`.

## 2026-07 — Kitty y comodidad visual

- Se comprueba que Kitty cargaba correctamente `~/.config/kitty/kitty.conf` y los temas de Noctalia.
- Se identifica que `font_size 11.0` coincidía con el valor predeterminado y por ello no aparecía entre las opciones diferentes del valor por defecto.
- Se establece `font_size 9.5` como preferencia local validada.
- Se confirma que las preferencias personales deben permanecer separadas de los archivos de tema generados.

## 2026-07 — Krita en Wayland nativo

- Se observa desenfoque general en la pantalla de carga y en toda la interfaz de Krita 6.0.2.1.
- Se confirma que la sesión del sistema usa Wayland y que no existen variables globales de Qt alterando el lanzamiento.
- La prueba `QT_QPA_PLATFORM=wayland krita` elimina inmediatamente el desenfoque.
- Se determina que la ejecución normal utilizaba XWayland y que el paquete de CachyOS no estaba roto.
- Se crea un override local de `org.kde.krita.desktop` en `~/.local/share/applications/`.
- La línea `Exec` se modifica para aplicar `QT_QPA_PLATFORM=wayland` únicamente a Krita.
- Se actualiza la base XDG y se valida la apertura nítida desde el launcher.
- Nest incorpora como patrón futuro la administración reversible de overrides XDG y compatibilidad Wayland por aplicación.

Fuente técnica: `docs/modulos/krita-wayland.md`.

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
- Creación de `TABLERO-MAESTRO.md` como fuente operativa para sesiones, prioridades y tareas pendientes.

## Regla de mantenimiento

Los eventos nuevos deben añadirse aquí solo cuando cambien el estado, la dirección o el conocimiento reproducible del proyecto. Los detalles diarios deben vivir en documentos técnicos o changelogs específicos.
