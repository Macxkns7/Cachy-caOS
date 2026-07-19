# Visualizador de imágenes

**Estado:** Vigente y validado  
**Última revisión:** 2026-07-18

## Objetivo

Definir el visualizador de imágenes adoptado por Cachy-caOS, registrar su validación práctica y establecer cómo Nest debe instalarlo y administrar sus asociaciones MIME sin acoplar la selección de la aplicación a la lógica general de tipos de archivo.

## Aplicación adoptada

La aplicación seleccionada es **Loupe**.

Estado comprobado en el sistema:

```text
Paquete: loupe
Versión validada: 50.0-1.1
Repositorio: cachyos-extra-v4
Arquitectura: x86_64_v4
Desktop ID: org.gnome.Loupe.desktop
```

Loupe fue instalado explícitamente desde los repositorios de CachyOS y se integra con el stack gráfico vigente mediante GTK4 y libadwaita.

## Motivos de la selección

Loupe fue elegido porque cumple el perfil técnico y visual definido para las aplicaciones base de Cachy-caOS:

- GTK4 y libadwaita;
- ejecución nativa en Wayland;
- apertura inmediata desde Nemo;
- interfaz mínima que deja protagonismo a la imagen;
- navegación y zoom fluidos;
- integración visual correcta con Noctalia;
- mantenimiento activo dentro del ecosistema GNOME;
- dependencias razonables para una aplicación base;
- ausencia de necesidad comprobada de CSS específico o fork.

La selección sigue el principio de Nest **adopción antes que fork**: se integra una herramienta externa bien mantenida y solo se contempla modificarla si aparece una necesidad técnica real que upstream no resuelva.

## Alternativas consideradas

Durante la evaluación se consideraron también:

- **Gwenview:** muy completo, pero introduce el stack Qt/KDE y una identidad visual menos coherente con la base GTK actual.
- **qView:** rápido y sencillo, pero basado en Qt y con menor integración visual con Noctalia.
- **imv** y **swayimg:** excelentes opciones ligeras para flujos centrados en teclado, pero menos adecuadas como aplicación gráfica predeterminada para una experiencia general de escritorio.
- **Eye of GNOME:** perteneciente a una generación anterior del stack GNOME y superado como opción principal por Loupe.

La decisión no establece que Loupe sea universalmente superior, sino que es el mejor ajuste para la arquitectura y experiencia actuales de Cachy-caOS.

## Integración visual validada

La prueba real confirmó:

- modo oscuro coherente;
- controles y headerbar de libadwaita correctamente renderizados;
- compatibilidad visual con la paleta aplicada por Noctalia;
- comportamiento natural junto a Nemo;
- apertura rápida y navegación fluida;
- ausencia de personalización específica necesaria en esta etapa.

Loupe utiliza GTK4/libadwaita, por lo que su apariencia depende del stack moderno de GNOME y no del tema GTK3 `adw-gtk-theme` usado para aplicaciones como Nemo. Nest debe respetar esta separación entre toolkits.

## Incidente detectado: asociación MIME incorrecta

Después de instalar Loupe, Nemo continuó mostrando **G'MIC-Qt** como aplicación predeterminada para JPEG.

Diagnóstico comprobado:

```fish
xdg-mime query default image/jpeg
```

Resultado inicial:

```text
gmic_qt.desktop
```

La misma asociación fue confirmada mediante:

```fish
gio mime image/jpeg
```

Loupe ya aparecía como aplicación registrada mediante el identificador:

```text
org.gnome.Loupe.desktop
```

El problema no correspondía a Loupe ni a Nemo, sino a la asociación MIME persistente del usuario.

## Asociación aplicada

Se estableció Loupe como aplicación predeterminada para los formatos de imagen comunes:

```fish
xdg-mime default org.gnome.Loupe.desktop image/jpeg
xdg-mime default org.gnome.Loupe.desktop image/png
xdg-mime default org.gnome.Loupe.desktop image/webp
xdg-mime default org.gnome.Loupe.desktop image/gif
xdg-mime default org.gnome.Loupe.desktop image/bmp
xdg-mime default org.gnome.Loupe.desktop image/tiff
xdg-mime default org.gnome.Loupe.desktop image/svg+xml
xdg-mime default org.gnome.Loupe.desktop image/avif
xdg-mime default org.gnome.Loupe.desktop image/heif
```

Validación posterior:

```fish
xdg-mime query default image/jpeg
gio mime image/jpeg
```

Resultado esperado:

```text
org.gnome.Loupe.desktop
```

Después del cambio, las imágenes se abren inmediatamente con Loupe mediante doble clic desde Nemo.

## Responsabilidad de Nest

Nest debe separar dos responsabilidades:

### Instalación de la aplicación

Un módulo de aplicación debe instalar Loupe de forma idempotente:

```fish
sudo pacman -S --needed loupe
```

Nombre conceptual sugerido:

```text
apps/loupe.sh
```

### Administración de asociaciones MIME

La selección de aplicaciones predeterminadas no debe quedar embebida dentro del instalador específico de Loupe.

Nest debe disponer de un módulo central de asociaciones, conceptualmente:

```text
defaults/mime.sh
```

Este módulo deberá:

- definir las aplicaciones oficiales por categoría;
- aplicar las asociaciones MIME de forma idempotente;
- verificar que el archivo `.desktop` objetivo exista antes de escribir la asociación;
- conservar un registro claro de los MIME administrados;
- permitir cambiar el visor futuro sin modificar otros módulos;
- validar el resultado con `xdg-mime query default`;
- evitar eliminar aplicaciones alternativas registradas;
- modificar únicamente el valor predeterminado solicitado.

## Modelo de datos recomendado

Nest debería mantener una única fuente declarativa para las asociaciones oficiales. Ejemplo conceptual:

```text
image/jpeg       -> org.gnome.Loupe.desktop
image/png        -> org.gnome.Loupe.desktop
image/webp       -> org.gnome.Loupe.desktop
image/gif        -> org.gnome.Loupe.desktop
image/bmp        -> org.gnome.Loupe.desktop
image/tiff       -> org.gnome.Loupe.desktop
image/svg+xml    -> org.gnome.Loupe.desktop
image/avif       -> org.gnome.Loupe.desktop
image/heif       -> org.gnome.Loupe.desktop
```

La implementación futura puede usar Bash, Fish o un formato declarativo intermedio, pero la fuente debe ser única y fácil de auditar.

## Reglas de implementación

1. Diagnosticar la asociación existente antes de cambiarla.
2. Instalar Loupe antes de asignar su Desktop ID.
3. No asumir que instalar un paquete cambia correctamente las asociaciones del usuario.
4. Aplicar asociaciones por MIME, no por extensión de archivo.
5. Verificar al menos JPEG y PNG después de la aplicación.
6. Mantener la operación reversible y documentar el valor anterior cuando el instalador disponga de estado o backup.
7. No ejecutar `update-desktop-database` ni otras operaciones globales salvo que exista una razón comprobada; Loupe ya queda registrado correctamente por el paquete.
8. Tratar las asociaciones MIME como configuración del usuario, no como una propiedad interna de Nemo.

## Estado final

El módulo **Visualizador de imágenes** queda aprobado para Cachy-caOS:

- aplicación oficial: Loupe;
- integración visual: validada;
- integración con Nemo: validada;
- asociación MIME: validada;
- personalización adicional: no requerida actualmente;
- implementación en Nest: pendiente, con arquitectura definida en este documento.
