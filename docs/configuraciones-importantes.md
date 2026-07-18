# Configuraciones importantes

**Estado:** Vigente  
**Última revisión:** 2026-07-18  
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

## Inicio de sesión

- Display manager: greetd.
- Greeter: Noctalia Greeter.
- Sesión válida actual: `Hyprland`.
- Evitar `Hyprland (uwsm-managed)` mientras `uwsm` no esté instalado.
- TTY de recuperación: `getty@tty2.service` habilitado.

Documentación detallada: `docs/integraciones/noctalia-greeter.md`.

## Identidad de aplicaciones

Las aplicaciones y WebApps deben mantener coherencia entre:

- nombre del archivo `.desktop`;
- `Icon=`;
- `StartupWMClass=` cuando corresponda;
- `class` o `app_id` real de la ventana;
- iconos instalados en rutas estándar.

Este punto está bajo investigación por el comportamiento del dock de Noctalia.

## Teclado y shell

- Layout principal: LATAM.
- Los procedimientos interactivos deben escribirse para Fish o indicar explícitamente cuando requieren Bash.
- Nest debe detectar Fish, Bash o Zsh antes de generar comandos para copiar.

## Audio y energía

- EasyEffects disponible para perfiles de audio.
- La instalación actual utiliza el gestor de energía predeterminado de CachyOS.
- La configuración anterior basada en `auto-cpufreq` pertenece a una instalación histórica y no debe aplicarse al sistema vigente.

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

## Regla operativa

```text
Diagnóstico → respaldo → cambio mínimo → verificación → documentación
```