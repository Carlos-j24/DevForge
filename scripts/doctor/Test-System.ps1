function Test-DevForgeSystem {
    $checks = @()

    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        try {
            $version = (& pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null).Trim()
            $checks += New-DevForgeToolCheck -Id "powershell" -Name "PowerShell" -Category "CORE" `
                -Installed $true -Version $version -Required $true -Status "OK" `
                -Message "PowerShell 7+ disponible."
        } catch {
            $checks += New-DevForgeToolCheck -Id "powershell" -Name "PowerShell" -Category "CORE" `
                -Installed $true -Version "N/A" -Required $true -Status "WARNING" `
                -Message "pwsh existe, pero no fue posible consultar la versión."
        }
    } else {
        $checks += New-DevForgeToolCheck -Id "powershell" -Name "PowerShell" -Category "CORE" `
            -Installed $false -Version "N/A" -Required $true -Status "ERROR" `
            -Message "PowerShell 7+ (pwsh) no está disponible."
    }

    return $checks
}
