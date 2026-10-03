function Expand-DevForgeHarnessTemplate {
    param(
        [Parameter(Mandatory)][string]$Name,
        [hashtable]$Values = @{}
    )

    $templatePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "templates/harness/$Name"
    $text = [IO.File]::ReadAllText($templatePath, [Text.Encoding]::UTF8)

    # Reemplazo literal (no regex): el nombre del proyecto puede traer "$1", paréntesis, etc.
    foreach ($key in $Values.Keys) {
        $text = $text.Replace("{{$key}}", [string]$Values[$key])
    }
    return $text
}

function New-DevForgeClaudeContent {
    return Expand-DevForgeHarnessTemplate -Name "CLAUDE.md"
}

function New-DevForgeMemoryContent {
    param([Parameter(Mandatory)][string]$ProjectName)

    return Expand-DevForgeHarnessTemplate -Name "MEMORY.md" -Values @{ PROJECT_NAME = $ProjectName }
}

function New-DevForgeAgentsContent {
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [AllowEmptyCollection()][object[]]$Stacks = @()
    )

    # Texto " (en `carpeta/`)" o " (desde `carpeta/`)"; vacío si es la raíz.
    $folderNote = { param($stack, $word) if ($stack.Folder -eq ".") { "" } else { " ($word ``$($stack.Folder)/``)" } }

    $stackLines = @($Stacks | ForEach-Object { "- $($_.Stack)$(& $folderNote $_ 'en')" })
    if ($stackLines.Count -eq 0) {
        $stackLines = @("- [COMPLETAR] Lenguajes, frameworks y estructura de carpetas.")
    }

    $commandLines = @($Stacks | Where-Object { $_.TestCommand } |
        ForEach-Object { "- Tests $($_.Stack): ``$($_.TestCommand)``$(& $folderNote $_ 'desde')" })
    if ($commandLines.Count -eq 0) {
        $commandLines = @("- [COMPLETAR] Cómo instalar dependencias, ejecutar el proyecto y correr los tests.")
    }

    return Expand-DevForgeHarnessTemplate -Name "AGENTS.md" -Values @{
        PROJECT_NAME = $ProjectName
        STACK        = $stackLines -join "`n"
        COMMANDS     = $commandLines -join "`n"
    }
}
