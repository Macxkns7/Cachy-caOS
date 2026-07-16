# Nest — metodología operativa

Fecha de consolidación: 2026-07-16

## Flujo principal

```text
Entender → Validar → Instalar → Diagnosticar → Documentar → Automatizar
```

Este orden evita convertir suposiciones en código y reduce el riesgo de que Nest automatice procedimientos incompletos.

## Reglas de trabajo

### Diagnóstico antes de solución

Las comprobaciones previas deben aparecer antes de cualquier comando que modifique el sistema. No se debe entregar primero una acción peligrosa y advertir después que todavía no debía ejecutarse.

### Compatibilidad con el shell real

Cachy-caOS utiliza Fish como shell interactivo principal. Las instrucciones deben comprobar compatibilidad antes de usar sintaxis propia de Bash, especialmente:

- asignaciones `VAR=value`;
- heredocs `<<EOF`;
- sustituciones y bucles;
- operadores condicionales.

Nest debería detectar Fish, Bash o Zsh y ejecutar internamente acciones estructuradas, evitando depender de fragmentos copiados por el usuario.

### Seguridad y recuperación

Antes de cambios críticos:

- crear o confirmar snapshot;
- respaldar archivos afectados;
- preparar una ruta de recuperación;
- verificar una TTY disponible cuando se modifica el login gráfico;
- no retirar la alternativa anterior hasta validar la nueva.

### Separar instalación y activación

Para componentes críticos se distinguen dos fases:

1. **Instalar y verificar** binarios, assets, configuración, dependencias y logs.
2. **Activar** el componente cuando la primera fase ya fue validada.

Esto permite que Nest instale una integración sin sustituir inmediatamente el componente activo.

### Upstream primero

Orden preferido:

1. repositorios oficiales;
2. proyecto Git oficial;
3. AUR u otros empaquetados comunitarios cuando aporten valor real.

No se crea un fork solo por branding o comodidad. Primero se intenta integrar el proyecto original y contribuir upstream cuando se detectan defectos generales.

### Evidencia antes que intuición

Las hipótesis se deben marcar como tales. Para confirmar un diagnóstico se utilizan:

- estado de servicios;
- archivos reales instalados;
- propietario de paquetes;
- clases/app IDs de ventanas;
- logs;
- configuración persistente;
- comportamiento reproducible.

## Forma futura de Nest Doctor

Cada diagnóstico debería reportar:

```text
✓ requisito cumplido
⚠ condición incompleta o riesgosa
✗ fallo confirmado
→ acción recomendada
```

Además debe distinguir entre:

- problema del sistema;
- problema de configuración;
- limitación de una integración;
- bug probable de upstream.

## Auditoría y documentación

Cada sesión importante debe dejar:

- decisión tomada;
- motivo;
- comandos o cambios aplicados;
- pruebas realizadas;
- errores encontrados;
- método de recuperación;
- implicaciones para la arquitectura de Nest.

La documentación no debe ser un changelog infinito. Debe separar el contexto histórico, las decisiones vigentes y los procedimientos reproducibles.