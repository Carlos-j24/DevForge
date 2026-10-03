function Write-DevForgeStatusLine {
    param(
        [Parameter(Mandatory)][string]$Status,
        [Parameter(Mandatory)][string]$Name,
        [string]$Version,
        [string]$Message
    )

    $icon = switch ($Status) {
        "OK"      { "[OK]" }
        "WARNING" { "[WARN]" }
        "ERROR"   { "[ERROR]" }
    }

    $versionText = if ($Version -and $Version -ne "N/A") { " $Version" } else { "" }
    Write-Host ("{0,-7} {1,-14}{2} {3}" -f $icon, $Name, $versionText, $Message)
}
