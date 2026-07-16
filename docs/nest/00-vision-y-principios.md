# Nest — visión y principios

Fecha de consolidación: 2026-07-16

## Propósito

Nest será la capa de administración de Cachy-caOS. Su valor no está en reemplazar cada componente del escritorio, sino en convertir un sistema Linux modular y disperso en una plataforma coherente, observable, reversible y fácil de mantener.

Nest debe resolver aquello que normalmente queda repartido entre archivos de configuración, comandos, servicios, logs y documentación incompleta.

## Lo que Nest es

- Un Core independiente de la interfaz visual.
- Un centro de administración modular.
- Una capa de integración entre componentes externos y herramientas propias.
- Un sistema de diagnóstico y recuperación.
- Un registro vivo de decisiones, estado y cambios.
- Una plataforma que permite cambiar piezas sin reconstruir todo el sistema.

## Lo que Nest no debe ser

- Una shell obligatoria.
- Una reimplementación innecesaria de proyectos maduros.
- Un conjunto de scripts que ejecutan comandos sin contexto.
- Una interfaz bonita desconectada del estado real del sistema.
- Una capa que sobrescribe configuraciones del usuario sin autorización.

## Constitución de Nest

1. **Core independiente de la shell.** Noctalia, Caelestia, Waybar u otras interfaces deben poder cambiarse sin afectar las funciones críticas.
2. **Toda shell es reemplazable.** La interfaz actual es un módulo, no la identidad del sistema.
3. **Interfaces estables para funciones críticas.** Backups, snapshots, actualizaciones, health checks y configuración no deben depender de una shell específica.
4. **Prioridad a la configuración del usuario.** Nest detecta, explica y propone; no destruye decisiones previas.
5. **Migraciones reversibles.** Toda sustitución importante debe incluir respaldo y ruta de retorno.
6. **Cambios verificables.** Antes y después de modificar el sistema se debe comprobar su estado.
7. **Adopción antes que fork.** Si una herramienta externa está bien diseñada, Nest debe integrarla y facilitar su uso. Solo se considera un fork cuando existan necesidades reales no atendidas por upstream.
8. **Documentación como parte del sistema.** El conocimiento adquirido debe sobrevivir a los chats, reinstalaciones y cambios de equipo.

## Arquitectura objetivo

```text
Nest Core
├── Config Store
├── System Doctor
├── Snapshot / Rollback
├── Update Manager
├── Backup Manager
├── Module Registry
├── Integration Adapters
└── Event / Audit Log

Servicios del escritorio
├── audio
├── brillo
├── red
├── Bluetooth
├── energía
├── notificaciones
└── sesión

Adaptadores
├── shell adapter
├── display-manager adapter
├── launcher adapter
├── theme adapter
└── external-tool adapter

Interfaces
├── Nest UI
├── CLI
└── futuras interfaces
```

## Dirección a largo plazo

Nest debe permitir construir una experiencia Cachy-caOS estable aun cuando cambien las piezas visuales del ecosistema Linux. La evolución de Hyprland, Wayland y las shells modernas apunta hacia componentes especializados e intercambiables; Nest debe aprovechar esa modularidad, no combatirla.

La meta no es controlar todo el software, sino controlar **cómo se integra, valida, configura, recupera y documenta** dentro del sistema.