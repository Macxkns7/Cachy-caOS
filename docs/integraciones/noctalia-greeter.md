# Integración: Noctalia Greeter + greetd

Fecha de implementación: 2026-07-15

## Resultado

Noctalia Greeter reemplazó correctamente a SDDM como pantalla de inicio de sesión de Cachy-caOS. La sesión funcional seleccionada es `Hyprland`, y el greeter recuerda la última elección en `/var/lib/noctalia-greeter/greeter.toml`.

## Decisión arquitectónica

Noctalia Greeter está bien construido y cumple correctamente su función. Nest debe adoptarlo como backend administrado, sin crear un fork ni reimplementar autenticación, compositor o renderizado salvo que aparezca una necesidad técnica real.

## Componentes

```text
systemd
└── greetd
    └── noctalia-greeter-session
        └── noctalia-greeter-compositor
            └── noctalia-greeter
                └── PAM
                    └── sesión Hyprland
```

Binarios instalados:

- `/usr/bin/noctalia-greeter`
- `/usr/bin/noctalia-greeter-compositor`
- `/usr/bin/noctalia-greeter-session`
- `/usr/bin/noctalia-greeter-apply-appearance`

Recursos:

- `/usr/share/noctalia-greeter/`
- `/usr/share/polkit-1/actions/org.noctalia.greeter.apply-appearance.policy`

Estado y configuración:

- `/etc/greetd/config.toml`
- `/var/lib/noctalia-greeter/greeter.toml`
- `/etc/pam.d/greetd`

Logs previstos:

- `/var/log/noctalia-greeter.log`
- `/var/lib/noctalia-greeter/greeter.log`
- fallbacks bajo `/tmp` y caché del usuario.

## Construcción realizada

Dependencias principales:

- `greetd`
- `wlroots0.20`
- `just`
- Meson y Ninja
- Wayland, EGL/GLES, Cairo, Pango, FreeType, libinput y librsvg

Configuración usada:

```text
meson setup build-release --prefix=/usr --buildtype=release
meson compile -C build-release
sudo meson install -C build-release
```

La compilación generó correctamente:

- `noctalia-greeter`
- `noctalia-greeter-compositor`
- `noctalia-greeter-apply-appearance`

## Preparación del sistema

El script oficial `setup_greeter_system.sh`:

- creó `/var/lib/noctalia-greeter`;
- preparó los archivos de log;
- generó `greeter.toml`;
- respaldó `/etc/pam.d/greetd`;
- añadió `pam_systemd.so` cuando fue necesario;
- imprimió la configuración recomendada para greetd.

Configuración aplicada:

```toml
[terminal]
vt = 1

[default_session]
command = "/usr/bin/noctalia-greeter-session"
user = "greeter"
```

Antes de activar greetd se mantuvo SDDM funcional y se habilitó `getty@tty2.service` como vía de recuperación.

## Polkit y sincronización visual

La primera sincronización quedó esperando autorización porque el agente Polkit nativo de Noctalia estaba desactivado.

Solución:

- activar el agente Polkit desde los ajustes de Noctalia;
- repetir la sincronización del greeter.

Resultado persistente:

```toml
[appearance]
scheme = "Synced"
```

Esto permitió copiar la apariencia de Noctalia al greeter mediante la herramienta privilegiada oficial.

## Error encontrado: sesión UWSM inválida

El selector mostró:

- `Hyprland (uwsm-managed)`
- `Hyprland`

Al usar la primera, la contraseña fue aceptada, pero la sesión no arrancó:

```text
/bin/sh: exec: uwsm: no encontrado
```

Investigación:

- `/usr/share/wayland-sessions/hyprland-uwsm.desktop` pertenece al paquete `hyprland`;
- contiene `TryExec=uwsm`;
- `uwsm` no está instalado;
- Noctalia Greeter mostró la entrada aunque `TryExec` no pudiera resolverse.

La sesión correcta fue:

```text
Hyprland
Exec=/usr/bin/start-hyprland
```

Después del inicio exitoso, el greeter guardó:

```toml
[session]
last = "Hyprland"
```

### Posible defecto upstream

Noctalia Greeter probablemente debería ocultar sesiones cuyo `TryExec` no esté disponible. Este caso es reproducible y puede reportarse upstream.

## Recuperación

En caso de fallo, desde TTY:

```text
systemctl disable greetd.service
systemctl enable sddm.service
reboot
```

Nest deberá ofrecer esta recuperación sin exigir que el usuario recuerde los comandos.

## Funciones futuras del módulo Nest

- detectar display manager activo;
- instalar el greeter sin activarlo;
- comprobar binarios y assets;
- validar el usuario `greeter`;
- revisar PAM y sus respaldos;
- detectar el agente Polkit;
- sincronizar apariencia;
- listar y validar sesiones Wayland;
- respetar `TryExec`;
- seleccionar sesión predeterminada;
- mostrar logs;
- alternar entre greetd y SDDM;
- generar una ruta de recuperación antes del cambio.

## Lección principal

La integración demostró que Nest debe aportar comprensión, diagnóstico, reversibilidad y facilidad de uso alrededor de proyectos externos sólidos. No debe reemplazar componentes únicamente para tener una implementación propia.