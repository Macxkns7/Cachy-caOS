# Módulo WebApps

**Estado:** En desarrollo y funcional  
**Última revisión:** 2026-07-16

## Propósito

Permitir crear, lanzar y administrar aplicaciones web integradas al escritorio sin depender de un proceso manual distinto para cada sitio.

## Estado actual

El módulo funciona con Vivaldi y genera archivos `.desktop` propios bajo el namespace de Cachy-caOS.

Ejemplos existentes:

```text
cachycaos-webapp-chatgpt.desktop
cachycaos-webapp-youtube.desktop
cachycaos-webapp-youtube-music.desktop
```

El lanzador principal utilizado durante el desarrollo es:

```text
~/.local/bin/cachycaos-webapp
```

Los módulos y datos han utilizado rutas como:

```text
~/.local/share/cachycaos/modules/webapps/
~/.local/share/cachycaos/webapps/
~/.local/share/cachycaos/webapps/icons/
```

Estas rutas deben normalizarse antes del instalador definitivo.

## Flujo funcional

```text
Nest WebApps
├── recibe nombre y URL
├── crea o importa icono
├── genera archivo .desktop
├── registra la WebApp
└── la lanza mediante Vivaldi
```

## Integración con el escritorio

Las ventanas de Vivaldi exponen clases Wayland específicas por sitio, por ejemplo:

```text
vivaldi-chatgpt.com__-Default
vivaldi-www.youtube.com__-Default
```

El archivo `.desktop`, el icono y la clase de la ventana deben poder relacionarse para que launchers y docks muestren correctamente la identidad de la aplicación.

## Problema abierto: iconos de ventanas activas

Noctalia muestra correctamente el icono en el launcher, pero algunas WebApps aparecen sin icono en el dock cuando están abiertas.

Hipótesis actualmente relevantes:

- el dock resuelve por `app_id` o clase de ventana y no por el nombre del `.desktop`;
- falta `StartupWMClass` o un identificador equivalente;
- el mapeo entre clase Vivaldi y desktop entry no coincide;
- Noctalia puede tener limitaciones al resolver rutas absolutas de iconos o aplicaciones web de Chromium/Vivaldi.

Este problema debe resolverse de forma general, porque Nest crea aplicaciones que después deben integrarse correctamente con cualquier shell compatible.

## Lecciones de rutas e instalación

Durante el desarrollo se detectó que `xdg-user-dir DOWNLOAD` devolvía `/home/macx` porque no existía `~/.config/user-dirs.dirs`, mientras el archivo real estaba en `~/Downloads`.

Reglas para el instalador:

- no asumir `Descargas` ni `Downloads`;
- validar la ruta antes de copiar;
- permitir selección explícita de archivo;
- almacenar los iconos finales dentro del espacio administrado por Nest;
- actualizar cachés de iconos solo después de validar la instalación;
- crear archivos `.desktop` reproducibles y portables.

## Requisitos futuros

- edición y eliminación segura;
- detección de duplicados;
- validación de URL;
- descarga o selección de iconos;
- resolución estable de `StartupWMClass`/`app_id`;
- backups antes de modificar entradas existentes;
- importación de WebApps ya creadas;
- soporte por adaptadores para otros navegadores;
- diagnóstico de integración con launcher y dock.

## Principio arquitectónico

El módulo WebApps no debe depender internamente de Noctalia. Debe producir entradas XDG correctas y dejar que cada shell las consuma mediante un adaptador o integración específica cuando sea necesario.
