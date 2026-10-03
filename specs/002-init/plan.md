# Plan 002 — DevForge Init

Estado: aprobado (2026-10-03) · Spec: `specs/002-init/spec.md` (aprobada)

## Archivos
| Archivo | Responsabilidad | RF |
|---|---|---|
| `scripts/init/Get-DevForgeProjectStack.ps1` | Detectar stacks y comandos de tests en la raíz y en el primer nivel | RF-4, RF-6, RF-7 |
| `scripts/init/New-DevForgeHarnessContent.ps1` | Generar el texto de AGENTS.md, CLAUDE.md y MEMORY.md a partir de las plantillas | RF-5, RF-8, RF-9, RF-15 |
| `scripts/init/Install-DevForgeHarnessFile.ps1` | Escribir un archivo respetando omitir, `-Force` y `-WhatIf` | RF-1, RF-2, RF-3, RF-13, RF-14 |
| `scripts/init/Invoke-DevForgeInit.ps1` | Orquestador: valida la ruta, llama a lo anterior, imprime el resumen y fija el código de salida | RF-10, RF-11, RF-12, RF-14 |
| `templates/harness/AGENTS.md`, `CLAUDE.md`, `MEMORY.md` | Plantillas con marcadores `{{CLAVE}}` | RF-5, RF-9, RF-15 |
| `tests/Init.Tests.ps1` | Tests de Pester en `$TestDrive` (carpetas temporales) | Todos |

Igual que en Doctor: la lógica devuelve objetos y solo el orquestador escribe en consola (constitución, principio 3).

## Funciones y lo que devuelven
- `Get-DevForgeProjectStack -Path` → lista de objetos `{ Stack; Folder; TestCommand }`.
  - `Stack` es uno de: Django, Python, Vue, Node.js o PowerShell.
  - `Folder` es `.` para la raíz o el nombre de la subcarpeta.
  - `TestCommand` es el comando de tests, o `$null` si no se detectó ninguno.
- `New-DevForgeAgentsContent -ProjectName -Stacks`, `New-DevForgeMemoryContent -ProjectName` y `New-DevForgeClaudeContent` → `[string]`. Son funciones puras: no tocan el disco, salvo para leer la plantilla.
- `Install-DevForgeHarnessFile -Path -Content [-Force]`, con `SupportsShouldProcess` (el soporte estándar de PowerShell para `-WhatIf`) → `{ File; Result; DryRun }`.
  - `Result` es `Created`, `Skipped` u `Overwritten`.
  - `DryRun` vale `$true` con `-WhatIf`.
- `Invoke-DevForgeInit.ps1 [-Path .] [-Force] [-WhatIf]` → escribe en consola y sale con 0, 1 o 2.

## Algoritmo
```
Invoke-DevForgeInit:
  si Path no existe o no es carpeta → mensaje + exit 2                      (RF-12)
  name   = nombre de la carpeta                                             (RF-9)
  stacks = Get-DevForgeProjectStack Path
  para cada (archivo, contenido) en AGENTS/CLAUDE/MEMORY:
      results += Install-DevForgeHarnessFile (Path/archivo) contenido -Force -WhatIf
      (si falla la escritura → mensaje + exit 2)
  marcadores = nº de "[COMPLETAR]" en los contenidos creados o sobrescritos
  imprimir resultados, stacks y marcadores                                  (RF-10)
  exit 1 si algún Skipped; si no, exit 0                                    (RF-11, RF-14)

Get-DevForgeProjectStack:
  carpetas = raíz + subcarpetas de primer nivel, excepto node_modules, .git, .venv y venv
  para cada carpeta:
      manage.py                          → Django, "python manage.py test"
      si no: pyproject.toml / requirements.txt → Python, sin comando
      package.json:
          JSON inválido                  → Node.js, sin comando
          declara vue (dependencies o devDependencies) → Vue; si no → Node.js
          scripts.test existe y no es el de npm por defecto → "npm test"
      *.ps1 o *.psd1 en la carpeta (sin recursión) → PowerShell, sin comando

Install-DevForgeHarnessFile:
  existe y no -Force → Skipped (no escribe)
  ShouldProcess falso (-WhatIf) → Created/Overwritten con DryRun = $true (no escribe)
  escribe UTF-8 sin BOM → Created u Overwritten
```

## Decisiones
- **Plantillas en archivos (`templates/harness/`) y no en el código.** Así puedes editar el arnés sin tocar PowerShell, y le damos uso a la carpeta `templates/`. Descartado: plantillas como texto dentro del `.ps1`, que obligan a editar código para cambiar una regla.
- **`-WhatIf` con `SupportsShouldProcess`.** Es el mecanismo estándar de PowerShell y también trae `-Confirm`. Descartado: un parámetro propio `-DryRun`, que no sigue la convención.
- **Escribir con `[IO.File]::WriteAllText` en UTF-8 sin BOM.** En 5.1, `Set-Content -Encoding UTF8` añade BOM y además se comporta distinto que en pwsh. El BOM solo hace falta en los `.ps1`, no en los `.md`. Descartado: `Set-Content`.
- **Detección por archivos indicadores, solo hasta el primer nivel.** Basta para MedAlert (`backend/`, `frontend/`) y es rápido incluso con `node_modules`. Descartado: búsqueda recursiva, que es lenta y da falsos positivos.
- **Django oculta a Python y Vue oculta a Node.js en la misma carpeta.** Así el AGENTS.md no repite lo obvio (casos límite de la spec).

## Estrategia de tests (Pester 5.5+)
- Cada test crea un proyecto falso en `$TestDrive`, una carpeta temporal que Pester borra sola. Nunca se toca una carpeta real.
- Unitarios para `Get-DevForgeProjectStack`: cada indicador, subcarpetas, carpetas ignoradas, `package.json` inválido y script `test` por defecto.
- Unitarios para el contenido: nombre del proyecto, stacks con su carpeta, marcadores cuando no hay stack, sección "Límites", máximo 40 y 50 líneas.
- Integración: `Invoke-DevForgeInit.ps1` en un proceso hijo (igual que los tests de Doctor) para comprobar los códigos de salida 0, 1 y 2, `-Force`, `-WhatIf` y que una segunda ejecución no cambia nada (comparando contenido y fecha de modificación).
- RF-13: comparar la lista de archivos del proyecto falso antes y después; solo pueden aparecer los tres del arnés.
