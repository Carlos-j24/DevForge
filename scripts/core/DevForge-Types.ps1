function New-DevForgeToolCheck {
    param(
        [string]$Id,
        [string]$Name,
        [string]$Category,
        [bool]$Installed,
        [string]$Version,
        [bool]$Required,
        [ValidateSet("OK","WARNING","ERROR")][string]$Status,
        [string]$Message
    )

    [PSCustomObject]@{
        Id        = $Id
        Name      = $Name
        Category  = $Category
        Installed = $Installed
        Version   = if ($Version) { $Version } else { "N/A" }
        Required  = $Required
        Status    = $Status
        Message   = $Message
    }
}

function Get-DevForgeGlobalStatus {
    param([array]$Checks)

    $errors = @($Checks | Where-Object Status -eq "ERROR").Count
    $warnings = @($Checks | Where-Object Status -eq "WARNING").Count

    if ($errors -gt 0) { return "ERROR" }
    if ($warnings -gt 0) { return "WARNING" }
    return "OK"
}
