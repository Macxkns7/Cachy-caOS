# Módulo Keybinds

**Estado:** En desarrollo y funcional  
**Última revisión:** 2026-07-16

## Propósito

Administrar atajos de Hyprland desde Nest sin convertir la configuración del usuario en un archivo opaco ni sobrescribir personalizaciones manuales.

El módulo también debe auditar que cada binding apunte a una acción realmente disponible y comprender cuándo esa acción pertenece a una shell integrada, a Hyprland o a una herramienta externa.

## Estado actual

Existe un módulo funcional bajo una estructura similar a:

```text
~/.local/share/cachycaos/modules/keybinds/app.sh
```

Durante el desarrollo también existieron rutas anteriores y respaldos de migración, entre ellas:

```text
~/.local/share/cachycaos/keybinds/app.sh
~/.local/share/cachycaos/backups/
~/.local/share/cachycaos/modules/keybinds/backups/
```

La coexistencia de estas rutas refleja la reorganización hacia una plataforma modular y debe resolverse en el instalador final.

## Objetivos funcionales

- listar atajos relevantes;
- añadir nuevos atajos;
- modificar atajos administrados;
- detectar colisiones;
- comprobar que la acción asociada existe;
- detectar teclas multimedia importantes sin binding;
- distinguir acciones de Hyprland, de una shell y de herramientas externas;
- conservar comentarios y configuración no administrada;
- crear respaldo antes de escribir;
- recargar Hyprland únicamente tras una validación correcta;
- restaurar la versión previa si la recarga falla.

## Principio de propiedad

Nest no debe apropiarse de todo `hyprland.conf` ni del archivo Lua principal.

La estrategia recomendada es mantener un archivo administrado y explícitamente incluido por la configuración principal, por ejemplo:

```text
~/.config/hypr/conf.d/nest-keybinds.conf
```

Así se separan:

- configuración personal;
- configuración de la shell;
- atajos administrados por Nest.

La ruta definitiva debe decidirse después de auditar la estructura limpia de Hyprland usada por Cachy-caOS y la forma correcta de integrar archivos declarativos con la configuración Lua actual.

## Modelo de acción

Un keybind no debe almacenarse solamente como texto. Debe representarse como datos verificables:

```text
id
tecla
modificadores
evento: press | release | repeat
acción lógica
proveedor preferido
comando resuelto
dependencias
origen: usuario | Nest | shell | sistema
perfil
estado de validación
```

Ejemplo conceptual:

```text
id: launcher
tecla: SUPER_L
evento: release
acción lógica: launcher.toggle
proveedor preferido: noctalia
comando resuelto: noctalia msg panel-toggle launcher
origen: Nest
perfil: Noctalia Standard
```

La acción lógica permite cambiar de proveedor sin rediseñar todo el perfil.

## Integración con shells

El módulo Keybinds registra las teclas en Hyprland. Los adaptadores de shell resuelven qué comando público ejecuta cada acción.

```text
Keybinds
→ acción lógica
→ adaptador de shell
→ comando público
```

Para Noctalia, la fuente canónica es:

```text
docs/integraciones/noctalia-v5.md
```

Ejemplo validado:

```text
Super al soltar
→ launcher.toggle
→ Noctalia Integration
→ noctalia msg panel-toggle launcher
```

Esta separación permite sustituir Noctalia por otra shell conservando la intención del atajo y cambiando solamente el proveedor.

## Auditoría y Nest Doctor

El diagnóstico debe distinguir al menos estos estados:

```text
✓ binding y acción disponibles
⚠ acción disponible, pero no existe binding
✗ binding presente, pero comando inexistente
✗ binding y comando presentes, pero falta una dependencia
⚠ colisión con otro binding
⚠ binding duplicado en archivos distintos
```

Casos reales observados en la instalación limpia:

```text
Brillo
- bindings XF86 presentes
- brightnessctl ausente
- reparación: instalar dependencia

Launcher
- SUPER+R apuntaba a hyprlauncher
- hyprlauncher ausente
- reparación: usar IPC de Noctalia
- mejora: añadir Super al soltar

Captura
- Print sin binding
- Noctalia expone acciones de captura
- backend y dependencias aún por validar
```

El diagnóstico no debe inventar el historial del sistema. Debe informar únicamente el estado comprobable: nunca instalado, actualmente ausente, reemplazado o disponible mediante otro proveedor solo cuando exista evidencia suficiente.

## Perfiles

Nest podrá ofrecer perfiles declarativos, revisables y reversibles.

Primer perfil propuesto:

```text
Noctalia Standard
```

Funciones iniciales:

```text
Super           → launcher
Print           → captura de región
Shift + Print   → captura completa
XF86Audio*      → audio y multimedia
XF86MonBrightness* → brillo
```

Los perfiles deben:

- mostrar el diff antes de aplicar;
- conservar atajos personalizados;
- detectar colisiones;
- permitir activar acciones individualmente;
- registrar qué adaptador resolvió cada comando;
- poder exportarse e importarse;
- poder revertirse.

## Flujo seguro propuesto

```text
leer → interpretar → resolver acciones → detectar conflictos
→ mostrar cambios → respaldar → escribir temporal
→ validar → reemplazar → recargar → comprobar
```

Nunca debe escribirse directamente sobre el archivo activo sin una etapa temporal y una copia recuperable.

## Consideraciones

- Hyprland permite múltiples archivos `source`; deben respetarse.
- Un mismo atajo puede estar declarado en distintos archivos.
- La shell puede exponer acciones, pero el binding pertenece al compositor.
- Las teclas físicas y layouts cambian entre equipos.
- El sistema principal usa teclado LATAM y Fish, pero los bindings pertenecen a Hyprland, no al shell interactivo.
- Los ejemplos operativos del proyecto deben ser compatibles con Fish o indicar explícitamente cuando requieren Bash.
- Las acciones deben almacenarse como datos cuando sea posible y no como fragmentos de texto difíciles de validar.
- Un comando disponible no garantiza que su backend o permisos estén operativos.

## Pendientes

- definir el esquema interno definitivo de un keybind;
- normalizar modificadores, teclas y eventos release/repeat;
- resolver colisiones y prioridades;
- distinguir atajos del usuario, de Nest y de la shell;
- implementar resolución por adaptadores;
- auditar todas las teclas multimedia de la instalación limpia;
- validar el backend de capturas de Noctalia;
- exportar e importar perfiles;
- crear interfaz de búsqueda;
- integrar el diagnóstico antes de recargar Hyprland;
- documentar la v0.2 y los cambios posteriores desde los respaldos existentes.

## Criterio de finalización

El módulo estará listo cuando pueda realizar cambios reversibles sobre un archivo administrado, detectar conflictos globales, verificar las acciones asociadas y demostrar que una actualización o sustitución de Noctalia o Hyprland no destruye los atajos personales ni obliga a reescribir los perfiles desde cero.