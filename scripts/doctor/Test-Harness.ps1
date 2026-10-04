function Get-DevForgeHarnessLineCount {
    param([AllowEmptyString()][string]$Text)

    # Líneas como las muestra un editor: el salto de línea final no cuenta como línea extra.
    if (-not $Text) { return 0 }
    $lines = $Text -split "\r?\n"
    if ($lines[-1] -eq "") { return $lines.Count - 1 }
    return $lines.Count
}

function Test-DevForgeHarness {
    param([Parameter(Mandatory)][string]$Path)

    # .NET no conoce la ubicación actual de PowerShell: se trabaja con la ruta absoluta.
    $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

    # Ruta inválida: un único ERROR en vez de cortar Doctor, para que el JSON siga completo.
    $pathProblem = if (-not (Test-Path -LiteralPath $Path)) { "La carpeta '$Path' no existe." }
        elseif (-not (Test-Path -LiteralPath $Path -PathType Container)) { "'$Path' no es una carpeta." }
    if ($pathProblem) {
        return @(New-DevForgeToolCheck -Id "harness-project" -Name "Proyecto" -Category "HARNESS" `
            -Installed $false -Version "N/A" -Required $true -Status "ERROR" -Message $pathProblem)
    }

    $files = @(
        # Límites de líneas iguales a los de la spec 002 (Init); CLAUDE.md no tiene límite.
        @{ Id = "harness-agents"; Name = "AGENTS.md"; MaxLines = 40 }
        @{ Id = "harness-claude"; Name = "CLAUDE.md"; MaxLines = $null }
        @{ Id = "harness-memory"; Name = "MEMORY.md"; MaxLines = 50 }
    )

    $checks = @()
    foreach ($file in $files) {
        $filePath = Join-Path $Path $file.Name

        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            $checks += New-DevForgeToolCheck -Id $file.Id -Name $file.Name -Category "HARNESS" `
                -Installed $false -Version "N/A" -Required $false -Status "WARNING" `
                -Message "No existe: ejecuta DevForge Init en el proyecto."
            continue
        }

        # Solo lectura (constitución, principio 1). UTF-8 acepta también archivos con BOM.
        $text = [IO.File]::ReadAllText($filePath, [Text.Encoding]::UTF8)
        $lineCount = Get-DevForgeHarnessLineCount -Text $text
        $problems = @()

        # Un import solo cuenta si ocupa su propia línea (así lo lee Claude Code).
        if ($file.Name -eq "CLAUDE.md") {
            $lines = @($text -split "\r?\n" | ForEach-Object { $_.Trim() })
            foreach ($import in @("@AGENTS.md", "@MEMORY.md")) {
                if ($lines -notcontains $import) { $problems += "falta el import $import" }
            }
        }

        if ($file.MaxLines -and $lineCount -gt $file.MaxLines) {
            $problems += "$lineCount líneas (máximo $($file.MaxLines))"
        }

        # Los marcadores solo tienen sentido en AGENTS.md y MEMORY.md (CLAUDE.md es solo el puente).
        if ($file.Name -ne "CLAUDE.md") {
            $markers = ([regex]::Matches($text, '\[COMPLETAR\]')).Count
            if ($markers -gt 0) { $problems += "$markers marcador(es) [COMPLETAR]" }
        }

        if ($problems.Count -eq 0) {
            $checks += New-DevForgeToolCheck -Id $file.Id -Name $file.Name -Category "HARNESS" `
                -Installed $true -Version "N/A" -Required $false -Status "OK" `
                -Message "Completo ($lineCount líneas)."
        } else {
            $checks += New-DevForgeToolCheck -Id $file.Id -Name $file.Name -Category "HARNESS" `
                -Installed $true -Version "N/A" -Required $false -Status "WARNING" `
                -Message ($problems -join "; ")
        }
    }

    return $checks
}
