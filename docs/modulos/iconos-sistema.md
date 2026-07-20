# Iconos del sistema y adaptación GTK/Qt

**Estado:** Vigente y validado; automatización de Nest pendiente  
**Última revisión:** 2026-07-20  
**Relacionado con:** `docs/integraciones/noctalia-temas-y-plantillas.md`, `docs/nest/02-roadmap-arquitectonico.md`, `docs/nest/03-estado-de-implementacion.md`

## Objetivo

Documentar la instalación y activación comprobadas de Papirus en CachyOS + Hyprland + Noctalia v5, explicar por qué GTK y Qt requieren mecanismos distintos y definir cómo Nest deberá convertir este procedimiento en una operación declarativa, verificable, reparable y reversible.

Este documento es la fuente canónica para:

- tema de iconos global;
- integración GTK y Qt;
- color de carpetas Papirus;
- interacción con Noctalia;
- persistencia en Hyprland;
- diseño del futuro módulo de apariencia de Nest.

## Resultado final comprobado

La instalación actual quedó validada con:

```text
Tema de iconos: Papirus-Dark
Color de carpetas: violet
GTK: org.gnome.desktop.interface icon-theme
Qt 6: qt6ct
Motor visual Qt: Fusion
Hyprland: QT_QPA_PLATFORMTHEME=qt6ct
Shell: Noctalia v5.0.0
```

La apariencia fue comprobada visualmente en el sistema real. Papirus-Dark y las carpetas `violet` mantienen contraste sobre el fondo AMOLED y son coherentes con la paleta comunitaria Lilac AMOLED de Noctalia.

## Arquitectura comprobada

No existe un único interruptor universal para iconos en una sesión Hyprland mínima.

```text
Papirus
├── aporta archivos del tema Freedesktop
├── no selecciona por sí solo el tema activo
└── no controla el color dinámico de Noctalia

GTK
└── obtiene icon-theme mediante gsettings

Qt
├── necesita un proveedor de configuración de plataforma
├── usa qt6ct en la instalación actual
└── lee icon_theme desde qt6ct.conf

Noctalia
├── es una aplicación Qt
├── no almacena icon_theme en settings.toml
├── usa el tema que Qt conoce al iniciar
└── conserva paleta y estilos como responsabilidades separadas

Hyprland
└── exporta QT_QPA_PLATFORMTHEME antes de iniciar Noctalia
```

Conclusión:

> Paleta, tema de widgets, tema de iconos y proveedor de configuración son capas distintas. Nest debe administrarlas mediante adaptadores separados y una política común.

## Diagnóstico inicial validado

Antes del cambio, el sistema contenía únicamente:

```text
adwaita-icon-theme
adwaita-icon-theme-legacy
hicolor-icon-theme
```

El tema GTK declarado era:

```text
'Adwaita'
```

No estaban instalados `papirus-icon-theme`, `qt6ct`, `paru`, `yay` ni un proveedor Qt equivalente. La sesión mostraba:

```text
XDG_CURRENT_DESKTOP=Hyprland
```

y no exportaba:

```text
QT_QPA_PLATFORMTHEME
```

Noctalia se ejecutaba como proceso directo, sin un servicio de usuario de systemd. Su configuración vigente estaba dividida entre:

```text
~/.config/noctalia/config.toml
~/.local/state/noctalia/settings.toml
```

Ninguno de esos archivos contenía una selección de tema de iconos.

## Procedimiento reproducible validado

### Instalar Papirus desde Arch

```fish
sudo pacman -S papirus-icon-theme
```

Verificación:

```fish
ls /usr/share/icons | grep -i papirus
```

Resultado observado:

```text
Papirus
Papirus-Dark
Papirus-Light
```

### Activar Papirus para GTK

```fish
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings get org.gnome.desktop.interface icon-theme
```

Resultado esperado:

```text
'Papirus-Dark'
```

Este paso configura GTK, pero no garantiza que aplicaciones Qt ni una instancia de Noctalia iniciada previamente adopten el cambio.

### Instalar el proveedor Qt

```fish
sudo pacman -S qt6ct
```

Abrir el configurador con el proveedor cargado explícitamente:

```fish
env QT_QPA_PLATFORMTHEME=qt6ct qt6ct
```

En **Icon Theme** se seleccionó `Papirus-Dark`. La configuración resultante contiene:

```ini
icon_theme=Papirus-Dark
style=Fusion
```

Archivo:

```text
~/.config/qt6ct/qt6ct.conf
```

Noctalia ya genera un esquema de color compatible bajo:

```text
~/.config/qt6ct/colors/noctalia.conf
```

La selección de iconos debe preservar el esquema de color y el estilo existentes; Nest no debe reemplazar el archivo completo.

### Persistir el proveedor en Hyprland

La configuración Lua actual exporta:

```lua
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
```

La declaración debe ejecutarse antes del arranque de Noctalia:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia")
end)
```

El cambio requiere una nueva sesión de Hyprland para verificar la herencia completa del entorno.

Comprobación posterior:

```fish
printenv QT_QPA_PLATFORMTHEME
```

Resultado esperado:

```text
qt6ct
```

### Instalar Papirus Folders sin un ayudante AUR

La instalación limpia no incluía `paru` ni `yay`. No se añadió un gestor AUR para una sola utilidad.

Se inspeccionó primero el instalador oficial y se fijó una versión estable:

```fish
curl -L https://git.io/papirus-folders-install \
    -o /tmp/papirus-folders-install.sh

sed -n '1,240p' /tmp/papirus-folders-install.sh

env PREFIX="$HOME/.local" TAG="v1.14.0" \
    sh /tmp/papirus-folders-install.sh
```

La instalación local añade el ejecutable bajo:

```text
~/.local/bin/papirus-folders
```

No instala el tema ni modifica `/usr` durante esa fase. El script queda fijado a `v1.14.0` para evitar depender de `master`.

### Aplicar carpetas violetas

Listar estado y colores admitidos:

```fish
papirus-folders -l --theme Papirus-Dark
```

Aplicar el color validado:

```fish
papirus-folders -C violet --theme Papirus-Dark
```

El cambio modifica enlaces del tema instalado en `/usr/share/icons/Papirus-Dark`, por lo que puede solicitar privilegios administrativos.

Restaurar el color después de una actualización de Papirus:

```fish
papirus-folders -Ru
```

Volver al color predeterminado:

```fish
papirus-folders -D --theme Papirus-Dark
```

## Hallazgos y decisiones técnicas

### Noctalia no administra el tema de iconos

`~/.local/state/noctalia/settings.toml` administra barra, dock, shell, widgets, wallpaper y paleta, pero no define `icon_theme`.

No debe añadirse una clave inventada ni editarse el archivo esperando que controle Qt. Noctalia consume el tema de la plataforma al iniciar.

### gsettings no sustituye la configuración Qt

`gsettings` aplicó correctamente `Papirus-Dark`, pero el cambio inicial no alcanzó Noctalia ni las aplicaciones Qt porque la sesión no tenía proveedor Qt.

Nest debe comprobar ambos backends y nunca presentar un cambio GTK como si fuera un cambio global completo.

### hyprland-qt-support no es hyprqt6engine

El paquete disponible durante la validación era:

```text
hyprland-qt-support 0.1.0
```

Ese paquete contiene un proveedor de estilos QML para aplicaciones Hyprland. No contiene un plugin `QT_QPA_PLATFORMTHEME` ni una opción `icon_theme`, por lo que no resuelve esta necesidad.

La documentación futura de Hyprland describe `hyprqt6engine` como reemplazo de `qt6ct`, con soporte para:

```text
QT_QPA_PLATFORMTHEME=hyprqt6engine
theme:icon_theme = Papirus-Dark
```

No estaba disponible en los repositorios habilitados durante la validación. Nest debe tratarlo como proveedor futuro y migrar solo después de detectar el paquete y comprobar su comportamiento real.

### El color de carpetas es reparable, no permanente por paquete

`papirus-folders` cambia enlaces pertenecientes al contenido instalado de Papirus. Una actualización de `papirus-icon-theme` puede restaurar los enlaces originales.

Nest debe registrar `violet` como estado deseado y ofrecer reparación idempotente, no asumir que una aplicación única será permanente.

## Diseño propuesto para Nest

### Responsabilidad del módulo

Nombre conceptual:

```text
Appearance / System Icons
```

No debe pertenecer al adaptador de Noctalia. Debe ser una capacidad del Core consumida por cualquier shell o interfaz.

Responsabilidades:

- descubrir temas instalados;
- instalar dependencias desde repositorios oficiales;
- seleccionar tema GTK;
- seleccionar tema Qt mediante un proveedor;
- declarar variables de entorno antes de iniciar la shell;
- aplicar una variante de carpetas;
- verificar el estado efectivo;
- reparar cambios después de actualizaciones;
- respaldar y revertir archivos administrados;
- exponer estado a TUI, GUI o CLI.

### Manifiesto declarativo propuesto

Ruta conceptual:

```text
~/.config/nest/appearance/icons.toml
```

Ejemplo:

```toml
schema_version = 1

[icons]
theme = "Papirus-Dark"
fallback = "Adwaita"

[icons.gtk]
enabled = true
backend = "gsettings"

[icons.qt]
enabled = true
provider = "qt6ct"
style = "Fusion"

[icons.folders]
enabled = true
provider = "papirus-folders"
color = "violet"
version = "v1.14.0"
repair_after_package_update = true
```

El manifiesto expresa intención. No debe convertirse en una copia de archivos de proveedor.

### Adaptadores propuestos

```text
Nest
└── appearance/
    ├── manifest
    ├── service
    ├── diagnostics
    └── adapters/
        ├── freedesktop-icons
        ├── gtk-gsettings
        ├── qt6ct
        ├── hyprqt6engine
        ├── hyprland-environment
        └── papirus-folders
```

Contratos mínimos:

```text
detect()
plan(desired_state)
apply()
verify()
repair()
rollback()
```

Cada adaptador debe informar:

- estado actual;
- estado deseado;
- acciones necesarias;
- archivos afectados;
- necesidad de privilegios;
- si requiere reinicio de aplicación o sesión;
- método de rollback.

### Flujo de aplicación

```text
leer manifiesto
→ detectar paquetes y temas disponibles
→ detectar proveedor Qt activo
→ mostrar plan
→ respaldar archivos personales
→ instalar dependencias oficiales
→ aplicar GTK
→ aplicar Qt sin sobrescribir otras claves
→ registrar entorno mediante Shell Adapter
→ aplicar color de carpetas
→ reiniciar solo componentes necesarios
→ verificar estado efectivo
→ guardar resultado y rollback
```

### Archivos que Nest puede administrar

```text
~/.config/qt6ct/qt6ct.conf
~/.config/nest/appearance/icons.toml
fragmento de entorno administrado por Nest para Hyprland
estado y backups bajo ~/.local/state/nest/
```

Nest debe editar solo las claves que posee. Debe conservar estilo, fuente, esquema de color y ajustes ajenos en `qt6ct.conf`.

La integración con Hyprland no debe depender para siempre de insertar líneas en un archivo monolítico autogenerado. El Shell Adapter deberá proporcionar un fragmento administrado y garantizar que se cargue antes del autostart de Noctalia.

### Dependencias y política de instalación

Paquetes oficiales:

```text
papirus-icon-theme
qt6ct
```

Utilidad externa validada:

```text
papirus-folders v1.14.0
```

Nest no debe ejecutar `curl | sh`. Opciones aceptables para una primera versión:

1. descargar una versión fijada;
2. verificar URL, versión y checksum;
3. instalar bajo una ruta administrada por Nest;
4. registrar licencia y origen;
5. permitir desinstalación y actualización explícitas.

Antes de redistribuir el script dentro del repositorio debe revisarse su licencia MIT y conservarse atribución. La documentación no autoriza automáticamente a copiar código de terceros.

### Reparación post-update

El System Doctor deberá detectar:

- `papirus-icon-theme` ausente;
- tema deseado no encontrado;
- `gsettings` diferente del manifiesto;
- `icon_theme` ausente o distinto en `qt6ct.conf`;
- proveedor Qt no exportado;
- Noctalia iniciada sin el proveedor esperado;
- color Papirus restaurado por una actualización;
- herramienta `papirus-folders` ausente o de versión inesperada.

Acción de reparación:

```text
diagnosticar
→ mostrar diferencias
→ reaplicar solo capas desviadas
→ ejecutar papirus-folders -Ru cuando corresponda
→ verificar
→ registrar resultado
```

Un hook automático de pacman no debe ser la primera implementación porque el color es una preferencia del usuario y los hooks se ejecutan como root. La primera versión debe usar diagnóstico/reparación explícita; una automatización posterior deberá conservar contexto de usuario y consentimiento.

### Interfaz futura

La interfaz de Nest podrá presentar:

- selector visual de tema;
- variantes clara y oscura;
- selector de color de carpetas;
- vista previa;
- alcance GTK, Qt o ambos;
- proveedor Qt activo;
- botón **Aplicar**;
- botón **Verificar**;
- botón **Reparar**;
- botón **Restaurar**;
- aviso cuando sea necesario cerrar sesión.

La interfaz no ejecutará comandos directamente. Consumirá el servicio del Core y mostrará su plan y resultado estructurados.

## Verificación consolidada

```fish
printf 'Qt: '
printenv QT_QPA_PLATFORMTHEME

printf 'GTK: '
gsettings get org.gnome.desktop.interface icon-theme

printf 'Papirus: '
grep '^icon_theme=' ~/.config/qt6ct/qt6ct.conf

printf 'Carpetas: '
papirus-folders -l --theme Papirus-Dark
```

Estado esperado:

```text
Qt: qt6ct
GTK: 'Papirus-Dark'
Papirus: icon_theme=Papirus-Dark
Carpetas: violet
```

También se debe validar visualmente una aplicación GTK, una aplicación Qt y el launcher de la shell después de una nueva sesión.

## Rollback

Rollback parcial de carpetas:

```fish
papirus-folders -D --theme Papirus-Dark
```

Rollback de GTK:

```fish
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
```

Rollback de Qt:

- restaurar el backup de `~/.config/qt6ct/qt6ct.conf`;
- o seleccionar `Adwaita` desde qt6ct;
- retirar `QT_QPA_PLATFORMTHEME=qt6ct` solo si ya no se desea usar ese proveedor.

Desinstalación de la utilidad local:

```fish
env PREFIX="$HOME/.local" uninstall=true \
    sh /tmp/papirus-folders-install.sh
```

Los paquetes oficiales solo deben retirarse tras comprobar que ninguna otra aplicación los requiere.

## Pendientes

- validar la persistencia completa después de una nueva sesión de Hyprland;
- calcular y registrar checksum del instalador fijado de Papirus Folders;
- decidir la ruta canónica del fragmento de entorno administrado por Nest;
- implementar parser INI que preserve claves ajenas de qt6ct;
- diseñar el formato común de resultados de los adaptadores;
- integrar reparación de carpetas en System Doctor;
- evaluar `hyprqt6engine` cuando esté disponible en repositorios;
- comprobar el comportamiento al alternar temas claros y oscuros;
- definir si Nest ofrecerá Papirus como predeterminado o como perfil visual instalable.

## Regla operativa

```text
diagnóstico
→ elección explícita
→ respaldo
→ dependencias oficiales
→ configuración GTK
→ configuración Qt
→ entorno antes de la shell
→ variante de carpetas
→ nueva sesión cuando corresponda
→ verificación cruzada
→ documentación y rollback
```

Nest debe convertir una secuencia manual de conocimiento experto en una operación clara y segura, sin ocultar qué capas cambia ni apropiarse de archivos administrados por Noctalia o por los paquetes del sistema.
