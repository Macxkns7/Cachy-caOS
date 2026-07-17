# Integración de Noctalia v5

**Estado:** Vigente con investigación abierta  
**Última revisión:** 2026-07-17

## Rol en Cachy-caOS

Noctalia v5 es la shell visual actual sobre Hyprland. Proporciona barra, launcher, dock, paneles, notificaciones, widgets, lockscreen, temas y servicios de interacción diaria.

Noctalia no forma parte del Core de Nest. Debe considerarse una implementación reemplazable conectada mediante un adaptador:

```text
Nest Core
├── Noctalia Integration
├── Caelestia Integration
├── Shell futura Integration
└── fallback Hyprland / herramientas estándar
```

Nest debe conservar las intenciones y capacidades aunque cambie la shell. El adaptador solo traduce esas intenciones a comandos públicos del proveedor activo.

## Principio de integración nativa

Antes de instalar una utilidad externa, Nest debe comprobar en este orden:

```text
1. ¿La shell o el sistema ya ofrecen la capacidad?
2. ¿Existe una interfaz pública y estable para invocarla?
3. ¿La implementación nativa satisface la necesidad?
4. ¿Existe ya una herramienta configurada por el usuario?
5. Solo entonces proponer una dependencia adicional.
```

Este principio evita duplicar launchers, gestores de portapapeles, selectores de caracteres, backends de captura y otros componentes pequeños que la shell ya resuelve.

La instalación de una dependencia no debe basarse en que sea habitual en otras configuraciones Wayland. Debe basarse en una carencia comprobada.

## Ubicaciones observadas

Configuración persistente principal:

```text
~/.local/state/noctalia/settings.toml
```

Datos y registros:

```text
~/.local/state/noctalia/
~/.cache/noctalia/noctalia.log
```

La configuración personal observada incluye barra, dock, idle, plugins, shell, tema, wallpaper y widgets.

## IPC pública

Noctalia expone acciones mediante:

```text
noctalia msg <comando> [argumentos]
```

La instalación actual ofrece familias de acciones para:

- paneles, launcher y ajustes;
- barra y dock;
- volumen, micrófono y reproducción multimedia;
- brillo;
- Wi-Fi y Bluetooth;
- capturas de pantalla;
- wallpapers, temas y plantillas;
- notificaciones;
- bloqueo, energía y sesión;
- plugins y widgets;
- perfiles de EasyEffects.

Nest debe consultar la ayuda de la versión instalada y validar los comandos en tiempo de ejecución:

```fish
noctalia msg --help
```

La documentación del adaptador no debe asumir que todas las versiones exponen las mismas acciones.

## Capacidades comprobadas

### Launcher de aplicaciones

```text
noctalia msg panel-toggle launcher
```

Funciona correctamente y reemplazó un binding anterior hacia `hyprlauncher`, cuyo ejecutable no estaba instalado.

### Selector nativo de caracteres

```text
noctalia msg panel-toggle launcher /emo
```

Abre el launcher directamente en el selector de emojis y caracteres. La integración fue validada visual y funcionalmente.

Esto permite resolver la capacidad lógica:

```text
character-picker.toggle
```

sin instalar Walker, Rofi u otro selector adicional.

No debe modelarse como una función inseparable de Noctalia. Debe registrarse como una capacidad con proveedor intercambiable:

```text
capacidad: character-picker.toggle
proveedor: noctalia
comando: noctalia msg panel-toggle launcher /emo
fallback posible: selector configurado por el usuario
```

### Selector nativo de wallpapers

El contexto `/wall` también fue comprobado manualmente desde el launcher:

```text
noctalia msg panel-toggle launcher /wall
```

Otros contextos hipotéticos como `/calc` o `/clipboard` no funcionaron en la versión probada y no deben documentarse como capacidades disponibles.

### Captura regional

```text
noctalia msg screenshot-region
```

Abre correctamente el selector interactivo de región.

### Captura completa

```text
noctalia msg screenshot-fullscreen all
```

Captura correctamente todos los monitores.

La instalación limpia comprobada no contiene:

```text
grim
slurp
satty
swappy
grimblast
```

Noctalia ejecuta ambas capturas sin esas herramientas, por lo que Nest no debe instalarlas por suposición.

### Centro de notificaciones

La IPC expone acciones de gestión de notificaciones y paneles genéricos. La apertura del panel de notificaciones mediante una tecla dedicada queda como siguiente validación.

La acción lógica prevista es:

```text
notification-center.toggle
```

El comando definitivo debe obtenerse y probarse antes de documentarlo como funcional.

## Modelo de integración

```text
Nest
├── Nest Core
│   ├── catálogo de capacidades
│   ├── estado declarativo
│   ├── diagnóstico
│   ├── backups y rollback
│   └── perfiles de integración
├── Adaptador Noctalia
│   ├── detección de versión
│   ├── descubrimiento de IPC
│   ├── validación de capacidades
│   ├── traducción de acciones lógicas
│   ├── comprobación de dependencias
│   └── degradación controlada
└── Adaptador Hyprland
    ├── keybinds
    ├── ventanas
    ├── workspaces
    └── reglas del compositor
```

Nest no debe tratar a Noctalia como dependencia absoluta. Debe habilitar únicamente las integraciones que realmente estén disponibles.

## Atajos y responsabilidades

Los bindings pertenecen al compositor. Noctalia expone acciones y Hyprland decide qué evento las ejecuta.

```text
tecla física
→ evento XKB/Wayland
→ binding de Hyprland
→ acción lógica de Nest
→ proveedor activo
→ comando público de Noctalia
```

Ejemplos validados:

```text
Super al soltar
→ launcher.toggle
→ noctalia msg panel-toggle launcher

tecla física F9 del ThinkBook
→ evento XKB Help
→ character-picker.toggle
→ noctalia msg panel-toggle launcher /emo
```

Esta separación permite sustituir Noctalia por otra shell conservando la intención del atajo.

## Perfil Noctalia Standard

Primer conjunto de capacidades propuestas:

```text
launcher.toggle              → Noctalia launcher
character-picker.toggle      → Noctalia launcher /emo
screenshot.region            → screenshot-region
screenshot.fullscreen        → screenshot-fullscreen all
audio.*                      → IPC multimedia
brightness.*                 → IPC o backend validado
notification-center.toggle   → pendiente de validar
```

El perfil debe definir acciones lógicas, no keycodes universales.

## Teclas comprobadas en Lenovo ThinkBook

### Capturas

```text
ImpPt sola      → XF86SelectiveScreenshot → keycode XKB 642
Fn + ImpPt      → Print                   → keycode XKB 107
```

Bindings funcionales:

```lua
hl.bind("code:642", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("code:107", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen all"))
```

### F9 física: selector de caracteres

La tecla rotulada por Lenovo para ayuda genera:

```text
wev/XKB: Help
keycode XKB: 146
```

Binding funcional:

```lua
-- Character Picker
hl.bind("Help", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher /emo"))
```

La leyenda física de una tecla no determina su evento ni su intención futura. Nest debe descubrir el evento real y luego proponer una asignación.

### F12 física: calculadora

La tecla genera:

```text
wev/XKB: XF86Calculator
keycode XKB: 148
```

Se instaló `galculator` como proveedor externo ligero porque Noctalia no expone una calculadora autónoma comprobada.

Binding funcional:

```lua
-- Calculator Key
hl.bind("XF86Calculator", hl.dsp.exec_cmd("galculator"))
```

La capacidad lógica debe registrarse como:

```text
calculator.open
```

Noctalia no es el proveedor en este caso; Hyprland ejecuta una aplicación externa elegida por el usuario.

## Auditoría de capacidades

El adaptador debe distinguir al menos:

```text
1. capacidad disponible y binding correcto
2. capacidad disponible, pero sin binding
3. binding presente, pero proveedor inexistente
4. proveedor presente, pero falta una dependencia
5. capacidad nativa disponible, pero duplicada por una utilidad externa
6. contexto o comando documentado, pero no soportado por la versión instalada
```

Casos reales:

```text
Brillo:
- bindings presentes
- brightnessctl ausente
- reparación: instalar dependencia requerida

Launcher:
- binding hacia hyprlauncher
- ejecutable ausente
- reparación: IPC nativa de Noctalia

Capturas:
- sin bindings funcionales
- Noctalia ya ofrecía las acciones
- reparación: bindings contra eventos observados con wev

Character Picker:
- capacidad nativa encontrada en launcher /emo
- no se instaló Walker
- reparación: binding Help hacia IPC nativa

Calculadora:
- tecla XF86Calculator detectada
- no existía proveedor instalado
- solución: Galculator + binding explícito
```

Nest Doctor debe comprender la relación entre tecla física, evento, binding, acción lógica, proveedor y dependencia real.

## Diagnóstico de teclas especiales

`Fn` no debe modelarse como un modificador universal. En muchos portátiles el firmware transforma la combinación y emite otro evento, incluso desde otro dispositivo.

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

Regla operativa:

> Para bindings `code:<n>` de Hyprland, la fuente de verdad es el keycode mostrado por `wev`, no el código evdev mostrado por `libinput debug-events`.

`libinput` sigue siendo útil para identificar el dispositivo y el evento del kernel.

## Fallback y degradación elegante

Cada capacidad debe definir una cadena de resolución. Ejemplo:

```text
character-picker.toggle:
1. Noctalia launcher /emo
2. proveedor configurado por el usuario
3. alternativa estándar disponible
4. sugerencia de instalación
5. estado no disponible claramente informado
```

```text
screenshot.region:
1. Noctalia IPC
2. backend Wayland configurado
3. sugerencia de instalación
4. diagnóstico sin cambios destructivos
```

Si Noctalia cambia o se reemplaza, solo debe modificarse el adaptador.

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

La configuración observada utiliza fuentes oficiales y comunitarias. Entre los plugins probados están Wallhaven y mpvpaper.

Nest no debe copiar el sistema de plugins. Puede mostrar estado, instalar o actualizar mediante comandos oficiales, respaldar configuración, diagnosticar errores y ofrecer accesos directos.

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
- ejecución de acciones asociadas a eventos.

### Nest

- catálogo de capacidades;
- configuración declarativa;
- mantenimiento y diagnóstico;
- backups y rollback;
- instalación y migración;
- perfiles de atajos;
- adaptadores de shell;
- selección del proveedor adecuado;
- prevención de dependencias redundantes.

## Investigación abierta: iconos del dock

El launcher encuentra archivos `.desktop` e iconos, pero algunas aplicaciones abiertas aparecen sin icono en el dock.

Casos observados:

```text
Nest UI class: nest-ui
ChatGPT class: vivaldi-chatgpt.com__-Default
YouTube class: vivaldi-www.youtube.com__-Default
```

Líneas de investigación:

- relación entre `app_id`/class y desktop entry;
- `StartupWMClass`;
- cachés de aplicaciones y dock;
- diferencias entre aplicaciones nativas y ventanas Vivaldi;
- aliases manuales;
- comportamiento de versiones beta de Noctalia v5.

## Regla para Nest

```text
detectar hardware
→ descubrir capacidades del proveedor
→ validar comandos
→ proponer acciones
→ mostrar dependencias y colisiones
→ respaldar
→ aplicar
→ comprobar
→ poder revertir
```

Noctalia Integration será el primer adaptador de shell y el modelo de referencia para futuras integraciones.