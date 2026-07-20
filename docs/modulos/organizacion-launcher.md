# Organización del launcher: General, Avanzado y Oculto

**Estado:** Prototipo funcional y validado; automatización de Nest pendiente

**Última revisión:** 2026-07-20

**Relacionado con:** `docs/integraciones/noctalia-v5.md`, `docs/nest/02-roadmap-arquitectonico.md`, `docs/nest/03-estado-de-implementacion.md`

## Objetivo

Documentar la clasificación comprobada de aplicaciones del launcher en tres capas lógicas y definir cómo Nest deberá convertirla en una función declarativa, reversible e independiente de la shell.

El problema no era la existencia de herramientas avanzadas, sino que todas sus Desktop Entries compartían la primera capa visual con las aplicaciones cotidianas. Eliminar paquetes habría sacrificado capacidades útiles a cambio de una mejora meramente visual.

La solución validada conserva íntegramente el software instalado y separa su descubrimiento:

```text
General
├── aplicaciones cotidianas
└── visibles en el proveedor normal

Avanzado
├── administración, diagnóstico y desarrollo
└── accesible mediante el proveedor /adv

Oculto
├── auxiliares, pruebas y entradas redundantes
└── instalado y ejecutable, sin aparecer en launchers XDG
```

## Resultado comprobado

La instalación actual usa:

```text
Shell: Noctalia v5.0.0
Plugin local: nest/advanced 0.2.0
Plugin API: 4
Proveedor: /adv
Aplicaciones avanzadas: 12
Entradas ocultas: 7
Archivos de paquetes modificados: 0
Paquetes eliminados por esta operación: 0
```

La validación confirmó:

- desaparición de las entradas avanzadas e internas de la categoría `Todo` y de las categorías nativas;
- presencia de las doce herramientas avanzadas dentro de `/adv`;
- búsqueda difusa dentro del proveedor;
- conservación de nombres, descripciones e iconos;
- apertura correcta de aplicaciones gráficas y de terminal;
- conservación de todos los ejecutables ocultos;
- integración intacta de File Roller con los archivos ZIP de Nemo;
- funcionamiento sin modificar el núcleo ni los archivos instalados por Noctalia.

## Clasificación validada

### General

La capa General corresponde al proveedor normal de aplicaciones después de retirar el ruido técnico. Incluye las herramientas de uso cotidiano, por ejemplo:

- Nemo;
- ChatGPT y WebApps;
- Galculator;
- Kitty;
- Krita;
- mpv;
- Nest UI;
- Noctalia;
- Vivaldi;
- visor de imágenes.

General no requiere un proveedor propio: es el resultado de mantener visibles solamente las Desktop Entries apropiadas para el uso diario.

### Avanzado

El proveedor `nest/advanced` publica:

| Desktop Entry original | Nombre presentado | Ejecución |
|---|---|---|
| `qt6ct.desktop` | Ajustes de Qt6 | gráfica |
| `btop.desktop` | btop++ | terminal |
| `btrfs-assistant.desktop` | Btrfs Assistant | gráfica |
| `arch-update.desktop` | Cachy-Update | terminal |
| `org.cachyos.KernelManager.desktop` | CachyOS Kernel Manager | gráfica |
| `gmic_qt.desktop` | G’MIC-Qt | gráfica |
| `lstopo.desktop` | Hardware Locality lstopo | gráfica |
| `limine-snapper-restore.desktop` | Limine-snapper-restore | gráfica |
| `org.gnome.Meld.desktop` | Meld | gráfica |
| `micro.desktop` | Micro | terminal |
| `org.cachyos.scx-manager.desktop` | SchedExt GUI Manager | gráfica |
| `uuctl.desktop` | uuctl | gráfica/picker |

Flujo visual comprobado:

```text
abrir launcher
→ escribir /adv
→ seleccionar N.E.S.T. · Avanzado
→ buscar o recorrer herramientas
→ ejecutar
```

El prefijo mantiene las herramientas fuera de la búsqueda global. La selección explícita del proveedor crea una segunda capa visual y reduce aperturas accidentales de utilidades administrativas.

### Oculto

Las siguientes entradas se ocultaron del launcher sin retirar sus paquetes:

| Desktop Entry | Función conservada |
|---|---|
| `avahi-discover.desktop` | exploración Zeroconf |
| `bssh.desktop` | exploración SSH mediante Avahi |
| `bvnc.desktop` | exploración VNC mediante Avahi |
| `org.gnome.FileRoller.desktop` | compresión y extracción integrada con Nemo |
| `qv4l2.desktop` | diagnóstico V4L2 |
| `qvidcap.desktop` | captura de prueba V4L2 |
| `vim.desktop` | editor disponible desde terminal |

Todos los comandos correspondientes continuaron presentes bajo `/usr/bin` después del cambio.

## Arquitectura de la integración Noctalia

Noctalia v5 permite proveedores de launcher mediante plugins Luau. El prototipo usa únicamente su API pública:

```text
plugin.toml
├── id = nest/advanced
├── plugin_api = 4
├── min_noctalia = 5.0.0
└── launcher_provider
    ├── prefix = adv
    ├── include_in_global_search = false
    └── entry = advanced.luau

advanced.luau
├── catálogo de aplicaciones
├── noctalia.fuzzyScore()
├── launcher.setResults()
├── noctalia.runAsync()
└── noctalia.runInTerminal()
```

La barra de categorías nativa de Noctalia no permite actualmente definir grupos arbitrarios como General y Avanzado. Está reservada para categorías expuestas por los proveedores internos compatibles. Por ello no se modificó el núcleo de la shell ni se forzaron valores Freedesktop ficticios.

El proveedor prefijado usa la integración pública soportada, es actualizable y reemplazable. Si Noctalia deja de ser la shell activa, Nest podrá conservar la misma política y traducirla mediante otro Launcher Adapter.

## Overrides XDG

Las entradas avanzadas y ocultas usan copias locales con el mismo Desktop ID:

```text
/usr/share/applications/<id>.desktop
→ ~/.local/share/applications/<id>.desktop
```

La copia local conserva el contenido original y establece:

```ini
NoDisplay=true
```

El orden de precedencia XDG hace que la entrada local oculte la versión del sistema en launchers compatibles. El paquete, el binario, las asociaciones y el archivo original permanecen instalados.

Este patrón es preferible a editar `/usr/share/applications`, porque:

- pacman conserva la propiedad de sus archivos;
- las actualizaciones no sobrescriben la intención local;
- no se requieren privilegios administrativos;
- el rollback consiste en retirar el override correspondiente;
- Nest puede auditar exactamente qué Desktop IDs administra.

## Riesgo de sincronización post-update

Un override completo representa una copia de la Desktop Entry en el momento de su creación. Si una actualización modifica posteriormente `Exec`, `Icon`, `MimeType`, acciones u otros campos del archivo del sistema, la copia local puede quedar obsoleta.

Nest no debe tratar `NoDisplay=true` como una escritura aislada y olvidada. El futuro módulo deberá comparar ambas versiones y regenerar el override desde la fuente actual conservando únicamente la intención administrada.

Contrato mínimo propuesto:

```text
scan_desktop_entries()
classify(entry_id, general|advanced|hidden)
plan_overrides()
apply_overrides()
sync_from_system()
verify_visibility()
verify_commands()
repair()
rollback()
```

La sincronización debe preservar cambios del usuario que no pertenezcan a Nest y nunca reemplazar silenciosamente un override preexistente.

## Modelo declarativo propuesto

La política no debe depender de nombres traducidos. Debe usar Desktop IDs estables:

```toml
[launcher]
default_layer = "general"

[launcher.entries."btop.desktop"]
layer = "advanced"

[launcher.entries."qv4l2.desktop"]
layer = "hidden"
```

El Core mantendrá la clasificación y los adaptadores materializarán el resultado:

```text
Nest Core
└── Launcher Policy
    ├── manifiesto declarativo
    ├── auditoría de Desktop Entries
    ├── backups y rollback
    └── detección de deriva

Launcher Adapter
├── XDG genérico → NoDisplay y precedencia local
├── Noctalia → proveedor /adv
└── shell futura → mecanismo equivalente
```

## Experiencia futura en Nest UI

La interfaz prevista deberá mostrar:

- nombre, icono y Desktop ID;
- paquete propietario o condición de entrada local;
- comando de ejecución;
- capa actual: General, Avanzado u Oculto;
- diferencias entre el archivo del sistema y el override;
- advertencias por ejecutables ausentes;
- acciones Aplicar, Verificar, Reparar y Restaurar.

Una clasificación no debe desinstalar paquetes. La limpieza de software y la organización visual son operaciones distintas y deben permanecer separadas.

## Estado de implementación

### Validado en el sistema real

- clasificación manual de tres capas;
- siete overrides ocultos;
- doce overrides avanzados;
- plugin local `nest/advanced` v0.2.0;
- búsqueda y ejecución mediante `/adv`;
- validación con `noctalia plugins lint`;
- prueba funcional de aplicaciones gráficas y terminales;
- conservación de integraciones internas.

### Pendiente de incorporar al código canónico

- manifiesto de clasificación administrado por Nest;
- generador idempotente de overrides;
- sincronización después de actualizaciones;
- backup y rollback automatizados;
- detección de colisiones con overrides del usuario;
- instalación del plugin mediante el adaptador Noctalia;
- equivalentes para otras shells;
- interfaz de asignación General, Avanzado y Oculto.

## Decisión resultante

Nest administrará la visibilidad del launcher como una política independiente de la instalación de paquetes.

La primera capa visual debe priorizar aplicaciones cotidianas; las herramientas técnicas conservarán acceso explícito mediante una capa avanzada; las entradas auxiliares podrán ocultarse sin perder su funcionalidad. La implementación debe usar interfaces públicas, precedencia XDG, estado declarativo y operaciones reversibles.
