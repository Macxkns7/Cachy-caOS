# Configuraciones importantes

**Estado:** Vigente  
**Última revisión:** 2026-07-16  
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
- auto-cpufreq administra energía.
- `power-profiles-daemon` no debe competir con auto-cpufreq.

## WebApps

- Backend propio `cachycaos-webapp`.
- Navegador actual: Vivaldi.
- Los `.desktop`, iconos y clases deben ser gestionados como una unidad.

## Seguridad y recuperación

- Btrfs + Snapper.
- Snapshot antes de cambios de alto impacto.
- Mantener backup previo al modificar PAM, display manager o archivos del sistema.
- Toda migración debe incluir una ruta de rollback comprobable.

## Regla operativa

```text
Diagnóstico → respaldo → cambio mínimo → verificación → documentación
```