# N.E.S.T. Keybinds

Fuente canónica del módulo de atajos administrados de Cachy-caOS.

## Alcance de v0.5

- inventaría los bindings activos y sigue módulos Lua cargados con `require`;
- tolera el JSON inválido de Hyprland 0.56 mediante fallback automático a
  `hyprctl binds`;
- relaciona el estado runtime con la configuración fuente;
- detecta combinaciones duplicadas;
- genera un archivo Lua dedicado desde `data/binds.toml`;
- muestra un diff antes de instalar;
- respalda el archivo administrado;
- recarga y valida Hyprland;
- restaura automáticamente el estado previo si la validación falla;
- permite verificación y rollback explícitos;
- muestra el archivo fuente real de cada binding, incluido el módulo
  administrado;
- crea y edita bindings como registros de un manifiesto TOML;
- importa bindings personales como borradores inicialmente deshabilitados;
- ofrece una vista previa e importación masiva de todos los bindings externos
  compatibles, con IDs deterministas y sin duplicar importaciones anteriores;
- puede habilitar todos los borradores como una sola transacción;
- cancela el lote completo si encuentra una acción incompatible o una sola
  combinación todavía activa fuera del archivo administrado;
- bloquea la habilitación y la aplicación si la combinación original continúa
  activa fuera del archivo administrado;
- diferencia `press` y `long_press` sobre una misma tecla sin tratarlos como
  una colisión;
- detecta pulsaciones largas tanto desde el JSON como desde el fallback
  textual de `hyprctl binds`;
- conserva un respaldo independiente antes de cada cambio del manifiesto.

N.E.S.T. sólo administra:

```text
~/.config/hypr/cachycaos/keybinds.lua
```

No reescribe `~/.config/hypr/hyprland.lua`. Este último únicamente debe cargar
el módulo:

```lua
require("cachycaos.keybinds")
```

## Instalación

Desde este directorio:

```bash
bash install.sh
```

Las actualizaciones reemplazan el código del módulo, pero nunca sobrescriben
un `data/binds.toml` existente. El manifiesto creado o editado por el usuario
se conserva entre instalaciones.

## Uso

```bash
cachycaos-keybinds
cachycaos-keybinds refresh
cachycaos-keybinds report
cachycaos-keybinds plan
cachycaos-keybinds apply
cachycaos-keybinds verify
cachycaos-keybinds rollback
```

`apply` no solicita confirmación en modo CLI; la interfaz interactiva sí muestra
el plan y pide aprobación. En ambos casos, una recarga inválida activa rollback
automático.

## Manifiesto

Cada `[[bind]]` admite:

| Campo | Valores |
|---|---|
| `id` | identificador único |
| `enabled` | `true` o `false` |
| `modifiers` | `SUPER`, `CTRL`, `ALT`, `SHIFT` |
| `key` | símbolo XKB o `code:<n>` validado con `wev` |
| `event` | `press`, `release`, `repeat` o `long_press` |
| `locked` | permite uso con la sesión bloqueada |
| `mouse` | marca bindings de mouse |
| `action` | acción lógica soportada o `exec` |
| `argument` | valor obligatorio para acciones parametrizadas |

Las acciones administradas en v0.5 son:

```text
exec
layout
focus
workspace.focus
workspace.special
window.close
window.float.toggle
window.pseudo
window.fullscreen
window.drag
window.resize
window.move
```

`press` genera explícitamente `repeating = false`. La repetición nunca queda
activada por omisión, especialmente en volumen y brillo.

`long_press` genera `long_press = true` y puede convivir con un registro
`press` que use la misma combinación. Esto permite asignar una acción a la
pulsación breve y otra al mantener la tecla sin scripts ni temporizadores
externos.

## Pruebas

```bash
bash tests/run.sh
```

La prueba incluye un rechazo simulado de Hyprland y comprueba que el archivo
anterior se restaura byte por byte. También reproduce la salida JSON corrupta
observada en Hyprland 0.56 y valida la recuperación desde el formato textual.
Además cubre atribución por archivo fuente, importación individual y masiva
deshabilitada, IDs deterministas, idempotencia, cancelación atómica ante una
acción incompatible, bloqueo global de colisiones externas, edición del
manifiesto, los doce tipos de acciones administradas y la convivencia segura
entre `press` y `long_press`.

## Flujo seguro de migración

1. `Actualizar` reconstruye el inventario runtime y fuente.
2. `Buscar atajos` permite inspeccionar e importar un binding externo.
3. La importación entra como borrador deshabilitado y conserva ruta, línea e
   identidad de origen.
4. `Atajos administrados` permite editarlo y revisar su estado.
5. Para migrarlo, el usuario retira de forma explícita la definición original.
6. N.E.S.T. sólo permite habilitarlo cuando ya no existe la colisión externa.
7. `Planificar cambios` enseña el diff y `Aplicar cambios` pide confirmación,
   respalda, recarga y valida Hyprland.

Para migrar un conjunto completo, `Atajos administrados` ofrece:

1. `Importar externos compatibles`, que primero enseña la vista previa y luego
   crea todos los registros como borradores;
2. retiro explícito y respaldado de las definiciones personales originales;
3. `Habilitar todos los borradores`, que comprueba el lote completo sin
   guardar cambios parciales;
4. planificación, aplicación y prueba por categorías.

N.E.S.T. nunca comenta, elimina ni reescribe silenciosamente el archivo Lua
personal del usuario.

## Siguiente fase

- asistente guiado para retirar una definición externa con diff separado;
- catálogo de capacidades y proveedores;
- captura de teclas mediante `wev`;
- exportación e importación de perfiles completos.
