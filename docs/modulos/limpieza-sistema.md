# Limpieza del sistema y auditoría de dependencias

**Estado:** Vigente y validado  
**Fecha:** 2026-07-20  
**Relacionado con:** `docs/TABLERO-MAESTRO.md`, `docs/integraciones/noctalia-greeter.md`, `docs/nest/02-roadmap-arquitectonico.md`

## Objetivo

Documentar la limpieza controlada realizada sobre Cachy-caOS, las decisiones de conservación, la validación posterior y el hallazgo crítico de dependencias no registradas por pacman.

Este documento es la fuente canónica para la sesión de limpieza de julio de 2026 y para el diseño futuro del módulo de auditoría de Nest/System Doctor.

## Resultado final

```text
Paquetes netos eliminados: 92
Archivos de caché retirados: 141
Caché recuperada: 438.28 MiB
Huérfanos finales: 0
Servicios fallidos del sistema: 0
Servicios fallidos del usuario: 0
Display manager activo: greetd
Kernels conservados: linux-cachyos y linux-cachyos-lts
```

Componentes críticos verificados:

```text
/usr/bin/hyprland
/usr/bin/noctalia
/usr/bin/nemo
/usr/bin/kitty
/usr/bin/mpv
/usr/bin/krita
```

Nemo y Krita fueron abiertos y validados visualmente después de la limpieza.

## Metodología

```text
inventario
→ clasificación
→ dependencias
→ simulación
→ eliminación por tandas
→ verificación funcional
→ auditoría de servicios
→ limpieza de caché
→ comprobación de binarios no empaquetados
→ documentación
```

No se ejecutó una eliminación automática de huérfanos ni se trató `pacman -Qdt` como autorización para borrar.

## Inventario inicial

Se revisaron:

- paquetes explícitos no requeridos;
- paquetes huérfanos;
- paquetes externos/AUR;
- Flatpaks y Snaps;
- servicios habilitados;
- aplicaciones del menú;
- kernels y headers;
- módulos DKMS;
- display managers;
- asociaciones MIME;
- servicios y timers activos;
- caché de pacman.

Estado inicial relevante:

- cero huérfanos;
- sin Flatpak;
- sin Snap;
- único paquete externo: `noctalia-git`;
- greetd activo y SDDM inactivo;
- dos kernels y dos paquetes de headers;
- DKMS no instalado;
- Dolphin y Nemo coexistían;
- VLC y mpv coexistían;
- `kitty-open.desktop` estaba asociado incorrectamente a `inode/directory`.

## Primera tanda

Objetivos directos retirados:

```text
alacritty
cachyos-zsh-config
cachyos-hello
cachyos-wallpapers
sddm
glances
cachyos-packageinstaller
shelly
linux-cachyos-headers
linux-cachyos-lts-headers
```

Motivos:

- Kitty reemplaza Alacritty.
- Fish reemplaza Zsh como shell interactiva.
- CachyOS Hello y sus wallpapers no participan en la experiencia actual.
- greetd + Noctalia Greeter reemplazan SDDM.
- btop cubre el monitoreo cotidiano.
- pacman y Nest vuelven redundantes los instaladores gráficos adicionales.
- no existían módulos DKMS que requirieran headers.

La eliminación recursiva retiró 36 paquetes, incluyendo dependencias exclusivas de estas herramientas.

Validación:

- greetd activo y habilitado;
- Hyprland, Noctalia y Kitty presentes;
- ambos kernels presentes;
- cero huérfanos.

## Segunda tanda

Antes de retirar Dolphin se corrigió la configuración de Hyprland:

```lua
local fileManager = "nemo"
```

También se reparó la asociación:

```fish
xdg-mime default nemo.desktop inode/directory
```

Estado validado:

```text
inode/directory → nemo.desktop
```

Objetivos directos:

```text
dolphin
vlc
wlroots0.20
```

Decisiones:

- Nemo permanece como administrador de archivos oficial.
- mpv permanece como reproductor predeterminado de audio y video.
- Dolphin y VLC eran redundantes.
- la retirada inicial de `wlroots0.20` fue revertida tras detectar una dependencia runtime no registrada.

La transacción inicial retiró 58 paquetes. Después se restauraron dos, por lo que el resultado neto de esta tanda fue 56 paquetes eliminados.

## Incidente: dependencia invisible para pacman

### Síntoma

`pacman -Qi wlroots0.20` mostraba:

```text
Required By: None
Install Reason: Explicitly installed
```

`mpvpaper` tampoco dependía de wlroots. Esto llevó a clasificar `wlroots0.20` como residuo.

### Causa

Noctalia Greeter había sido construido e instalado manualmente mediante Meson:

```text
sudo meson install -C build-release
```

El binario:

```text
/usr/bin/noctalia-greeter-compositor
```

no pertenece a ningún paquete:

```text
pacman -Qo /usr/bin/noctalia-greeter-compositor
→ ningún paquete contiene el archivo
```

Pacman no puede registrar ni proteger dependencias de archivos instalados fuera de su base de datos.

Después de retirar wlroots:

```text
libwlroots-0.20.so => not found
```

El greeter seguía activo porque el proceso ya había cargado la biblioteca antes de la eliminación. Un reinicio posterior habría fallado.

### Reparación

```fish
sudo pacman -S wlroots0.20
```

Se restauraron:

```text
wlroots0.20 0.20.2-1.1
libliftoff 0.5.0-1.1
```

Verificación final:

```text
libwlroots-0.20.so => /usr/lib/libwlroots-0.20.so
dependencias ausentes: ninguna
greetd: active
greetd: enabled
```

Snapper creó los snapshots 73 y 74 durante la reparación.

## Lección para Nest/System Doctor

El grafo del gestor de paquetes no es suficiente cuando existen instalaciones manuales.

Nest deberá inventariar:

- archivos ELF bajo rutas del sistema no propiedad de pacman;
- binarios en `/usr/bin`, `/usr/local/bin` y rutas administradas por Nest;
- bibliotecas compartidas resueltas por cada binario;
- dependencias `not found`;
- origen de instalación;
- relación entre servicios activos y binarios no empaquetados.

Flujo mínimo antes de retirar una biblioteca:

```text
consultar pacman
→ buscar archivos no empaquetados relevantes
→ inspeccionar servicios
→ ejecutar ldd sobre binarios ELF
→ simular transacción
→ aplicar
→ repetir ldd
→ validar próximo arranque
```

Contrato propuesto:

```text
detect_unowned_elf()
resolve_shared_libraries()
find_runtime_consumers()
plan_removal()
verify_after_removal()
repair()
```

Una biblioteca con `Required By: None` no debe considerarse automáticamente innecesaria.

## Aplicaciones y herramientas conservadas

Se conservaron conscientemente:

- Nemo;
- mpv y mpvpaper;
- Krita y G'MIC;
- Galculator;
- Meld;
- Btrfs Assistant;
- `wev`;
- `netctl` y `systemd-resolvconf`;
- `nfs-utils`;
- `networkmanager-openvpn`;
- `xl2tpd`;
- utilidades de hardware, firmware, audio, archivos y recuperación;
- Avahi y descubrimiento local;
- portales XDG;
- timers de Snapper, TRIM, mirrors, logs y llaves.

Principio aplicado:

> No se elimina una capacidad futura útil a cambio de una reducción mínima de espacio o recursos.

## Servicios y timers

La auditoría final encontró:

- 21 servicios de sistema activos, todos con función válida;
- 19 servicios de usuario activos, todos coherentes con la sesión;
- nueve timers de sistema;
- un timer de usuario para actualizaciones;
- cero unidades fallidas.

Se conservaron `arch-update-tray.service` y `arch-update.timer`: forman parte del mismo flujo de notificación y no se demostró redundancia funcional.

## Caché de pacman

Tamaño antes de retirar paquetes desinstalados:

```text
3.1 GiB
```

`paccache -d -k 2` no encontró candidatos entre paquetes instalados. Se mantuvo la política de conservar dos versiones para rollback.

Se simularon y retiraron solamente archivos de paquetes ya desinstalados:

```fish
paccache -d -u -k 0
sudo paccache -r -u -k 0
```

Resultado:

```text
141 packages removed
438.28 MiB recuperados
caché restante aproximada: 2.6 GiB
```

Los directorios temporales `download-*` propiedad de root produjeron avisos de permisos al ejecutar `du` sin sudo, pero no afectaron la operación ni la validación.

## Rollback y recuperación

- Los paquetes retirados siguen disponibles en repositorios si se necesitan.
- Los dos kernels se conservaron.
- Snapper creó snapshots durante las transacciones.
- SDDM ya no está instalado; la recuperación primaria del login es TTY.
- Si greetd falla, debe diagnosticarse desde `getty@tty2.service`.
- La restauración de wlroots quedó completada antes de cerrar sesión o reiniciar.

## Estado futuro de Nest

El módulo deberá ofrecer:

- inventario de aplicaciones y herramientas;
- clasificación por función;
- tamaño y motivo de instalación;
- dependencias de pacman;
- dependencias runtime externas a pacman;
- simulación visible;
- selección por tandas;
- backup y snapshot;
- verificación de servicios, asociaciones y binarios;
- reporte de huérfanos;
- limpieza segura de caché;
- reparación y rollback;
- registro documental de decisiones de conservación.

La interfaz no debe convertir “optimización” en una carrera por reducir el número de paquetes. Debe priorizar utilidad, resiliencia y comprensión del sistema.
