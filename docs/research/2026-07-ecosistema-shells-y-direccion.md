# Ecosistema de shells y dirección de Nest

Fecha de consolidación: 2026-07-16

## Contexto

El ecosistema Wayland está avanzando hacia una separación cada vez más clara entre:

- compositor;
- shell visual;
- servicios del escritorio;
- herramientas de administración;
- aplicaciones y módulos externos.

Hyprland puede actuar como compositor sin exigir una shell monolítica. Proyectos como Noctalia, Caelestia y otras interfaces construidas alrededor de tecnologías como QuickShell demuestran que la experiencia visual puede evolucionar de forma independiente del compositor.

## Conclusión estratégica

Nest no debe competir en la misma categoría que una shell. Debe situarse por debajo de ellas como plataforma de administración.

```text
Shell visual
    ↓
Shell Adapter
    ↓
Nest Core
    ↓
servicios, configuración, mantenimiento y recuperación
```

Esto permite:

- sustituir una shell sin perder funciones críticas;
- comparar e integrar nuevas interfaces sin rehacer el sistema;
- conservar una experiencia estable durante cambios rápidos del ecosistema;
- administrar componentes comunes desde una única fuente de verdad.

## Criterios para evaluar shells

Antes de integrar una shell se debe revisar:

- actividad y mantenimiento del proyecto;
- comunidad y adopción;
- arquitectura y lenguaje utilizado;
- dependencia del compositor;
- configuración persistente;
- IPC o interfaces disponibles;
- capacidad de recarga;
- consumo y estabilidad;
- integración con aplicaciones `.desktop`;
- soporte para temas, paneles, dock, launcher, notificaciones y servicios;
- facilidad para respaldar, migrar y desinstalar.

La popularidad por sí sola no es suficiente. Nest debe privilegiar proyectos mantenibles y con límites claros.

## Noctalia v5 como shell actual

Noctalia v5 es la shell utilizada actualmente en Cachy-caOS. Se considera una integración reemplazable, no una dependencia del Core.

Aprendizajes iniciales:

- dispone de launcher y dock internos;
- administra configuración persistente en TOML;
- ofrece IPC mediante `noctalia msg`;
- incluye agente Polkit opcional;
- puede sincronizar apariencia con Noctalia Greeter;
- todavía se encuentra en una etapa de evolución activa, por lo que pueden aparecer limitaciones de integración.

## Herramientas similares a Nest

Existen múltiples herramientas que resuelven partes del problema —control centers, instaladores, dotfile managers, shells y utilidades de mantenimiento—, pero Nest busca unir capacidades que normalmente permanecen separadas:

- gestión del sistema;
- experiencia de escritorio;
- diagnóstico;
- recuperación;
- documentación;
- módulos propios;
- integraciones externas.

La diferenciación de Nest no debe basarse en tener más widgets, sino en conservar contexto, explicar riesgos y hacer reversibles las operaciones.

## Dirección futura de Hyprland y riesgo de acoplamiento

No se debe asumir que Hyprland incorporará o recomendará permanentemente una shell oficial. Incluso si surgiera una integración privilegiada, Nest debe mantener su independencia.

Regla:

> Las decisiones futuras de Hyprland pueden influir en los adaptadores, pero no deben redefinir el Core de Nest.

## Próximos pasos de investigación

- mantener una lista pequeña de shells relevantes;
- comparar sus mecanismos de configuración e IPC;
- definir una interfaz mínima para `Shell Adapter`;
- identificar funciones comunes y funciones exclusivas;
- crear pruebas de instalación, activación, rollback y desinstalación;
- registrar bugs upstream reproducibles antes de crear parches locales permanentes.