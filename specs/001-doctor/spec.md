# Spec 001 — DevForge Doctor

Estado: implementada (v0.1.0) · spec-anchored: escrita a partir del código existente y de `DEVFORGE-001-DOCTOR.md`.

## Contexto y objetivo
Antes de trabajar en un proyecto, el desarrollador necesita saber si su máquina tiene las herramientas necesarias. Doctor lo diagnostica en segundos, sin instalar ni modificar nada, y deja el resultado en un formato que pueden leer tanto una persona como un script o un agente de IA.

## Usuarios
- Desarrollador que prepara o revisa su entorno.
- Scripts y agentes de IA que necesitan saber si el entorno está listo antes de actuar.

## Historias de usuario
- HU-1. Como desarrollador, quiero ver de un vistazo qué herramientas tengo y cuáles faltan para saber si puedo empezar a trabajar.
- HU-2. Como script o agente, quiero un resultado en JSON y un código de salida para decidir qué hacer sin leer texto.

## Definiciones
- **Requerido**: componente sin el cual el entorno no está listo (Git, PowerShell 7+, VS Code, Python, Node.js).
- **Opcional**: componente recomendado (Docker, Ollama).

## Requisitos funcionales
- RF-1: CUANDO se ejecuta Doctor, EL SISTEMA comprueba Git, PowerShell 7+, VS Code, Python, Node.js, Docker y Ollama.
- RF-2: CUANDO un componente está disponible, EL SISTEMA lo marca como OK e informa su versión, o "Detectado" si la versión sale vacía.
- RF-3: SI falta un componente requerido, ENTONCES EL SISTEMA lo marca como ERROR.
- RF-4: SI falta un componente opcional, ENTONCES EL SISTEMA lo marca como WARNING.
- RF-5: SI un componente existe pero no se puede obtener su versión, ENTONCES EL SISTEMA lo marca como WARNING.
- RF-6: EL SISTEMA calcula el estado global: ERROR si hay al menos un ERROR; si no, WARNING si hay al menos un WARNING; si no, OK.
- RF-7: CUANDO termina, EL SISTEMA sale con código 0 (OK), 1 (WARNING) o 2 (ERROR).
- RF-8: CUANDO se ejecuta con `-Json`, EL SISTEMA imprime solo JSON con `tool`, `version`, `timestamp` (UTC, ISO 8601), `status`, `summary` (`ok`, `warnings`, `errors`) y `checks`.
- RF-9: CUANDO se ejecuta sin `-Json`, EL SISTEMA muestra los checks agrupados por categoría (CORE, EDITOR, LANGUAGES, CONTAINER, AI) y un resumen con el estado global.
- RF-10: EL SISTEMA nunca instala, modifica ni borra componentes.

## Requisitos no funcionales
- Funciona con PowerShell 7+ en Windows; sin módulos externos en runtime.
- Cada check devuelve un objeto con: Id, Name, Category, Installed, Version, Required, Status, Message.

## Casos límite
- La versión sale en varias líneas → se usa solo la primera.
- El comando de versión escribe en stderr → se captura igual (`2>&1`).
- Se ejecuta desde Windows PowerShell 5.1 → el check de PowerShell mira si existe `pwsh`, no la versión de la sesión actual.

> Nota (2026-10-03): la spec 003 añade `-Project <ruta>` (categoría `HARNESS`) y sube Doctor a 0.2.0. Sin `-Project`, todo lo de esta spec sigue igual.

## Fuera de alcance
- Validar versiones mínimas, diagnosticar el proyecto actual, reportes HTML, modo `--fix` (ver "Próxima evolución" en DEVFORGE-001-DOCTOR.md).

## Criterios de finalización
- Todos los RF con un test Pester en verde (RF-9 y RF-10 se verifican a mano).
- Ejecución manual en consola y con `-Json` sin errores.

## Dudas abiertas
- [NECESITA ACLARACIÓN] Alias de Python de Microsoft Store: `python` existe en PATH pero no es Python real. ¿Se debe marcar como ERROR, WARNING o detectarlo como "no instalado"?
- [NECESITA ACLARACIÓN] ¿Hace falta comprobar que `node`/`python` cumplen una versión mínima? (Hoy fuera de alcance.)
