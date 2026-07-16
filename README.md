# Cachy-caOS

Cachy-caOS es un proyecto personal de sistema Linux construido sobre **CachyOS + Hyprland**, orientado a crear una experiencia modular, comprensible, reversible y administrable mediante **Nest**.

El proyecto nació como una colección de mejoras sobre Omarchy, pero esa etapa ya no representa su dirección actual. Omarchy fue una referencia y una base de aprendizaje; Cachy-caOS avanza ahora hacia una arquitectura propia, sin depender de una capa externa para comprender, mantener o reconstruir el sistema.

## Nest

Nest es la futura capa de administración de Cachy-caOS. No busca convertirse en una shell ni reemplazar proyectos bien construidos. Su función es integrar, configurar, diagnosticar y proteger los distintos componentes del sistema mediante interfaces y flujos coherentes.

Principios centrales:

- El Core debe ser independiente de la shell visual.
- Las shells y componentes de interfaz deben ser reemplazables.
- Los cambios importantes deben ser reversibles.
- La configuración del usuario tiene prioridad.
- Las integraciones externas se adoptan cuando aportan valor técnico real.
- Antes de automatizar una tecnología, se debe comprender cómo funciona.
- La documentación forma parte del producto, no es una tarea secundaria.

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
│   ├── audio
│   ├── brillo
│   ├── red y Bluetooth
│   ├── energía
│   ├── notificaciones
│   └── sesión
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
- Noctalia Greeter sobre greetd como gestor de inicio de sesión.
- Nest UI como centro de administración en desarrollo.
- WebApps y módulos propios administrados por Nest.
- Diagnóstico, recuperación y documentación como funciones de primera clase.

## Metodología

```text
Entender → Validar → Instalar → Diagnosticar → Documentar → Automatizar
```

Nunca se incorpora una herramienta únicamente porque sea atractiva. Primero se evalúan su arquitectura, mantenimiento, integración, riesgos y capacidad de recuperación. Si una solución externa hace bien su trabajo, Nest debe administrarla y simplificarla, no reescribirla sin una necesidad real.

## Documentación

La carpeta `docs/` conserva:

- decisiones históricas;
- configuración y reconstrucción del sistema;
- visión y arquitectura de Nest;
- integraciones técnicas;
- metodología y aprendizajes reales obtenidos durante el desarrollo.

## Estado

El proyecto se encuentra en desarrollo activo y su arquitectura continúa evolucionando. Las decisiones actuales son una dirección de trabajo, no una promesa de compatibilidad estable ni una distribución lista para uso general.