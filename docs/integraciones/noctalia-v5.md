# Integración de Noctalia v5

**Estado:** Vigente con investigación abierta  
**Última revisión:** 2026-07-16

## Rol en Cachy-caOS

Noctalia v5 es la shell visual actual sobre Hyprland. Proporciona barra, launcher, dock, paneles, notificaciones, widgets, lockscreen, temas y servicios de interacción diaria.

Noctalia no forma parte del Core de Nest. Debe considerarse una implementación reemplazable conectada mediante adaptadores.

## Ubicaciones observadas

Configuración persistente principal:

```text
~/.local/state/noctalia/settings.toml
```

Otros datos aparecen bajo:

```text
~/.local/state/noctalia/
~/.cache/noctalia/noctalia.log
```

La configuración personal actualmente incluye barra, dock, idle, plugins, shell, tema, wallpaper y widgets.

## Comandos de administración

Noctalia ofrece IPC mediante:

```text
noctalia msg <comando>
```

Capacidades útiles para una futura integración con Nest:

- `config-reload`;
- `dock-show`, `dock-hide`, `dock-toggle`, `dock-reload`;
- `settings-open` y `settings-toggle`;
- `panel-open` y `panel-toggle`;
- control de Wi-Fi, Bluetooth, brillo y volumen;
- sincronización del greeter;
- gestión de plugins;
- wallpaper y temas;
- sesión, bloqueo y energía.

Nest debe usar IPC público cuando exista y evitar modificar internamente archivos de Noctalia sin necesidad.

## Agente Polkit

Noctalia v5 incluye un agente Polkit propio, deshabilitado por defecto en algunas configuraciones:

```toml
[shell]
polkit_agent = true
```

Fue necesario activarlo desde Ajustes para autorizar la sincronización de Noctalia Greeter.

Nest Doctor debe comprobar:

- `polkitd` activo;
- agente gráfico disponible;
- ausencia de agentes duplicados;
- capacidad de ejecutar acciones privilegiadas mediante `pkexec`.

## Plugins y widgets

La configuración actual utiliza fuentes oficiales y comunitarias de plugins. Entre los plugins observados están Wallhaven y mpvpaper.

Nest no debe copiar el sistema de plugins de Noctalia. Puede:

- mostrar estado;
- instalar o actualizar mediante comandos oficiales;
- respaldar configuración;
- diagnosticar errores;
- ofrecer accesos directos a ajustes.

## Separación de responsabilidades

### Noctalia

- experiencia visual;
- barra, dock y launcher;
- paneles y widgets;
- notificaciones;
- lockscreen;
- aplicación visual de temas.

### Nest

- configuración declarativa del sistema;
- mantenimiento y diagnóstico;
- backups y rollback;
- instalación y migración;
- administración de módulos propios;
- adaptadores hacia Noctalia y otras shells.

## Investigación abierta: iconos del dock

El launcher encuentra correctamente archivos `.desktop` e iconos, pero algunas aplicaciones abiertas aparecen sin icono en el dock.

Casos observados:

- Nest UI con clase `nest-ui`;
- WebApps Vivaldi con clases por dominio;
- ChatGPT y YouTube muestran icono en launcher pero no siempre en dock.

Datos relevantes:

```text
Nest UI class: nest-ui
ChatGPT class: vivaldi-chatgpt.com__-Default
YouTube class: vivaldi-www.youtube.com__-Default
```

Los `.desktop` de las WebApps usan iconos absolutos. Nest UI usa `Icon=nest-ui` instalado en el tema hicolor.

Líneas de investigación:

- cómo Noctalia relaciona `app_id`/class con desktop entry;
- respeto de `StartupWMClass`;
- cachés de aplicaciones y dock;
- diferencias entre aplicaciones nativas y ventanas Vivaldi;
- posible configuración manual de aliases;
- comportamiento de versiones beta de Noctalia v5.

## Regla para Nest

Las integraciones deben degradarse con elegancia: si Noctalia cambia o se reemplaza, los módulos del Core deben seguir funcionando y solamente el adaptador visual requerir ajustes.
