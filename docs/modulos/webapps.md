# Módulo WebApps

**Estado:** En desarrollo y funcional  
**Versión validada:** v0.6 Beta  
**Última revisión:** 2026-07-16

## Propósito

Permitir crear, lanzar, listar, reparar y eliminar aplicaciones web integradas al escritorio sin depender de un proceso manual distinto para cada sitio.

## Código fuente canónico

```text
src/bin/cachycaos-webapp
src/modules/webapps/app.sh
```

El futuro instalador debe desplegarlos como:

```text
src/bin/cachycaos-webapp
  → ~/.local/bin/cachycaos-webapp

src/modules/webapps/app.sh
  → ~/.local/share/cachycaos/modules/webapps/app.sh
```

## Estado actual

El módulo funciona con Vivaldi y genera archivos `.desktop` propios bajo el namespace de Cachy-caOS.

Ejemplos:

```text
cachycaos-webapp-chatgpt.desktop
cachycaos-webapp-youtube.desktop
cachycaos-webapp-youtube-music.desktop
```

Rutas de ejecución y datos:

```text
~/.local/bin/cachycaos-webapp
~/.local/share/cachycaos/modules/webapps/app.sh
~/.local/share/cachycaos/webapps/
~/.local/share/cachycaos/webapps/icons/
~/.local/share/applications/cachycaos-webapp-*.desktop
```

## Capacidades v0.6

- crear una WebApp desde nombre, URL e icono opcional;
- normalizar URLs sin esquema;
- obtener favicon o importar un icono local/remoto;
- lanzar mediante Vivaldi en modo `--app`;
- listar URL y `StartupWMClass` asociados;
- eliminar `.desktop` e icono administrado;
- reparar WebApps existentes;
- regenerar o reemplazar `StartupWMClass` sin duplicarlo;
- actualizar la base XDG de aplicaciones;
- solicitar recarga del dock de Noctalia cuando está disponible.

## Flujo funcional

```text
Nest WebApps
├── recibe nombre y URL
├── normaliza el dominio
├── crea o importa icono
├── calcula la identidad Wayland esperada
├── genera archivo .desktop
├── registra la WebApp
└── la lanza mediante Vivaldi
```

## Descubrimiento técnico: identidad de aplicaciones

Las ventanas de Vivaldi exponen clases Wayland específicas por sitio:

```text
https://chatgpt.com
→ vivaldi-chatgpt.com__-Default

https://www.youtube.com
→ vivaldi-www.youtube.com__-Default

https://music.youtube.com
→ vivaldi-music.youtube.com__-Default
```

Noctalia intenta relacionar una ventana activa con una Desktop Entry comparando el `app_id` de la ventana con:

- el ID del archivo `.desktop`;
- `StartupWMClass`;
- `Name`.

Cuando no encuentra coincidencia crea una identidad provisional para la ventana. El síntoma observado era:

- el acceso fijado mostraba el icono correcto;
- al abrirlo aparecía una segunda entrada con icono genérico de engranaje;
- las ventanas ya abiertas no heredaban el icono de la WebApp.

### Causa raíz

Los `.desktop` antiguos no declaraban `StartupWMClass`, mientras la clase real de Vivaldi no coincidía con el ID `cachycaos-webapp-*`.

### Solución v0.6

El módulo calcula automáticamente:

```text
StartupWMClass=vivaldi-<hostname>__-Default
```

Ejemplo generado:

```ini
[Desktop Entry]
Name=ChatGPT
Exec=/home/usuario/.local/bin/cachycaos-webapp launch "https://chatgpt.com"
Icon=/home/usuario/.local/share/cachycaos/webapps/icons/chatgpt.png
StartupWMClass=vivaldi-chatgpt.com__-Default
```

## Motor de reparación

Comando:

```bash
cachycaos-webapp repair
```

Proceso:

1. localiza todos los `cachycaos-webapp-*.desktop`;
2. lee `X-CachycaOS-WebApp-URL`;
3. calcula el hostname y la clase esperada;
4. crea o reemplaza `StartupWMClass`;
5. evita claves duplicadas;
6. valida la Desktop Entry;
7. actualiza la base de aplicaciones;
8. recarga el dock de Noctalia cuando existe.

La reparación fue validada eliminando manualmente `StartupWMClass` de ChatGPT y confirmando que el módulo la restauraba correctamente.

## Validación realizada

- WebApps antiguas migradas correctamente.
- ChatGPT agrupado con su icono fijado.
- YouTube agrupado con su icono fijado.
- Creación de una WebApp nueva sin parche manual.
- Persistencia tras recargar el dock.
- Recuperación automática de una clave eliminada.
- Ausencia de segunda instancia con engranaje.

## Lecciones de rutas e instalación

Durante el desarrollo se detectó que `xdg-user-dir DOWNLOAD` podía devolver una ruta incorrecta cuando no existía `~/.config/user-dirs.dirs`, mientras el archivo real estaba en `~/Downloads`.

Reglas para el instalador:

- no asumir `Descargas` ni `Downloads`;
- validar la ruta antes de copiar;
- permitir selección explícita de archivo;
- almacenar iconos finales dentro del espacio administrado por Nest;
- actualizar cachés solo después de validar la instalación;
- crear archivos `.desktop` reproducibles y portables;
- instalar código desde `src/` hacia rutas XDG del usuario.

## Limitaciones actuales

- El cálculo de identidad está diseñado para el formato actual de Vivaldi.
- La recarga de Noctalia es una integración opcional y no una dependencia del Core.
- Aún no existe un adaptador universal para Brave, Chromium, Edge o Firefox.
- El favicon de Google puede no ser suficiente para todos los sitios.

## Evolución futura

Una versión posterior puede aprender la identidad real de una ventana:

```text
crear WebApp
→ lanzarla temporalmente
→ observar app_id mediante el compositor
→ guardar la identidad real
→ cerrar la ejecución de aprendizaje
```

Esto permitiría soportar distintos navegadores sin codificar previamente su convención de clases.

## Principio arquitectónico

El módulo WebApps no debe depender internamente de Noctalia. Debe producir entradas XDG correctas. Las recargas, diagnósticos o comportamientos específicos de una shell deben permanecer como integraciones opcionales y reemplazables.
