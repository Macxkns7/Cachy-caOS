# Tablero maestro de Cachy-caOS y Nest

**Estado:** Vivo — fuente operativa principal  
**Última revisión:** 2026-07-21

## Propósito

Mantener en un solo lugar el estado operativo del proyecto: trabajo terminado, tareas activas, pendientes, descubrimientos nuevos y prioridades de la próxima sesión.

Este documento debe revisarse al comenzar una sesión importante y actualizarse cada vez que se solicite una actualización general de la documentación del repositorio.

No sustituye los documentos técnicos ni el roadmap arquitectónico. Su función es responder rápidamente:

- ¿qué ya está terminado y validado?;
- ¿qué está en curso?;
- ¿qué quedó pendiente?;
- ¿qué descubrimientos generaron trabajo nuevo?;
- ¿qué conviene abordar a continuación?

## Convención de estados

- ✅ **Terminado:** implementado, comprobado y documentado.
- 🟡 **En curso:** investigación o integración activa.
- ⏳ **Pendiente:** definido, pero todavía no iniciado o no priorizado.
- 🔬 **Investigación:** requiere evidencia antes de tomar una decisión.
- 🧊 **En pausa:** conservado conscientemente para retomarlo más adelante.
- ❌ **Descartado:** evaluado y abandonado con una razón documentada.

## Foco de la próxima sesión

1. Diseñar el manifiesto de perfiles por dispositivo y el adaptador de EasyEffects para el futuro Nest Audio.
2. Continuar afinando la experiencia visual, priorizando problemas reproducibles antes que personalización estética aislada.
3. Actualizar la base técnica de Nest con los patrones ya validados: aplicaciones predeterminadas, overrides XDG y compatibilidad Wayland.

El foco puede cambiar al inicio de una sesión, pero debe quedar registrado aquí antes de abrir varios frentes en paralelo.

---

# Vista ejecutiva

## Sistema base y escritorio

- ✅ CachyOS como base oficial.
- ✅ Hyprland limpio como compositor.
- ✅ Noctalia v5 como shell actual y reemplazable.
- ✅ Independencia estructural de Omarchy definida.
- ✅ Fish como shell interactiva principal.
- ✅ Btrfs + Snapper como mecanismo de seguridad y recuperación.
- 🟡 Reconstrucción reproducible desde una instalación limpia.
- ⏳ Instalador por fases de Cachy-caOS/Nest.

## Experiencia visual y toolkits

- ✅ Investigación y documentación de la arquitectura GTK.
- ✅ Tema GTK3 integrado mediante `adw-gtk-theme` y plantillas de Noctalia.
- ✅ Nemo completamente integrado visualmente con Noctalia.
- ✅ Loupe integrado como visualizador de imágenes oficial.
- ✅ Kitty ajustado a un tamaño de fuente cómodo mediante `font_size 9.5`.
- ✅ Krita corregido para usar Wayland nativo mediante override local de su Desktop Entry.
- ✅ Papirus-Dark adoptado como tema de iconos para GTK y Qt.
- ✅ Carpetas Papirus `violet` validadas con la paleta Lilac AMOLED.
- ✅ `qt6ct` integrado mediante `QT_QPA_PLATFORMTHEME` antes del arranque de Noctalia.
- ⏳ Implementar el módulo declarativo de iconos y apariencia en Nest.
- 🟡 Afinar la experiencia visual general del sistema.
- 🔬 Investigar arquitectura, temas y escalado de aplicaciones Qt.
- 🔬 Crear inventario de aplicaciones que usan Wayland nativo o XWayland.

## Multimedia

- ✅ Base multimedia revisada.
- ✅ Visualizador de imágenes elegido e integrado.
- ✅ EasyEffects instalado y validado sobre PipeWire.
- ✅ Perfil específico `NEST-Lenovo-13sG2-HK-v2` aprobado mediante pruebas A/B.
- ✅ Presets neutral y afinado exportados y versionados.
- ✅ Teclas de volumen estabilizadas al desactivar repetición incremental.
- ⏳ Diseñar Nest Audio con perfiles por dispositivo, prueba A/B, verificación y rollback.
- ⏳ Revisar reproductores, edición multimedia y asociaciones predeterminadas restantes cuando exista una necesidad real.

## Archivos y aplicaciones predeterminadas

- ✅ Nemo adoptado como administrador de archivos actual.
- ✅ Loupe asociado a los MIME comunes de imágenes.
- ✅ Diagnóstico de asociaciones mediante `xdg-mime` y `gio mime`.
- ✅ Decisión de centralizar las asociaciones MIME en Nest.
- ⏳ Crear una fuente declarativa de aplicaciones predeterminadas.
- ⏳ Diseñar comandos de aplicar, verificar, reparar y restaurar asociaciones MIME.

## Compatibilidad Wayland

- ✅ Caso Krita diagnosticado: el desenfoque era causado por XWayland.
- ✅ Lanzamiento validado con `QT_QPA_PLATFORM=wayland`.
- ✅ Override persistente creado en `~/.local/share/applications/org.kde.krita.desktop`.
- ✅ Confirmado que no era necesario reemplazar el paquete de CachyOS.
- 🔬 Detectar backend real por aplicación.
- ⏳ Diseñar un módulo de compatibilidad Wayland con prueba y rollback.
- ⏳ Definir una base declarativa de variables de entorno por aplicación.
- ⏳ Evaluar otras aplicaciones Qt solo cuando estén instaladas o sean candidatas reales del sistema.

## Nest — base técnica

- ✅ Nest definido como plataforma modular de administración y no como shell.
- ✅ Separación conceptual entre Core, módulos e interfaz.
- ✅ Nest UI temprana disponible como TUI con Kitty y `gum`.
- ✅ Módulo WebApps funcional.
- ✅ Módulo Keybinds funcional en el sistema de desarrollo.
- ✅ Noctalia Greeter identificado como primera integración externa administrada.
- ✅ Patrón validado: instalación de aplicaciones separada de asociaciones MIME.
- ✅ Patrón validado: overrides locales XDG en lugar de modificar archivos del sistema.
- ✅ Patrón validado: compatibilidad gráfica configurada por aplicación, no mediante variables globales.
- ✅ Patrón validado: tema de iconos separado en adaptadores GTK, Qt, entorno y variantes de carpetas.
- ✅ Patrón validado: organización General/Avanzado/Oculto independiente de la instalación de paquetes.
- ✅ Proveedor local `nest/advanced` v0.2.0 validado con doce herramientas bajo `/adv`.
- ✅ Siete entradas auxiliares ocultas mediante overrides XDG sin perder funcionalidad.
- ✅ Patrón validado: perfiles de audio explícitos por dispositivo mediante EasyEffects Adapter.
- ✅ Referencia neutral, perfil afinado y rollback de audio versionados.
- 🟡 Continuar construyendo la base técnica de Nest.
- ⏳ Cerrar la v0.4 de Nest UI.
- ⏳ Normalizar rutas y estructura de instalación.
- ⏳ Definir contratos entre Core y módulos.
- ⏳ Crear diagnóstico común y formato de resultados.
- ⏳ Diseñar instalador y actualizador.
- ⏳ Incorporar Launcher Policy, reconciliador XDG y plugin avanzado al árbol canónico.
- ⏳ Incorporar Keybinds al árbol canónico de código fuente.
- ⏳ Importar el PNG maestro de Nest al repositorio.
- ⏳ Iniciar una interfaz gráfica desacoplada de la shell.

## Diagnóstico y mantenimiento

- ✅ Metodología establecida: diagnóstico → respaldo → cambio mínimo → verificación → documentación.
- ✅ Snapshots antes de cambios importantes.
- ✅ Chat y flujo dedicados a revisiones post-update.
- ⏳ System Doctor.
- ⏳ Revisión automática de `.pacnew`.
- ⏳ Estado de mirrors.
- ⏳ Estado de snapshots.
- ⏳ Kernel, paquetes y servicios fallidos.
- ⏳ Backups y restauración.
- ⏳ Logs y coredumps relevantes.
- ⏳ Validación automática de integraciones.
- 🧊 Seguimiento periódico del lector Goodix `27c6:55a4` hasta que exista soporte útil.

## Noctalia e integraciones

- ✅ Noctalia v5 adoptada como shell actual.
- ✅ Investigación de shells alternativas y dirección del ecosistema.
- ✅ Integración de temas y plantillas GTK documentada.
- ✅ Noctalia Greeter + greetd instalados y validados.
- ✅ SDDM retirado tras validar greetd; TTY conservada como recuperación primaria.
- ✅ Dependencia runtime `wlroots0.20` del greeter restaurada y documentada.
- ✅ Plugin API de Noctalia validada mediante el proveedor prefijado `/adv` de Nest.
- ✅ Separación General/Avanzado/Oculto comprobada sin modificar el núcleo de Noctalia.
- 🔬 Seguir observando límites, IPC y puntos de integración con Nest.
- ⏳ Diseñar Shell Adapter y Theme Adapter.
- ⏳ Evitar que cualquier función crítica dependa de Noctalia.

## WebApps e identidad de aplicaciones

- ✅ WebApps v0.6 Beta funcional.
- ✅ Creación, listado, eliminación y reparación.
- ✅ `StartupWMClass` generado para Vivaldi.
- ✅ Agrupación correcta entre accesos fijados y ventanas Wayland.
- ✅ Reparación idempotente de Desktop Entries antiguas.
- ⏳ Adaptadores de identidad para otros navegadores.
- ⏳ Centralizar manejo de Desktop Entries, iconos y clases.
- 🔬 Investigar comportamientos restantes del dock de Noctalia cuando aparezcan casos reproducibles.

## Documentación y memoria del proyecto

- ✅ Índice documental canónico.
- ✅ Separación entre documentación vigente e histórica.
- ✅ Decisiones importantes y configuraciones críticas mantenidas.
- ✅ Timeline del proyecto.
- ✅ Documentación técnica de Loupe y MIME.
- ✅ Documentación técnica de Krita y Wayland.
- ✅ Tablero maestro creado como fuente operativa.
- 🟡 Mantener este tablero en cada actualización general de GitHub.
- ⏳ Añadir referencias al tablero cuando se creen nuevas áreas documentales.

---

# Actividades terminadas recientemente

## 2026-07-21

- ✅ Instalados EasyEffects, `lsp-plugins-lv2` y Calf sobre la pila PipeWire existente.
- ✅ Confirmada la activación bajo demanda de PipeWire Pulse mediante socket.
- ✅ Construida y descartada una primera curva agresiva después de pruebas auditivas.
- ✅ Validada la v1 neutral con limitador LSP: entrada +3 dB, threshold -1 dB y lookahead 5 ms.
- ✅ Afinada y aprobada `NEST-Lenovo-13sG2-HK-v2` para los parlantes Harman Kardon del Lenovo.
- ✅ Versionados ambos presets y documentado su alcance específico por dispositivo.
- ✅ Diagnosticada la subida/bajada completa ocasional del volumen como repetición de bindings a 25 eventos/s.
- ✅ Cambiados los bindings de volumen a `repeating = false` y comprobado un salto estable de 5 % por pulsación.
- ✅ Definido el alcance inicial del futuro módulo Nest Audio.

## 2026-07-20

- ✅ Completada limpieza controlada: 92 paquetes netos retirados, cero huérfanos y cero servicios fallidos.
- ✅ Nemo consolidado como gestor de archivos; Dolphin retirado.
- ✅ mpv consolidado como reproductor; VLC retirado.
- ✅ SDDM retirado después de validar greetd.
- ✅ Eliminados 141 archivos de caché de paquetes desinstalados, recuperando 438.28 MiB.
- ✅ Detectada y reparada dependencia ELF de Noctalia Greeter invisible para pacman.
- ✅ Instalado `papirus-icon-theme` desde repositorios oficiales.
- ✅ Activado `Papirus-Dark` mediante `gsettings` y `qt6ct`.
- ✅ Persistido `QT_QPA_PLATFORMTHEME=qt6ct` en la configuración Lua de Hyprland.
- ✅ Instalado Papirus Folders v1.14.0 bajo `~/.local` tras inspeccionar el instalador.
- ✅ Aplicado y validado visualmente el color `violet`.
- ✅ Documentada la estrategia de automatización, reparación y rollback para Nest.
- ✅ Clasificado el launcher en General, Avanzado y Oculto sin retirar paquetes.
- ✅ Creados diecinueve overrides XDG: doce avanzados y siete ocultos.
- ✅ Validado `nest/advanced` v0.2.0 con iconos, búsqueda y ejecución gráfica o en terminal.
- ✅ Conservadas las integraciones internas, incluida la apertura de ZIP con File Roller desde Nemo.

## 2026-07-19

- ✅ Ajustado Kitty mediante `font_size 9.5` en `~/.config/kitty/kitty.conf`.
- ✅ Confirmada la configuración efectiva de Kitty y su recarga.
- ✅ Diagnosticado el desenfoque de Krita como ejecución mediante XWayland.
- ✅ Validado Krita 6.0.2.1 con backend Wayland nativo.
- ✅ Creado override local de `org.kde.krita.desktop` con `QT_QPA_PLATFORM=wayland`.
- ✅ Comprobada la apertura correcta desde el launcher.
- ✅ Documentado el patrón para un futuro módulo de compatibilidad Wayland de Nest.

## 2026-07-18

- ✅ Loupe elegido como visualizador oficial.
- ✅ Integración con Nemo validada.
- ✅ MIME comunes de imágenes asignados a Loupe.
- ✅ Definida la separación entre módulos de aplicación y aplicaciones predeterminadas.

---

# Pendientes que no deben perderse

- ⏳ Diseñar e implementar Nest Audio a partir del perfil EasyEffects ya validado.
- 🟡 Continuar la afinación visual del sistema.
- 🟡 Continuar la base técnica de Nest.
- ⏳ Crear módulo central de aplicaciones predeterminadas/MIME.
- ⏳ Crear módulo de compatibilidad Wayland y overrides XDG.
- ⏳ Completar la investigación general de la capa Qt más allá del caso ya validado de iconos.
- ⏳ Implementar el módulo Appearance / System Icons de Nest.
- ⏳ Integrar reparación de Papirus Folders en System Doctor.
- ⏳ Cerrar v0.4 de Nest UI y normalizar contratos.
- ⏳ Diseñar System Doctor y revisión post-update.
- ⏳ Incorporar detección de ELF no empaquetados y bibliotecas ausentes.
- ⏳ Completar la reconstrucción reproducible desde cero.
- ⏳ Importar el icono maestro de Nest al árbol de código.
- ⏳ Diseñar instalador y actualizador.
- ⏳ Versionar el proveedor `nest/advanced` y el manifiesto declarativo del launcher.
- ⏳ Implementar sincronización post-update de overrides XDG y detección de deriva.
- 🧊 Herramienta futura de edición inteligente de wallpapers como módulo de Nest.

---

# Reglas de mantenimiento del tablero

1. Revisarlo al inicio de cada sesión importante del proyecto.
2. Actualizarlo cuando se solicite actualizar la documentación de GitHub.
3. No marcar una actividad como terminada sin una validación real.
4. Cuando una tarea genere una decisión técnica, enlazar su documento canónico.
5. Cuando aparezca una tarea nueva durante otra investigación, registrarla antes de que se pierda.
6. Mantener pocas prioridades activas; el resto debe quedar como pendiente o en pausa.
7. No duplicar explicaciones técnicas extensas: el tablero resume y enlaza.
8. Diferenciar claramente el estado actual de Cachy-caOS de configuraciones históricas.

## Fuentes canónicas relacionadas

- Arquitectura y dirección: `docs/nest/00-vision-y-principios.md`.
- Método operativo: `docs/nest/01-metodologia-operativa.md`.
- Roadmap técnico: `docs/nest/02-roadmap-arquitectonico.md`.
- Implementación real de Nest: `docs/nest/03-estado-de-implementacion.md`.
- Decisiones: `docs/decisiones-importantes.md`.
- Estado técnico: `docs/configuraciones-importantes.md`.
- Historia: `docs/timeline.md`.
- Loupe y MIME: `docs/modulos/visor-imagenes.md`.
- Krita y Wayland: `docs/modulos/krita-wayland.md`.
- Iconos del sistema: `docs/modulos/iconos-sistema.md`.
- Limpieza y auditoría ELF: `docs/modulos/limpieza-sistema.md`.
- Organización del launcher: `docs/modulos/organizacion-launcher.md`.
- Audio, EasyEffects y perfiles por dispositivo: `docs/modulos/audio-easyeffects.md`.
