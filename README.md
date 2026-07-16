# Cachy-caOS

Cachy-caOS es un proyecto personal de sistema Linux construido sobre **CachyOS + Hyprland**, orientado a crear una experiencia modular, comprensible, reversible y administrable mediante **Nest**.

El proyecto nació como una colección de mejoras sobre Omarchy, pero esa etapa ya no representa su dirección actual. Omarchy se conserva como referencia histórica y aprendizaje; Cachy-caOS avanza hacia una arquitectura propia sin depender de una capa externa para comprender, mantener o reconstruir el sistema.

## Nest

Nest es la futura capa de administración de Cachy-caOS. No busca convertirse en una shell ni reemplazar proyectos bien construidos. Su función es integrar, configurar, diagnosticar y proteger los componentes del sistema mediante interfaces y flujos coherentes.

Principios centrales:

- Core independiente de la shell visual.
- Shells y componentes reemplazables.
- Cambios importantes reversibles.
- Configuración del usuario por encima de defaults externos.
- Adopción de integraciones externas cuando aporten valor técnico real.
- Comprender antes de automatizar.
- Documentación como parte del producto.

## Arquitectura general

```text
Cachy-caOS
├── Nest Core
│   ├── configuración
│   ├── mantenimiento
│   ├── snapshots y rollback
│   ├── health checks
│   ├── backups
│   └── actualizaciones
├── Servicios de escritorio
├── Adaptadores
│   ├── shells
│   ├── display managers
│   ├── launchers
│   └── aplicaciones externas
└── Nest UI
    └── centro modular de administración
```

## Dirección actual

- CachyOS limpio como base.
- Hyprland como compositor.
- Noctalia v5 como shell actual, sin acoplarla al Core.
- Noctalia Greeter sobre greetd para el inicio de sesión.
- Fish como shell interactiva principal.
- Nest UI como centro de administración en desarrollo.
- WebApps y módulos propios administrados por Nest.
- Diagnóstico, recuperación y documentación como funciones de primera clase.

## Metodología

```text
Entender → Validar → Instalar → Diagnosticar → Documentar → Automatizar
```

Nunca se incorpora una herramienta únicamente porque sea atractiva. Primero se evalúan su arquitectura, mantenimiento, integración, riesgos y capacidad de recuperación. Si una solución externa hace bien su trabajo, Nest debe administrarla y simplificarla, no reescribirla sin una necesidad real.

## Documentación

El punto de entrada oficial es [`docs/README.md`](docs/README.md).

La documentación está separada en:

- estado y decisiones actuales;
- arquitectura y metodología de Nest;
- integraciones técnicas;
- investigaciones;
- archivo histórico de etapas reemplazadas.

Las reglas de mantenimiento están en [`docs/convenciones-documentales.md`](docs/convenciones-documentales.md).

## Estado

El proyecto se encuentra en desarrollo activo. Sus decisiones actuales representan una dirección de trabajo comprobada progresivamente, no una distribución terminada ni una promesa de compatibilidad estable.