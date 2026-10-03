# Validación 002 — DevForge Init

VEREDICTO: APROBADO · CI en verde en el PR #3 (pwsh y 5.1) · T9 hecha en MedAlert

Fecha: 2026-10-03 · Tests: `tests/Init.Tests.ps1`, 62/62 en verde en pwsh 7.6.6 y en Windows PowerShell 5.1 (77/77 contando los de Doctor).

## Requisitos funcionales
| RF | Qué se comprueba | Cómo | Resultado |
|---|---|---|---|
| RF-1 | Crea los archivos que no existen | Test "RF-1: crea el archivo…"; "RF-11: en un proyecto vacío crea los tres…" | ✅ |
| RF-2 | No modifica un archivo existente y lo informa como omitido | Test "RF-2: si existe… no cambia contenido ni fecha"; "RF-11: si ya existe CLAUDE.md…" | ✅ |
| RF-3 | `-Force` sobrescribe e informa | Test "RF-3: con -Force sobrescribe…"; manual con `-WhatIf -Force` | ✅ |
| RF-4 | Detecta Django, Python, Vue, Node.js y PowerShell en raíz y primer nivel | 18 tests en "Get-DevForgeProjectStack en la raíz" y "en subcarpetas" | ✅ |
| RF-5 | Escribe los stacks con su carpeta | Test "RF-5: lista cada stack con su carpeta…"; manual en MedAlertFalso | ✅ |
| RF-6 | Django → `python manage.py test` desde su carpeta | Tests "RF-6: Django da…" y "RF-6, RF-7: lista los comandos…" | ✅ |
| RF-7 | `package.json` con script `test` → `npm test` | Tests "RF-7" (3) y casos de script por defecto, sin scripts e inválido | ✅ |
| RF-8 | `[COMPLETAR]` si no hay stack o comandos | Tests "RF-8" (2); manual en Vacio (7 marcadores) | ✅ |
| RF-9 | Nombre de la carpeta como nombre del proyecto | Tests "RF-9" en AGENTS y MEMORY; ruta con espacios y tildes | ✅ |
| RF-10 | Resumen: resultado por archivo, stacks y marcadores | Tests "RF-10" (2); manual en los tres proyectos | ✅ |
| RF-11 | Códigos 0 / 1 / 2 | Tests "RF-11" (3) en proceso hijo; manual: Vacio 0, Parcial 1, MedAlertFalso 0 | ✅ |
| RF-12 | Ruta inexistente o archivo → nada creado, exit 2 | Tests "RF-12" (2) | ✅ |
| RF-13 | Solo escribe los tres archivos, nada fuera | Test "RF-13" con foto antes/después que incluye un archivo vecino; mutación "archivo extra" detectada | ✅ |
| RF-14 | `-WhatIf` no escribe y sale con el código real | Tests "RF-14" (6); mutación "ignora -WhatIf" detectada; manual con pwsh y 5.1 | ✅ |
| RF-15 | Sección "Límites" con tres reglas | Test "RF-15: incluye la sección Límites…" | ✅ |

## Requisitos no funcionales
| Requisito | Cómo | Resultado |
|---|---|---|
| Script con la carpeta por parámetro; por defecto la actual | Test "sin -Path usa la carpeta actual" | ✅ |
| PowerShell 7 y 5.1, sin módulos externos | Suite completa en ambos; CI con los dos | ✅ |
| Sin preguntas en consola | Todos los tests corren en procesos no interactivos | ✅ |
| AGENTS.md ≤ 40 líneas, MEMORY.md ≤ 50 | Tests de líneas; manual: 26 y 14 | ✅ |
| UTF-8; CLAUDE.md solo es el puente | Test "UTF-8 sin BOM…"; tests de New-DevForgeClaudeContent | ✅ |
| Segunda ejecución sin `-Force` no cambia nada | Test de idempotencia (contenido y fechas) | ✅ |

## Casos límite de la spec
Todos cubiertos por tests: proyecto vacío, Django + Vue en subcarpetas, `package.json` inválido, varios `package.json`, solo CLAUDE.md, carpetas ignoradas, ruta con espacios y tildes, Django oculta Python, Vue oculta Node.js y script `test` por defecto de npm.

## Primer uso real: MedAlert (T9, 2026-10-03)
- `-WhatIf` detectó Node.js en la raíz por un `package.json` sobrante (restos de un `npm install` en la carpeta equivocada). Init funcionó según la spec y además destapó un problema real del proyecto. Se limpió MedAlert (24 tests de Vue siguen en verde) y no se cambió la spec.
- Ejecución real: 3 archivos creados, Django (`backend`) y Vue (`frontend`) detectados con sus comandos de tests, 5 marcadores; exit 0.
- Los marcadores se completaron leyendo el código de MedAlert. Se encontró un posible fallo de zona horaria en `enviar_recordatorios_whatsapp`, que quedó apuntado en el MEMORY.md de MedAlert.

## Observaciones (no bloquean)
- Con `-WhatIf`, PowerShell añade sus propios mensajes "What If: …" además del resumen de init.
- Si falla la escritura del segundo o tercer archivo, los anteriores quedan escritos (decisión aceptada por Carlos: init nunca borra).
- En la consola de la herramienta de Claude las tildes se ven alteradas; en los archivos y en una terminal normal están bien.
