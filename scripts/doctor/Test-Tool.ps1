function Test-DevForgeTool {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Category,
        [Parameter(Mandatory)][string]$Command,
        [bool]$Required = $true,
        [string]$VersionArgument = "--version"
    )

    $commandInfo = Get-Command $Command -ErrorAction SilentlyContinue

    if (-not $commandInfo) {
        $status = if ($Required) { "ERROR" } else { "WARNING" }
        return New-DevForgeToolCheck `
            -Id $Id -Name $Name -Category $Category `
            -Installed $false -Version "N/A" -Required $Required `
            -Status $status `
            -Message $(if ($Required) { "No está instalado o no está disponible en PATH." } else { "No instalado (opcional)." })
    }

    try {
        $rawVersion = (& $Command $VersionArgument 2>&1 | Select-Object -First 1 | Out-String).Trim()
        $version = if ($rawVersion) { $rawVersion } else { "Detectado" }

        return New-DevForgeToolCheck `
            -Id $Id -Name $Name -Category $Category `
            -Installed $true -Version $version -Required $Required `
            -Status "OK" -Message "Disponible en PATH."
    }
    catch {
        return New-DevForgeToolCheck `
            -Id $Id -Name $Name -Category $Category `
            -Installed $true -Version "N/A" -Required $Required `
            -Status "WARNING" -Message "Está instalado, pero no fue posible obtener su versión."
    }
}
