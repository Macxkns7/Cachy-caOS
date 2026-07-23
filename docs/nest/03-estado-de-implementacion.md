# Estado de implementación de Nest

**Estado:** En desarrollo  
**Última revisión:** 2026-07-23

## Propósito

Registrar qué partes de Nest existen hoy, qué decisiones ya están validadas y qué trabajo sigue abierto. Este documento conecta la arquitectura teórica con la implementación real.

## Estado general

Nest se encuentra en una etapa temprana de construcción, pero ya dejó de ser una idea abstracta. Existe una base funcional en terminal, módulos propios, código fuente versionado y una dirección arquitectónica definida.

## Componentes existentes

### Nest Core y lanzador

- Estructura separada entre `core/` y `modules/`.
- Lanzador principal mediante `app.sh`.
- Interfaz terminal construida con Bash y `gum`.
- Ejecución integrada con Kitty.
- Acceso desde un archivo `.desktop`.
- Identidad de ventana propia mediante la clase `nest-ui`.
- Icono instalado y administrado por Nest desde `~/.local/share/cachycaos/assets/icons/nest-ui.png`.
- Nombre y descripción pública: **Nest UI — Centro de administración de Cachy-caOS**.

### Módulos funcionales

- WebApps.
- Keybinds.

Ambos módulos han sido probados de forma independiente y desde el lanzador principal.

### Keybinds v0.4

Estado: **ciclo administrado y migración masiva implementados; migración real
del lote pendiente de validación final**.

Capacidades confirmadas:

- inventario runtime con fallback ante el JSON inválido de Hyprland 0.56;
- atribución a archivo y línea fuente;
- manifiesto TOML persistente y archivo Lua administrado separado;
- edición visual e importación individual como borrador;
- piloto real `SUPER + Q` migrado sin cambiar su comportamiento;
- importación masiva transaccional con vista previa e IDs deterministas;
- activación atómica del lote y bloqueo global de conflictos externos;
- generación validada de los doce tipos de acción usados en el sistema;
- respaldo, diff, recarga, verificación y rollback automático.

La siguiente validación operativa migrará los 53 atajos personales restantes y
los probará por categorías antes de incorporar nuevas combinaciones.

Fuente: `docs/modulos/keybinds.md`.

### Organización del launcher

Estado: **prototipo funcional y validado en el sistema real**.

Capacidades confirmadas:

- clasificación en General, Avanzado y Oculto sin desinstalar paquetes;
- siete entradas auxiliares ocultas mediante overrides XDG locales;
- doce herramientas técnicas retiradas del proveedor general;
- plugin local `nest/advanced` v0.2.0 compatible con la Plugin API 4 de Noctalia;
- proveedor `/adv` con iconos, descripciones, búsqueda difusa y ejecución gráfica o en terminal;
- integración de File Roller con Nemo conservada después de ocultar su acceso directo;
- cero archivos de paquetes o del núcleo de Noctalia modificados.

La prueba valida el futuro contrato Launcher Policy + Launcher Adapter. La política pertenece al Core; `/adv` es solamente su materialización para la shell actual.

Fuente: `docs/modulos/organizacion-launcher.md`.

### Perfil de audio y futuro Nest Audio

Estado: **configuración funcional y validada; automatización pendiente**.

Capacidades confirmadas en el sistema real:

- PipeWire, WirePlumber y EasyEffects operativos;
- presets v1 y v2 exportados y versionados;
- perfil `NEST-Lenovo-13sG2-HK-v2` validado mediante pruebas A/B;
- cadena ecualizador de 32 bandas → limitador LSP;
- perfil explícitamente limitado a los parlantes integrados del Lenovo;
- referencia neutral y rollback conservados;
- repetición descontrolada de volumen resuelta en el módulo Keybinds.

La prueba valida un futuro contrato Audio Profiles + EasyEffects Adapter. Nest deberá detectar dispositivos, desplegar presets, asociarlos de forma explícita y permitir bypass, verificación y rollback sin reimplementar procesamiento DSP.

Fuente: `docs/modulos/audio-easyeffects.md`.

### Fastfetch e identidad de terminal

Estado: **prototipo visual funcional y validado; automatización pendiente**.

Capacidades confirmadas en el sistema real:

- configuración compacta válida en Kitty completa y dividida;
- dos gatos ASCII apilados como preset personal de Manuel;
- selección reducida de módulos útiles para diagnóstico cotidiano;
- claves y valores alineados sin sacrificar el ancho compacto;
- identidad `Fastfetch : N.E.S.T. Kitty’s Edition`;
- preset y arte ASCII incorporados al repositorio como ejemplo reproducible.

La prueba valida un futuro contrato Terminal Identity + Fastfetch Adapter. N.E.S.T. podrá previsualizar presets incorporados, seleccionar arte local, importar texto desde URL con validación y preservar o restaurar la configuración previa.

Fuente: `docs/modulos/fastfetch-personalizable.md`.

### WebApps v0.6 Beta

Estado: **funcional y validado en el sistema real**.

Capacidades confirmadas:

- creación, listado y eliminación de WebApps;
- generación automática de `StartupWMClass` para Vivaldi;
- agrupación correcta entre acceso fijado y ventana Wayland;
- nuevo comando `cachycaos-webapp repair`;
- migración de Desktop Entries antiguas;
- reparación idempotente sin duplicar claves;
- actualización de la base XDG;
- recarga opcional del dock de Noctalia.

Código fuente canónico:

```text
src/bin/cachycaos-webapp
src/modules/webapps/app.sh
```

## Estructura observada en el sistema de desarrollo

```text
~/.local/share/cachycaos/
├── app.sh
├── assets/
│   └── icons/
│       └── nest-ui.png
├── core/
│   └── nest/
├── modules/
│   ├── webapps/
│   └── keybinds/
└── backups/
```

La estructura local todavía puede evolucionar antes de convertirse en un layout de instalación definitivo.

## Estructura inicial del código fuente

```text
src/
├── applications/
│   └── nest-ui.desktop.in
├── assets/
│   └── icons/
│       └── README.md
├── bin/
│   └── cachycaos-webapp
└── modules/
    └── webapps/
        └── app.sh
```

La ubicación canónica reservada para el binario del icono es `src/assets/icons/nest-ui.png`. Su importación al repositorio continúa pendiente; el archivo actualmente validado reside en el sistema de desarrollo.

El instalador futuro será responsable de transformar el árbol `src/` en las rutas XDG del usuario y de sustituir los marcadores de las plantillas por rutas absolutas.

## Decisiones firmes

- Nest no será una shell.
- El Core no dependerá de Noctalia ni de otra shell concreta.
- Las interfaces deben consumir capacidades del Core, no contener la lógica crítica.
- Los módulos deben ser independientes y reemplazables.
- La configuración del usuario debe preservarse.
- Toda operación sensible debe tener diagnóstico, respaldo y recuperación.
- Los módulos deben poder reparar y migrar recursos creados por versiones anteriores.
- Los recursos visuales propios deben vivir bajo el árbol administrado por Nest.
- Las Desktop Entries generadas deben usar rutas absolutas para assets propios cuando la resolución por tema no sea fiable.
- Fish es el shell interactivo principal del sistema; los comandos mostrados al usuario deben ser compatibles con Fish o indicar explícitamente otro intérprete.
- El tema de iconos es una capacidad transversal del Core y se implementará mediante adaptadores GTK, Qt, entorno y variantes de carpetas.
- Los adaptadores deben modificar únicamente claves propias, preservar configuración ajena y ofrecer `detect`, `plan`, `apply`, `verify`, `repair` y `rollback`.
- La visibilidad del launcher es una política separada de la instalación de paquetes y debe usar Desktop IDs estables.
- Los overrides completos de Desktop Entries deben detectar deriva y sincronizarse después de actualizaciones sin destruir cambios ajenos.
- System Doctor deberá complementar pacman con auditoría ELF para detectar consumidores runtime instalados manualmente.

## Estado de Nest UI

La interfaz actual es una TUI temprana. Cumple el propósito de validar navegación, módulos y organización, pero todavía no representa la interfaz gráfica final.

La v0.4 debe consolidar:

- navegación principal;
- contratos entre Core y módulos;
- rutas canónicas;
- detección de dependencias;
- manejo de errores;
- estado y salida consistente;
- documentación de instalación y actualización.

## Acceso desde el escritorio

La ventana de Nest usa una clase propia de Kitty:

```text
class = nest-ui
title = Nest UI
```

La Desktop Entry validada usa:

```ini
Exec=kitty --class nest-ui --title "Nest UI" -e /home/<usuario>/.local/share/cachycaos/app.sh
Icon=/home/<usuario>/.local/share/cachycaos/assets/icons/nest-ui.png
StartupWMClass=nest-ui
```

La combinación fue comprobada en el sistema real: el icono aparece correctamente tanto en el launcher como en el dock de Noctalia.

## Riesgos abiertos

- Las rutas locales aún arrastran restos de reorganizaciones previas.
- No existe todavía un instalador reproducible que despliegue binarios, assets y archivos `.desktop`.
- El binario maestro `src/assets/icons/nest-ui.png` aún debe importarse desde el sistema de desarrollo.
- El estado de versión aún no está centralizado.
- Falta una interfaz estable entre los módulos y el Core.
- WebApps todavía usa una convención específica de Vivaldi para calcular la identidad Wayland.
- El prototipo `nest/advanced` y su manifiesto de clasificación aún no forman parte del árbol canónico de código.
- Los overrides locales del launcher requieren un reconciliador post-update antes de poder administrarse automáticamente.

## Hallazgo de limpieza y dependencias runtime

La limpieza validada retiró 92 paquetes netos y consolidó Nemo, mpv y greetd. Durante el proceso se comprobó que `pacman Required By` no cubre binarios instalados manualmente: `noctalia-greeter-compositor` dependía de `libwlroots-0.20.so`, aunque wlroots aparecía sin dependientes.

`wlroots0.20` y `libliftoff` fueron restaurados antes del reinicio. Este caso define una nueva capacidad obligatoria para System Doctor: inventario de ELF no empaquetados, resolución de bibliotecas y verificación posterior a eliminaciones.

Fuente: `docs/modulos/limpieza-sistema.md`.

## Problemas cerrados recientemente

### Identidad e iconos de WebApps en Noctalia

**Estado:** Resuelto en WebApps v0.6.

La causa era la ausencia de `StartupWMClass` en las Desktop Entries. Noctalia no podía asociar las clases `vivaldi-<hostname>__-Default` con los IDs `cachycaos-webapp-*`, por lo que mostraba una segunda instancia con icono genérico.

La solución quedó generalizada en el generador y en el motor de reparación; no se mantiene como un parche específico para ChatGPT o YouTube.

### Icono genérico de Nest UI

**Estado:** Resuelto y validado en el sistema de desarrollo.

La clase de ventana y `StartupWMClass` ya coincidían correctamente como `nest-ui`. El engranaje persistía porque `Icon=nest-ui` dependía de la resolución del tema `hicolor` y de sus cachés.

La solución validada fue mover el icono al árbol administrado por Nest y utilizar su ruta absoluta en la Desktop Entry:

```text
~/.local/share/cachycaos/assets/icons/nest-ui.png
```

Esto eliminó el icono genérico tanto en el launcher como en el dock de Noctalia. La plantilla y el contrato de instalación ya están versionados; solo falta importar el PNG maestro al árbol `src/assets/icons/`.

## Próximos hitos

1. Diseñar el manifiesto de perfiles por dispositivo y contrato EasyEffects Adapter para Nest Audio.\n2. Diseñar el manifiesto de Terminal Identity y el adaptador de Fastfetch a partir de Kitty’s Edition.
3. Diseñar el contrato de auditoría ELF y dependencias runtime para System Doctor.
4. Diseñar el manifiesto y contrato de `Appearance / System Icons` a partir del procedimiento Papirus validado.
5. Diseñar el manifiesto, reconciliador XDG y contrato Launcher Policy + Launcher Adapter.
6. Incorporar el proveedor `nest/advanced` al árbol canónico después de estabilizar su instalación y rollback.
7. Importar el PNG maestro de Nest en `src/assets/icons/nest-ui.png`.
8. Cerrar la v0.4 de la TUI.
9. Normalizar estructura y rutas.
10. Definir contratos de módulos.
11. Crear diagnóstico común.
12. Diseñar instalador y actualizador para desplegar `src/`.
13. Incorporar el módulo Keybinds al árbol de código fuente.
14. Diseñar adaptadores de identidad para otros navegadores.
15. Iniciar una interfaz gráfica sin acoplarla a la shell.

## Regla de actualización

Este documento debe actualizarse cada vez que una versión cambie la estructura, incorpore un módulo funcional o convierta una decisión experimental en una decisión firme.
