# N.E.S.T. WebApp Router · prototipo

Prototipo reversible para comprobar si una extensión de Vivaldi puede
reutilizar una ventana independiente de YouTube Music cuando un enlace externo
se abre inicialmente en una pestaña normal.

## Alcance

- solo observa `https://music.youtube.com/*`;
- solo considera pestañas recién creadas, evitando secuestrar una navegación
  iniciada dentro de una pestaña normal antigua;
- solo actúa sobre pestañas procedentes de una ventana `normal`;
- solo redirige si encuentra otra ventana de tipo `popup` o `app` que ya
  contiene YouTube Music;
- navega y enfoca la WebApp antes de cerrar la pestaña intermediaria;
- si no reconoce un destino seguro, conserva la pestaña normal;
- no cambia los manejadores HTTP/HTTPS;
- no utiliza Remote Debugging ni automatización de teclado.

## Instalación

```bash
bash src/modules/webapps/router/install.sh
```

Después:

1. abrir `vivaldi://extensions`;
2. activar **Modo desarrollador**;
3. seleccionar **Cargar extensión sin empaquetar**;
4. elegir la ruta mostrada por el instalador;
5. mantener abierta la WebApp de YouTube Music;
6. ejecutar:

   ```bash
   xdg-open 'https://music.youtube.com/library/playlists'
   ```

## Resultado esperado

La pestaña normal se usa solamente como evento de entrada. La extensión navega
la ventana independiente de YouTube Music, la enfoca y elimina la pestaña
intermediaria.

Si no ocurre, el panel de la extensión muestra:

- el último resultado del enrutador;
- el tipo de la ventana de origen;
- los tipos y URLs de las ventanas visibles para la API de extensiones.

Ese diagnóstico permite adaptar la detección sin cerrar pestañas ambiguas.

## Desinstalación

Primero retirar la extensión desde `vivaldi://extensions` y luego ejecutar:

```bash
bash src/modules/webapps/router/install.sh uninstall
```
