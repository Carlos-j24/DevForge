# AGENTS.md — DevForge
Ecosistema personal de desarrollo en PowerShell (scripts, IA, plantillas). Módulos: DevForge Doctor (DEVFORGE-001), que diagnostica el entorno sin instalar nada, y DevForge Init (DEVFORGE-002), que instala el arnés de IA en otros proyectos.

## Stack y estructura
- PowerShell 7+ (`pwsh`) en Windows. Sin dependencias externas en runtime.
- `scripts/core/` modelo `ToolCheck` y salida por consola · `scripts/doctor/` orquestador y checks.
- `scripts/init/` detección de stack, contenido y escritura del arnés · `templates/harness/` plantillas AGENTS/CLAUDE/MEMORY.
- `specs/NNN-nombre/` specs SDD · `docs/constitution.md` principios · `tests/` Pester 5.5+.

## Comandos
- Doctor: `pwsh -File scripts/doctor/Invoke-DevForgeDoctor.ps1` (`-Json` para JSON; `-Project <ruta>` revisa el arnés de un proyecto).
- Init: `pwsh -File scripts/init/Invoke-DevForgeInit.ps1 -Path <proyecto>` (`-WhatIf` para simular, `-Force` para sobrescribir).
- Tests: `pwsh -c "Invoke-Pester ./tests -Output Detailed"` (requiere Pester 5.5 o superior).

## Convenciones
- Funciones `Verbo-DevForgeNombre` con verbos aprobados (`Get-Verb`). Un archivo por responsabilidad.
- Código e identificadores en inglés; mensajes, docs y commits en español.
- Todo check devuelve un objeto de `New-DevForgeToolCheck`; nunca `Write-Host` dentro de un check.

## Reglas de dominio / trampas
- Doctor es de solo lectura: jamás instala, modifica ni borra nada del sistema.
- Códigos de salida: 0 OK, 1 WARNING, 2 ERROR. Son contrato público: no cambiarlos.
- En Windows `python` puede ser el alias de Microsoft Store: existir en PATH no garantiza Python real.
- Para crear carpetas usa `New-Item -ItemType Directory`; sin eso se crean archivos vacíos.
- Init nunca pisa archivos existentes sin `-Force` y solo escribe AGENTS.md, CLAUDE.md y MEMORY.md.

## Forma de trabajar
- Lee `docs/constitution.md`, `MEMORY.md` y la spec activa antes de tocar código.
- Cambios medianos o grandes: flujo SDD (skill `sdd`). Cambios pequeños: modo plan y aprobación.
- Al terminar: resume cambios, resultado de los tests y decisiones que deba revisar.

## Límites
- ✅ Siempre: tests en verde antes de dar algo por hecho; actualizar `MEMORY.md` y `CHANGELOG.md`.
- ⚠️ Pregunta antes: módulos nuevos de PowerShell Gallery, cambiar el esquema JSON o los códigos de salida.
- 🚫 Nunca: guardar claves o tokens en el repo; ejecutar instaladores; borrar archivos del usuario.

## Verificación
- `Invoke-Pester ./tests` en verde + ejecutar Doctor una vez en consola y otra con `-Json`.
- El CI (`.github/workflows/tests.yml`) corre Pester en pwsh y 5.1 en cada PR: no fusionar con el CI en rojo.
