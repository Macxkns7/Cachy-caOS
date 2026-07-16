# Estado de implementación de Nest

**Estado:** En desarrollo  
**Última revisión:** 2026-07-16

## Propósito

Registrar qué partes de Nest existen hoy, qué decisiones ya están validadas y qué trabajo sigue abierto. Este documento conecta la arquitectura teórica con la implementación real.

## Estado general

Nest se encuentra en una etapa temprana de construcción, pero ya dejó de ser una idea abstracta. Existe una base funcional en terminal, módulos propios y una dirección arquitectónica definida.

## Componentes existentes

### Nest Core y lanzador

- Estructura separada entre `core/` y `modules/`.
- Lanzador principal mediante `app.sh`.
- Interfaz terminal construida con Bash y `gum`.
- Ejecución integrada con Kitty.
- Acceso desde un archivo `.desktop`.
- Identidad visual propia mediante el icono `nest-ui`.
- Nombre y descripción pública: **Nest UI — Centro de administración de Cachy-caOS**.

### Módulos funcionales

- WebApps.
- Keybinds.

Ambos módulos han sido probados de forma independiente y desde el lanzador principal.

## Estructura observada en el sistema de desarrollo

```text
~/.local/share/cachycaos/
├── app.sh
├── core/
│   └── nest/
├── modules/
│   ├── webapps/
│   └── keybinds/
└── backups/
```

La estructura local todavía puede evolucionar antes de convertirse en un layout de instalación definitivo.

## Decisiones firmes

- Nest no será una shell.
- El Core no dependerá de Noctalia ni de otra shell concreta.
- Las interfaces deben consumir capacidades del Core, no contener la lógica crítica.
- Los módulos deben ser independientes y reemplazables.
- La configuración del usuario debe preservarse.
- Toda operación sensible debe tener diagnóstico, respaldo y recuperación.
- Fish es el shell interactivo principal del sistema; los comandos mostrados al usuario deben ser compatibles con Fish o indicar explícitamente otro intérprete.

## Estado de Nest UI

La interfaz actual es una TUI temprana. Cumple el propósito de validar navegación, módulos y organización, pero todavía no representa la interfaz gráfica final.

La v0.4 debe consolidar:

- navegación principal;
- contratos entre Core y módulos;
- rutas canónicas;
- detección de dependencias;
- manejo de errores;
- estado y salida consistente;
- documentación de instalación y actualización.

## Acceso desde el escritorio

El archivo `.desktop` usa una clase propia de Kitty:

```text
class = nest-ui
title = Nest UI
```

Esto permite identificar la ventana de Nest desde Hyprland y shells compatibles.

## Riesgos abiertos

- Las rutas locales aún arrastran restos de reorganizaciones previas.
- No existe todavía un instalador reproducible que despliegue binarios, iconos y archivos `.desktop`.
- El mapeo de iconos de aplicaciones abiertas en el dock de Noctalia sigue en investigación.
- El estado de versión aún no está centralizado.
- Falta una interfaz estable entre los módulos y el Core.

## Próximos hitos

1. Cerrar la v0.4 de la TUI.
2. Normalizar estructura y rutas.
3. Definir contratos de módulos.
4. Crear diagnóstico común.
5. Diseñar instalador y actualizador.
6. Iniciar una interfaz gráfica sin acoplarla a la shell.

## Regla de actualización

Este documento debe actualizarse cada vez que una versión cambie la estructura, incorpore un módulo funcional o convierta una decisión experimental en una decisión firme.
