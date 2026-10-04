# Validación 003 — Doctor revisa el arnés de un proyecto

VEREDICTO: APROBADO · CI en verde en el PR #5 (pwsh y 5.1)

Fecha: 2026-10-03 · Tests: `tests/Harness.Tests.ps1`, 38/38 en verde en pwsh 7.6.6 y en Windows PowerShell 5.1 (115/115 en total).

## Requisitos funcionales
| RF | Qué se comprueba | Cómo | Resultado |
|---|---|---|---|
| RF-1 | Sin `-Project` Doctor no cambia | Los 15 tests de Doctor sin tocar; test "sin -Project no aparece ningún check HARNESS" | ✅ |
| RF-2 | Tres checks HARNESS en orden | Test "RF-2: devuelve tres checks HARNESS…" | ✅ |
| RF-3 | Archivo que falta → WARNING que sugiere Init | Tests "RF-3" (4) | ✅ |
| RF-4 | Imports de CLAUDE.md | Tests "RF-4" (3) y casos de vacío, espacios, CRLF e import dentro de una frase; mutaciones detectadas | ✅ |
| RF-5 | Límites de 40 y 50 líneas | Tests "RF-5" (5) en el borde; mutación "≥ en vez de >" detectada | ✅ |
| RF-6 | Cuenta los marcadores pendientes | Tests "RF-6" (2); manual en DevForge | ✅ |
| RF-7 | Arnés correcto → OK | Test "RF-7"; manual en MedAlert (3 OK) | ✅ |
| RF-8 | Varios problemas en el mismo mensaje | Test "RF-8" | ✅ |
| RF-9 | Ruta inválida → un único ERROR | Tests "RF-9" (2); manual con `C:/no/existe` en 5.1 (exit 2) | ✅ |
| RF-10 | Cuenta en estado, resumen, código de salida y JSON | Tests "RF-10" (2) en proceso hijo; manual con `-Json` | ✅ |
| RF-11 | Sección HARNESS en consola | Test "RF-11"; manual con pwsh y 5.1 | ✅ |
| RF-12 | No modifica el proyecto | Test "RF-12" (foto antes y después); MedAlert sin cambios tras las ejecuciones manuales | ✅ |
| RF-13 | Versión 0.2.0 | Tests "RF-10, RF-13" y "RF-1, RF-13"; manual con `-Json` | ✅ |

## Requisitos no funcionales y casos límite
- pwsh y 5.1, sin módulos externos: suite completa en ambos. ✅
- JSON solo crece de forma aditiva: los tests de esquema de la spec 001 pasan sin cambios. ✅
- Casos límite de la spec cubiertos por tests: sin arnés, archivos vacíos, 40/41 líneas, sin salto final, imports con espacios, rutas con espacios y tildes, BOM y CRLF. Además, una ruta relativa (`-Project .`), por un fallo encontrado en la T5. ✅

## Prueba manual (2026-10-03)
| Proyecto | pwsh | 5.1 |
|---|---|---|
| DevForge | AGENTS OK (39 líneas), CLAUDE OK, MEMORY WARNING (1 marcador) | Igual |
| MedAlert | 3 OK | Igual |
| `C:/no/existe` con `-Json` | — | `harness-project` ERROR, exit 2 |

El WARNING de DevForge era un **falso positivo**: MEMORY.md mencionaba el marcador de forma literal al describir la Fase C. Doctor cumple la spec, que es contar el texto. Se reescribió esa línea y queda apuntado como idea para una spec futura: ignorar los marcadores escritos entre comillas de código.

## Observaciones (no bloquean)
- La primera ejecución manual con 5.1 sobre `-Project .` se quedó colgada y se cortó por tiempo. No se pudo reproducir: el mismo comando, y también el Doctor de `main`, terminan en 2-3 s, y los tests de 5.1 pasan. Se atribuye al entorno de la ejecución, que lanzaba muchos procesos seguidos.
- Al redirigir `-Json` a un archivo desde la consola de Windows, las tildes salen con la codificación de la consola. Ya pasaba antes de esta spec y queda fuera de su alcance.
