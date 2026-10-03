# Spec 002 — DevForge Init

Estado: implementada (2026-10-03) · primer uso real en MedAlert hecho (T9)

## Contexto y objetivo
Preparar un proyecto para trabajar con agentes de IA (Claude Code, OpenCode) hoy exige crear a mano el mismo arnés en cada repo: reglas del proyecto, memoria entre sesiones y el puente para Claude. En DevForge ese arnés ya existe y funciona. `devforge init` lo instala en cualquier otro proyecto en segundos, adaptado a lo que encuentre en él y sin tocar nada de lo que el proyecto ya tenga. El primer cliente real será MedAlert (Django + Vue).

## Usuarios
- Desarrollador que quiere empezar a usar agentes de IA en un proyecto existente o nuevo.
- Scripts y agentes que preparan proyectos de forma automática (sin preguntas en consola).

## Historias de usuario
- HU-1. Como desarrollador, quiero instalar el arnés de IA en un proyecto con un solo comando para no copiar archivos a mano.
- HU-2. Como desarrollador, quiero que el AGENTS.md generado ya traiga el stack y los comandos de mi proyecto para no empezar de cero.
- HU-3. Como desarrollador, quiero la garantía de que init nunca pisa mis archivos para poder ejecutarlo sin miedo, incluso dos veces.
- HU-4. Como script o agente, quiero un código de salida claro para saber si la instalación fue completa.

## Definiciones
- **Arnés (núcleo)**: los tres archivos que se instalan: AGENTS.md (reglas del proyecto, fuente única), CLAUDE.md (solo importa AGENTS.md y MEMORY.md) y MEMORY.md (estado entre sesiones).
- **Proyecto destino**: la carpeta en la que se instala el arnés. Por defecto, la carpeta actual.
- **Stack detectado**: tecnología identificada por archivos indicadores en la raíz del proyecto destino o en sus subcarpetas de primer nivel.
- **Marcador**: el texto `[COMPLETAR]`, que señala lo que init no pudo deducir y debe rellenar una persona o un agente.

## Requisitos funcionales
- RF-1: CUANDO se ejecuta init sobre un proyecto destino, EL SISTEMA crea en su raíz los archivos del arnés que no existan: AGENTS.md, CLAUDE.md y MEMORY.md.
- RF-2: SI un archivo del arnés ya existe, ENTONCES EL SISTEMA no lo modifica y lo informa como omitido.
- RF-3: CUANDO se ejecuta con `-Force`, EL SISTEMA sobrescribe los archivos del arnés existentes e informa cada uno como sobrescrito.
- RF-4: EL SISTEMA detecta estos stacks por sus indicadores:
  - Django: `manage.py`.
  - Python: `pyproject.toml` o `requirements.txt`.
  - Vue: `package.json` que declara `vue` como dependencia.
  - Node.js: `package.json`.
  - PowerShell: algún `.ps1` o `.psd1`.
- RF-5: CUANDO detecta uno o más stacks, EL SISTEMA los escribe en la sección de stack del AGENTS.md, indicando la carpeta en la que se detectó cada uno si no es la raíz.
- RF-6: CUANDO detecta Django, EL SISTEMA incluye en AGENTS.md el comando de tests `python manage.py test`, ejecutado desde la carpeta donde está `manage.py`.
- RF-7: CUANDO detecta un `package.json` con un script `test`, EL SISTEMA incluye en AGENTS.md el comando `npm test`, ejecutado desde esa carpeta.
- RF-8: SI no detecta ningún stack o ningún comando de tests, ENTONCES EL SISTEMA deja la sección correspondiente con el marcador `[COMPLETAR]`.
- RF-9: EL SISTEMA usa el nombre de la carpeta del proyecto destino como nombre del proyecto en AGENTS.md y MEMORY.md.
- RF-10: CUANDO termina, EL SISTEMA muestra cada archivo del arnés con su resultado (creado, omitido o sobrescrito), los stacks detectados y cuántos marcadores `[COMPLETAR]` quedaron.
- RF-11: CUANDO termina, EL SISTEMA sale con código 0 si creó o sobrescribió los tres archivos, 1 si omitió alguno y 2 si no pudo instalar el arnés.
- RF-12: SI el proyecto destino no existe o no es una carpeta, ENTONCES EL SISTEMA no crea nada, explica el motivo y sale con código 2.
- RF-13: EL SISTEMA solo escribe los archivos del arnés dentro del proyecto destino: no modifica ni borra ningún otro archivo, y no escribe fuera de esa carpeta.
- RF-14: CUANDO se ejecuta con `-WhatIf`, EL SISTEMA muestra qué archivos crearía, omitiría o sobrescribiría y los stacks detectados, no escribe nada y sale con el código que habría tenido la ejecución real.
- RF-15: EL SISTEMA incluye en el AGENTS.md generado una sección "Límites" con estas reglas: no guardar claves ni tokens en el repo; tests en verde antes de dar algo por hecho; actualizar MEMORY.md al terminar cada tarea.

## Requisitos no funcionales
- Se ejecuta como un script que recibe la carpeta destino por parámetro, igual que Doctor.
- PowerShell 7+ en Windows, sin módulos externos en runtime; debe funcionar también en Windows PowerShell 5.1 (igual que Doctor).
- No hace preguntas en consola: sirve igual para personas, scripts y agentes.
- El AGENTS.md generado tiene como máximo 40 líneas, y el MEMORY.md como máximo 50.
- Los archivos se escriben en UTF-8. CLAUDE.md solo contiene el puente: importa AGENTS.md y MEMORY.md.
- Ejecutar init dos veces seguidas sin `-Force` no cambia nada la segunda vez.

## Casos límite
- Proyecto vacío → crea los tres archivos con marcadores en stack y comandos; sale con 0.
- Django y Vue en carpetas distintas (por ejemplo, `backend/` y `frontend/`) → detecta ambos e indica la carpeta de cada uno.
- `package.json` mal formado (JSON inválido) → lo cuenta como Node.js, no intenta detectar Vue ni el script `test`, y no falla.
- Varios indicadores del mismo stack (dos `package.json` en carpetas distintas) → lista cada uno con su carpeta.
- Solo existe CLAUDE.md, que es el puente → crea AGENTS.md y MEMORY.md, omite CLAUDE.md y sale con 1.
- Carpetas pesadas en primer nivel (`node_modules`, `.git`, `.venv`, `venv`) → se ignoran en la detección.
- La ruta tiene espacios o tildes → funciona igual.
- Carpeta con `manage.py` y `requirements.txt` → se informa solo Django (Python queda implícito).
- `package.json` que declara `vue` → se informa solo Vue (Node.js queda implícito), pero sigue aplicando RF-7.
- Script `test` por defecto de npm (`echo "Error: no test specified" && exit 1`) → se trata como si no hubiera script `test`.

## Fuera de alcance
- Constitución, carpeta `specs/` y skill `sdd` (spec futura).
- Modificar el `.gitignore` del proyecto destino.
- Workflows de CI.
- Hacer commits o cualquier operación de git.
- Detectar stacks más allá del primer nivel de subcarpetas.
- Salida JSON.
- Un comando global `devforge` (queda para la CLI de la v0.3.0 del ROADMAP).

## Criterios de finalización
- Todos los RF tienen al menos un test de Pester en verde, en pwsh y en 5.1 (CI).
- Probado a mano sobre una carpeta temporal: proyecto vacío, proyecto con arnés parcial y proyecto con Django + Vue en subcarpetas.
- Después, ejecutado sobre MedAlert y revisado el AGENTS.md generado con Carlos.
- MEMORY.md y CHANGELOG.md de DevForge actualizados.

## Decisiones de la clarificación (2026-10-03)
- Archivos existentes: no se tocan y se avisa; `-Force` para sobrescribir (RF-2, RF-3).
- Contenido: se detecta el stack; lo que no se deduce queda con `[COMPLETAR]` (RF-4 a RF-8).
- Alcance: solo el núcleo del arnés; se prueba primero en carpetas temporales y después en MedAlert.
- Se ejecuta como script con parámetro de ruta, igual que Doctor; el comando global queda fuera.
- Se incluye `-WhatIf` (RF-14) y una sección "Límites" en el AGENTS.md generado (RF-15).

## Dudas abiertas
- Ninguna.
