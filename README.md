<div align="center">

# ⚒️ DevForge

### Professional AI Development Environment

*Forge your ideas. Build your future.*

![Version](https://img.shields.io/badge/version-v0.2.0-blue)
![Status](https://img.shields.io/badge/status-In%20Development-success)
![License](https://img.shields.io/badge/license-MIT-green)

</div>

---

# 🚀 ¿Qué es DevForge?

DevForge es un ecosistema de desarrollo profesional diseñado para aumentar la productividad mediante inteligencia artificial, automatización y buenas prácticas de ingeniería de software.

El objetivo del proyecto es proporcionar un entorno moderno que permita desarrollar aplicaciones de forma más rápida, organizada y escalable sin sacrificar la calidad del código.

---

# 🎯 Nuestra misión

Construir un entorno de desarrollo que permita a cualquier desarrollador concentrarse en resolver problemas, mientras DevForge automatiza las tareas repetitivas.

---

# 🌍 Nuestra visión

Convertir DevForge en una plataforma completa para el desarrollo de software, integrando herramientas de inteligencia artificial, automatización, documentación y gestión de proyectos en un único ecosistema.

---

# 🧰 Módulos disponibles

| Módulo | Qué hace | Comando |
|---|---|---|
| **DevForge Doctor** | Diagnostica el entorno (Git, PowerShell 7, VS Code, Python, Node.js, Docker, Ollama) sin instalar nada. Con `-Project`, revisa además el arnés de IA de un proyecto. | `pwsh -File scripts/doctor/Invoke-DevForgeDoctor.ps1 [-Json] [-Project <ruta>]` |
| **DevForge Init** | Instala el arnés de IA (AGENTS.md, CLAUDE.md, MEMORY.md) en cualquier proyecto, detectando su stack. Nunca pisa archivos sin `-Force`. | `pwsh -File scripts/init/Invoke-DevForgeInit.ps1 -Path <proyecto> [-WhatIf] [-Force]` |

Códigos de salida de ambos: `0` OK, `1` con avisos, `2` error.

Tests (requiere [Pester](https://pester.dev) 5.5 o superior):

```powershell
Invoke-Pester ./tests -Output Detailed
```

---

# ⚙️ Tecnologías

Actualmente DevForge está pensado para trabajar con:

- VS Code
- Git
- GitHub
- Ollama
- Continue
- Cline
- Python
- TypeScript
- Vue.js
- Django
- Docker
- PostgreSQL

---

# 🏗️ Arquitectura del proyecto

```
DevForge
│
├── .claude/skills/   # Skills para agentes (p. ej. sdd)
├── .github/          # CI: tests en cada PR
├── ai/
├── docs/             # Constitución y documentación
├── knowledge/
├── scripts/
│   ├── core/         # Modelo ToolCheck y salida por consola
│   ├── doctor/       # DevForge Doctor
│   └── init/         # DevForge Init
├── specs/            # Specs SDD (spec, plan, tareas, validación)
├── templates/
│   └── harness/      # Plantillas del arnés de IA
├── tests/            # Tests Pester
└── workspace/
```

Las reglas para agentes de IA están en [AGENTS.md](AGENTS.md).

---

# 🛣️ Roadmap

## ✅ Versión 0.1 Alpha

- Repositorio
- README
- Manifesto
- Roadmap
- Scripts iniciales
- Estructura del proyecto

## ✅ Versión 0.2.0 — Arnés de IA

- Arnés de IA: AGENTS.md, MEMORY.md, constitución y flujo SDD
- DevForge Doctor y DevForge Init
- Tests Pester y CI con GitHub Actions

---

## 🔜 Próximas versiones

- Integración con Ollama
- Continue
- Cline
- Automatización
- Templates
- Dashboard
- CLI DevForge
- IA especializada
- Plugins

Detalle completo en [ROADMAP.md](ROADMAP.md).

---

# 📌 Filosofía

En DevForge creemos que:

- La arquitectura importa.
- La automatización ahorra tiempo.
- El código limpio siempre gana.
- Documentar es desarrollar.
- Las IA son asistentes, no reemplazos del criterio humano.

---

# 🤝 Cómo contribuir

Actualmente DevForge se encuentra en desarrollo.

Las contribuciones serán bienvenidas una vez se publique la primera versión estable.

---

# 📜 Licencia

Este proyecto se distribuye bajo la licencia MIT.

---

<div align="center">

## ⚒️ DevForge

**Professional AI Development Environment**

Construido con ❤️ por Carlos José Castro López.

Con el apoyo de ChatGPT como compañero técnico.

</div>