# Spec 003 — Doctor revisa el arnés de un proyecto

Estado: implementada (2026-10-03)

## Contexto y objetivo
DevForge Init (spec 002) instala el arnés de IA en un proyecto, pero después nada comprueba que siga en buen estado: puede faltar un archivo, quedar marcadores `[COMPLETAR]` sin rellenar, crecer AGENTS.md o MEMORY.md por encima de su límite o romperse el puente de CLAUDE.md. Doctor ya diagnostica la máquina; con esta spec también diagnostica el arnés de un proyecto, en el mismo reporte y con el mismo contrato de estados y códigos de salida.

## Usuarios
- Desarrollador que quiere saber si un proyecto está listo para trabajar con agentes de IA.
- Scripts, CI y agentes que necesitan esa respuesta en JSON y con código de salida.

## Historias de usuario
- HU-1. Como desarrollador, quiero ver en el reporte de Doctor si el arnés de mi proyecto está completo y al día, para corregirlo antes de trabajar con un agente.
- HU-2. Como desarrollador, quiero que Doctor me diga qué hacer cuando falta el arnés (ejecutar Init), para no tener que recordarlo.
- HU-3. Como script o agente, quiero el diagnóstico del arnés en el mismo JSON de Doctor, para no tener que leer dos formatos.

## Definiciones
- **Arnés**: AGENTS.md, CLAUDE.md y MEMORY.md en la raíz del proyecto (como los crea la spec 002).
- **Proyecto**: la carpeta indicada con `-Project`.
- **Marcador pendiente**: el texto `[COMPLETAR]` dentro de AGENTS.md o MEMORY.md.
- **Líneas**: las líneas del archivo tal como las muestra un editor; un salto de línea al final no cuenta como línea extra.

## Requisitos funcionales
- RF-1: MIENTRAS no se indique `-Project`, EL SISTEMA se comporta exactamente como en la spec 001 (mismos checks, misma salida, mismo JSON).
- RF-2: CUANDO se ejecuta con `-Project <ruta>`, EL SISTEMA añade a los checks de la máquina tres checks de categoría HARNESS, uno por archivo del arnés: AGENTS.md, CLAUDE.md y MEMORY.md.
- RF-3: SI falta un archivo del arnés, ENTONCES EL SISTEMA marca su check como WARNING y el mensaje sugiere ejecutar DevForge Init.
- RF-4: SI CLAUDE.md existe pero no importa `@AGENTS.md` y `@MEMORY.md`, ENTONCES EL SISTEMA marca su check como WARNING e indica qué import falta.
- RF-5: SI AGENTS.md tiene más de 40 líneas o MEMORY.md más de 50, ENTONCES EL SISTEMA marca su check como WARNING e indica las líneas que tiene y el límite.
- RF-6: SI AGENTS.md o MEMORY.md contienen marcadores pendientes, ENTONCES EL SISTEMA marca su check como WARNING e indica cuántos quedan.
- RF-7: CUANDO un archivo del arnés existe y no tiene ninguno de los problemas anteriores, EL SISTEMA marca su check como OK.
- RF-8: SI un archivo tiene varios problemas, ENTONCES EL SISTEMA los informa todos en el mensaje de su check.
- RF-9: SI la ruta de `-Project` no existe o no es una carpeta, ENTONCES EL SISTEMA añade un único check HARNESS en ERROR que lo explica, en lugar de los tres checks de archivos.
- RF-10: EL SISTEMA incluye los checks HARNESS en el estado global, el resumen, el código de salida (spec 001, RF-6 y RF-7) y el JSON, con el mismo formato que el resto de checks.
- RF-11: CUANDO se ejecuta sin `-Json`, EL SISTEMA muestra los checks HARNESS en su propia sección, después de las de la máquina.
- RF-12: EL SISTEMA no modifica ningún archivo del proyecto (constitución, principio 1).
- RF-13: EL SISTEMA informa la versión 0.2.0 en el campo `version` del JSON, con o sin `-Project`.

## Requisitos no funcionales
- PowerShell 7+ y Windows PowerShell 5.1, sin módulos externos (igual que Doctor).
- El esquema JSON solo crece de forma aditiva: mismos campos de primer nivel y mismo formato de check; la novedad es la categoría `HARNESS`. Los consumidores actuales no se rompen.
- Los checks HARNESS no son requeridos (`Required = false`) salvo el ERROR de RF-9.

## Casos límite
- Proyecto sin ningún archivo del arnés → tres WARNING, cada uno sugiriendo Init.
- Archivo vacío → AGENTS.md o MEMORY.md vacíos son OK en líneas y marcadores (no hay problemas que informar); CLAUDE.md vacío es WARNING porque le faltan los dos imports.
- AGENTS.md con exactamente 40 líneas → OK; con 41 → WARNING.
- Archivo que termina sin salto de línea → se cuenta igual que con salto.
- Imports con espacios al final de la línea (`@AGENTS.md  `) → cuentan como import.
- Ruta con espacios o tildes → funciona igual.
- Archivos con BOM o en CRLF → se leen igual.

## Fuera de alcance
- Secretos expuestos, tests, CI y restos sospechosos (posibles specs futuras).
- Revisar la calidad del contenido más allá de marcadores, líneas e imports.
- Corregir el arnés (para eso está Init).
- Revisar varios proyectos a la vez.

## Criterios de finalización
- Todos los RF con al menos un test de Pester en verde, en pwsh y en 5.1 (CI).
- Los 77 tests actuales siguen en verde (RF-1).
- Ejecutado a mano sobre DevForge y sobre MedAlert, en consola y con `-Json`.
- MEMORY.md, CHANGELOG.md y la spec 001 (nota sobre `-Project`) actualizados.

## Decisiones de la clarificación (2026-10-03)
- Se ejecuta como `Doctor -Project <ruta>`, en el mismo reporte (cambio aditivo del JSON).
- Solo se revisan los archivos del arnés; secretos, tests, CI y restos quedan fuera.
- Que falte el arnés es WARNING; solo una ruta inválida es ERROR.
- Un check por archivo con todos sus problemas en el mensaje (RF-2, RF-8).
- Doctor pasa a la versión 0.2.0 (versión menor: añade funcionalidad sin romper nada) (RF-13).

## Dudas abiertas
- Ninguna.
