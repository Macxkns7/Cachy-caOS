# Iconos de Nest

Este directorio contiene los iconos maestros versionados del proyecto.

## Nest UI

El icono oficial debe almacenarse como:

```text
src/assets/icons/nest-ui.png
```

Durante la instalación debe copiarse a:

```text
~/.local/share/cachycaos/assets/icons/nest-ui.png
```

La Desktop Entry instalada debe usar la ruta absoluta resultante, no el nombre temático `nest-ui`:

```ini
Icon=/home/<usuario>/.local/share/cachycaos/assets/icons/nest-ui.png
StartupWMClass=nest-ui
```

Este criterio fue validado en Noctalia: el icono aparece correctamente tanto en el launcher como en el dock. La identidad de ventana sigue siendo `nest-ui`, mientras el recurso visual permanece bajo control directo de Nest.

La plantilla `src/applications/nest-ui.desktop.in` usa `@NEST_ICON@` y `@NEST_ROOT@`; el instalador debe sustituir ambos marcadores por rutas absolutas del usuario.
