# Convenciones documentales

**Estado:** Vigente  
**Última revisión:** 2026-07-16

## Objetivo

Mantener la documentación de Cachy-caOS y Nest como un sistema confiable, navegable y alineado con el estado real del proyecto.

## Encabezado estándar

Todo documento canónico debe indicar:

```markdown
**Estado:** Vigente | En desarrollo | Histórico | Pendiente de reemplazo
**Última revisión:** AAAA-MM-DD
**Reemplaza a:** ruta opcional
**Relacionado con:** rutas opcionales
```

## Criterios de estado

### Vigente

Describe el sistema actual o una decisión oficialmente adoptada.

### En desarrollo

Representa una dirección aprobada, pero contiene etapas todavía incompletas o sujetas a validación.

### Histórico

Describe una etapa anterior. Debe conservarse, pero nunca presentarse como procedimiento actual.

### Pendiente de reemplazo

Contiene información parcialmente útil que aún no fue migrada a una fuente canónica.

## Estructura

- `docs/nest/`: visión, arquitectura, metodología y roadmap.
- `docs/integraciones/`: adopciones concretas de componentes externos.
- `docs/research/`: investigaciones, comparaciones e hipótesis.
- `docs/historico/`: etapas reemplazadas y decisiones antiguas.
- raíz de `docs/`: fuentes canónicas del sistema completo.

## Fuente única

Una decisión o procedimiento no debe mantenerse íntegramente en varios archivos. Se elige una fuente canónica y los demás documentos la enlazan.

## Qué documentar

- decisiones y motivos;
- procedimientos reproducibles;
- riesgos y rollback;
- dependencias y rutas;
- pruebas exitosas y fallidas que aporten conocimiento;
- estado final comprobado;
- pendientes concretos.

## Qué no documentar como fuente canónica

- conversación informal completa;
- hipótesis descartadas sin valor futuro;
- comandos no verificados;
- planes presentados como hechos;
- configuraciones antiguas mezcladas con las vigentes.

## Flujo de actualización

```text
Cambio real
  → verificar resultado
  → actualizar documento canónico
  → actualizar timeline si es un hito
  → archivar la versión reemplazada cuando aporte contexto
  → revisar enlaces e índice
```

## Regla de honestidad

La documentación debe distinguir explícitamente entre:

- comprobado;
- inferido;
- planificado;
- pendiente de validación.

Nunca debe sonar estable algo que todavía no fue probado.