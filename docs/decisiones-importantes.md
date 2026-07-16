# Decisiones importantes

Fecha de creación: 2026-06-20

Última actualización: 2026-07-16

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

Primer caso validado:

* Noctalia Greeter se adopta como backend de login administrado por Nest.

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

## 2026-07-16

* Omarchy reclasificado como etapa histórica superada.
* Nest definido como plataforma de administración modular.
* Registrados los principios de independencia de shell, adopción antes que fork, compatibilidad Fish y migraciones reversibles.
* Noctalia Greeter reconocido como primera integración externa administrada.

## 2026-06-20

* Documento creado.
* Registradas las decisiones fundacionales de Cachy-caOS.