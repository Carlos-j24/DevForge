# 📜 Changelog

Todos los cambios importantes de **DevForge** serán documentados en este archivo.

Este proyecto sigue el estándar **Keep a Changelog** y utiliza **Semantic Versioning**.

---

# [Unreleased]

---

# [0.2.0] - 2026-10-05

## 🤖 Arnés de IA

### Agregado

- DevForge Doctor 0.1.0 (DEVFORGE-001): modelo estándar `ToolCheck`; detección de Git, PowerShell, VS Code, Python, Node.js, Docker y Ollama; estados `OK`, `WARNING` y `ERROR`; estado global; reporte JSON con `-Json`; códigos de salida `0` OK, `1` WARNING, `2` ERROR.
- Arnés de IA: `AGENTS.md`, `CLAUDE.md`, `MEMORY.md`, `docs/constitution.md`, `specs/001-doctor/spec.md` y skill `sdd`.
- Tests Pester (5.5+) para Doctor (`tests/Doctor.Tests.ps1`).
- CI con GitHub Actions (`.github/workflows/tests.yml`): Pester en cada PR y push a `main`, en PowerShell 7 y 5.1.
- DevForge Init (DEVFORGE-002, spec `specs/002-init`): instala el arnés de IA (AGENTS.md, CLAUDE.md, MEMORY.md) en cualquier proyecto; detecta Django, Python, Vue, Node.js y PowerShell en la raíz y en el primer nivel, y escribe sus comandos de tests; nunca pisa archivos sin `-Force`; `-WhatIf` para simular; códigos de salida `0` completo, `1` algún archivo omitido, `2` error. Plantillas editables en `templates/harness/`. 62 tests nuevos.
- Doctor 0.2.0 (spec `specs/003-harness-doctor`): `-Project <ruta>` revisa el arnés de IA de un proyecto (que existan AGENTS.md, CLAUDE.md y MEMORY.md; imports de CLAUDE.md; límites de 40 y 50 líneas; marcadores pendientes) en una nueva categoría `HARNESS` del reporte y del JSON. Sin `-Project`, Doctor no cambia. 38 tests nuevos.

### Corregido

- ROADMAP: marcadas como completadas las tareas ya hechas de la v0.1.0-alpha.
- Las carpetas de `ai/`, `docs/`, `knowledge/`, `templates/`, `workspace/` y `.github/` eran archivos vacíos; ahora son carpetas con `.gitkeep`.
- Acentos rotos en Windows PowerShell 5.1: los `.ps1` con caracteres no ASCII se guardan en UTF-8 con BOM.
- Skill `sdd` movida a su ubicación definitiva, `.claude/skills/sdd/`.

### Cambiado

- `scripts/setup-devforge.ps1` ya no duplica la lógica de Doctor: es un atajo que lo ejecuta con los mismos parámetros.
- ROADMAP reordenado: la v0.2.0 pasa a ser "Arnés de IA" (lo construido) y las versiones siguientes se corren un número.
- README: versión, módulos disponibles y estructura del proyecto al día.

---

# [0.1.0-alpha] - 2026-07-11

## 🎉 Primera versión pública

### Agregado

- Creación del repositorio DevForge.
- README profesional.
- ROADMAP oficial.
- DEVFORGE_MANIFESTO.
- Script inicial `setup-devforge.ps1`.
- Licencia MIT.

### En desarrollo

- Configuración de VS Code.
- Automatización del entorno.
- Templates.
- Knowledge Base.

---

## Próximas versiones

Ver [ROADMAP.md](ROADMAP.md).
