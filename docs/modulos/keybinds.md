# Módulo Keybinds

**Estado:** En desarrollo y funcional  
**Última revisión:** 2026-07-17

## Propósito

Administrar atajos de Hyprland desde Nest sin convertir la configuración del usuario en un archivo opaco ni sobrescribir personalizaciones manuales.

El módulo también debe auditar que cada binding apunte a una acción realmente disponible y comprender cuándo esa acción pertenece a una shell integrada, a Hyprland o a una herramienta externa.

## Estado actual

Existe un módulo funcional bajo una estructura similar a:

```text
~/.local/share/cachycaos/modules/keybinds/app.sh
```

Durante el desarrollo también existieron rutas anteriores y respaldos de migración, entre ellas:

```text
~/.local/share/cachycaos/keybinds/app.sh
~/.local/share/cachycaos/backups/
~/.local/share/cachycaos/modules/keybinds/backups/
```

La coexistencia de estas rutas refleja la reorganización hacia una plataforma modular y debe resolverse en el instalador final.

## Objetivos funcionales

- listar atajos relevantes;
- añadir nuevos atajos;
- modificar atajos administrados;
- detectar colisiones;
- comprobar que la acción asociada existe;
- detectar teclas multimedia importantes sin binding;
- distinguir acciones de Hyprland, de una shell y de herramientas externas;
- conservar comentarios y configuración no administrada;
- crear respaldo antes de escribir;
- recargar Hyprland únicamente tras una validación correcta;
- restaurar la versión previa si la recarga falla.

## Principio de propiedad

Nest no debe apropiarse de todo `hyprland.conf` ni del archivo Lua principal.

La estrategia recomendada es mantener un archivo administrado y explícitamente incluido por la configuración principal, por ejemplo:

```text
~/.config/hypr/conf.d/nest-keybinds.conf
```

Así se separan:

- configuración personal;
- configuración de la shell;
- atajos administrados por Nest.

La ruta definitiva debe decidirse después de auditar la estructura limpia de Hyprland usada por Cachy-caOS y la forma correcta de integrar archivos declarativos con la configuración Lua actual.

## Modelo de acción

Un keybind no debe almacenarse solamente como texto. Debe representarse como datos verificables:

```text
id
tecla física esperada
evento XKB observado
keycode XKB, cuando sea necesario
modificadores
evento: press | release | repeat
acción lógica
proveedor preferido
comando resuelto
dependencias
origen: usuario | Nest | shell | sistema
perfil
estado de validación
```

Ejemplo conceptual:

```text
id: launcher
tecla: SUPER_L
evento: release
acción lógica: launcher.toggle
proveedor preferido: noctalia
comando resuelto: noctalia msg panel-toggle launcher
origen: Nest
perfil: Noctalia Standard
```

La acción lógica permite cambiar de proveedor sin rediseñar todo el perfil.

## Integración con shells

El módulo Keybinds registra las teclas en Hyprland. Los adaptadores de shell resuelven qué comando público ejecuta cada acción.

```text
Keybinds
→ acción lógica
→ adaptador de shell
→ comando público
```

Para Noctalia, la fuente canónica es:

```text
docs/integraciones/noctalia-v5.md
```

Ejemplo validado:

```text
Super al soltar
→ launcher.toggle
→ Noctalia Integration
→ noctalia msg panel-toggle launcher
```

Esta separación permite sustituir Noctalia por otra shell conservando la intención del atajo y cambiando solamente el proveedor.

## Auditoría y Nest Doctor

El diagnóstico debe distinguir al menos estos estados:

```text
✓ binding y acción disponibles
⚠ acción disponible, pero no existe binding
✗ binding presente, pero comando inexistente
✗ binding y comando presentes, pero falta una dependencia
⚠ colisión con otro binding
⚠ binding duplicado en archivos distintos
⚠ tecla física emite un evento distinto al esperado
```

Casos reales observados en la instalación limpia:

```text
Brillo
- bindings XF86 presentes
- brightnessctl ausente
- reparación: instalar dependencia

Launcher
- SUPER+R apuntaba a hyprlauncher
- hyprlauncher ausente
- reparación: usar IPC de Noctalia
- mejora: añadir Super al soltar

Captura
- sin bindings funcionales al inicio
- Noctalia expone y ejecuta acciones de captura
- ImpPt sola emite XF86SelectiveScreenshot, key 642
- Fn + ImpPt emite Print, key 107
- reparación: enlazar ambos keycodes XKB a la IPC de Noctalia
```

El diagnóstico no debe inventar el historial del sistema. Debe informar únicamente el estado comprobable: nunca instalado, actualmente ausente, reemplazado o disponible mediante otro proveedor solo cuando exista evidencia suficiente.

## Diagnóstico de teclas físicas y Fn

`Fn` no debe modelarse como un modificador universal. En muchos portátiles, la combinación es procesada por el firmware y genera otro evento de teclado. Ese evento puede provenir incluso de un dispositivo distinto.

Caso validado en un Lenovo ThinkBook:

```text
ImpPt sola
├── dispositivo kernel: ideapad-extra-buttons
├── libinput: KEY_SELECTIVE_SCREENSHOT (634)
└── wev/XKB: XF86SelectiveScreenshot, key 642

Fn + ImpPt
├── dispositivo kernel: AT Translated Set 2 keyboard
├── libinput: KEY_SYSRQ (99), junto a KEY_WAKEUP
└── wev/XKB: Print, key 107
```

El identificador `ideapad-extra-buttons` es el nombre del controlador de Linux utilizado por Lenovo y no identifica necesariamente la gama comercial del portátil.

### Fuente correcta para `code:`

Los códigos mostrados por `libinput debug-events` pertenecen al nivel kernel/evdev. Los códigos mostrados por `wev` corresponden al nivel Wayland/XKB que necesita Hyprland para bindings `code:<n>`.

Regla obligatoria:

> Para escribir `code:<n>` en Hyprland, usar el keycode mostrado por `wev`. No copiar directamente el número mostrado por `libinput`.

En la prueba real, estos bindings no funcionaron:

```lua
hl.bind("code:634", ...)
hl.bind("code:99", ...)
```

Los bindings correctos fueron:

```lua
hl.bind("code:642", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("code:107", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen all"))
```

Los números son específicos del equipo y del evento observado; no deben asumirse en otros teclados.

### Flujo de diagnóstico recomendado

Aplicar un paso, comprobarlo y avanzar solo con evidencia:

```text
1. identificar el binding actual
2. desactivarlo temporalmente si interfiere con la medición
3. usar wev para obtener símbolo y keycode XKB
4. usar libinput solo si hace falta identificar dispositivo/evento kernel
5. añadir un único binding
6. recargar Hyprland
7. probar la acción
8. conservar o revertir según el resultado
```

Para reducir ruido en Fish:

```fish
wev | grep --line-buffered -E 'key:|sym:'
```

La ventana de `wev` recibe las pulsaciones. Para cerrar con `Ctrl+C`, puede ser necesario devolver primero el foco a la terminal.

## Perfiles

Nest podrá ofrecer perfiles declarativos, revisables y reversibles.

Primer perfil propuesto:

```text
Noctalia Standard
```

Funciones iniciales:

```text
Super                   → launcher
captura regional        → acción lógica screenshot.region
captura completa        → acción lógica screenshot.fullscreen
XF86Audio*              → audio y multimedia
XF86MonBrightness*      → brillo
```

El perfil no debe asumir `Shift + Print` como combinación universal. Debe resolver las acciones contra los eventos reales emitidos por el teclado o permitir que el usuario los asigne explícitamente.

Los perfiles deben:

- mostrar el diff antes de aplicar;
- conservar atajos personalizados;
- detectar colisiones;
- permitir activar acciones individualmente;
- registrar qué adaptador resolvió cada comando;
- registrar cómo fue detectada la tecla;
- poder exportarse e importarse;
- poder revertirse.

## Flujo seguro propuesto

```text
leer → interpretar → resolver acciones → detectar conflictos
→ mostrar cambios → respaldar → escribir temporal
→ validar → reemplazar → recargar → comprobar
```

Nunca debe escribirse directamente sobre el archivo activo sin una etapa temporal y una copia recuperable.

Durante diagnóstico interactivo debe respetarse además:

```text
una hipótesis → un comando o cambio → una prueba → un resultado
```

No se deben encadenar pasos posteriores antes de verificar que el paso actual funciona.

## Consideraciones

- Hyprland permite múltiples archivos `source`; deben respetarse.
- Un mismo atajo puede estar declarado en distintos archivos.
- La shell puede exponer acciones, pero el binding pertenece al compositor.
- Las teclas físicas, layouts, firmware y controladores cambian entre equipos.
- `Fn` puede cambiar el evento en firmware y no llegar como modificador.
- El sistema principal usa teclado LATAM y Fish, pero los bindings pertenecen a Hyprland, no al shell interactivo.
- Los ejemplos operativos del proyecto deben ser compatibles con Fish o indicar explícitamente cuando requieren Bash.
- Toda instrucción de edición debe indicar objetivo, archivo y ubicación exacta antes del cambio.
- Las acciones deben almacenarse como datos cuando sea posible y no como fragmentos de texto difíciles de validar.
- Un comando disponible no garantiza que su backend o permisos estén operativos.

## Pendientes

- definir el esquema interno definitivo de un keybind;
- normalizar modificadores, teclas y eventos release/repeat;
- resolver colisiones y prioridades;
- distinguir atajos del usuario, de Nest y de la shell;
- implementar resolución por adaptadores;
- auditar las teclas multimedia restantes de la instalación limpia;
- convertir el flujo de detección con `wev` en un asistente guiado;
- exportar e importar perfiles;
- crear interfaz de búsqueda;
- integrar el diagnóstico antes de recargar Hyprland;
- documentar la v0.2 y los cambios posteriores desde los respaldos existentes.

## Criterio de finalización

El módulo estará listo cuando pueda realizar cambios reversibles sobre un archivo administrado, detectar conflictos globales, verificar las acciones asociadas, identificar correctamente eventos de teclas especiales y demostrar que una actualización o sustitución de Noctalia o Hyprland no destruye los atajos personales ni obliga a reescribir los perfiles desde cero.