# Herramientas con objetivos similares o adyacentes a Nest

**Estado:** Research vigente  
**Última revisión:** 2026-07-16

## Pregunta de investigación

¿Qué proyectos existentes resuelven partes del problema que Nest quiere abordar y qué puede aprenderse de ellos sin convertir Nest en una copia?

## Conclusión principal

No se identificó una herramienta única que reúna toda la visión de Nest: administración modular del sistema, diagnóstico, recuperación, configuración del escritorio, módulos propios y adaptadores hacia shells reemplazables.

Sí existen familias de proyectos que resuelven partes del problema y sirven como referencias técnicas.

## Familias relevantes

### Centros de control de escritorios completos

GNOME Settings y KDE System Settings demuestran el valor de:

- categorías coherentes;
- backends separados de la interfaz;
- páginas de diagnóstico y estado;
- integración de servicios mediante APIs estables.

Nest debe aprender de su organización, pero no asumir un escritorio monolítico ni depender de tecnologías GNOME/KDE.

### Herramientas declarativas de configuración

NixOS, Home Manager y proyectos de dotfiles declarativos muestran:

- reproducibilidad;
- composición de módulos;
- separación entre estado deseado y estado actual;
- rollback y generaciones.

Nest no necesita adoptar Nix como base para beneficiarse de esos principios. Puede mantener manifiestos propios y operaciones idempotentes sobre CachyOS/Arch.

### Gestores de dotfiles

chezmoi, GNU Stow y yadm aportan ideas sobre:

- plantillas;
- diferencias por equipo;
- seguimiento de archivos;
- secretos y datos locales;
- aplicación repetible.

Nest debe evitar ser solamente un gestor de dotfiles: su alcance incluye servicios, paquetes, diagnósticos y migraciones.

### Herramientas de salud y mantenimiento

Los asistentes de actualizaciones, Snapper, Btrfs Assistant, systemd, pacman hooks y utilidades de diagnóstico enseñan a:

- observar antes de modificar;
- mantener logs;
- crear snapshots;
- mostrar impacto y recuperación;
- detectar cambios posteriores a actualizaciones.

Esta familia es especialmente relevante para Nest Doctor y el centro de revisión post-update.

### Shells y paneles para Wayland

Noctalia, Caelestia y proyectos basados en QuickShell muestran cómo construir experiencias visuales completas sobre un compositor.

Nest no debe competir directamente con ellos. Debe administrar sus configuraciones mediante adaptadores y permitir su reemplazo.

### Instaladores y capas de distribución

Omarchy, scripts de bootstrap y perfiles de distribuciones enseñan el valor de una instalación sencilla, pero también el riesgo de:

- esconder demasiado comportamiento;
- sobrescribir configuración personal;
- acoplar todo el sistema a una capa externa;
- dificultar la reconstrucción cuando upstream cambia.

Nest debe ofrecer comodidad sin sacrificar comprensión ni control.

## Capacidades que distinguen a Nest

- Core independiente de la shell.
- Operaciones reversibles y respaldadas.
- Diagnóstico integrado antes y después de cambios.
- Conocimiento específico de CachyOS, Arch, Hyprland y el entorno personal.
- Módulos propios como WebApps y Keybinds.
- Adaptadores hacia proyectos externos bien mantenidos.
- Documentación como parte del producto.
- Interfaz terminal y futura interfaz gráfica sobre el mismo Core.

## Estrategia de adopción

Para cada proyecto externo:

1. identificar el problema que resuelve;
2. estudiar su interfaz pública y formato de configuración;
3. adoptar upstream si es sólido;
4. crear un adaptador delgado;
5. mantener recuperación y diagnóstico propios;
6. considerar fork solo ante una necesidad concreta no aceptada upstream.

## Riesgo a evitar

El mayor riesgo es convertir Nest en una colección de wrappers sin modelo propio. Cada integración debe alimentar una arquitectura común de estado, acciones, validación, respaldo y recuperación.

## Dirección recomendada

Nest debe evolucionar como plataforma de orquestación local: menos interesada en reemplazar herramientas maduras y más enfocada en unirlas de forma comprensible, segura y coherente.
