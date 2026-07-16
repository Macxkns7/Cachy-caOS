# Roadmap de Hyprland y efectos sobre Nest

**Estado:** Research vigente y sujeto a cambios upstream  
**Última revisión:** 2026-07-16

## Propósito

Registrar las señales relevantes sobre la evolución de Hyprland y traducirlas en decisiones prudentes para Cachy-caOS y Nest.

## Conclusión principal

La dirección más consistente del ecosistema es mantener a Hyprland como compositor y desarrollar la experiencia de escritorio mediante componentes externos: shells, barras, launchers, paneles, greeters y servicios especializados.

No existe una base suficientemente sólida para asumir que Hyprland integrará una shell oficial completa que vuelva innecesarios proyectos como Noctalia o Caelestia.

## Tendencias relevantes

- Consolidación del compositor y sus protocolos.
- Mayor interés por mecanismos de sesión compatibles con systemd y UWSM.
- Evolución continua de IPC, reglas de ventanas y configuración.
- Separación entre compositor y shell visual.
- Crecimiento de shells basadas en QuickShell y componentes Wayland nativos.
- Cambios frecuentes en paquetes y archivos de sesión que requieren validación posterior a actualizaciones.

## Implicaciones para Nest

### No acoplarse a detalles internos

Nest debe preferir:

- `hyprctl` e IPC documentado;
- archivos `source` administrados y separados;
- validación antes de recargar;
- detección de capacidades por versión;
- adaptadores pequeños para funciones específicas.

Debe evitar depender de parches sobre archivos distribuidos por el paquete de Hyprland.

### Tratar la shell como reemplazable

Aunque Noctalia sea la shell actual, Nest Core debe continuar funcionando con:

- otra shell para Hyprland;
- componentes separados;
- una futura shell propia;
- un entorno mínimo sin shell completa.

### Prepararse para cambios de sesión

La instalación de Noctalia Greeter reveló un caso concreto:

```text
hyprland-uwsm.desktop
TryExec=uwsm
```

El archivo estaba instalado por el paquete `hyprland`, pero `uwsm` no estaba instalado. El greeter mostró la sesión de todos modos y el inicio falló.

Nest debe validar:

- existencia del ejecutable indicado por `TryExec`;
- comando `Exec` de cada sesión;
- disponibilidad de la sesión predeterminada;
- cambios después de actualizar Hyprland.

## Áreas que requieren seguimiento

- cambios de sintaxis de configuración;
- reglas y propiedades de ventanas;
- protocolos Wayland adoptados o retirados;
- integración con systemd/UWSM;
- requisitos de portals;
- cambios en sesiones `.desktop`;
- IPC y eventos relevantes para shells;
- compatibilidad de wlroots y componentes relacionados.

## Estrategia recomendada

1. Mantener Hyprland limpio y cercano a upstream.
2. Encapsular configuración administrada por Nest en archivos propios.
3. Detectar versión y capacidades en tiempo de ejecución.
4. Probar cambios en una fase de diagnóstico antes de aplicarlos.
5. Mantener snapshots y rollback para actualizaciones importantes.
6. Revisar periódicamente roadmap, releases y cambios incompatibles.
7. No diseñar Nest alrededor de una hipotética shell oficial futura.

## Posición de proyecto

Nest debe prepararse para un ecosistema cambiante, no intentar congelarlo. Su valor estará en absorber cambios mediante adaptadores, diagnósticos y migraciones sin hacer que el usuario reconstruya manualmente todo el escritorio.

## Nota de mantenimiento

Este documento resume una investigación temporal. Debe revisarse cuando Hyprland publique cambios importantes, anuncie nuevos proyectos oficiales o modifique su estrategia de sesión y componentes de escritorio.
