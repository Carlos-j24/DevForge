# DEVFORGE-001 — DevForge Doctor

## Objetivo
Diagnosticar el entorno de desarrollo sin instalar ni modificar componentes.

## Flujo
`DETECT → VALIDATE → REPORT`

## Ejecución
```powershell
.\Invoke-DevForgeDoctor.ps1
```

JSON:
```powershell
.\Invoke-DevForgeDoctor.ps1 -Json
```

## Estados
- `OK`: componente disponible.
- `WARNING`: componente opcional ausente o información incompleta.
- `ERROR`: componente requerido ausente o no disponible.

## Códigos de salida
- `0`: READY
- `1`: READY WITH WARNINGS
- `2`: NOT READY

## Componentes iniciales
| Categoría | Componente | Requerido |
|---|---|---|
| CORE | Git | Sí |
| CORE | PowerShell 7+ | Sí |
| EDITOR | VS Code | Sí |
| LANGUAGE | Python | Sí |
| LANGUAGE | Node.js | Sí |
| CONTAINER | Docker | No |
| AI | Ollama | No |

## Próxima evolución
1. Validación de versiones mínimas.
2. Diagnóstico del proyecto actual.
3. Reportes HTML.
4. CLI `devforge doctor`.
5. Modo `--fix` con acciones explícitas y seguras.
