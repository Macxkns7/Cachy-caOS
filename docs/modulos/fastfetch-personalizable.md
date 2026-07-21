# Fastfetch personalizable en N.E.S.T.

**Estado:** Prototipo visual validado; módulo N.E.S.T. pendiente  
**Última revisión:** 2026-07-21  
**Relacionado con:** `docs/nest/02-roadmap-arquitectonico.md`, `docs/nest/03-estado-de-implementacion.md`

## Propósito

Convertir Fastfetch en una identidad visual útil y administrable por N.E.S.T., sin tratarlo como un adorno aislado ni acoplarlo a CachyOS, Kitty o una shell concreta.

El prototipo real demostró que una composición compacta puede conservar información de diagnóstico, funcionar tanto en una terminal completa como en una división vertical y expresar una identidad personal mediante arte ASCII.

## Resultado validado

La edición personal de Manuel quedó identificada como:

```text
Fastfetch : N.E.S.T. Kitty’s Edition
```

Características comprobadas:

- dos gatos ASCII apilados, inspirados en sus dos gatos hermanos;
- ancho de logo reducido para no romper una división vertical de Kitty;
- módulos limitados a información cotidiana y de diagnóstico;
- CPU y GPU abreviadas mediante formatos específicos;
- claves y resultados alineados manualmente;
- colores compatibles con la paleta lavanda y menta actual;
- una sola configuración válida en vista completa y dividida;
- configuración activa en `~/.config/fastfetch/config.jsonc`.

El ejemplo reproducible vive en:

```text
examples/fastfetch/manuel-kitty-edition/
├── config.jsonc
└── nest-cat.txt
```

## Alcance del ejemplo de Manuel

Este preset es un ejemplo validado y una preferencia personal, no un valor predeterminado obligatorio para todos los usuarios de N.E.S.T.

El nombre, los gatos, los colores y la selección de módulos pueden reutilizarse voluntariamente. N.E.S.T. debe preservar siempre la configuración existente y solicitar confirmación antes de reemplazarla.

## Capacidad futura de N.E.S.T.

Un futuro módulo **Terminal Identity / Fastfetch** podrá ofrecer:

1. detectar Fastfetch y su versión;
2. detectar la configuración activa y crear un respaldo;
3. previsualizar presets sin aplicarlos;
4. elegir imágenes ASCII incorporadas;
5. importar ASCII desde un archivo local;
6. importar desde una URL después de mostrar origen, tamaño y contenido;
7. editar título, etiqueta de edición, colores y módulos;
8. seleccionar diseños compactos o amplios;
9. comprobar el ancho con perfiles de terminal completa y dividida;
10. aplicar, verificar, reparar y restaurar la configuración anterior.

## Modelo declarativo propuesto

```toml
id = "manuel-kitty-edition"
name = "N.E.S.T. Kitty’s Edition"
author = "Manuel"
status = "validated-example"

[logo]
source = "nest-cat.txt"
layout = "stacked"
max_width = 8

[layout]
profile = "compact"
target_columns = 60

[identity]
label = "Fastfetch"
value = "N.E.S.T. Kitty’s Edition"
```

El manifiesto es todavía una propuesta y no representa una interfaz implementada.

## Reglas de seguridad

- no sobrescribir `config.jsonc` sin respaldo;
- no descargar ni ejecutar scripts desde una URL de arte;
- tratar el contenido remoto exclusivamente como texto;
- imponer límites de tamaño y longitud de línea;
- previsualizar caracteres de control y rechazarlos por defecto;
- conservar rutas XDG del usuario;
- permitir rollback con una sola operación;
- validar el resultado con Fastfetch antes de marcar la aplicación como exitosa.

## Instalación manual del ejemplo

```fish
mkdir -p ~/.config/fastfetch
cp examples/fastfetch/manuel-kitty-edition/config.jsonc ~/.config/fastfetch/config.jsonc
cp examples/fastfetch/manuel-kitty-edition/nest-cat.txt ~/.config/fastfetch/nest-cat.txt
fastfetch
```

Cuando se ejecuta desde un clon del repositorio, los comandos deben lanzarse en su raíz.

## Verificación

```fish
fastfetch --config ~/.config/fastfetch/config.jsonc
```

Debe comprobarse:

- ausencia de errores de configuración;
- alineación de todas las claves;
- ausencia de wrapping en una división vertical habitual;
- logo legible con la fuente activa;
- conservación de los datos de diagnóstico elegidos.

## Rollback manual

Antes de aplicar otro preset:

```fish
cp ~/.config/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc.bak
```

Para restaurarlo:

```fish
cp ~/.config/fastfetch/config.jsonc.bak ~/.config/fastfetch/config.jsonc
fastfetch
```

El módulo futuro deberá crear respaldos versionados y evitar depender de un único archivo `.bak`.

## Decisión arquitectónica

La personalización de Fastfetch pertenece a la experiencia visual administrada por N.E.S.T., no al Core crítico ni a Cachy-caOS como requisito de funcionamiento.

N.E.S.T. puede ofrecer catálogo, previsualización, importación y reparación; Fastfetch continúa siendo el motor responsable de detectar y presentar la información del sistema.
