---
name: sdd
description: Úsala siempre que trabajes con Spec-Driven Development en DevForge (docs/constitution.md o cualquier archivo en specs/) - redactar, revisar o cambiar specs, planes y tareas, o implementar y validar una tarea de una spec.
---

# Spec-Driven Development en DevForge

## Flujo
Constitución → Spec → Clarificación → Plan → Tareas → Implementación → Validación → Cambio.

- Nunca pases a la siguiente fase sin la aprobación explícita de Carlos.
- La spec manda: si algo no está en la spec, no se implementa. Si falta una decisión, para y pregunta.
- Un cambio de requisitos va primero a la spec, luego al plan y las tareas, y por último al código.
- Cada spec vive en `specs/NNN-nombre/` con `spec.md`, `plan.md` y `tasks.md`. NNN = siguiente número libre (el ID del módulo coincide: spec 002 = DEVFORGE-002).
- Al terminar cada fase, actualiza `MEMORY.md`.

## Plantilla de spec (spec.md)
```
# Spec NNN — <Nombre>

Estado: borrador | aprobada | implementada

## Contexto y objetivo
## Usuarios
## Historias de usuario
- HU-1. Como <rol>, quiero <acción> para <beneficio>.
## Definiciones (solo si hay términos ambiguos)
## Requisitos funcionales
## Requisitos no funcionales
## Casos límite
## Fuera de alcance
## Criterios de finalización
## Dudas abiertas
- [NECESITA ACLARACIÓN] <duda>
```
La spec describe el QUÉ y el POR QUÉ. Nada de nombres de funciones ni archivos.

## Requisitos en EARS (en español)
- RF-x: CUANDO <evento>, EL SISTEMA <respuesta>.
- RF-x: SI <condición no deseada>, ENTONCES EL SISTEMA <respuesta>.
- RF-x: MIENTRAS <estado>, EL SISTEMA <respuesta>.
- RF-x: EL SISTEMA <comportamiento permanente>.

Cada RF debe ser verificable: nada de "rápido" o "profesional" sin un criterio medible.

## Plan (plan.md)
Archivos y responsabilidad de cada uno · Funciones (verbo aprobado + `DevForge`) · Qué objetos devuelven (contrato `ToolCheck` u otro) · Algoritmo en pseudocódigo · Decisiones justificadas con su alternativa descartada · Estrategia de tests con Pester 5.5+. Indica qué RF cubre cada parte.

## Tareas (tasks.md)
```
- [ ] **Tn. <Descripción>.** RF-x, RF-y
  - Hecho cuando: <comprobación verificable>.
```
Máximo 20-30 min por tarea, en orden de dependencia. Si salen más de 10, propón dividir la spec.

## Implementación
Una sola tarea cada vez: primero el test en `tests/` (en rojo), después el código, `Invoke-Pester ./tests` en verde, marcar la tarea y parar.

## Validación
Recorre la spec RF por RF: qué test lo cubre y su resultado. Lo que no se pueda testear (salida en consola, no modificar el sistema), verifícalo ejecutando el script y dilo. Empieza con `VEREDICTO: APROBADO` o `VEREDICTO: CAMBIOS NECESARIOS`.
