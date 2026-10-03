[CmdletBinding()]
param(
    [switch]$Json
)

$scriptRoot = Split-Path -Parent $PSScriptRoot
$corePath = Join-Path $scriptRoot "core"

. (Join-Path $corePath "DevForge-Types.ps1")
. (Join-Path $corePath "Write-DevForgeMessage.ps1")
. (Join-Path $PSScriptRoot "Test-Tool.ps1")
. (Join-Path $PSScriptRoot "Test-System.ps1")

$checks = @()
$checks += Test-DevForgeSystem

$checks += Test-DevForgeTool -Id "git" -Name "Git" -Category "CORE" -Command "git" -Required $true
$checks += Test-DevForgeTool -Id "vscode" -Name "VS Code" -Category "EDITOR" -Command "code" -Required $true
$checks += Test-DevForgeTool -Id "python" -Name "Python" -Category "LANGUAGE" -Command "python" -Required $true
$checks += Test-DevForgeTool -Id "node" -Name "Node.js" -Category "LANGUAGE" -Command "node" -Required $true
$checks += Test-DevForgeTool -Id "docker" -Name "Docker" -Category "CONTAINER" -Command "docker" -Required $false
$checks += Test-DevForgeTool -Id "ollama" -Name "Ollama" -Category "AI" -Command "ollama" -Required $false

$globalStatus = Get-DevForgeGlobalStatus -Checks $checks
$ok = @($checks | Where-Object Status -eq "OK").Count
$warnings = @($checks | Where-Object Status -eq "WARNING").Count
$errors = @($checks | Where-Object Status -eq "ERROR").Count

if ($Json) {
    [PSCustomObject]@{
        tool = "DevForge Doctor"
        version = "0.1.0"
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        status = $globalStatus
        summary = [PSCustomObject]@{ ok=$ok; warnings=$warnings; errors=$errors }
        checks = $checks
    } | ConvertTo-Json -Depth 5
    if ($globalStatus -eq "ERROR") { exit 2 }
    if ($globalStatus -eq "WARNING") { exit 1 }
    exit 0
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "          DEVFORGE DOCTOR" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($category in @("CORE","EDITOR","LANGUAGE","CONTAINER","AI")) {
    $categoryChecks = @($checks | Where-Object Category -eq $category)
    if ($categoryChecks.Count -eq 0) { continue }

    $title = switch ($category) {
        "LANGUAGE" { "LANGUAGES" }
        default { $category }
    }

    Write-Host $title -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    foreach ($check in $categoryChecks) {
        Write-DevForgeStatusLine -Status $check.Status -Name $check.Name -Version $check.Version -Message $check.Message
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GLOBAL STATUS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

switch ($globalStatus) {
    "OK"      { Write-Host "[OK] READY" -ForegroundColor Green }
    "WARNING" { Write-Host "[WARN] READY WITH WARNINGS" -ForegroundColor Yellow }
    "ERROR"   { Write-Host "[ERROR] NOT READY" -ForegroundColor Red }
}

Write-Host ""
Write-Host "$ok OK"
Write-Host "$warnings WARNING"
Write-Host "$errors ERROR"
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($globalStatus -eq "ERROR") { exit 2 }
if ($globalStatus -eq "WARNING") { exit 1 }
exit 0
