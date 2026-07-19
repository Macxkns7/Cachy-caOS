# Krita en Wayland nativo

**Estado:** Vigente y validado  
**Última revisión:** 2026-07-19

## Objetivo

Documentar el diagnóstico y la solución aplicada para ejecutar Krita con el backend Wayland nativo en Cachy-caOS, evitando el desenfoque provocado por XWayland bajo escalado.

## Entorno validado

- Sistema: CachyOS.
- Compositor: Hyprland 0.55.4.
- Sesión: Wayland.
- Shell: Noctalia v5.
- Krita: `6.0.2.1-2.1`.
- Repositorio: `cachyos-extra-v4`.
- Arquitectura del paquete: `x86_64_v4`.
- Qt: Qt 6.

## Síntoma

Krita abría correctamente, pero toda la interfaz se veía ligeramente borrosa:

- texto lavado o poco definido;
- iconos y líneas finas con pérdida de nitidez;
- pantalla de carga afectada antes de abrir la ventana principal;
- tamaño general de la interfaz aparentemente correcto.

El síntoma no estaba limitado al lienzo: afectaba a la aplicación completa.

## Diagnóstico

Se comprobó primero que la sesión gráfica era Wayland y que no existían variables globales de Qt alterando el entorno.

```fish
echo $XDG_SESSION_TYPE
env | grep QT
```

Resultado relevante:

```text
wayland
```

La prueba decisiva fue iniciar Krita forzando el plugin QPA de Wayland:

```fish
QT_QPA_PLATFORM=wayland krita
```

La interfaz pasó inmediatamente a verse nítida y con el renderizado esperado. Esto confirmó que el paquete no estaba roto y que la causa era el uso del backend X11/XWayland en el lanzamiento normal.

## Solución aplicada

No se modificó el archivo del sistema en `/usr/share/applications/`. Se creó una copia local para el usuario:

```fish
mkdir -p ~/.local/share/applications
cp /usr/share/applications/org.kde.krita.desktop \
   ~/.local/share/applications/
```

Archivo modificado:

```text
~/.local/share/applications/org.kde.krita.desktop
```

La línea de lanzamiento se cambió desde:

```ini
Exec=krita %F
```

hacia:

```ini
Exec=env QT_QPA_PLATFORM=wayland krita %F
```

Después se actualizó la base de datos local de aplicaciones:

```fish
update-desktop-database ~/.local/share/applications
```

## Validación

Krita fue abierto desde el launcher habitual y se comprobó que:

- inicia sin necesidad de usar un comando manual;
- la interfaz se renderiza de forma nítida;
- la solución sobrevive a actualizaciones del paquete porque el override vive en el directorio XDG del usuario;
- no fue necesario reemplazar el paquete de CachyOS por AppImage o Flatpak.

## Recuperación

Para volver al lanzador del sistema basta con eliminar el override local y actualizar la base de datos:

```fish
rm ~/.local/share/applications/org.kde.krita.desktop
update-desktop-database ~/.local/share/applications
```

## Aprendizajes para Nest

### 1. Compatibilidad Wayland como capacidad administrable

Nest debería poder detectar aplicaciones que se ejecutan mediante XWayland y ofrecer overrides locales cuando el backend Wayland nativo esté disponible y validado.

### 2. No modificar Desktop Entries del sistema

Los ajustes deben implementarse mediante copias en:

```text
~/.local/share/applications/
```

Esto evita conflictos con `pacman`, conserva una ruta de recuperación sencilla y permite auditar exactamente qué cambió Nest.

### 3. Separar instalación de compatibilidad

El módulo de instalación de una aplicación no debería contener directamente todos sus ajustes gráficos. Nest debería separar:

- instalación y desinstalación;
- asociaciones MIME;
- overrides de lanzamiento;
- variables de entorno por aplicación;
- validación de backend Wayland/XWayland.

### 4. Flujo propuesto

```text
Detectar aplicación
→ localizar Desktop Entry efectiva
→ respaldar override anterior si existe
→ comprobar backend actual
→ aplicar cambio mínimo
→ actualizar base XDG
→ relanzar y verificar
→ ofrecer rollback
```

### 5. Futuro módulo de compatibilidad

Una futura sección de Nest podría mostrar:

```text
Compatibilidad Wayland
├── Krita: Wayland nativo validado
├── Backend actual
├── Override local activo
├── Probar lanzamiento
└── Restaurar configuración original
```

La solución debe ser declarativa, idempotente y específica por aplicación. No se recomienda exportar globalmente `QT_QPA_PLATFORM=wayland`, porque otras aplicaciones Qt pueden necesitar un backend diferente o presentar incompatibilidades propias.

## Regla resultante

> Las variables de compatibilidad gráfica deben aplicarse por aplicación y solo después de una prueba comparativa validada.
