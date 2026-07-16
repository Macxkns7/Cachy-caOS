# Cachy-caOS

**Estado:** Vigente  
**Última revisión:** 2026-07-16  
**Histórico relacionado:** `docs/historico/era-omarchy/cachyos-manuel-2026-06-20.md`

## Descripción

Cachy-caOS es el sistema Linux personal de Manuel, construido sobre **CachyOS + Hyprland** y administrado progresivamente mediante **Nest**.

El proyecto busca una experiencia modular, comprensible, reversible y documentada. No pretende acumular personalizaciones ni reescribir proyectos externos sin necesidad: adopta soluciones bien construidas, las integra con criterio y añade diagnóstico, recuperación y facilidad de uso.

## Dirección vigente

- CachyOS limpio como base.
- Hyprland como compositor.
- Noctalia v5 como shell actual y reemplazable.
- greetd + Noctalia Greeter para el inicio de sesión.
- Fish como shell interactiva principal.
- Kitty como terminal.
- Nest como plataforma de administración, no como shell.
- WebApps y módulos propios con identidades de escritorio consistentes.
- Snapshots, backups y rollback como funciones de primera clase.

## Filosofía

- Funcionalidad antes que apariencia.
- Entender antes de automatizar.
- Diagnosticar antes de modificar.
- Cambios reversibles y con respaldo.
- Configuración del usuario por encima de defaults externos.
- Core independiente de la shell visual.
- Documentación como parte del producto.

## Hitos

1. Migración desde Ubuntu hacia CachyOS.
2. Etapa Omarchy como referencia y aprendizaje.
3. Decisión de independizar Cachy-caOS de Omarchy.
4. Creación de Nest y Nest UI.
5. Desarrollo de módulos propios de WebApps y keybinds.
6. Adopción de Noctalia v5 como shell actual.
7. Migración de SDDM a greetd + Noctalia Greeter.
8. Inicio de una arquitectura documental y técnica propia.

## Estado

El sistema está operativo y en desarrollo activo. La arquitectura aún evoluciona, pero la dirección oficial ya es independiente de Omarchy y orientada a Nest como capa estable de administración.