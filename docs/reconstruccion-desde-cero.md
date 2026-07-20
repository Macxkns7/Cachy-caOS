# Reconstrucción desde cero

**Estado:** Vigente, en desarrollo  
**Última revisión:** 2026-07-16  
**Histórico relacionado:** `docs/historico/era-omarchy/reconstruccion-desde-cero-2026-06-20.md`

## Objetivo

Definir una ruta reproducible para reconstruir Cachy-caOS sin depender de Omarchy ni de conocimiento escondido en conversaciones.

## Fase 0 — Preparación

- Respaldar repositorios y configuraciones personales.
- Confirmar acceso a GitHub.
- Guardar lista de paquetes y servicios.
- Confirmar snapshots o backup externo.

## Fase 1 — Sistema base

- Instalar CachyOS limpio.
- Usar Btrfs cuando sea posible.
- Configurar red, usuario, sudo y repositorios.
- Instalar Hyprland desde paquetes del sistema.

## Fase 2 — Sesión gráfica mínima

Validar antes de personalizar:

- Hyprland inicia correctamente.
- Kitty funciona.
- Fish está disponible como shell interactiva.
- Audio, brillo, red, Bluetooth y energía responden.

## Fase 3 — Shell

- Instalar o configurar Noctalia v5 como shell actual.
- Mantener el sistema base independiente de la shell.
- No copiar dependencias de Omarchy salvo que se adopten explícitamente como módulos propios.

## Fase 4 — Login

- Instalar greetd.
- Compilar o instalar Noctalia Greeter mediante su ruta oficial.
- Validar PAM, Polkit, wrapper, compositor, assets y logs.
- Mantener una TTY de recuperación.
- Seleccionar la sesión `Hyprland` mientras `uwsm` no esté disponible.

Consultar: `docs/integraciones/noctalia-greeter.md`.

## Fase 5 — Nest Core y Nest UI

- Instalar la estructura de Cachy-caOS en rutas definidas.
- Validar el lanzador principal de Nest.
- Instalar su `.desktop` e icono.
- Activar módulos uno a uno, sin acoplarlos a Noctalia.

## Fase 6 — Módulos propios

Prioridad inicial:

1. WebApps.
2. Keybinds.
3. System Doctor.
4. Backups y snapshots.
5. Display Manager.
6. Adaptador de shell.

## Fase 7 — Configuración personal

- Layout LATAM.
- EasyEffects.
- auto-cpufreq.
- Tema y wallpaper.
- `papirus-icon-theme` y `qt6ct` desde repositorios oficiales.
- `Papirus-Dark` aplicado en GTK y Qt.
- `QT_QPA_PLATFORMTHEME=qt6ct` cargado antes de Noctalia.
- Papirus Folders v1.14.0 y variante `violet` como perfil validado.
- Verificación y rollback según `docs/modulos/iconos-sistema.md`.
- Vivaldi y perfiles de navegación.

## Fase 8 — Seguridad

- Verificar que binarios instalados manualmente tengan todas sus bibliotecas runtime.
- Confirmar `ldd /usr/bin/noctalia-greeter-compositor` sin entradas `not found`.
- Conservar `wlroots0.20` y `libliftoff` mientras el greeter continúe instalado manualmente.

- Configurar Snapper.
- Establecer límites de snapshots.
- Crear snapshot antes y después de migraciones críticas.
- Documentar rollback de cada integración del sistema.

## Fase 9 — Validación final

Comprobar:

- `systemctl --failed` sin errores relevantes.
- login y logout funcionales;
- Hyprland y Noctalia operativos;
- Nest y módulos propios funcionales;
- WebApps con iconos e identidad correctos;
- snapshots disponibles;
- documentación sincronizada con el estado real.

## Pendientes

Esta guía seguirá evolucionando hasta convertirse en la base del instalador de Cachy-caOS/Nest. Ninguna fase debe automatizarse por completo antes de ser reproducida manualmente y documentada.

Fuente de auditoría y limpieza: `docs/modulos/limpieza-sistema.md`.
