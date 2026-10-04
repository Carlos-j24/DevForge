# Tareas 002 — DevForge Init

Spec: `spec.md` (aprobada) · Plan: `plan.md` (aprobado)

Regla: una tarea cada vez. Primero el test en `tests/Init.Tests.ps1` (en rojo), después el código, `Invoke-Pester ./tests` en verde (pwsh y 5.1), marcar la tarea y parar.

- [x] **T1. Detección de stacks en la raíz.** RF-4
  - Hecho cuando: `Get-DevForgeProjectStack` detecta Django, Python, Vue, Node.js y PowerShell por sus indicadores en la raíz (`Folder = "."`). Django oculta a Python y Vue oculta a Node.js. Un proyecto vacío devuelve una lista vacía.
- [x] **T2. Detección en subcarpetas y comandos de tests.** RF-4, RF-6, RF-7
  - Hecho cuando:
    - Detecta en subcarpetas de primer nivel, con su `Folder`, e ignora `node_modules`, `.git`, `.venv` y `venv`.
    - Django da `python manage.py test`, y un `package.json` con script `test` da `npm test`.
    - Con el script `test` por defecto de npm, o con un `package.json` inválido, el comando es `$null`; con JSON inválido además no falla y lo cuenta como Node.js.
- [x] **T3. Plantillas y contenido de CLAUDE.md y MEMORY.md.** RF-9
  - Hecho cuando:
    - Existen `templates/harness/{AGENTS,CLAUDE,MEMORY}.md`.
    - `New-DevForgeClaudeContent` solo importa AGENTS.md y MEMORY.md.
    - `New-DevForgeMemoryContent` incluye el nombre del proyecto y tiene como máximo 50 líneas.
- [x] **T4. Contenido de AGENTS.md.** RF-5, RF-6, RF-7, RF-8, RF-15
  - Hecho cuando:
    - Incluye el nombre del proyecto, cada stack con su carpeta si no es la raíz y los comandos de tests detectados.
    - Pone `[COMPLETAR]` si no hay stack o no hay comandos.
    - Tiene la sección "Límites" con sus tres reglas.
    - Tiene como máximo 40 líneas con Django + Vue + PowerShell.
- [x] **T5. Escritura de archivos.** RF-1, RF-2, RF-3, RF-14
  - Hecho cuando: `Install-DevForgeHarnessFile`:
    - Devuelve `Created` si el archivo no existía.
    - Devuelve `Skipped` si existía, sin cambiar ni su contenido ni su fecha.
    - Devuelve `Overwritten` con `-Force`.
    - Con `-WhatIf` devuelve `DryRun = $true` y no escribe nada.
    - El archivo queda en UTF-8 sin BOM, con las tildes intactas.
- [x] **T6. Orquestador y códigos de salida.** RF-10, RF-11, RF-12
  - Hecho cuando: `Invoke-DevForgeInit.ps1`, ejecutado en un proceso hijo:
    - Sale con 0 en un proyecto vacío.
    - Sale con 1 si ya existe CLAUDE.md, y crea los otros dos.
    - Sale con 2 si la ruta no existe o es un archivo, sin crear nada.
    - Imprime el resultado de cada archivo, los stacks detectados y el número de marcadores.
- [x] **T7. `-WhatIf`, idempotencia y límites de escritura.** RF-13, RF-14
  - Hecho cuando:
    - `-WhatIf` no crea nada y sale con el código que tendría la ejecución real.
    - Una segunda ejecución sin `-Force` no cambia ni contenido ni fechas.
    - Antes y después solo cambian los tres archivos del arnés.
    - Funciona con una ruta con espacios y tildes.
- [x] **T8. Validación manual y documentación.** Criterios de finalización
  - Hecho cuando:
    - Init se ejecutó a mano en carpetas temporales (proyecto vacío, arnés parcial y Django + Vue en `backend/` y `frontend/`) con pwsh y con 5.1, y se revisó la salida.
    - El CI está en verde.
    - Están actualizados el AGENTS.md de DevForge (comando de init), CHANGELOG.md y MEMORY.md, y la validación RF por RF tiene el veredicto.
- [x] **T9. Primer uso real en MedAlert.** Criterios de finalización
  - Hecho cuando:
    - Se ejecutó primero con `-WhatIf` y Carlos revisó la salida.
    - Después se ejecutó en real y Carlos revisó el AGENTS.md generado.
    - Los ajustes que salgan van primero a la spec.
