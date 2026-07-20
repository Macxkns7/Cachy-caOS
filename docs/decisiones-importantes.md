# Decisiones importantes

Fecha de creación: 2026-06-20

Última actualización: 2026-07-20

---

## Objetivo

Registrar las decisiones que dieron forma a Cachy-caOS y explicar por qué fueron tomadas.

Este documento preserva tanto las decisiones vigentes como las etapas históricas superadas, para comprender la evolución del sistema sin depender de la memoria.

---

# CachyOS sobre Ubuntu

Decisión vigente:

Migrar completamente desde Ubuntu hacia CachyOS.

Motivos:

* Mejor rendimiento.
* Mayor control del sistema.
* Mejor experiencia para personalización.
* Filosofía más alineada con el proyecto.

---

# Omarchy como etapa de aprendizaje

Decisión histórica, actualmente superada:

Omarchy fue adoptado inicialmente como base del entorno por su minimalismo, productividad e integración con Hyprland.

Evolución:

En julio de 2026 se decidió abandonar la dependencia estructural de Omarchy y avanzar hacia CachyOS + Hyprland limpios, conservando únicamente ideas, patrones o funciones que hayan demostrado valor real.

Motivos del cambio:

* Controlar las decisiones del sistema.
* Evitar depender del ritmo y la dirección de un tercero.
* Comprender y mantener cada componente.
* Construir una arquitectura propia alrededor de Nest.

---

# Nest como plataforma de administración

Decisión vigente:

Nest no será una shell monolítica. Será la capa de administración modular de Cachy-caOS.

Motivos:

* Permitir cambiar shells sin afectar el Core.
* Integrar herramientas externas bien construidas sin reimplementarlas.
* Centralizar diagnóstico, configuración, backups, mantenimiento y recuperación.
* Mantener interfaces visuales reemplazables.

---

# Core independiente de la shell

Decisión vigente:

Noctalia, Caelestia, Waybar u otra shell futura deben ser módulos intercambiables.

Motivos:

* El ecosistema Wayland evoluciona rápidamente.
* Las funciones críticas no pueden depender de una interfaz concreta.
* La estabilidad del sistema debe sobrevivir a cambios visuales.

---

# Adopción antes que fork

Decisión vigente:

No se creará una versión propia de una herramienta externa únicamente por estética, branding o entusiasmo.

Nest adoptará e integrará proyectos bien diseñados. Solo se considerará un fork cuando existan necesidades técnicas reales que upstream no pueda o no quiera resolver.

Primeros casos validados:

* Noctalia Greeter se adopta como backend de login administrado por Nest.
* Loupe se adopta como visualizador de imágenes sin CSS específico ni fork.

---

# Loupe como visualizador de imágenes oficial

Decisión vigente:

Utilizar Loupe como visualizador de imágenes predeterminado de Cachy-caOS.

Motivos:

* Está construido con GTK4 y libadwaita.
* Se integra correctamente con Wayland, Noctalia y la identidad visual actual.
* Abre imágenes de inmediato desde Nemo.
* Mantiene una interfaz simple, moderna y enfocada en el contenido.
* Su mantenimiento pertenece al ecosistema GNOME.
* No requiere personalización específica comprobada.

La instalación de una aplicación y la definición de sus tipos MIME serán responsabilidades separadas dentro de Nest.

El módulo de Loupe deberá instalar la aplicación, mientras un módulo central de asociaciones predeterminadas administrará `org.gnome.Loupe.desktop` para los MIME de imágenes compatibles.

Fuente técnica: `docs/modulos/visor-imagenes.md`.

---

# Asociaciones MIME centralizadas

Decisión vigente:

Nest administrará las aplicaciones predeterminadas mediante una fuente declarativa y un módulo central, en lugar de distribuir comandos `xdg-mime` dentro de cada instalador de aplicación.

Motivos:

* Evitar duplicación y acoplamiento.
* Permitir sustituir una aplicación sin modificar módulos ajenos.
* Diagnosticar y validar el estado antes y después de cada cambio.
* Tratar la asociación MIME como configuración del usuario y no como una propiedad de Nemo u otra aplicación concreta.
* Mantener el proceso reproducible, auditable e idempotente.

La operación debe cambiar únicamente el valor predeterminado y conservar registradas las aplicaciones alternativas.

---

# Iconos del sistema como capacidad transversal

Decisión vigente:

Papirus-Dark será el tema de iconos validado para el perfil visual actual, con carpetas `violet`. Nest administrará los iconos como una capacidad transversal del Core y no como una función propia de Noctalia.

La integración se dividirá en adaptadores:

* tema Freedesktop instalado;
* GTK mediante `gsettings`;
* Qt mediante un proveedor de plataforma;
* entorno de Hyprland antes del arranque de la shell;
* variantes y reparación de Papirus Folders.

Motivos:

* Noctalia no guarda una selección de tema de iconos.
* GTK y Qt consumen configuraciones distintas.
* La shell debe poder reemplazarse sin perder la identidad visual.
* Las actualizaciones de Papirus pueden restaurar el color de carpetas.
* La operación futura debe poder diagnosticar, aplicar, verificar, reparar y revertir.
* La configuración de terceros debe editarse por claves y no reemplazarse completa.

`qt6ct` es el proveedor Qt validado actualmente. `hyprland-qt-support` no cumple esa función. `hyprqt6engine` solo se adoptará cuando esté disponible y sea comprobado en el sistema real.

Fuente técnica: `docs/modulos/iconos-sistema.md`.

---

# Minimalismo antes que complejidad

Decisión vigente:

Mantener un sistema simple y ordenado.

Motivos:

* Menor carga mental.
* Mayor facilidad de mantenimiento.
* Menor cantidad de errores.
* Experiencia más limpia.

Ejemplos:

* Eliminación de software innecesario.
* Reducción de duplicidades.
* Uso selectivo de herramientas.

---

# Personalización con propósito

Decisión vigente:

Toda personalización debe aportar valor real.

Motivos:

* Evitar modificaciones únicamente estéticas.
* Mantener coherencia visual.
* Facilitar mantenimiento futuro.
* Priorizar accesibilidad, integración o productividad.

---

# PWAs y WebApps administradas

Decisión vigente:

Utilizar WebApps cuando resulten más coherentes que instalar aplicaciones redundantes, y administrarlas mediante Nest.

Motivos:

* Integración sencilla.
* Menor consumo de recursos.
* Menor mantenimiento.
* Mejor organización del sistema.

---

# Español y adaptación al usuario

Decisión vigente:

El sistema y las herramientas propias deben ofrecer una experiencia coherente en español, sin acoplarse a archivos internos de una distribución externa.

---

# Snapshots como mecanismo principal de seguridad

Decisión vigente:

Crear snapshots antes de cambios importantes.

Motivos:

* Recuperación rápida.
* Reducción de riesgos.
* Libertad para experimentar.

Principio asociado:

> Snapshot primero.

---

# Diagnóstico antes de modificación

Decisión vigente:

Los prerrequisitos y pasos de diagnóstico deben presentarse y ejecutarse antes de la solución final.

Motivos:

* Evitar cambios prematuros.
* Mantener evidencia del estado anterior.
* Reducir errores durante el troubleshooting.

---

# Fish como shell interactivo principal

Decisión vigente:

Las instrucciones para Cachy-caOS deben considerar Fish antes de usar sintaxis de Bash.

Nest deberá detectar el shell y evitar depender de comandos copiados que cambien según Fish, Bash o Zsh.

---

# Migraciones reversibles

Decisión vigente:

Toda sustitución crítica debe incluir respaldo, validación y ruta de recuperación.

Ejemplo aplicado:

Durante la migración de SDDM a greetd + Noctalia Greeter se mantuvo SDDM instalado, se habilitó una TTY de rescate y se validaron PAM, Polkit, binarios, assets y sesiones antes del cambio final.

---

# Documentación obligatoria

Decisión vigente:

Documentar configuraciones, hitos, errores, procedimientos y decisiones.

Motivos:

* Reducir dependencia de la memoria.
* Facilitar reconstrucción futura.
* Mantener continuidad entre chats y etapas.
* Convertir experiencia real en funciones futuras de Nest.

---

# Cachy-caOS como proyecto

Decisión vigente:

Tratar el sistema operativo como un proyecto documentado y reproducible.

Motivos:

* Evolución controlada.
* Historial verificable.
* Reproducibilidad.
* Aprendizaje continuo.

---

# Historial de cambios

## 2026-07-20

* Papirus-Dark adoptado como tema de iconos validado.
* Carpetas `violet` adoptadas para el perfil Lilac AMOLED.
* Iconos definidos como capacidad transversal de Nest con adaptadores GTK, Qt, entorno y reparación.
* `qt6ct` validado como proveedor Qt actual; `hyprland-qt-support` descartado para esta función.

## 2026-07-18

* Loupe adoptado como visualizador de imágenes oficial.
* Separadas las responsabilidades de instalación de aplicaciones y asociaciones MIME.
* Definida una estrategia centralizada y declarativa para aplicaciones predeterminadas en Nest.

## 2026-07-16

* Omarchy reclasificado como etapa histórica superada.
* Nest definido como plataforma de administración modular.
* Registrados los principios de independencia de shell, adopción antes que fork, compatibilidad Fish y migraciones reversibles.
* Noctalia Greeter reconocido como primera integración externa administrada.

## 2026-06-20

* Documento creado.
* Registradas las decisiones fundacionales de Cachy-caOS.