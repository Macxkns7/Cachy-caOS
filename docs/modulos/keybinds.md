# Módulo Keybinds

**Estado:** v0.2 operativa; edición visual pendiente  
**Última revisión:** 2026-07-22

## Propósito

Administrar atajos de Hyprland desde Nest sin convertir la configuración del usuario en un archivo opaco ni sobrescribir personalizaciones manuales.

El módulo debe comprender la cadena completa:

```text
tecla física
→ dispositivo de entrada
→ evento kernel/evdev
→ evento Wayland/XKB
→ binding de Hyprland
→ acción lógica
→ proveedor
→ comando y dependencias
```

No basta con escribir combinaciones de teclas. Nest debe descubrir qué existe, entender qué emite cada tecla y proponer un perfil basado en evidencia.

## Principio central: descubrir antes de configurar

Nest no debe aplicar un perfil universal de teclado. Debe:

```text
1. detectar dispositivos de entrada
2. inventariar teclas estándar, multimedia, de sistema y especiales
3. observar los eventos reales emitidos
4. detectar funciones ya resueltas por la shell o el sistema
5. identificar teclas sin uso, bindings rotos y colisiones
6. proponer acciones compatibles con el hardware y proveedores disponibles
7. pedir aprobación antes de escribir
```

La serigrafía física orienta al usuario, pero no constituye una fuente técnica confiable. Una tecla rotulada para ayuda puede emitir `Help`; una tecla de captura puede emitir eventos distintos con y sin `Fn`.

## Estado actual

El código fuente canónico se encuentra en:

```text
src/modules/keybinds/
src/bin/cachycaos-keybinds
```

La instalación activa utiliza:

```text
~/.local/share/cachycaos/modules/keybinds/app.sh
~/.local/bin/cachycaos-keybinds
```

Durante el desarrollo también existieron rutas anteriores y respaldos de migración:

```text
~/.local/share/cachycaos/keybinds/app.sh
~/.local/share/cachycaos/backups/
~/.local/share/cachycaos/modules/keybinds/backups/
```

La coexistencia debe resolverse en el instalador final.

La configuración activa de Hyprland observada usa Lua:

```text
~/.config/hypr/hyprland.lua
```

Toda instrucción manual debe indicar explícitamente:

```text
objetivo → archivo → ubicación exacta → bloque → recarga → prueba
```

## Objetivos funcionales

- listar atajos relevantes;
- detectar hardware de entrada y teclas especiales;
- identificar eventos XKB y keycodes cuando sea necesario;
- añadir y modificar atajos administrados;
- detectar colisiones, duplicados y comandos inexistentes;
- distinguir acciones de Hyprland, de una shell y de herramientas externas;
- conservar comentarios y configuración no administrada;
- crear respaldo antes de escribir;
- validar sintaxis antes de recargar;
- restaurar la versión previa si la recarga falla;
- exportar e importar perfiles;
- ofrecer un asistente guiado para teclas multimedia.

## Principio de propiedad

Nest no debe apropiarse de todo `hyprland.conf` ni del archivo Lua principal.

La estrategia recomendada es mantener un archivo administrado y explícitamente incluido por la configuración principal. La ruta definitiva debe decidirse tras auditar la integración correcta con la configuración Lua actual.

Ejemplo conceptual:

```text
~/.config/hypr/conf.d/nest-keybinds.conf
```

Deben mantenerse separadas:

- configuración personal;
- configuración de la shell;
- configuración de Hyprland;
- atajos administrados por Nest.

## Modelo de datos

Un keybind debe representarse como datos verificables:

```text
id
tecla física o posición esperada
dispositivo de entrada
evento kernel/evdev observado
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
fecha y método de detección
```

Ejemplo conceptual:

```text
id: thinkbook-f9-character-picker
tecla física: F9 / ayuda Lenovo
evento XKB: Help
keycode XKB: 146
acción lógica: character-picker.toggle
proveedor: noctalia
comando: noctalia msg panel-toggle launcher /emo
origen: Nest
perfil: Lenovo ThinkBook detectado + Noctalia
estado: validado
```

La acción lógica permite sustituir el proveedor sin rediseñar el perfil.

## Catálogo de capacidades

Los perfiles no deben almacenar solamente comandos. Deben resolver intenciones:

```text
launcher.toggle
character-picker.toggle
calculator.open
screenshot.region
screenshot.fullscreen
notification-center.toggle
audio.mute
audio.volume-up
audio.volume-down
microphone.mute
brightness.up
brightness.down
radio.airplane-toggle
display.switch
call.accept
call.reject
special-key.activate
```

Una misma capacidad puede tener distintos proveedores:

```text
character-picker.toggle
├── Noctalia: noctalia msg panel-toggle launcher /emo
├── Walker: proveedor alternativo
└── otro backend configurado por el usuario
```

Nest debe preferir capacidades nativas ya presentes antes de proponer dependencias externas.

## Integración con shells

```text
Keybinds
→ acción lógica
→ adaptador de shell o proveedor externo
→ comando público
```

La fuente canónica de Noctalia es:

```text
docs/integraciones/noctalia-v5.md
```

Ejemplos validados:

```text
Super al soltar
→ launcher.toggle
→ Noctalia Integration
→ noctalia msg panel-toggle launcher

F9 física del ThinkBook
→ Help
→ character-picker.toggle
→ Noctalia Integration
→ noctalia msg panel-toggle launcher /emo
```

## Clasificación de teclas

Nest debería clasificar el inventario al menos en:

```text
Keyboard
├── Standard Keys
├── Multimedia Keys
│   ├── audio
│   ├── micrófono
│   ├── reproducción
│   ├── brillo
│   └── radio/modo avión
├── System Keys
│   ├── captura
│   ├── calculadora
│   ├── cambio de pantalla
│   └── llamadas
└── Special Key
```

### Special Key

`Special Key` es el nombre conceptual para una tecla especial del fabricante que Nest puede reutilizar.

Puede aparecer físicamente como:

- estrella o símbolo propietario;
- tecla Copilot;
- botón Lenovo, ASUS, HP, Dell o ROG;
- asistente;
- tecla sin función útil en Linux.

Nest no debe asumir su evento ni su función. Debe detectarla y ofrecer acciones sugeridas.

Ejemplo de experiencia futura:

```text
⭐ Special Key detectada

¿Quieres darle un superpoder?

- Centro de notificaciones
- Quick Actions
- Launcher
- Portapapeles
- Aplicación personalizada
- Más tarde
```

En el ThinkBook actual, la tecla física muestra una `S` dentro de una estrella. Su evento y binding se validarán en el siguiente paso de la auditoría.

## Auditoría y Nest Doctor

Estados mínimos:

```text
✓ binding y acción disponibles
⚠ acción disponible, pero sin binding
✗ binding presente, pero comando inexistente
✗ proveedor presente, pero falta una dependencia
⚠ colisión con otro binding
⚠ binding duplicado en archivos distintos
⚠ tecla física emite un evento diferente al esperado
⚠ utilidad externa duplica una capacidad nativa
⚠ comando/contexto no existe en la versión instalada
```

Casos reales:

```text
Brillo
- bindings XF86 presentes
- brightnessctl ausente
- reparación: instalar dependencia requerida

Launcher
- binding hacia hyprlauncher
- ejecutable ausente
- reparación: usar IPC nativa de Noctalia

Captura
- Noctalia ya exponía ambas acciones
- ImpPt sola emite XF86SelectiveScreenshot, key 642
- Fn + ImpPt emite Print, key 107
- reparación: bindings contra keycodes observados con wev

Character Picker
- F9 física emite Help, key 146
- Noctalia ya ofrece launcher /emo
- reparación: binding Help a la capacidad nativa
- resultado: cero dependencias adicionales

Calculadora
- F12 física emite XF86Calculator, key 148
- no existía calculadora instalada
- solución: Galculator como proveedor ligero
```

El diagnóstico no debe inventar el historial del sistema. Debe describir únicamente estados comprobables.

## Diagnóstico de teclas físicas y Fn

`Fn` no debe modelarse como un modificador universal. En muchos portátiles la combinación es procesada por firmware y genera otro evento, incluso desde un dispositivo distinto.

Caso validado en Lenovo ThinkBook:

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

El identificador `ideapad-extra-buttons` corresponde al controlador de Linux utilizado por Lenovo y no identifica necesariamente la gama comercial.

### Fuente correcta para `code:`

Los códigos de `libinput debug-events` pertenecen al nivel kernel/evdev. Los códigos de `wev` corresponden al nivel Wayland/XKB que necesita Hyprland.

Regla obligatoria:

> Para escribir `code:<n>` en Hyprland, usar el keycode mostrado por `wev`. No copiar directamente el número mostrado por `libinput`.

Bindings incorrectos probados:

```lua
hl.bind("code:634", ...)
hl.bind("code:99", ...)
```

Bindings correctos:

```lua
hl.bind("code:642", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("code:107", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen all"))
```

Los números son específicos del equipo y del evento observado.

## Perfil Lenovo ThinkBook observado

Estado actual de las teclas multimedia:

```text
Audio y volumen             → funcional
Mute de micrófono           → funcional
Brillo                      → funcional
Modo avión                  → funcional
Captura regional            → funcional
Captura completa            → funcional
F9 / ayuda                  → Character Picker de Noctalia
F12 / calculadora           → Galculator
Cambio de pantalla          → pendiente de probar con monitor externo
F10/F11 / llamadas          → pendiente de detectar y definir utilidad
⭐ Special Key              → pendiente de detectar; candidata a notificaciones
```

### Bindings validados

```lua
-- Screenshot Keys
hl.bind("code:642", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("code:107", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen all"))

-- Calculator Key
hl.bind("XF86Calculator", hl.dsp.exec_cmd("galculator"))

-- Character Picker
hl.bind("Help", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher /emo"))
```

El archivo activo usado durante la prueba fue:

```text
~/.config/hypr/hyprland.lua
```

Estos fragmentos documentan el resultado real, pero Nest deberá escribir en un archivo administrado propio cuando el módulo madure.

## Repetición de teclas de volumen

Caso validado en el Lenovo 13s G2:

- una pulsación breve podía llevar ocasionalmente el volumen a mínimo o máximo;
- el síntoma también había aparecido en Ubuntu y en la etapa Omarchy;
- Hyprland tenía `repeat_rate = 25`, `repeat_delay = 600` y bindings de volumen con `repeating = true`;
- cada repetición modificaba 5 %, por lo que una liberación tardía podía recorrer toda la barra en menos de un segundo.

Configuración corregida:

```lua
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = false })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = false })
```

Resultado comprobado:

- una pulsación cambia exactamente 5 %;
- una pulsación prolongada no inicia una ráfaga;
- se conserva `locked = true` para permitir control con la sesión bloqueada;
- no fue necesario modificar EasyEffects ni PipeWire.

Regla para Nest:

> La repetición no debe activarse por defecto en acciones incrementales peligrosas como volumen o brillo. El perfil debe declarar explícitamente si acepta `press`, `release` o `repeat` y mostrar la tasa efectiva antes de aplicar.

Respaldo validado:

```text
~/.config/hypr/hyprland.lua.pre-volume-repeat-20260721.bak
```

La configuración de audio relacionada se documenta en `docs/modulos/audio-easyeffects.md`.

## Flujo de diagnóstico recomendado

Aplicar un paso, comprobarlo y avanzar solo con evidencia:

```text
1. identificar el binding actual
2. desactivarlo temporalmente si interfiere
3. usar wev para obtener símbolo y keycode XKB
4. usar libinput solo si hace falta identificar dispositivo/evento kernel
5. comprobar si la shell ya ofrece la capacidad
6. seleccionar proveedor y dependencias
7. añadir un único binding
8. recargar Hyprland
9. probar la acción
10. conservar o revertir
11. documentar solo después de validar
```

Comando de medición usado en Fish:

```fish
wev | grep --line-buffered -E 'key:|sym:'
```

La ventana de `wev` recibe las pulsaciones. Para cerrar con `Ctrl+C`, puede ser necesario devolver primero el foco a la terminal.

Regla de trabajo:

```text
una hipótesis
→ un comando o cambio
→ una prueba
→ un resultado
```

No se deben adelantar pasos posteriores antes de verificar el actual.

## Perfiles

Primer perfil de shell propuesto:

```text
Noctalia Standard
```

Primer perfil de hardware observado:

```text
Lenovo ThinkBook — perfil detectado, no universal
```

Los perfiles pueden combinarse:

```text
hardware detectado
+ shell detectada
+ proveedores disponibles
+ preferencias del usuario
= propuesta de perfil
```

Un perfil debe:

- mostrar el diff antes de aplicar;
- conservar atajos personalizados;
- detectar colisiones;
- permitir activar acciones individualmente;
- registrar qué adaptador resolvió cada comando;
- registrar cómo fue detectada la tecla;
- indicar dependencias nuevas y capacidades nativas reutilizadas;
- poder exportarse, importarse y revertirse.

## Flujo seguro de escritura

```text
leer
→ interpretar
→ resolver acciones
→ detectar conflictos
→ mostrar cambios
→ respaldar
→ escribir temporal
→ validar
→ reemplazar
→ recargar
→ comprobar
```

Nunca debe escribirse directamente sobre el archivo activo sin una etapa temporal y una copia recuperable.

## Consideraciones

- Hyprland permite múltiples archivos `source`; deben respetarse.
- Un mismo atajo puede aparecer en distintos archivos.
- La shell expone acciones, pero el binding pertenece al compositor.
- Teclados, layouts, firmware y controladores cambian entre equipos.
- `Fn` puede cambiar el evento en firmware y no llegar como modificador.
- El sistema principal usa teclado LATAM y Fish.
- Los ejemplos operativos deben ser compatibles con Fish o indicarlo explícitamente.
- Toda instrucción de edición debe indicar archivo y ubicación exacta.
- Un comando existente no garantiza que su backend o permisos estén operativos.
- Una capacidad nativa debe preferirse sobre una utilidad redundante.
- La detección debe preceder a la propuesta de perfil.

## Hito v0.2: ciclo administrado seguro

La primera implementación completa del ciclo de vida quedó publicada el 22 de julio de 2026.

Capacidades comprobadas:

- scanner recursivo de configuración Lua y módulos cargados mediante `require`;
- correlación entre los bindings runtime y su fuente;
- manifiesto TOML separado de la configuración personal;
- archivo administrado definitivo en `~/.config/hypr/cachycaos/keybinds.lua`;
- modelo explícito de `press`, `release` y `repeat`;
- flags `locked` y `mouse`;
- `repeating = false` por omisión para evitar repeticiones peligrosas;
- diff previo con `cachycaos-keybinds plan`;
- instalación, respaldo, recarga y validación con `apply`;
- comprobación de sincronía con `verify`;
- recuperación explícita con `rollback`;
- rollback automático cuando Hyprland rechaza la recarga o informa errores.

La prueba automatizada simula deliberadamente un error de Hyprland y comprueba que el archivo anterior se restaura byte por byte. El scanner también fue validado contra la configuración real del ThinkBook: detectó 55 bindings sin necesidad de apropiarse del archivo principal.

Comandos públicos:

```bash
cachycaos-keybinds
cachycaos-keybinds refresh
cachycaos-keybinds report
cachycaos-keybinds plan
cachycaos-keybinds apply
cachycaos-keybinds verify
cachycaos-keybinds rollback
```

Límite deliberado de esta fase:

> v0.2 hace plenamente operativo el archivo administrado, pero todavía no migra ni edita visualmente los bindings personales. Los 54 atajos externos descubiertos permanecen bajo propiedad del usuario; N.E.S.T. sólo administra el binding declarado en su manifiesto.

## Pendientes

- ampliar el esquema con hardware, proveedor y evidencia de detección;
- resolver colisiones propuestas antes de instalar, además de los duplicados activos;
- distinguir atajos del usuario, de Nest y de la shell;
- implementar resolución por adaptadores;
- detectar y configurar la ⭐ Special Key;
- auditar F10/F11 de llamadas;
- validar cambio de pantalla con monitor externo;
- convertir `wev` en un asistente guiado;
- inventariar dispositivos y teclas automáticamente;
- exportar e importar perfiles;
- crear interfaz de búsqueda;

## Criterio de finalización

El módulo estará listo cuando pueda descubrir el hardware, identificar correctamente los eventos de teclas especiales, resolver acciones contra proveedores disponibles, evitar dependencias redundantes, mostrar y aplicar cambios reversibles, detectar conflictos globales y demostrar que una actualización o sustitución de Noctalia o Hyprland no destruye los atajos personales ni obliga a reescribir los perfiles desde cero.