# Plan 003 — Doctor revisa el arnés de un proyecto

Estado: aprobado (2026-10-03) · Spec: `specs/003-harness-doctor/spec.md` (aprobada)

## Archivos
| Archivo | Responsabilidad | RF |
|---|---|---|
| `scripts/doctor/Test-Harness.ps1` (nuevo) | Revisar los tres archivos del arnés de un proyecto y devolver checks `ToolCheck` | RF-2 a RF-9, RF-12 |
| `scripts/doctor/Invoke-DevForgeDoctor.ps1` | Parámetro `-Project`, sección HARNESS en consola, versión 0.2.0 | RF-1, RF-10, RF-11, RF-13 |
| `tests/Harness.Tests.ps1` (nuevo) | Tests de Pester en `$TestDrive` y de Doctor en un proceso hijo | Todos |

Se sigue el patrón de Doctor: un archivo `Test-*.ps1` por grupo de checks, que devuelve objetos `ToolCheck` sin escribir en consola (constitución, principio 3). El orquestador es el único que imprime.

## Funciones y lo que devuelven
- `Test-DevForgeHarness -Path` → lista de `ToolCheck` (contrato de la spec 001):
  - Ruta válida: tres checks, en este orden: `harness-agents`, `harness-claude` y `harness-memory`. Los campos son: `Name` = nombre del archivo, `Category = "HARNESS"`, `Installed` = si existe, `Version = "N/A"`, `Required = $false`, `Status` OK o WARNING, y `Message` con todos los problemas separados por `; `.
  - Ruta inválida: un solo check `harness-project` con `Status = "ERROR"`, `Required = $true` y un mensaje que explica el motivo.
- `Get-DevForgeHarnessLineCount -Text` → `[int]`, el número de líneas tal como las muestra un editor. Es una función auxiliar interna.

## Algoritmo
```
Test-DevForgeHarness(Path):
  si Path no existe → [ERROR "La carpeta no existe"]                        (RF-9)
  si no es carpeta → [ERROR "No es una carpeta"]                            (RF-9)
  para cada (id, archivo, límite) en [(agents, AGENTS.md, 40), (claude, CLAUDE.md, -), (memory, MEMORY.md, 50)]:
      si no existe → WARNING "No existe: ejecuta DevForge Init en el proyecto." (RF-3)
      texto = leer en UTF-8 (acepta BOM y CRLF)
      problemas = []
      si es CLAUDE.md: por cada import (@AGENTS.md, @MEMORY.md) que no aparezca
          como línea propia (ignorando espacios) → "falta el import @X"    (RF-4)
      si tiene límite y líneas > límite → "N líneas (máximo L)"            (RF-5)
      si no es CLAUDE.md y hay [COMPLETAR] → "N marcador(es) [COMPLETAR]"  (RF-6)
      problemas vacío → OK "Completo (N líneas)."                           (RF-7)
      si no → WARNING con los problemas unidos por "; "                     (RF-8)

Get-DevForgeHarnessLineCount(Text):
  vacío → 0; si no: partir por \r?\n y no contar el último trozo si queda vacío (salto final)

Invoke-DevForgeDoctor:
  param [string]$Project
  checks de la máquina (sin cambios)                                        (RF-1)
  si se indicó Project → checks += Test-DevForgeHarness Project             (RF-2, RF-10)
  categorías de consola: CORE, EDITOR, LANGUAGE, CONTAINER, AI, HARNESS     (RF-11)
  título de la sección: "HARNESS (<nombre del proyecto>)"
  version = "0.2.0"                                                         (RF-13)
```

## Decisiones
- **Archivo nuevo `Test-Harness.ps1` junto a los otros checks.** Mantiene "un archivo por responsabilidad" y el patrón `Test-Tool` y `Test-System`. Descartado: meterlo en el orquestador, porque mezclaría lógica y presentación.
- **No reutilizar código de Init.** Los nombres de los archivos y los límites son los mismos, pero Doctor no debe depender de los scripts de Init: así Doctor sigue funcionando aunque Init cambie. Descartado: importar `scripts/init/`. Como contrapartida, los límites (40 y 50) quedan escritos en dos sitios; los tests de ambos lados los fijan.
- **Una ruta inválida es un check ERROR y no una salida temprana.** Así el JSON sigue siendo válido y completo, y el estado global y el código de salida 2 salen solos del mecanismo de siempre (RF-10). Descartado: `exit 2` con un mensaje suelto, que rompería `-Json`.
- **El import solo cuenta si ocupa una línea propia.** Es como lo interpreta Claude Code. Descartado: buscar el texto en cualquier parte, porque daría por bueno un `@AGENTS.md` escrito dentro de una frase.

## Estrategia de tests (Pester 5.5+)
- Unitarios de `Test-DevForgeHarness` con proyectos falsos en `$TestDrive`:
  - Los tres archivos faltan.
  - Arnés completo (OK).
  - CLAUDE.md sin uno de los imports y sin los dos.
  - Límites en el borde: 40 y 41 líneas, 50 y 51.
  - Marcadores pendientes.
  - Varios problemas a la vez.
  - Archivo vacío, sin salto final, con BOM y CRLF, e imports con espacios al final.
  - Ruta inexistente y ruta que es un archivo.
- RF-12: una "foto" del proyecto (tamaño y fecha de cada archivo) antes y después debe ser idéntica.
- Integración: Doctor con `-Project -Json` en un proceso hijo. Debe tener la categoría HARNESS, la versión 0.2.0, el resumen y el código de salida coherentes, y un proyecto inexistente debe salir con 2. En consola debe aparecer la sección HARNESS.
- RF-1: los 15 tests actuales de Doctor siguen en verde sin cambios, y un test nuevo comprueba que sin `-Project` no aparece ningún check HARNESS.
