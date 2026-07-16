# Índice de documentación

**Estado:** Vigente  
**Última revisión:** 2026-07-16

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

## Integraciones

| Documento | Estado | Propósito |
|---|---|---|
| `integraciones/noctalia-greeter.md` | Vigente | greetd, PAM, Polkit, instalación y recuperación |

## Investigación

| Documento | Estado | Propósito |
|---|---|---|
| `research/2026-07-ecosistema-shells-y-direccion.md` | Vigente como research | Shells, Wayland y dirección futura |

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
- decisiones → `decisiones-importantes.md`;
- estado técnico → `configuraciones-importantes.md`;
- reconstrucción → `reconstruccion-desde-cero.md`;
- historia → `timeline.md`.

Otros documentos deben enlazar estas fuentes en lugar de duplicarlas.