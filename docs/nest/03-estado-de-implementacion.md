# Estado de implementación de Nest

**Estado:** En desarrollo  
**Última revisión:** 2026-07-20

## Propósito

Registrar qué partes de Nest existen hoy, qué decisiones ya están validadas y qué trabajo sigue abierto. Este documento conecta la arquitectura teórica con la implementación real.

## Estado general

Nest se encuentra en una etapa temprana de construcción, pero ya dejó de ser una idea abstracta. Existe una base funcional en terminal, módulos propios, código fuente versionado y una dirección arquitectónica definida.

## Componentes existentes

### Nest Core y lanzador

- Estructura separada entre `core/` y `modules/`.
- Lanzador principal mediante `app.sh`.
- Interfaz terminal construida con Bash y `gum`.
- Ejecución integrada con Kitty.
- Acceso desde un archivo `.desktop`.
- Identidad de ventana propia mediante la clase `nest-ui`.
- Icono instalado y administrado por Nest desde `~/.local/share/cachycaos/assets/icons/nest-ui.png`.
- Nombre y descripción pública: **Nest UI — Centro de administración de Cachy-caOS**.

### Módulos funcionales

- WebApps.
- Keybinds.

Ambos módulos han sido probados de forma independiente y desde el lanzador principal.

### WebApps v0.6 Beta

Estado: **funcional y validado en el sistema real**.

Capacidades confirmadas:

- creación, listado y eliminación de WebApps;
- generación automática de `StartupWMClass` para Vivaldi;
- agrupación correcta entre acceso fijado y ventana Wayland;
- nuevo comando `cachycaos-webapp repair`;
- migración de Desktop Entries antiguas;
- reparación idempotente sin duplicar claves;
- actualización de la base XDG;
- recarga opcional del dock de Noctalia.

Código fuente canónico:

```text
src/bin/cachycaos-webapp
src/modules/webapps/app.sh
```

## Estructura observada en el sistema de desarrollo

```text
~/.local/share/cachycaos/
├── app.sh
├── assets/
│   └── icons/
│       └── nest-ui.png
├── core/
│   └── nest/
├── modules/
│   ├── webapps/
│   └── keybinds/
└── backups/
```

La estructura local todavía puede evolucionar antes de convertirse en un layout de instalación definitivo.

## Estructura inicial del código fuente

```text
src/
├── applications/
│   └── nest-ui.desktop.in
├── assets/
│   └── icons/
│       └── README.md
├── bin/
│   └── cachycaos-webapp
└── modules/
    └── webapps/
        └── app.sh
```

La ubicación canónica reservada para el binario del icono es `src/assets/icons/nest-ui.png`. Su importación al repositorio continúa pendiente; el archivo actualmente validado reside en el sistema de desarrollo.

El instalador futuro será responsable de transformar el árbol `src/` en las rutas XDG del usuario y de sustituir los marcadores de las plantillas por rutas absolutas.

## Decisiones firmes

- Nest no será una shell.
- El Core no dependerá de Noctalia ni de otra shell concreta.
- Las interfaces deben consumir capacidades del Core, no contener la lógica crítica.
- Los módulos deben ser independientes y reemplazables.
- La configuración del usuario debe preservarse.
- Toda operación sensible debe tener diagnóstico, respaldo y recuperación.
- Los módulos deben poder reparar y migrar recursos creados por versiones anteriores.
- Los recursos visuales propios deben vivir bajo el árbol administrado por Nest.
- Las Desktop Entries generadas deben usar rutas absolutas para assets propios cuando la resolución por tema no sea fiable.
- Fish es el shell interactivo principal del sistema; los comandos mostrados al usuario deben ser compatibles con Fish o indicar explícitamente otro intérprete.
- El tema de iconos es una capacidad transversal del Core y se implementará mediante adaptadores GTK, Qt, entorno y variantes de carpetas.
- Los adaptadores deben modificar únicamente claves propias, preservar configuración ajena y ofrecer `detect`, `plan`, `apply`, `verify`, `repair` y `rollback`.
- System Doctor deberá complementar pacman con auditoría ELF para detectar consumidores runtime instalados manualmente.

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

La ventana de Nest usa una clase propia de Kitty:

```text
class = nest-ui
title = Nest UI
```

La Desktop Entry validada usa:

```ini
Exec=kitty --class nest-ui --title "Nest UI" -e /home/<usuario>/.local/share/cachycaos/app.sh
Icon=/home/<usuario>/.local/share/cachycaos/assets/icons/nest-ui.png
StartupWMClass=nest-ui
```

La combinación fue comprobada en el sistema real: el icono aparece correctamente tanto en el launcher como en el dock de Noctalia.

## Riesgos abiertos

- Las rutas locales aún arrastran restos de reorganizaciones previas.
- No existe todavía un instalador reproducible que despliegue binarios, assets y archivos `.desktop`.
- El binario maestro `src/assets/icons/nest-ui.png` aún debe importarse desde el sistema de desarrollo.
- El estado de versión aún no está centralizado.
- Falta una interfaz estable entre los módulos y el Core.
- WebApps todavía usa una convención específica de Vivaldi para calcular la identidad Wayland.

## Hallazgo de limpieza y dependencias runtime

La limpieza validada retiró 92 paquetes netos y consolidó Nemo, mpv y greetd. Durante el proceso se comprobó que `pacman Required By` no cubre binarios instalados manualmente: `noctalia-greeter-compositor` dependía de `libwlroots-0.20.so`, aunque wlroots aparecía sin dependientes.

`wlroots0.20` y `libliftoff` fueron restaurados antes del reinicio. Este caso define una nueva capacidad obligatoria para System Doctor: inventario de ELF no empaquetados, resolución de bibliotecas y verificación posterior a eliminaciones.

Fuente: `docs/modulos/limpieza-sistema.md`.

## Problemas cerrados recientemente

### Identidad e iconos de WebApps en Noctalia

**Estado:** Resuelto en WebApps v0.6.

La causa era la ausencia de `StartupWMClass` en las Desktop Entries. Noctalia no podía asociar las clases `vivaldi-<hostname>__-Default` con los IDs `cachycaos-webapp-*`, por lo que mostraba una segunda instancia con icono genérico.

La solución quedó generalizada en el generador y en el motor de reparación; no se mantiene como un parche específico para ChatGPT o YouTube.

### Icono genérico de Nest UI

**Estado:** Resuelto y validado en el sistema de desarrollo.

La clase de ventana y `StartupWMClass` ya coincidían correctamente como `nest-ui`. El engranaje persistía porque `Icon=nest-ui` dependía de la resolución del tema `hicolor` y de sus cachés.

La solución validada fue mover el icono al árbol administrado por Nest y utilizar su ruta absoluta en la Desktop Entry:

```text
~/.local/share/cachycaos/assets/icons/nest-ui.png
```

Esto eliminó el icono genérico tanto en el launcher como en el dock de Noctalia. La plantilla y el contrato de instalación ya están versionados; solo falta importar el PNG maestro al árbol `src/assets/icons/`.

## Próximos hitos

1. Diseñar el contrato de auditoría ELF y dependencias runtime para System Doctor.
3. Diseñar el manifiesto y contrato de `Appearance / System Icons` a partir del procedimiento Papirus validado.
3. Importar el PNG maestro de Nest en `src/assets/icons/nest-ui.png`.
4. Cerrar la v0.4 de la TUI.
5. Normalizar estructura y rutas.
6. Definir contratos de módulos.
7. Crear diagnóstico común.
8. Diseñar instalador y actualizador para desplegar `src/`.
9. Incorporar el módulo Keybinds al árbol de código fuente.
10. Diseñar adaptadores de identidad para otros navegadores.
11. Iniciar una interfaz gráfica sin acoplarla a la shell.

## Regla de actualización

Este documento debe actualizarse cada vez que una versión cambie la estructura, incorpore un módulo funcional o convierta una decisión experimental en una decisión firme.
