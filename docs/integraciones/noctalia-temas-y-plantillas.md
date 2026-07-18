# Temas y plantillas de Noctalia v5

**Estado:** Vigente con desarrollo pendiente  
**Última revisión:** 2026-07-18  
**Relacionado con:** `docs/integraciones/noctalia-v5.md`, `docs/configuraciones-importantes.md`

## Objetivo

Documentar el funcionamiento comprobado del sistema de temas y plantillas de Noctalia v5, con énfasis en la integración GTK3 validada de extremo a extremo en Cachy-caOS.

Este documento distingue entre:

- hechos comprobados en la instalación actual;
- decisiones arquitectónicas adoptadas para Nest;
- extensiones todavía pendientes de diseño o validación.

## Resultado final comprobado

La integración GTK3 de Noctalia v5 quedó funcionando con esta cadena:

```text
paleta activa de Noctalia
→ plantilla oficial gtk3.css
→ ~/.config/gtk-3.0/noctalia.css
→ import desde ~/.config/gtk-3.0/gtk.css
→ tema base adw-gtk3-dark
→ widgets GTK3
→ aplicaciones como Nemo
```

Estado verificado:

```text
Paquete: adw-gtk-theme 6.5-1
Tema GTK activo: adw-gtk3-dark
Tema claro disponible: /usr/share/themes/adw-gtk3
Tema oscuro disponible: /usr/share/themes/adw-gtk3-dark
Import GTK3: @import url("noctalia.css");
```

La activación final fue confirmada con:

```fish
gsettings get org.gnome.desktop.interface gtk-theme
```

Resultado:

```text
'adw-gtk3-dark'
```

Nemo adoptó correctamente el tema oscuro y la paleta generada por Noctalia.

## Hallazgo principal

Noctalia no implementa un tema GTK completo. Su responsabilidad es generar una paleta semántica y sincronizar la apariencia del sistema.

`adw-gtk-theme` aporta el estilo y la estructura visual de los widgets GTK3. La plantilla de Noctalia redefine colores simbólicos que ese tema y las aplicaciones pueden consumir.

Por tanto, las responsabilidades reales son:

```text
Noctalia
├── genera colores semánticos
├── escribe noctalia.css
├── garantiza el import en gtk.css
├── sincroniza modo claro u oscuro
└── selecciona adw-gtk3 cuando está disponible

adw-gtk-theme
├── renderiza widgets GTK3
├── aporta reglas visuales generales
└── consume colores simbólicos compatibles

Nest
├── conserva esta separación
├── añade integración y seguridad
└── podrá extender aplicaciones concretas con CSS mínimo y reversible
```

## Instalación observada

El paquete de la shell es:

```text
noctalia-git
```

Sus recursos oficiales se distribuyen bajo:

```text
/usr/share/noctalia/assets/templates/
```

El catálogo incorporado está en:

```text
/usr/share/noctalia/assets/templates/builtin.toml
```

La integración GTK contiene:

```text
/usr/share/noctalia/assets/templates/gtk/
├── gtk3.css
├── gtk4.css
└── apply.sh
```

Estos archivos pertenecen al paquete. No deben modificarse directamente porque una actualización de `noctalia-git` puede reemplazarlos.

## Catálogo y procesamiento de plantillas

Las entradas del catálogo describen nombre, categoría, entrada, salida y hook posterior. Para GTK3, el flujo observado es equivalente a:

```toml
[templates.gtk3]
input_path = "./gtk/gtk3.css"
output_path = "$XDG_CONFIG_HOME/gtk-3.0/noctalia.css"
post_hook = "bash '{{ config_dir }}/gtk/apply.sh' {{ mode }}"
```

Campos comprobados:

- `input_path`: plantilla de entrada;
- `output_path`: archivo renderizado;
- `input_path_dynamic`: resolución dinámica de entrada;
- `output_path_dynamic`: resolución dinámica de salida;
- `post_hook`: acción posterior al renderizado.

La configuración de usuario utiliza otra raíz TOML:

```toml
[theme.templates.user.nombre]
```

No debe confundirse con las entradas internas `[templates.*]` del catálogo incorporado.

## Plantillas de usuario

Las extensiones propias deben vivir bajo:

```text
~/.config/noctalia/
```

Ejemplo mínimo validado por el esquema de configuración:

```toml
[theme.templates.user.nest_test]
input_path = "$XDG_CONFIG_HOME/noctalia/templates/nest-test.txt"
output_path = "$XDG_CACHE_HOME/nest/nest-test-output.txt"
```

Validación:

```fish
noctalia config validate
```

Regla para Nest:

> Las extensiones propias deben declararse como plantillas de usuario o como recursos administrados por Nest. Nunca deben añadirse dentro de `/usr/share/noctalia/`.

## Tokens comprobados

La plantilla GTK3 oficial utiliza tokens como:

```text
{{ colors.primary.default.hex }}
{{ colors.on_primary.default.hex }}
{{ colors.surface.default.hex }}
{{ colors.surface_container.default.hex }}
{{ colors.on_surface.default.hex }}
{{ colors.error.default.hex }}
{{ colors.on_error.default.hex }}
{{ mode }}
{{ config_dir }}
```

Interpretación comprobada:

- `colors.<rol>.default.hex`: valor hexadecimal del rol semántico;
- `mode`: `dark` o `light`;
- `config_dir`: directorio base usado durante el procesamiento.

No deben asumirse tokens adicionales sin verificarlos en la versión instalada o mediante una prueba controlada.

## Qué genera `gtk3.css`

La plantilla oficial contiene únicamente definiciones de colores simbólicos. Ejemplos:

```css
@define-color accent_color {{colors.primary.default.hex}};
@define-color accent_bg_color {{colors.primary.default.hex}};
@define-color accent_fg_color {{colors.on_primary.default.hex}};

@define-color window_bg_color {{colors.surface.default.hex}};
@define-color window_fg_color {{colors.on_surface.default.hex}};

@define-color view_bg_color {{colors.surface.default.hex}};
@define-color view_fg_color {{colors.on_surface.default.hex}};

@define-color headerbar_bg_color {{colors.surface_container.default.hex}};
@define-color sidebar_bg_color {{colors.surface_container.default.hex}};
```

También define roles para:

- errores y acciones destructivas;
- popovers;
- tarjetas y diálogos;
- overview;
- sidebars primarias y secundarias;
- selección enfocada;
- estados desenfocados.

No contiene selectores de widgets como:

```css
window { }
button { }
treeview { }
.sidebar { }
.nemo-window { }
```

Conclusión comprobada:

> `gtk3.css` es un exportador de paleta semántica, no un tema GTK ni un tema específico para Nemo.

## Archivo generado en el usuario

Noctalia renderiza:

```text
~/.config/gtk-3.0/noctalia.css
```

En la validación actual, ese archivo contenía valores como:

```css
@define-color accent_bg_color #b58fff;
@define-color accent_fg_color #000000;
@define-color window_bg_color #000000;
@define-color window_fg_color #e8d8ff;
@define-color headerbar_bg_color #110d1a;
@define-color sidebar_bg_color #110d1a;
```

Esto confirma que la paleta activa de Noctalia estaba siendo procesada correctamente antes de instalar el tema GTK base.

## Qué hace `apply.sh`

El script oficial realiza cuatro tareas principales.

### Garantizar el import

Define:

```css
@import url("noctalia.css");
```

Y lo crea o añade en:

```text
~/.config/gtk-3.0/gtk.css
~/.config/gtk-4.0/gtk.css
```

Evita duplicar el import y procura preservar el contenido existente.

### Preservar archivos previos

Si `gtk.css` ya existe, conserva su contenido y añade el import. Si es un enlace simbólico escribible, modifica el destino. Si el destino es de solo lectura, crea un archivo local.

### Sincronizar apariencia

Usa `gsettings` y recurre a `dconf` cuando corresponde para establecer:

```text
org.gnome.desktop.interface color-scheme
```

Valores esperados:

```text
prefer-dark
prefer-light
```

### Seleccionar el tema GTK base

Para modo claro busca:

```text
adw-gtk3
```

Para modo oscuro busca:

```text
adw-gtk3-dark
```

El script verifica primero que el tema exista en rutas estándar:

```text
~/.themes
~/.local/share/themes
/usr/share/themes
/usr/local/share/themes
rutas derivadas de XDG_DATA_DIRS
```

Si no lo encuentra, muestra un aviso y omite el cambio de `gtk-theme`. La shell y la generación de colores continúan funcionando.

## Diferencia crítica de `--appearance-only`

El modo:

```fish
/usr/share/noctalia/assets/templates/gtk/apply.sh --appearance-only dark
```

sincroniza solamente el esquema claro u oscuro. Internamente llama a la sincronización con la actualización del tema GTK deshabilitada.

Por tanto, **no selecciona `adw-gtk3-dark`**, aunque el paquete ya esté instalado.

Para aplicar la integración completa se debe ejecutar:

```fish
/usr/share/noctalia/assets/templates/gtk/apply.sh dark
```

Salida comprobada:

```text
GTK3 colors applied successfully
GTK4 colors applied successfully
```

Después de esa ejecución, `gsettings` pasó de:

```text
'Adwaita'
```

a:

```text
'adw-gtk3-dark'
```

## Dependencia opcional de integración

`adw-gtk-theme` no forma parte del núcleo necesario para ejecutar Noctalia v5. La shell se instaló y funcionó correctamente sin él, sin errores de instalación.

La arquitectura observada indica que es una dependencia funcional de la integración GTK:

```text
Noctalia sin adw-gtk-theme
→ shell funcional
→ paleta GTK generada
→ tema GTK previo conservado

Noctalia con adw-gtk-theme
→ shell funcional
→ paleta GTK generada
→ adw-gtk3 seleccionado
→ integración visual GTK3 completa
```

Esto explica por qué la instalación inicial no emitió errores ni advertencias: no existía una falla del paquete principal.

## Procedimiento reproducible validado

### Diagnóstico inicial

```fish
pacman -Qs adw
find /usr/share/themes -maxdepth 2 -type f -name 'gtk.css'
gsettings get org.gnome.desktop.interface gtk-theme
sed -n '1,160p' ~/.config/gtk-3.0/gtk.css
```

Estado observado antes del cambio:

```text
adw-gtk-theme no instalado
/usr/share/themes sin adw-gtk3
Tema activo: Adwaita
gtk.css: @import url("noctalia.css");
```

### Inspección de la integración oficial

```fish
sed -n '1,240p' /usr/share/noctalia/assets/templates/gtk/gtk3.css
sed -n '1,240p' /usr/share/noctalia/assets/templates/gtk/apply.sh
```

### Instalación

```fish
sudo pacman -S adw-gtk-theme
```

Versión instalada durante la validación:

```text
adw-gtk-theme 6.5-1
```

Snapper creó automáticamente:

```text
snapshot previo: 51
snapshot posterior: 52
```

### Verificación de archivos

```fish
find /usr/share/themes -maxdepth 1 -type d | grep adw
```

Resultado:

```text
/usr/share/themes/adw-gtk3
/usr/share/themes/adw-gtk3-dark
```

### Aplicación completa

```fish
/usr/share/noctalia/assets/templates/gtk/apply.sh dark
```

### Confirmación

```fish
gsettings get org.gnome.desktop.interface gtk-theme
```

Resultado:

```text
'adw-gtk3-dark'
```

### Validación visual

Se cerró y volvió a abrir Nemo. La aplicación adoptó:

- fondo negro de la paleta activa;
- acento púrpura;
- controles y navegación con estilo `adw-gtk3-dark`;
- integración coherente con el escritorio Noctalia.

## Nemo y el soporte específico del tema

Nemo posee lógica propia de compatibilidad de temas. Reconoce algunas familias y, cuando no detecta soporte específico, carga un fallback mínimo.

El fallback interno cubre principalmente elementos puntuales como:

- panel inactivo en vista dividida;
- campo de renombrado;
- barra de estado flotante.

No reemplaza un tema GTK completo.

La instalación de `adw-gtk-theme` resolvió la ausencia del motor visual general. Aun así, futuras mejoras específicas de Nemo podrían requerir selectores propios, siempre sobre esta base ya funcional.

## Decisión arquitectónica para Nest

Nest no debe crear inicialmente un tema GTK completo ni mantener un fork de `adw-gtk3`.

Modelo adoptado:

```text
Noctalia Palette
→ roles semánticos
→ adaptador del toolkit
→ extensiones específicas mínimas
→ aplicaciones
```

Para GTK3:

```text
Noctalia
→ noctalia.css
→ adw-gtk3
→ adaptador GTK de Nest opcional
→ Nemo y demás aplicaciones GTK3
```

Principios:

- no editar `/usr/share/noctalia/`;
- no editar `/usr/share/themes/adw-gtk3*`;
- no sobrescribir manualmente `noctalia.css`;
- usar roles semánticos antes que valores hexadecimales fijos;
- separar paleta, toolkit y aplicación;
- mantener backup y rollback;
- validar dependencias antes de aplicar cambios;
- documentar la versión probada;
- degradarse con elegancia si una dependencia opcional no está instalada.

## Estructura propuesta para futuras extensiones

Dirección de diseño todavía no implementada:

```text
Nest
└── themes/
    ├── noctalia/
    │   ├── templates/
    │   └── hooks/
    └── adapters/
        ├── gtk3/
        ├── gtk4/
        └── apps/
            └── nemo/
```

Cada integración deberá separar:

- plantilla de entrada;
- archivo generado;
- hook de aplicación o recarga;
- comprobación de dependencias;
- backup;
- rollback;
- pruebas de compatibilidad.

## Rollback

El cambio es reversible sin eliminar Noctalia.

Para volver temporalmente a Adwaita:

```fish
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
```

Para retirar el paquete:

```fish
sudo pacman -Rns adw-gtk-theme
```

Antes de una reversión mayor también están disponibles los snapshots 51 y 52 creados durante la instalación.

## Comandos útiles

Listar recursos de Noctalia:

```fish
find /usr/share/noctalia/assets/templates ~/.config/noctalia/templates \
    -type f \( -name '*.css' -o -name '*.toml' -o -name '*.sh' \) \
    -print
```

Inspeccionar archivos generados:

```fish
sed -n '1,220p' ~/.config/gtk-3.0/noctalia.css
sed -n '1,160p' ~/.config/gtk-3.0/gtk.css
```

Revisar el tema activo:

```fish
gsettings get org.gnome.desktop.interface gtk-theme
```

Validar configuración de Noctalia:

```fish
noctalia config validate
```

## Pendientes

- identificar los selectores CSS reales de Nemo antes de cualquier extensión específica;
- comprobar cambios automáticos al alternar wallpaper y modo claro/oscuro;
- validar coexistencia entre `noctalia.css` y un adaptador GTK propio de Nest;
- diseñar backup y rollback automáticos para extensiones GTK;
- evaluar si la diferenciación entre `surface` y `surface_container` requiere reglas adicionales;
- comprobar la integración GTK4 de extremo a extremo sin confundirla con libadwaita.

## Regla operativa

```text
inspeccionar versión instalada
→ leer plantilla y hook oficiales
→ verificar dependencia opcional
→ respaldar
→ instalar cambio mínimo
→ aplicar integración completa
→ confirmar gsettings
→ reiniciar solo la aplicación afectada
→ validar visualmente
→ documentar
→ conservar rollback
```

Noctalia debe seguir siendo la fuente de la paleta. `adw-gtk-theme` aporta el renderizado GTK3. Nest debe añadir solamente integración, seguridad y extensiones específicas mantenibles.