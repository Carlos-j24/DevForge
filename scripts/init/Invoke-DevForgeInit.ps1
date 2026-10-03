[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Path = ".",
    [switch]$Force
)

. (Join-Path $PSScriptRoot "Get-DevForgeProjectStack.ps1")
. (Join-Path $PSScriptRoot "New-DevForgeHarnessContent.ps1")
. (Join-Path $PSScriptRoot "Install-DevForgeHarnessFile.ps1")

$projectPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)

if (-not (Test-Path -LiteralPath $projectPath)) {
    Write-Host "[ERROR] La carpeta '$projectPath' no existe. No se ha creado nada." -ForegroundColor Red
    exit 2
}
if (-not (Test-Path -LiteralPath $projectPath -PathType Container)) {
    Write-Host "[ERROR] '$projectPath' no es una carpeta. No se ha creado nada." -ForegroundColor Red
    exit 2
}

$projectName = Split-Path -Leaf $projectPath.TrimEnd('\', '/')
$stacks = @(Get-DevForgeProjectStack -Path $projectPath)

$files = [ordered]@{
    "AGENTS.md" = New-DevForgeAgentsContent -ProjectName $projectName -Stacks $stacks
    "CLAUDE.md" = New-DevForgeClaudeContent
    "MEMORY.md" = New-DevForgeMemoryContent -ProjectName $projectName
}

$results = @()
$markers = 0
foreach ($name in $files.Keys) {
    try {
        $result = Install-DevForgeHarnessFile -Path (Join-Path $projectPath $name) -Content $files[$name] -Force:$Force -ErrorAction Stop
    } catch {
        Write-Host "[ERROR] No se pudo escribir $name : $($_.Exception.Message)" -ForegroundColor Red
        exit 2
    }
    $results += $result
    if ($result.Result -ne "Skipped") {
        $markers += ([regex]::Matches($files[$name], '\[COMPLETAR\]')).Count
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "          DEVFORGE INIT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Proyecto: $projectName ($projectPath)"
if ($WhatIfPreference) {
    Write-Host "Modo -WhatIf: no se ha escrito ningún archivo; esto es lo que haría." -ForegroundColor Yellow
}
Write-Host ""

foreach ($result in $results) {
    switch ($result.Result) {
        "Created"     { Write-Host ("{0,-14} {1}" -f "[CREADO]", $result.File) -ForegroundColor Green }
        "Overwritten" { Write-Host ("{0,-14} {1}" -f "[SOBRESCRITO]", $result.File) -ForegroundColor Yellow }
        "Skipped"     { Write-Host ("{0,-14} {1} (ya existe; usa -Force para sobrescribirlo)" -f "[OMITIDO]", $result.File) -ForegroundColor Yellow }
    }
}

$stackText = if ($stacks.Count -eq 0) { "ninguno" } else {
    ($stacks | ForEach-Object { if ($_.Folder -eq ".") { $_.Stack } else { "$($_.Stack) ($($_.Folder))" } }) -join ", "
}
Write-Host ""
Write-Host "Stacks detectados: $stackText"
Write-Host "Marcadores [COMPLETAR]: $markers"
Write-Host ""

if (@($results | Where-Object Result -eq "Skipped").Count -gt 0) { exit 1 }
exit 0
