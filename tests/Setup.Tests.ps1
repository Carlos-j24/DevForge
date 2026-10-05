# Tests de scripts/setup-devforge.ps1: es un atajo a DevForge Doctor. Requiere Pester 5.5 o superior.

BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $setupScript = Join-Path $repoRoot "scripts/setup-devforge.ps1"
    $pwshPath = (Get-Process -Id $PID).Path
}

Describe "setup-devforge.ps1" {
    It "ejecuta Doctor: pasa los parámetros y devuelve su código de salida" {
        $output = & $pwshPath -NoProfile -File $setupScript -Json 2>&1
        $code = $LASTEXITCODE
        $report = ($output -join "`n") | ConvertFrom-Json
        $report.tool | Should -Be "DevForge Doctor"
        $code | Should -Be (@{ OK = 0; WARNING = 1; ERROR = 2 }[$report.status])
    }
}
