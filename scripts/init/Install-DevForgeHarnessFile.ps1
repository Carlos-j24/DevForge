function Install-DevForgeHarnessFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content,
        [switch]$Force
    )

    # .NET no conoce la ubicación actual de PowerShell: se trabaja con la ruta absoluta.
    $fullPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
    $exists = Test-Path -LiteralPath $fullPath -PathType Leaf
    $dryRun = [bool]$WhatIfPreference

    $result = if (-not $exists) { "Created" } elseif ($Force) { "Overwritten" } else { "Skipped" }

    if ($result -ne "Skipped") {
        $action = if ($result -eq "Created") { "Crear archivo" } else { "Sobrescribir archivo" }
        if ($PSCmdlet.ShouldProcess($fullPath, $action)) {
            # UTF-8 sin BOM: el BOM solo hace falta en los .ps1, no en los .md.
            [IO.File]::WriteAllText($fullPath, $Content, (New-Object Text.UTF8Encoding $false))
        } else {
            $dryRun = $true
        }
    }

    [PSCustomObject]@{
        File   = Split-Path -Leaf $fullPath
        Result = $result
        DryRun = $dryRun
    }
}
