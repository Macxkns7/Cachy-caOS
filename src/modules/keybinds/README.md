# N.E.S.T. Keybinds

Fuente canónica del módulo de atajos administrados de Cachy-caOS.

## Alcance de v0.2

- inventaría los bindings activos y sigue módulos Lua cargados con `require`;
- relaciona el estado runtime con la configuración fuente;
- detecta combinaciones duplicadas;
- genera un archivo Lua dedicado desde `data/binds.toml`;
- muestra un diff antes de instalar;
- respalda el archivo administrado;
- recarga y valida Hyprland;
- restaura automáticamente el estado previo si la validación falla;
- permite verificación y rollback explícitos.

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
./install.sh
```

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
| `event` | `press`, `release` o `repeat` |
| `locked` | permite uso con la sesión bloqueada |
| `mouse` | marca bindings de mouse |
| `action` | acción lógica soportada o `exec` |
| `argument` | comando obligatorio para `exec` |

`press` genera explícitamente `repeating = false`. La repetición nunca queda
activada por omisión, especialmente en volumen y brillo.

## Pruebas

```bash
./tests/run.sh
```

La prueba incluye un rechazo simulado de Hyprland y comprueba que el archivo
anterior se restaura byte por byte.

## Pendiente

La edición visual e importación guiada de bindings personales llegará en una
fase posterior. v0.2 hace seguro y operativo el ciclo de vida del archivo
administrado sin migrar silenciosamente la configuración del usuario.
