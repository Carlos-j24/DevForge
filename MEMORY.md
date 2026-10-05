# MEMORY.md — DevForge
Memoria del proyecto entre sesiones. Máximo ~50 líneas: resume o elimina lo que ya no aporte.

## Estado actual
- v0.2.0 "Arnés de IA" (2026-10-05): Doctor 0.2.0 (consola, `-Json`, `-Project <ruta>`) e Init (spec 002, usado en MedAlert). 116 tests en verde (pwsh + 5.1).
- Versiones siguientes en ROADMAP.md (reordenado en la v0.2.0): la próxima es la v0.3.0, Professional Workspace.
- Arnés de IA creado: AGENTS.md, CLAUDE.md, constitución, spec 001-doctor, skill sdd, tests Pester.
- CI: GitHub Actions corre Pester (pwsh + 5.1) en cada PR. Trabajo en ramas + PR; `gh` instalado y autenticado.
- Fuente de verdad: carpeta `DevForge-001-Doctor` (remoto `Carlos-j24/DevForge`). La carpeta `DevForge` es una copia antigua (revisada el 2026-10-05: no tiene nada que no esté en GitHub; se puede borrar).

## Decisiones (y por qué)
- AGENTS.md es la fuente única; CLAUDE.md solo lo importa → mismas reglas para Claude Code y OpenCode.
- Skills en `.claude/skills/` → Claude Code y OpenCode las leen de ahí (una sola copia).
- SDD en modo spec-anchored: la spec 001 se escribió después del código y se mantiene viva.
- Tests con Pester 5.5+ (probado con 6.2): sintaxis de Pester 5, que la 6 sigue soportando. Windows trae la 3.4, así que hay que instalarlo, y por separado para 5.1 y para pwsh (cada uno tiene su carpeta de módulos).

## Aprendizajes y errores a evitar
- Las carpetas `ai/*`, `docs/*`, `knowledge/*`, `templates/*`, `workspace/*` y `.github/*` eran archivos vacíos (faltó `-ItemType Directory`). Corregido el 2026-10-03: ahora son carpetas con `.gitkeep`.
- Los `.ps1` con acentos deben guardarse en UTF-8 **con BOM**: Windows PowerShell 5.1 lee los que no tienen BOM como ANSI y muestra "estÃ¡".
- `pwsh` 7.6.6 instalado el 2026-10-03; los tests pasan tanto en pwsh como en 5.1.
- `setup-devforge.ps1` es solo un atajo a Doctor desde la v0.2.0: no volver a meter lógica ahí.
- Si un test pasa a la primera, se comprueba metiendo un fallo a propósito (en la spec 002 se hizo en T2 y T7).
- En tests, `Should -BeNullOrEmpty` sobre una lista de varios `$null` falla: comprobar elemento a elemento.
- Usar init primero con `-WhatIf`: en MedAlert destapó un `package.json` sobrante en la raíz.
- Las funciones de .NET (`[IO.File]`) no conocen la carpeta actual de PowerShell: convertir antes la ruta a absoluta (fallo encontrado en la spec 003).

## Próximos pasos
- Resolver dudas abiertas de `specs/001-doctor/spec.md` (alias de Python en Store, versiones mínimas).
- MedAlert está en `C:\Users\USUARIO\Desktop\MedAlert` (`appmedalert` es una versión antigua).
- Fases A, B y C terminadas (2026-10-03): arnés + CI, DevForge Init (spec 002) y Doctor `-Project` (spec 003), todo en `main`. Ideas para specs futuras: secretos expuestos, tests y CI, restos como el `package.json` de MedAlert, e ignorar marcadores escritos entre comillas de código (hoy una mención literal cuenta como pendiente).
