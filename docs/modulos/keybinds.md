# Módulo Keybinds

**Estado:** En desarrollo y funcional  
**Última revisión:** 2026-07-16

## Propósito

Administrar atajos de Hyprland desde Nest sin convertir la configuración del usuario en un archivo opaco ni sobrescribir personalizaciones manuales.

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
- conservar comentarios y configuración no administrada;
- crear respaldo antes de escribir;
- recargar Hyprland únicamente tras una validación correcta;
- restaurar la versión previa si la recarga falla.

## Principio de propiedad

Nest no debe apropiarse de todo `hyprland.conf`.

La estrategia recomendada es mantener un archivo administrado y explícitamente incluido por la configuración principal, por ejemplo:

```text
~/.config/hypr/conf.d/nest-keybinds.conf
```

Así se separan:

- configuración personal;
- configuración de la shell;
- atajos administrados por Nest.

La ruta definitiva debe decidirse después de auditar la estructura limpia de Hyprland usada por Cachy-caOS.

## Flujo seguro propuesto

```text
leer → interpretar → detectar conflictos → mostrar cambios
→ respaldar → escribir temporal → validar → reemplazar → recargar
```

Nunca debe escribirse directamente sobre el archivo activo sin una etapa temporal y una copia recuperable.

## Consideraciones

- Hyprland permite múltiples archivos `source`; deben respetarse.
- Un mismo atajo puede estar declarado en distintos archivos.
- La shell puede registrar atajos propios.
- Las teclas físicas y layouts cambian entre equipos.
- El sistema principal usa teclado LATAM y Fish, pero los bindings pertenecen a Hyprland, no al shell interactivo.
- Las acciones deben almacenarse como datos cuando sea posible y no como fragmentos de texto difíciles de validar.

## Pendientes

- definir esquema interno de un keybind;
- normalizar modificadores y teclas;
- resolver colisiones y prioridades;
- distinguir atajos del usuario, de Nest y de la shell;
- exportar e importar perfiles;
- crear interfaz de búsqueda;
- integrar un diagnóstico antes de recargar Hyprland;
- documentar la v0.2 y los cambios posteriores desde los respaldos existentes.

## Criterio de finalización

El módulo estará listo cuando pueda realizar cambios reversibles sobre un archivo administrado, detectar conflictos globales y demostrar que una actualización de Noctalia o Hyprland no destruye los atajos personales.
