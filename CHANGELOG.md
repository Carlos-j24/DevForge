# 📜 Changelog

Todos los cambios importantes de **DevForge** serán documentados en este archivo.

Este proyecto sigue el estándar **Keep a Changelog** y utiliza **Semantic Versioning**.

---

# [Unreleased]

### Agregado

- DevForge Doctor 0.1.0 (DEVFORGE-001): modelo estándar `ToolCheck`; detección de Git, PowerShell, VS Code, Python, Node.js, Docker y Ollama; estados `OK`, `WARNING` y `ERROR`; estado global; reporte JSON con `-Json`; códigos de salida `0` OK, `1` WARNING, `2` ERROR.
- Arnés de IA: `AGENTS.md`, `CLAUDE.md`, `MEMORY.md`, `docs/constitution.md`, `specs/001-doctor/spec.md` y skill `sdd`.
- Tests Pester (5.5+) para Doctor (`tests/Doctor.Tests.ps1`).
- CI con GitHub Actions (`.github/workflows/tests.yml`): Pester en cada PR y push a `main`, en PowerShell 7 y 5.1.

### Corregido

- ROADMAP: marcadas como completadas las tareas ya hechas de la v0.1.0-alpha.
- Las carpetas de `ai/`, `docs/`, `knowledge/`, `templates/`, `workspace/` y `.github/` eran archivos vacíos; ahora son carpetas con `.gitkeep`.
- Acentos rotos en Windows PowerShell 5.1: los `.ps1` con caracteres no ASCII se guardan en UTF-8 con BOM.
- Skill `sdd` movida a su ubicación definitiva, `.claude/skills/sdd/`.

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

### v0.2.0

- Workspace profesional.
- Continue.
- Cline.
- Ollama.
- Extensiones VS Code.

---

### v0.3.0

- Templates.
- Automatización.
- CLI DevForge.

---

### v1.0.0

Primera versión estable.