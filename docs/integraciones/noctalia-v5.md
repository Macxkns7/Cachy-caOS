# Integración de Noctalia v5

**Estado:** Vigente con investigación abierta  
**Última revisión:** 2026-07-17

## Rol en Cachy-caOS

Noctalia v5 es la shell visual actual sobre Hyprland. Proporciona barra, launcher, dock, paneles, notificaciones, widgets, lockscreen, temas y servicios de interacción diaria.

Noctalia no forma parte del Core de Nest. Debe considerarse una implementación reemplazable conectada mediante un adaptador de integración.

El nombre conceptual de esta capa es:

```text
Noctalia Integration
```

Este patrón debe poder replicarse para otras shells sin modificar el Core:

```text
Nest Core
├── Noctalia Integration
├── Caelestia Integration
├── Shell futura Integration
└── fallback Hyprland / herramientas estándar
```

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

## IPC pública

Noctalia ofrece una interfaz de comandos mediante:

```text
noctalia msg <comando>
```

La instalación actual expone, entre otras, estas familias de acciones:

- paneles, launcher y ajustes;
- barra y dock;
- volumen, micrófono y reproducción multimedia;
- brillo;
- Wi-Fi y Bluetooth;
- capturas de pantalla;
- wallpaper, temas y plantillas;
- notificaciones;
- bloqueo, energía y sesión;
- plugins y widgets;
- perfiles de EasyEffects.

Comandos comprobados directamente:

```text
noctalia msg panel-toggle launcher
noctalia msg screenshot-region
noctalia msg screenshot-fullscreen all
```

El launcher fue validado correctamente con:

```text
noctalia msg panel-toggle launcher
```

Las capturas fueron validadas correctamente con:

```text
noctalia msg screenshot-region
noctalia msg screenshot-fullscreen all
```

La captura regional abre el selector de área y la captura completa funciona sin que estén instalados `grim`, `slurp`, `satty`, `swappy` ni `grimblast`. En esta instalación, por tanto, Nest no debe instalar esas herramientas por suposición.

Nest debe preferir esta IPC pública cuando exista y evitar modificar archivos internos de Noctalia sin necesidad.

## Modelo de integración

La responsabilidad debe separarse por capas:

```text
Nest
├── Nest Core
│   ├── estado declarativo
│   ├── diagnóstico
│   ├── backups y rollback
│   └── perfiles de integración
├── Adaptador Noctalia
│   ├── detección de versión y disponibilidad
│   ├── validación de IPC
│   ├── traducción de acciones de Nest a `noctalia msg`
│   ├── comprobación de dependencias externas
│   └── degradación controlada
└── Adaptador Hyprland
    ├── keybinds
    ├── ventanas
    ├── workspaces
    └── reglas del compositor
```

Nest no debe tratar a Noctalia como una dependencia absoluta. Debe detectar sus capacidades en tiempo de ejecución y habilitar únicamente las integraciones disponibles.

## Atajos y responsabilidades

Los bindings pertenecen al compositor. Noctalia expone acciones; Hyprland decide qué tecla las ejecuta.

Modelo correcto:

```text
tecla física
→ evento XKB/Wayland
→ binding de Hyprland
→ acción pública de Noctalia
```

Ejemplo validado:

```text
Super
→ Hyprland binding con release
→ noctalia msg panel-toggle launcher
```

Esto evita depender de launchers externos cuando Noctalia ya ofrece esa capacidad.

La instalación limpia observada incluía un binding hacia `hyprlauncher`, aunque el ejecutable no estaba instalado. La corrección fue reemplazarlo por la IPC oficial de Noctalia y añadir la apertura mediante la tecla Super al soltarla.

## Perfil Noctalia Standard

Nest debería poder ofrecer un perfil declarativo y reversible para funciones comunes:

```text
Super                 → launcher
captura regional      → screenshot-region
captura completa      → screenshot-fullscreen all
XF86Audio*            → volumen, mute y multimedia
XF86MonBrightness*    → brillo
```

El perfil debe definir acciones lógicas, no asumir que todos los teclados emiten las mismas teclas. En el Lenovo ThinkBook comprobado, la tecla física `ImpPt` tiene dos capas de firmware:

```text
ImpPt sola      → XF86SelectiveScreenshot → keycode XKB 642
Fn + ImpPt      → Print                   → keycode XKB 107
```

Los bindings funcionales en la configuración Lua de Hyprland quedaron como:

```lua
hl.bind("code:642", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("code:107", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen all"))
```

Estos códigos son específicos del evento observado y no deben convertirse en valores universales del perfil. Nest debe detectar o pedir confirmación del evento real del equipo antes de aplicarlos.

Este perfil no debe escribirse de forma opaca ni apropiarse de toda la configuración de Hyprland. Debe administrarse desde el módulo Keybinds y mostrar previamente los cambios y colisiones.

El perfil representa una propuesta de integración de Nest, no una obligación impuesta por Noctalia.

## Auditoría de capacidades

El adaptador debe distinguir al menos cuatro estados:

```text
1. Acción disponible y binding correcto
2. Acción disponible, pero sin binding
3. Binding presente, pero comando inexistente
4. Acción declarada, pero falta una dependencia externa
```

Ejemplos observados en la instalación limpia:

```text
Brillo:
- bindings presentes
- `brightnessctl` ausente
- corregido instalando la dependencia

Launcher:
- binding presente hacia `hyprlauncher`
- ejecutable ausente
- corregido usando `noctalia msg panel-toggle launcher`

Capturas:
- sin bindings funcionales al inicio
- sin grim, slurp, satty, swappy ni grimblast
- Noctalia expone y ejecuta sus acciones de captura
- bindings corregidos usando los keycodes XKB observados con `wev`
```

Nest Doctor no debe limitarse a comprobar si un comando existe. Debe comprender la relación entre tecla física, evento emitido, binding, proveedor de la acción y dependencia real.

## Diagnóstico de teclas especiales

Las teclas `Fn` no deben modelarse como un modificador universal. En muchos portátiles, el firmware transforma la combinación y emite un evento diferente, a veces incluso desde otro dispositivo de entrada.

En el ThinkBook comprobado:

```text
ImpPt sola
→ dispositivo: ideapad-extra-buttons
→ kernel/libinput: KEY_SELECTIVE_SCREENSHOT (634)
→ Wayland/XKB mediante wev: XF86SelectiveScreenshot, key 642

Fn + ImpPt
→ dispositivo: AT Translated Set 2 keyboard
→ kernel/libinput: KEY_SYSRQ (99), junto a KEY_WAKEUP
→ Wayland/XKB mediante wev: Print, key 107
```

El nombre `ideapad-extra-buttons` corresponde al controlador del kernel utilizado por Lenovo y no implica que el equipo sea necesariamente un IdeaPad.

Regla operativa:

> Para bindings `code:<n>` de Hyprland, la fuente de verdad debe ser el keycode mostrado por `wev`, no el código evdev mostrado por `libinput debug-events`.

`libinput` sigue siendo útil para identificar el dispositivo físico y el evento del kernel, pero sus números no deben copiarse directamente a `code:` en Hyprland.

## Fallback y degradación elegante

Cada acción integrada debe definir una cadena de resolución, por ejemplo:

```text
launcher:
1. Noctalia IPC
2. launcher configurado por el usuario
3. alternativa estándar disponible
4. diagnóstico sin aplicar cambios destructivos
```

```text
captura:
1. Noctalia IPC, si está operativa
2. backend Wayland configurado
3. sugerencia de instalación
4. estado no disponible claramente informado
```

Si Noctalia cambia o se reemplaza, los módulos del Core deben seguir funcionando. Solo el adaptador visual debe requerir ajustes.

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
- aplicación visual de temas;
- exposición de acciones mediante IPC.

### Hyprland

- registro de keybinds;
- ventanas y workspaces;
- reglas del compositor;
- ejecución de las acciones asociadas a teclas.

### Nest

- configuración declarativa del sistema;
- mantenimiento y diagnóstico;
- backups y rollback;
- instalación y migración;
- administración de módulos propios;
- perfiles de atajos;
- adaptadores hacia Noctalia y otras shells;
- selección del proveedor adecuado para cada acción.

## Capturas: validación completada

La instalación limpia comprobada no contiene:

```text
grim
slurp
satty
swappy
grimblast
```

Noctalia sí ejecuta correctamente:

```text
noctalia msg screenshot-region
noctalia msg screenshot-fullscreen all
```

Conclusiones:

- la captura regional y la captura completa están operativas;
- no fue necesario instalar un backend externo adicional;
- Nest debe probar primero la IPC disponible;
- una dependencia no debe instalarse solo porque sea habitual en otras configuraciones Wayland;
- siguen pendientes de documentar la ruta de guardado, portales, permisos de screencopy y comportamiento ante fallos internos.

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

La integración debe basarse en capacidades, no en suposiciones sobre una versión, fabricante o instalación concreta:

```text
detectar → consultar capacidades → validar → proponer → respaldar → aplicar → comprobar → poder revertir
```

Noctalia Integration será el primer adaptador de shell y el modelo de referencia para futuras integraciones.