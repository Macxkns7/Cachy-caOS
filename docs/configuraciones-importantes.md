# Configuraciones importantes

**Estado:** Vigente  
**Última revisión:** 2026-07-19  
**Histórico relacionado:** `docs/historico/era-omarchy/configuraciones-importantes-2026-06-20.md`

## Objetivo

Registrar las configuraciones críticas que permiten mantener, diagnosticar y reconstruir Cachy-caOS sin depender de la memoria.

## Base gráfica

- Compositor: Hyprland.
- Shell actual: Noctalia v5.
- Launcher y paneles: provistos actualmente por Noctalia.
- Terminal: Kitty.
- Shell interactiva: Fish.

Nest debe permanecer desacoplado de Noctalia para permitir sustituir la shell sin alterar el Core.

## Terminal Kitty

Estado comprobado:

- archivo principal: `~/.config/kitty/kitty.conf`;
- temas cargados mediante `include`;
- tamaño de fuente personalizado: `font_size 9.5`;
- fuente efectiva observada: Noto Sans Mono;
- backend: Wayland nativo.

La configuración efectiva puede inspeccionarse desde Kitty y solo muestra como diferencias las opciones que no coinciden con los valores predeterminados. Por ello, una prueba de configuración no debe utilizar exactamente el valor por defecto.

Las preferencias personales, como tamaño o familia de fuente, deben vivir fuera de los archivos generados por el sistema de temas para evitar que Noctalia las sobrescriba.

## Integración visual GTK

Estado comprobado:

- paquete de integración GTK3: `adw-gtk-theme 6.5-1`;
- tema GTK activo: `adw-gtk3-dark`;
- tema claro disponible: `/usr/share/themes/adw-gtk3`;
- tema oscuro disponible: `/usr/share/themes/adw-gtk3-dark`;
- paleta GTK3 generada por Noctalia: `~/.config/gtk-3.0/noctalia.css`;
- import de usuario: `~/.config/gtk-3.0/gtk.css`.

Contenido esperado del import:

```css
@import url("noctalia.css");
```

Comprobación del tema activo:

```fish
gsettings get org.gnome.desktop.interface gtk-theme
```

Resultado esperado en modo oscuro:

```text
'adw-gtk3-dark'
```

Aplicación completa de la integración:

```fish
/usr/share/noctalia/assets/templates/gtk/apply.sh dark
```

No utilizar `--appearance-only` para seleccionar el tema GTK: esa opción sincroniza solamente el esquema claro u oscuro.

Fuente canónica: `docs/integraciones/noctalia-temas-y-plantillas.md`.

## Iconos del sistema

Estado comprobado:

- paquete: `papirus-icon-theme`;
- tema GTK: `Papirus-Dark`;
- proveedor Qt 6: `qt6ct`;
- tema Qt: `Papirus-Dark`;
- estilo Qt conservado: `Fusion`;
- entorno de sesión: `QT_QPA_PLATFORMTHEME=qt6ct`;
- variante de carpetas: `violet`;
- utilidad local: `~/.local/bin/papirus-folders` v1.14.0.

Configuración GTK:

```fish
gsettings get org.gnome.desktop.interface icon-theme
```

Resultado esperado:

```text
'Papirus-Dark'
```

Configuración Qt:

```text
~/.config/qt6ct/qt6ct.conf
```

Claves esperadas:

```ini
icon_theme=Papirus-Dark
style=Fusion
```

Persistencia en `~/.config/hypr/hyprland.lua`:

```lua
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
```

La variable debe declararse antes del evento que inicia Noctalia. El color de carpetas puede repararse después de una actualización mediante:

```fish
papirus-folders -Ru
```

Fuente canónica: `docs/modulos/iconos-sistema.md`.

## Visualizador de imágenes

Estado comprobado:

- aplicación oficial: Loupe;
- paquete validado: `loupe 50.0-1.1`;
- repositorio: `cachyos-extra-v4`;
- arquitectura: `x86_64_v4`;
- Desktop ID: `org.gnome.Loupe.desktop`;
- integración: GTK4 + libadwaita;
- apertura desde Nemo: validada;
- personalización CSS específica: no requerida actualmente.

Asociación predeterminada esperada para JPEG:

```fish
xdg-mime query default image/jpeg
```

Resultado:

```text
org.gnome.Loupe.desktop
```

Verificación alternativa:

```fish
gio mime image/jpeg
```

Los MIME de imagen administrados actualmente son:

```text
image/jpeg
image/png
image/webp
image/gif
image/bmp
image/tiff
image/svg+xml
image/avif
image/heif
```

La instalación inicial detectó `gmic_qt.desktop` como predeterminado para JPEG. La corrección se realizó mediante `xdg-mime` y no requirió modificar Nemo.

Nest deberá separar la instalación de Loupe de un módulo central para asociaciones MIME.

Fuente canónica: `docs/modulos/visor-imagenes.md`.

## Krita y compatibilidad Wayland

Estado comprobado:

- paquete: `krita 6.0.2.1-2.1`;
- repositorio: `cachyos-extra-v4`;
- arquitectura: `x86_64_v4`;
- la ejecución normal presentaba una interfaz borrosa por XWayland;
- la ejecución con `QT_QPA_PLATFORM=wayland` fue validada como nítida;
- no fue necesario reemplazar el paquete por AppImage o Flatpak.

Override local activo:

```text
~/.local/share/applications/org.kde.krita.desktop
```

Línea de lanzamiento efectiva:

```ini
Exec=env QT_QPA_PLATFORM=wayland krita %F
```

Después de modificar una Desktop Entry local se actualiza la base XDG:

```fish
update-desktop-database ~/.local/share/applications
```

No exportar globalmente `QT_QPA_PLATFORM=wayland`. Las variables de compatibilidad deben aplicarse por aplicación y solo después de una validación comparativa.

Fuente canónica: `docs/modulos/krita-wayland.md`.

## Inicio de sesión

- Display manager: greetd.
- Greeter: Noctalia Greeter.
- Sesión válida actual: `Hyprland`.
- Evitar `Hyprland (uwsm-managed)` mientras `uwsm` no esté instalado.
- TTY de recuperación: `getty@tty2.service` habilitado.
- SDDM no está instalado; cualquier fallback alternativo debe instalarse antes de cambiar servicios.

Documentación detallada: `docs/integraciones/noctalia-greeter.md`.

## Identidad de aplicaciones

Las aplicaciones y WebApps deben mantener coherencia entre:

- nombre del archivo `.desktop`;
- `Icon=`;
- `StartupWMClass=` cuando corresponda;
- `class` o `app_id` real de la ventana;
- iconos instalados en rutas estándar.

Los overrides de lanzamiento administrados por el usuario deben vivir en `~/.local/share/applications/` y nunca modificar directamente los archivos pertenecientes a paquetes en `/usr/share/applications/`.

Este punto está bajo investigación por el comportamiento del dock de Noctalia.

## Teclado y shell

- Layout principal: LATAM.
- Los procedimientos interactivos deben escribirse para Fish o indicar explícitamente cuando requieren Bash.
- Nest debe detectar Fish, Bash o Zsh antes de generar comandos para copiar.

## Audio y energía

- EasyEffects disponible para perfiles de audio.
- La instalación actual utiliza el gestor de energía predeterminado de CachyOS.
- La configuración anterior basada en `auto-cpufreq` pertenece a una instalación histórica y no debe aplicarse al sistema vigente.
- El apartado de audio permanece en revisión operativa.

## WebApps

- Backend propio `cachycaos-webapp`.
- Navegador actual: Vivaldi.
- Los `.desktop`, iconos y clases deben ser gestionados como una unidad.

## Seguridad y recuperación

- Btrfs + Snapper.
- Snapshot antes de cambios de alto impacto.
- Mantener backup previo al modificar PAM, display manager o archivos del sistema.
- Toda migración debe incluir una ruta de rollback comprobable.
- La instalación de `adw-gtk-theme` quedó protegida por los snapshots 51 y 52.
- Los cambios de Desktop Entries deben realizarse mediante overrides locales reversibles.

## Limpieza y estado de dependencias

Estado validado el 2026-07-20:

- 92 paquetes netos retirados;
- cero huérfanos;
- cero servicios fallidos;
- 141 archivos de caché de paquetes desinstalados retirados;
- 438.28 MiB recuperados de caché;
- Nemo predeterminado para `inode/directory`;
- mpv predeterminado para `video/mp4` y `audio/mpeg`;
- greetd activo y habilitado;
- SDDM, Dolphin, VLC, Alacritty, Shelly y herramientas redundantes retirados;
- `wlroots0.20` y `libliftoff` instalados por dependencia runtime del greeter.

Comprobación crítica:

```fish
ldd /usr/bin/noctalia-greeter-compositor | grep -E 'wlroots|not found'
```

Resultado esperado:

```text
libwlroots-0.20.so => /usr/lib/libwlroots-0.20.so
```

Fuente canónica: `docs/modulos/limpieza-sistema.md`.

## Regla operativa

```text
Diagnóstico → respaldo → cambio mínimo → verificación → documentación
```
