# Audio con EasyEffects

**Estado:** Vigente y validado  
**Última revisión:** 2026-07-21  
**Relacionado con:** `docs/modulos/keybinds.md`, `docs/configuraciones-importantes.md`

## Propósito

Documentar la mejora de audio validada para los parlantes integrados Harman Kardon del Lenovo 13s G2 y convertirla en una integración reproducible para Nest.

El perfil no es universal. Fue ajustado mediante pruebas A/B en el equipo real y no debe aplicarse automáticamente a auriculares, Bluetooth, HDMI u otro hardware.

## Estado validado

Pila de audio:

- PipeWire 1.6.8;
- PipeWire PulseAudio;
- WirePlumber 0.5.15;
- EasyEffects 8.2.7;
- LSP Plugins LV2 1.2.33;
- Calf 0.90.9;
- frecuencia efectiva: 48 kHz;
- salida evaluada: parlantes integrados del Lenovo 13s G2.

Cadena aprobada:

```text
Ecualizador de 32 bandas
→ Limitador LSP
→ dispositivo de salida
```

Preset aprobado:

```text
NEST-Lenovo-13sG2-HK-v2
```

Referencia conservada:

```text
NEST-Lenovo-13sG2-HK-v1
```

## Instalación mínima

Actualizar el sistema completo e instalar únicamente los backends requeridos:

```fish
sudo pacman -Syu easyeffects lsp-plugins-lv2 calf
```

Cuando Qt solicite un proveedor multimedia, la opción validada en CachyOS x86-64-v4 fue:

```text
qt6-multimedia-ffmpeg
```

No se requiere el metapaquete `lsp-plugins`: instala CLAP, GStreamer, LADSPA, standalone, VST y VST3 que este flujo no utiliza. `lsp-plugins-lv2` aporta el ecualizador y `calf` conserva disponibilidad de efectos adicionales compatibles.

Después de una actualización de kernel o Hyprland debe reiniciarse antes de validar audio.

## Comprobación de la pila

```fish
pacman -Q easyeffects lsp-plugins-lv2 calf
systemctl --user is-active pipewire wireplumber
systemctl --user status pipewire-pulse.socket --no-pager
pactl info
wpctl status
```

`pipewire-pulse.service` puede aparecer inicialmente inactivo si su socket está escuchando. Una consulta mediante `pactl` lo activa bajo demanda; eso no constituye un fallo.

El servidor esperado es:

```text
PulseAudio (on PipeWire)
```

No establecer manualmente los dispositivos virtuales de EasyEffects como salida predeterminada.

## Presets versionados

Archivos canónicos:

```text
configs/easyeffects/output/NEST-Lenovo-13sG2-HK-v1.json
configs/easyeffects/output/NEST-Lenovo-13sG2-HK-v2.json
```

Instalación local:

```fish
install -Dm644 configs/easyeffects/output/NEST-Lenovo-13sG2-HK-v1.json \
  ~/.local/share/easyeffects/output/NEST-Lenovo-13sG2-HK-v1.json

install -Dm644 configs/easyeffects/output/NEST-Lenovo-13sG2-HK-v2.json \
  ~/.local/share/easyeffects/output/NEST-Lenovo-13sG2-HK-v2.json
```

EasyEffects guarda presets de salida en:

```text
~/.local/share/easyeffects/output/
```

La preferencia de iniciar EasyEffects con la sesión fue activada desde la propia aplicación y validada por el usuario.

## Perfil v1: referencia neutral amplificada

La v1 conserva las 32 bandas en `0 dB` y usa únicamente el limitador para elevar el volumen percibido sin rehacer la afinación del equipo.

Limitador:

| Parámetro | Valor |
|---|---:|
| Modo | Herm Thin |
| Ganancia de entrada | +3.00 dB |
| Límite/threshold | -1.00 dB |
| Ganancia de salida | 0.00 dB |
| Ataque | 5 ms |
| Liberación | 5 ms |
| Lookahead | 5 ms |
| Enlace estéreo | 100 % |
| Sobremuestreo | None |
| Dithering | None |
| Sidechain | Internal |
| Gain boost | activado |

Resultado validado: cuerpo similar al audio original y aumento considerable del volumen general. Una canción excepcionalmente exigente seguía provocando distorsión leve en graves.

## Perfil v2: ajuste aprobado para el Lenovo

La v2 conserva íntegro el limitador de la v1 y modifica solamente ganancias del ecualizador en ambos canales.

Ajuste de graves:

| Frecuencia | Ganancia |
|---:|---:|
| 22.4 Hz | -1.50 dB |
| 27.8 Hz | -1.50 dB |
| 34.51 Hz | -1.25 dB |
| 42.82 Hz | -1.00 dB |
| 53.14 Hz | -0.75 dB |
| 65.95 Hz | -0.50 dB |
| 81.83 Hz | -0.25 dB |
| desde 101.55 Hz | 0.00 dB |

Ajuste de presencia:

| Frecuencia | Ganancia |
|---:|---:|
| 1.680 kHz | +0.15 dB |
| 2.085 kHz | +0.25 dB |
| 2.588 kHz | +0.35 dB |
| 3.211 kHz | +0.45 dB |
| 3.985 kHz | +0.50 dB |
| 4.945 kHz | +0.50 dB |
| 6.137 kHz | +0.40 dB |
| 7.615 kHz | +0.30 dB |
| 9.450 kHz | +0.20 dB |
| 11.727 kHz | +0.10 dB |
| desde 14.552 kHz | 0.00 dB |

Las demás bandas permanecen neutrales. Se preservan:

- 32 bandas;
- modo IIR;
- filtros Bell;
- `Q 4.36`;
- modo `RLC (BT)`;
- canales sin división;
- entrada y salida del ecualizador en `0 dB`.

## Evidencia de pruebas y decisiones

Primera hipótesis descartada:

- una curva amplia con hasta +3 dB en graves y +2 dB en agudos;
- mejoró voces y claridad;
- produjo graves reventados;
- bajar la entrada del ecualizador a -3 dB eliminó la saturación, pero redujo demasiado cuerpo y graves.

Conclusión:

> Los parlantes ya poseen una afinación útil. La mejora debe conservarla, controlar solo el grave problemático y obtener la mayor parte de la ganancia mediante limitación segura.

La v2 fue comparada con:

- efectos desactivados;
- v1 neutral + limitador;
- contenido con graves exigentes;
- distintos estilos musicales;
- voces e instrumentos.

Resultado: mayor volumen, cuerpo conservado, graves controlados y claridad sutil sin carácter artificial.

## Teclas de volumen: repetición descontrolada

Síntoma:

- una pulsación breve podía llevar ocasionalmente el volumen a mínimo o máximo;
- el comportamiento ya se había observado en Ubuntu y en la etapa Omarchy;
- no dependía de EasyEffects.

Diagnóstico en Hyprland:

```text
input:repeat_rate  = 25
input:repeat_delay = 600
```

Los bindings cambiaban 5 % y estaban declarados con `repeating = true`. Tras 600 ms podían ejecutar 25 cambios por segundo.

Corrección validada en `~/.config/hypr/hyprland.lua`:

```lua
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = false })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = false })
```

Se conserva `locked = true` para controlar el volumen con la sesión bloqueada. Cada pulsación cambia 5 % y mantener la tecla ya no genera una ráfaga.

Respaldo aplicado antes del cambio:

```text
~/.config/hypr/hyprland.lua.pre-volume-repeat-20260721.bak
```

La fuente canónica del diseño general de atajos sigue siendo `docs/modulos/keybinds.md`.

## Verificación y rollback

Comprobar proceso y perfil:

```fish
pgrep -a easyeffects
find ~/.local/share/easyeffects/output -maxdepth 1 -type f -printf '%f\n' | sort
wpctl status
```

Rollback por niveles:

1. seleccionar `NEST-Lenovo-13sG2-HK-v1`;
2. desactivar individualmente el ecualizador;
3. desactivar individualmente el limitador;
4. desactivar globalmente los efectos;
5. restaurar el archivo Lua respaldado si se requiere repetición de volumen.

Los presets no modifican el hardware ni reemplazan la configuración de PipeWire.

## Diseño para Nest Audio

La prueba valida un futuro módulo pequeño de Nest con responsabilidades claras:

```text
Audio Detect
→ Audio Profiles
→ EasyEffects Adapter
→ Device Association
→ Verify / Repair / Rollback
```

Capacidades propuestas:

- detectar PipeWire, WirePlumber y compatibilidad PulseAudio;
- instalar únicamente dependencias necesarias;
- importar, exportar y versionar presets;
- asociar perfiles por dispositivo de salida;
- evitar aplicar el perfil del notebook a auriculares, Bluetooth o HDMI;
- mostrar cadena, ganancia y techo antes de activar;
- ofrecer prueba A/B y bypass inmediato;
- comprobar inicio automático y proceso;
- detectar presets ausentes o incompatibles;
- restaurar una referencia neutral;
- administrar adaptadores sin reimplementar DSP.

Regla:

> Nest no debe inventar una ecualización universal. Debe detectar el dispositivo, desplegar perfiles explícitos, explicar su alcance y conservar rollback.

## Pendientes

- validar persistencia después de próximos reinicios y actualizaciones de EasyEffects;
- estudiar asociación automática segura por dispositivo;
- probar un perfil separado para auriculares;
- diseñar el manifiesto de perfiles de Nest Audio;
- decidir si el módulo debe exponer el cambio de perfiles mediante IPC de la shell o directamente mediante EasyEffects;
- añadir diagnóstico de repetición para teclas multimedia en Keybinds.
