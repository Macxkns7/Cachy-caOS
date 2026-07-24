# N.E.S.T. WebApp Router

Router reversible para abrir enlaces externos dentro de una ventana WebApp
existente, evitando una segunda instancia o una pestaña normal permanente.

## Fuente canónica

El registro se genera desde las Desktop Entries administradas por N.E.S.T.:

```text
~/.local/share/applications/cachycaos-webapp-*.desktop
```

Una entrada participa cuando contiene:

```ini
X-CachycaOS-WebApp=true
X-CachycaOS-WebApp-URL=https://example.com/ruta
```

Puede excluirse sin eliminarla:

```ini
X-CachycaOS-WebApp-Router=false
```

Las entradas antiguas que no contienen esa última clave permanecen habilitadas
por compatibilidad.

## Seguridad

- genera permisos de host únicamente para los dominios administrados;
- solo considera pestañas recién creadas desde ventanas `normal`;
- solo redirige hacia otra ventana `popup` o `app` del mismo origen;
- navega y enfoca la WebApp antes de cerrar la pestaña intermediaria;
- ante ambigüedad o error conserva la pestaña original;
- no modifica los manejadores HTTP/HTTPS;
- no usa Remote Debugging ni automatización de teclado.

## Instalación

```bash
bash src/modules/webapps/router/install.sh
```

El instalador despliega:

```text
~/.local/bin/cachycaos-webapp-router
~/.local/share/cachycaos/modules/webapps/router/
~/.local/share/cachycaos/webapps/router-extension/
```

Después:

1. abrir `vivaldi://extensions`;
2. activar **Modo desarrollador**;
3. seleccionar **Cargar extensión sin empaquetar**;
4. elegir `~/.local/share/cachycaos/webapps/router-extension`.

## Sincronización

```bash
cachycaos-webapp-router sync
```

La creación, reparación o eliminación de una WebApp mediante
`cachycaos-webapp` sincroniza el registro automáticamente cuando el router está
instalado.

Los cambios de dominios alteran los permisos declarados en el manifiesto. Por
esa razón Vivaldi debe recargar la extensión desde `vivaldi://extensions`
después de una sincronización que informe cambios.

## Diagnóstico

El panel de la extensión muestra:

- WebApps y orígenes registrados;
- último resultado del enrutador;
- tipo de la ventana de origen y destino;
- tipos y URLs visibles para la API de extensiones.

## Comandos

```text
cachycaos-webapp-router install
cachycaos-webapp-router sync
cachycaos-webapp-router path
cachycaos-webapp-router uninstall
```

## Validación

```bash
bash src/modules/webapps/router/tests/run.sh
```
