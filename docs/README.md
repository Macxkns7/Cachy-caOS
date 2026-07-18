# Índice de documentación

**Estado:** Vigente  
**Última revisión:** 2026-07-18

Este archivo es el punto de entrada canónico para comprender Cachy-caOS y Nest.

## Estados documentales

- **Vigente:** describe el sistema o la dirección actual.
- **En desarrollo:** válido como dirección, pero incompleto.
- **Histórico:** conserva una etapa anterior y no debe usarse como guía actual.
- **Pendiente de reemplazo:** se mantiene temporalmente mientras se crea una fuente canónica.

Las reglas completas están en `docs/convenciones-documentales.md`.

## Proyecto actual

| Documento | Estado | Propósito |
|---|---|---|
| `cachyos-manuel.md` | Vigente | Descripción actual de Cachy-caOS |
| `decisiones-importantes.md` | Vigente | Decisiones canónicas y sus motivos |
| `configuraciones-importantes.md` | Vigente | Configuraciones críticas actuales |
| `reconstruccion-desde-cero.md` | En desarrollo | Ruta reproducible de reconstrucción |
| `timeline.md` | Vigente | Historia cronológica del proyecto |

## Nest

| Documento | Estado | Propósito |
|---|---|---|
| `nest/00-vision-y-principios.md` | Vigente | Constitución arquitectónica de Nest |
| `nest/01-metodologia-operativa.md` | Vigente | Método de trabajo y seguridad |
| `nest/02-roadmap-arquitectonico.md` | En desarrollo | Camino técnico a largo plazo |
| `nest/03-estado-de-implementacion.md` | En desarrollo | Estado real de Nest UI, estructura y próximos hitos |

## Módulos

| Documento | Estado | Propósito |
|---|---|---|
| `modulos/webapps.md` | En desarrollo y funcional | Creación e integración de aplicaciones web |
| `modulos/keybinds.md` | En desarrollo y funcional | Administración segura de atajos de Hyprland |

## Integraciones

| Documento | Estado | Propósito |
|---|---|---|
| `integraciones/noctalia-v5.md` | Vigente con investigación abierta | Shell actual, IPC, Polkit y límites con Nest |
| `integraciones/noctalia-temas-y-plantillas.md` | Vigente con investigación abierta | Motor de plantillas, tokens, GTK y estrategia de extensión de Nest |
| `integraciones/noctalia-greeter.md` | Vigente | greetd, PAM, Polkit, instalación y recuperación |

## Investigación

| Documento | Estado | Propósito |
|---|---|---|
| `research/2026-07-ecosistema-shells-y-direccion.md` | Vigente como research | Shells, Wayland y dirección futura |
| `research/2026-07-herramientas-similares-a-nest.md` | Vigente como research | Proyectos adyacentes y estrategia de adopción |
| `research/2026-07-roadmap-hyprland.md` | Vigente como research | Evolución de Hyprland e impacto arquitectónico |

## Histórico

`historico/` conserva documentación que explica etapas anteriores pero que no debe utilizarse como verdad operativa.

### Era Omarchy

- descripción original de Cachy-caOS;
- configuraciones originales;
- guía original de reconstrucción.

## Regla de fuente única

Cada tema debe tener una sola fuente canónica:

- visión y principios → `nest/00-vision-y-principios.md`;
- metodología → `nest/01-metodologia-operativa.md`;
- implementación de Nest → `nest/03-estado-de-implementacion.md`;
- decisiones → `decisiones-importantes.md`;
- estado técnico → `configuraciones-importantes.md`;
- reconstrucción → `reconstruccion-desde-cero.md`;
- WebApps → `modulos/webapps.md`;
- Keybinds → `modulos/keybinds.md`;
- integración general de Noctalia v5 → `integraciones/noctalia-v5.md`;
- temas y plantillas de Noctalia → `integraciones/noctalia-temas-y-plantillas.md`;
- historia → `timeline.md`.

Otros documentos deben enlazar estas fuentes en lugar de duplicarlas.