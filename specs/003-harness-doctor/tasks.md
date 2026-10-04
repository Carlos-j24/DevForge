# Tareas 003 — Doctor revisa el arnés de un proyecto

Spec: `spec.md` (aprobada) · Plan: `plan.md` (aprobado)

Regla: una tarea cada vez. Primero el test en `tests/Harness.Tests.ps1` (en rojo), después el código, `Invoke-Pester ./tests` en verde (pwsh y 5.1), marcar la tarea y parar. Si un test pasa a la primera, se comprueba metiendo un fallo a propósito.

- [x] **T1. Existencia de los archivos y caso OK.** RF-2, RF-3, RF-7, RF-12
  - Hecho cuando:
    - `Test-DevForgeHarness` devuelve tres checks HARNESS en orden (`harness-agents`, `harness-claude`, `harness-memory`), con `Required = $false`.
    - Un archivo que falta es WARNING, con `Installed = $false` y un mensaje que sugiere Init.
    - Un arnés completo y correcto da tres OK.
    - La foto del proyecto antes y después es idéntica.
- [x] **T2. Imports de CLAUDE.md.** RF-4
  - Hecho cuando:
    - Si a CLAUDE.md le falta `@AGENTS.md`, `@MEMORY.md` o los dos, es WARNING y el mensaje nombra cada import que falta.
    - Un import con espacios al final cuenta.
    - Un `@AGENTS.md` dentro de una frase no cuenta.
    - Un CLAUDE.md vacío es WARNING.
- [x] **T3. Líneas, marcadores y varios problemas.** RF-5, RF-6, RF-8
  - Hecho cuando:
    - AGENTS.md con 40 líneas es OK y con 41 es WARNING ("41 líneas (máximo 40)"); MEMORY.md igual con 50 y 51.
    - Los marcadores `[COMPLETAR]` se cuentan en el mensaje.
    - Un archivo con exceso de líneas y marcadores informa los dos problemas.
    - El salto de línea final, el BOM y CRLF no cambian el recuento.
    - Un archivo vacío es OK.
- [x] **T4. Ruta inválida.** RF-9
  - Hecho cuando: una ruta inexistente y una ruta que es un archivo devuelven un único check `harness-project` en ERROR, con `Required = $true` y un mensaje que explica el motivo.
- [x] **T5. Integración en Doctor.** RF-1, RF-10, RF-11, RF-13
  - Hecho cuando: en un proceso hijo,
    - `-Project <ruta> -Json` incluye los checks HARNESS, `version = "0.2.0"`, un resumen que cuadra con los checks y un código de salida que corresponde al estado global.
    - Un proyecto inexistente sale con 2.
    - Sin `-Project` no aparece ningún check HARNESS.
    - En consola aparece la sección "HARNESS (nombre)".
    - Funciona con una ruta con espacios y tildes.
    - Los 15 tests de Doctor siguen en verde sin cambios.
- [ ] **T6. Validación manual y documentación.** Criterios de finalización
  - Hecho cuando:
    - Doctor `-Project` se ejecutó a mano sobre DevForge y sobre MedAlert, en consola y con `-Json`, con pwsh y con 5.1.
    - AGENTS.md (comando), CHANGELOG.md, MEMORY.md y la spec 001 (nota sobre `-Project`) están actualizados.
    - `validation.md` tiene su veredicto.
    - El PR está abierto y el CI en verde.
