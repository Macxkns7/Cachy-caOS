# Módulo WebApps

**Estado:** En desarrollo y funcional  
**Versión validada:** v0.7 Beta + WebApp Router v0.3
**Última revisión:** 2026-07-24

## Propósito

Permitir crear, lanzar, listar, reparar y eliminar aplicaciones web integradas al escritorio sin depender de un proceso manual distinto para cada sitio.

## Código fuente canónico

```text
src/bin/cachycaos-webapp
src/modules/webapps/app.sh
src/bin/cachycaos-webapp-router
src/modules/webapps/router/
```

El futuro instalador debe desplegarlos como:

```text
src/bin/cachycaos-webapp
  → ~/.local/bin/cachycaos-webapp

src/modules/webapps/app.sh
  → ~/.local/share/cachycaos/modules/webapps/app.sh

src/bin/cachycaos-webapp-router
  → ~/.local/bin/cachycaos-webapp-router

src/modules/webapps/router/
  → ~/.local/share/cachycaos/modules/webapps/router/
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
- sincronizar opcionalmente el registro de dominios del WebApp Router.

## WebApp Router v0.3

La prueba real con la PWA nativa de YouTube Music confirmó que una extensión
Manifest V3 puede recibir un enlace abierto mediante `xdg-open`, localizar la
ventana WebApp existente, navegarla y enfocarla, y cerrar después la pestaña
normal intermediaria.

La implementación actual conserva y amplía ese mecanismo:

1. descubre `cachycaos-webapp-*.desktop`;
2. exige `X-CachycaOS-WebApp=true`;
3. obtiene la URL desde `X-CachycaOS-WebApp-URL`;
4. reduce cada URL a su origen canónico;
5. elimina dominios duplicados;
6. genera `routes.json`;
7. genera permisos mínimos en `manifest.json`;
8. genera reglas exactas de activación para Hyprland;
9. sincroniza automáticamente al crear, reparar o eliminar una WebApp.

La validación multi-WebApp confirmó el enrutamiento hacia ChatGPT, GitHub y
YouTube Music sin duplicar ventanas. Cuando la WebApp de GitHub estaba en otro
workspace, Vivaldi navegaba correctamente la ventana existente pero Hyprland no
le entregaba el foco.

### Activación entre workspaces

La causa no estaba en el router: Hyprland exponía
`misc.focus_on_activate=false`, su política global segura. La extensión podía
activar la pestaña y solicitar foco para su ventana, pero el compositor evitaba
el cambio de workspace.

WebApp Router v0.3 genera:

```text
~/.config/hypr/cachycaos/webapps.lua
```

El archivo contiene una regla exacta por `StartupWMClass` administrado:

```lua
hl.window_rule({
    name = "nest-webapp-github-focus",
    match = {
        class = "^vivaldi-github[.]com__-Default$",
    },
    focus_on_activate = true,
})
```

La configuración principal solo debe cargar el adaptador:

```lua
require("cachycaos.webapps")
```

N.E.S.T. no cambia globalmente `misc.focus_on_activate`. Por ello una
aplicación común no obtiene permiso para robar el foco; solamente las clases
exactas derivadas de las WebApps registradas pueden activar su ventana y mover
al usuario al workspace que la contiene.

Al sincronizar el registro, el archivo Lua se regenera de forma idempotente. Si
el `require` ya está activo y Hyprland está disponible, el módulo recarga el
compositor. Al desinstalar el router, conserva un adaptador vacío para no dejar
una importación rota.

Una WebApp puede excluirse sin ser eliminada:

```ini
X-CachycaOS-WebApp-Router=false
```

Las entradas antiguas que omiten esa clave participan por defecto.

### Flujo de enrutamiento

```text
enlace externo
→ Vivaldi crea una pestaña normal
→ la extensión reconoce un origen registrado
→ busca otra ventana popup/app del mismo origen
→ navega y enfoca la WebApp existente
→ cierra la pestaña intermediaria
```

Si el destino no existe, es ambiguo o produce un error, la pestaña normal
permanece abierta.

### Sincronización y permisos

```bash
cachycaos-webapp-router sync
```

El manifiesto solo solicita acceso a los dominios actualmente administrados.
Cuando esos permisos cambian, Vivaldi debe recargar manualmente la extensión
desde `vivaldi://extensions`.

El router no modifica los manejadores globales HTTP/HTTPS y no usa Remote
Debugging ni simulación de teclado.

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
- Registro de seis dominios administrados con permisos mínimos.
- Reutilización real de ChatGPT, GitHub y YouTube Music.
- Navegación de GitHub dentro de una WebApp situada en otro workspace.
- Cambio de workspace y foco mediante una regla exclusiva por clase.
- Conservación de `misc.focus_on_activate=false` a nivel global.

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
