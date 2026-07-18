# Temas y plantillas de Noctalia v5

**Estado:** Vigente con investigación abierta  
**Última revisión:** 2026-07-18  
**Relacionado con:** `docs/integraciones/noctalia-v5.md`

## Objetivo

Documentar el funcionamiento comprobado del sistema de temas y plantillas de Noctalia v5, su integración con GTK y las reglas que Nest debe seguir para extenderlo sin modificar archivos administrados por el paquete.

Este documento separa explícitamente:

- hechos comprobados en la instalación actual;
- inferencias arquitectónicas derivadas del código instalado;
- decisiones adoptadas para Nest;
- pendientes que todavía requieren validación.

## Instalación observada

El paquete instalado se identifica como `noctalia-git` y distribuye sus recursos bajo:

```text
/usr/share/noctalia/assets/templates/
```

El catálogo incorporado está en:

```text
/usr/share/noctalia/assets/templates/builtin.toml
```

Las plantillas oficiales se organizan por integración:

```text
alacritty/
btop/
cava/
emacs/
foot/
ghostty/
gtk/
helix/
hyprland/
kde/
kitty/
labwc/
mango/
niri/
qt/
scroll/
starship/
sway/
wezterm/
```

La carpeta `gtk/` contiene:

```text
gtk3.css
gtk4.css
apply.sh
```

Estos archivos pertenecen al paquete y no deben editarse directamente. Una actualización de `noctalia-git` podría reemplazarlos.

## Arquitectura comprobada

El flujo conceptual observado es:

```text
paleta activa de Noctalia
→ mapa de tokens del tema
→ plantilla seleccionada
→ archivo de configuración generado
→ post_hook opcional
→ aplicación o recarga de la integración
```

Noctalia separa dos responsabilidades:

1. **Generación de valores:** el procesador sustituye tokens como `{{ colors.primary.default.hex }}`.
2. **Integración con la aplicación:** un `post_hook` puede importar el archivo, recargar la aplicación o sincronizar ajustes del sistema.

Esta separación es importante para Nest: la paleta y el estilo específico de una aplicación no son la misma capa.

## Catálogo incorporado

`builtin.toml` tiene dos grupos principales.

### Catálogo visible

Las entradas `[catalog.<id>]` definen metadatos para la interfaz:

```toml
[catalog.gtk3]
name = "GTK 3"
category = "system"
```

El catálogo no contiene la implementación visual. Solo registra nombre y categoría.

### Definición de plantillas

Las entradas `[templates.<id>]` describen el proceso:

```toml
[templates.gtk3]
input_path = "./gtk/gtk3.css"
output_path = "$XDG_CONFIG_HOME/gtk-3.0/noctalia.css"
post_hook = "bash '{{ config_dir }}/gtk/apply.sh' {{ mode }}"
```

Campos comprobados:

- `input_path`: archivo plantilla estático;
- `output_path`: destino renderizado;
- `input_path_dynamic`: comando que resuelve dinámicamente la entrada;
- `output_path_dynamic`: comando que resuelve dinámicamente la salida;
- `output_path` como lista: permite escribir el mismo resultado en varios destinos;
- `post_hook`: comando ejecutado después del renderizado.

El catálogo incorporado y la configuración de usuario no usan exactamente la misma raíz TOML.

Catálogo incorporado:

```toml
[templates.gtk3]
```

Configuración de usuario:

```toml
[theme.templates.user.nest_test]
```

No deben mezclarse ambos contextos.

## Plantillas de usuario

La configuración personal se almacena bajo:

```text
~/.config/noctalia/
```

Una plantilla de usuario mínima comprobada puede registrarse así:

```toml
[theme.templates.user.nest_test]
input_path = "$XDG_CONFIG_HOME/noctalia/templates/nest-test.txt"
output_path = "$XDG_CACHE_HOME/nest/nest-test-output.txt"
```

La configuración fue aceptada por:

```fish
noctalia config validate
```

Los avisos observados sobre ajustes antiguos de widgets no estaban relacionados con la plantilla. La validación confirmó que la sección `theme.templates.user` era reconocida.

Regla para Nest:

> Las extensiones propias deben declararse como plantillas de usuario o recursos administrados por Nest. Nunca deben añadirse dentro de `/usr/share/noctalia/`.

## Sintaxis de tokens comprobada

La plantilla GTK3 oficial utiliza expresiones como:

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

Tokens comprobados directamente:

- `colors.<rol>.default.hex`: color hexadecimal de un rol del tema;
- `mode`: modo `dark` o `light`;
- `config_dir`: directorio base desde el que se procesa el catálogo.

No debe asumirse que existen más tokens sin verificarlos en una plantilla oficial, la ayuda de la versión instalada o una prueba controlada.

## GTK3: qué genera Noctalia

La plantilla oficial `gtk3.css` contiene únicamente definiciones de color:

```css
@define-color accent_color {{colors.primary.default.hex}};
@define-color window_bg_color {{colors.surface.default.hex}};
@define-color window_fg_color {{colors.on_surface.default.hex}};
@define-color headerbar_bg_color {{colors.surface_container.default.hex}};
```

También define colores semánticos para:

- acento;
- errores y acciones destructivas;
- ventanas y vistas;
- headerbars;
- popovers;
- tarjetas y diálogos;
- overview;
- sidebars;
- estados seleccionados;
- estados desenfocados.

La plantilla oficial no contiene selectores de widgets como:

```css
treeview { }
.sidebar { }
.nemo-window { }
```

Conclusión comprobada:

> La plantilla GTK de Noctalia proporciona una paleta semántica. No implementa por sí sola el estilo completo de Nemo ni de otras aplicaciones GTK3.

## GTK: qué hace `apply.sh`

El script oficial realiza cuatro tareas principales.

### 1. Garantizar el import

Define:

```css
@import url("noctalia.css");
```

Y lo crea o añade en:

```text
~/.config/gtk-3.0/gtk.css
~/.config/gtk-4.0/gtk.css
```

El script evita duplicar el import si ya está presente.

### 2. Preservar contenido existente

Si `gtk.css` ya existe, conserva su contenido y añade el import. Si es un enlace simbólico escribible, modifica el destino. Si apunta a un destino de solo lectura, lo reemplaza por un archivo local.

### 3. Sincronizar modo claro u oscuro

Usa `gsettings` cuando está disponible y recurre a `dconf` como alternativa:

```text
org.gnome.desktop.interface color-scheme
```

El valor se sincroniza con:

```text
prefer-dark
prefer-light
```

### 4. Seleccionar el tema GTK base

Para modo claro intenta utilizar:

```text
adw-gtk3
```

Para modo oscuro:

```text
adw-gtk3-dark
```

Antes comprueba que el tema exista en las rutas habituales de temas. Si no está disponible, mantiene la sincronización de apariencia, pero omite el cambio de `gtk-theme`.

Conclusión arquitectónica:

```text
adw-gtk3 / adw-gtk3-dark
→ define estructura y estilo de widgets GTK3

noctalia.css
→ redefine colores semánticos

reglas CSS adicionales del usuario o de Nest
→ personalización específica de una aplicación
```

## Por qué Nemo puede seguir viéndose genérico

Nemo informó:

```text
Current gtk theme is not known to have nemo support (Adwaita)
The theme appears to have no nemo support. Adding some...
```

No se encontraron reglas `nemo` persistentes bajo los directorios personales de temas o GTK. La evidencia indica que Nemo añade compatibilidad de respaldo durante la ejecución cuando el tema activo no declara soporte específico.

Esto explica por qué cambiar solo las variables de Noctalia no necesariamente transforma toda la interfaz de Nemo:

- Noctalia aporta colores;
- `adw-gtk3` aporta el estilo general;
- Nemo puede añadir fallback interno;
- los detalles propios de Nemo requieren selectores y reglas adicionales.

La siguiente investigación debe identificar las clases CSS y widgets reales expuestos por Nemo antes de crear reglas permanentes.

## Decisión para Nest

Nest debe actuar como una capa de extensión, no como reemplazo del sistema de temas de Noctalia.

Modelo adoptado:

```text
Noctalia
├── genera la paleta
├── renderiza tokens
└── sincroniza apariencia

Nest Theme Extensions
├── consume colores generados
├── añade reglas específicas por aplicación
├── conserva archivos administrados por Noctalia
├── valida antes de aplicar
└── permite backup y rollback
```

Principios:

- no editar `/usr/share/noctalia/`;
- no sobrescribir `noctalia.css` con contenido manual;
- no depender de valores hexadecimales fijos cuando exista un rol semántico;
- separar paleta, integración y estilo específico;
- mantener cada integración reversible;
- validar que el archivo generado exista antes de importar;
- documentar la versión de Noctalia con la que se probó;
- degradarse con elegancia si Noctalia no está instalada.

## Estructura propuesta para futuras extensiones

La estructura definitiva todavía no está implementada, pero la dirección aprobada es:

```text
Nest
└── themes/
    ├── noctalia/
    │   ├── templates/
    │   └── hooks/
    └── apps/
        ├── nemo/
        ├── gtk3/
        └── gtk4/
```

Cada aplicación debe mantener separadas:

- plantilla de entrada;
- archivo generado;
- hook de aplicación o recarga;
- comprobación de dependencias;
- backup;
- rollback;
- pruebas de compatibilidad.

Esta estructura es una dirección de diseño, no una implementación validada todavía.

## Comandos útiles comprobados

Listar recursos instalados:

```fish
pacman -Ql noctalia | grep -E 'templates|builtin|assets|share/noctalia'
```

Inspeccionar el catálogo:

```fish
sed -n '1,200p' /usr/share/noctalia/assets/templates/builtin.toml
```

Inspeccionar GTK3:

```fish
sed -n '1,200p' /usr/share/noctalia/assets/templates/gtk/gtk3.css
```

Inspeccionar el hook GTK:

```fish
sed -n '1,240p' /usr/share/noctalia/assets/templates/gtk/apply.sh
```

Validar configuración personal:

```fish
noctalia config validate
```

Consultar la ayuda del procesador de temas:

```fish
noctalia theme --help
```

## Pendientes de validación

- ejecutar de extremo a extremo una plantilla de usuario contra la paleta activa;
- determinar el mecanismo exacto con el que la interfaz vuelve a renderizar plantillas habilitadas;
- comprobar dónde y cómo se mantiene el mapa de tokens durante la ejecución;
- enumerar tokens adicionales de forma controlada;
- validar comportamiento tras cambiar wallpaper y modo claro/oscuro;
- comprobar coexistencia con reglas CSS de Nest;
- identificar selectores CSS reales de Nemo;
- diseñar rollback automático para extensiones GTK.

## Regla operativa

```text
inspeccionar versión instalada
→ leer plantilla oficial
→ verificar tokens
→ crear plantilla de usuario
→ renderizar en destino controlado
→ revisar diff
→ respaldar archivo objetivo
→ aplicar hook
→ reiniciar solo la aplicación afectada
→ comprobar resultado
→ documentar
→ poder revertir
```

Noctalia debe seguir siendo la fuente de la paleta. Nest debe aportar integración, seguridad y extensiones específicas sin apropiarse de archivos administrados por el proveedor.