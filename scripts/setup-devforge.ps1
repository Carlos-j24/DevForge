# ==========================================
# DevForge Initializer
# Version: 0.1.0-alpha
# ==========================================

Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "        DEVFORGE INITIALIZER" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function Test-Tool {

    param (
        [string]$Name,
        [string]$Command,
        [string]$VersionCommand
    )

    if (Get-Command $Command -ErrorAction SilentlyContinue) {

        try {

            $version = Invoke-Expression $VersionCommand 2>$null

            if ($version -is [array]) {
                $version = $version[0]
            }

        }
        catch {

            $version = "Unknown"

        }

        Write-Host "[OK] $Name" -ForegroundColor Green

        return [PSCustomObject]@{

            Name    = $Name
            Status  = "OK"
            Version = $version

        }

    }

    Write-Host "[MISSING] $Name" -ForegroundColor Red

    return [PSCustomObject]@{

        Name    = $Name
        Status  = "Missing"
        Version = "-"

    }

}
$results = @()

$results += Test-Tool "Git" "git" "git --version"
$results += Test-Tool "VS Code" "code" "code --version"
$results += Test-Tool "Python" "python" "python --version"
$results += Test-Tool "Node.js" "node" "node --version"
$results += Test-Tool "Docker" "docker" "docker --version"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Environment Status" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$results | Format-Table -AutoSize

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "DevForge Ready!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
