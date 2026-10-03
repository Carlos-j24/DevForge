# Tests de DevForge Doctor (spec 001). Requiere Pester 5.5 o superior (probado con 6.2):
#   Install-Module Pester -MinimumVersion 5.5 -Force -SkipPublisherCheck -Scope CurrentUser
#   Invoke-Pester ./tests -Output Detailed

BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $repoRoot "scripts/core/DevForge-Types.ps1")
    . (Join-Path $repoRoot "scripts/doctor/Test-Tool.ps1")
    $doctorScript = Join-Path $repoRoot "scripts/doctor/Invoke-DevForgeDoctor.ps1"
    $pwshPath = (Get-Process -Id $PID).Path
}

Describe "New-DevForgeToolCheck" {
    It "usa 'N/A' cuando no hay versión" {
        $check = New-DevForgeToolCheck -Id "x" -Name "X" -Category "CORE" -Installed $false `
            -Version "" -Required $true -Status "ERROR" -Message "m"
        $check.Version | Should -Be "N/A"
    }

    It "expone todas las propiedades del contrato ToolCheck" {
        $check = New-DevForgeToolCheck -Id "x" -Name "X" -Category "CORE" -Installed $true `
            -Version "1.0" -Required $true -Status "OK" -Message "m"
        $check.PSObject.Properties.Name |
            Should -Be @("Id", "Name", "Category", "Installed", "Version", "Required", "Status", "Message")
    }

    It "rechaza estados fuera de OK/WARNING/ERROR" {
        { New-DevForgeToolCheck -Id "x" -Name "X" -Category "CORE" -Installed $true `
            -Version "1.0" -Required $true -Status "MAYBE" -Message "m" } | Should -Throw
    }
}

Describe "Get-DevForgeGlobalStatus (RF-6)" {
    BeforeAll {
        function New-Check([string]$Status) { [PSCustomObject]@{ Status = $Status } }
    }

    It "devuelve ERROR si hay al menos un ERROR" {
        Get-DevForgeGlobalStatus -Checks @((New-Check OK), (New-Check WARNING), (New-Check ERROR)) |
            Should -Be "ERROR"
    }

    It "devuelve WARNING si no hay ERROR pero sí WARNING" {
        Get-DevForgeGlobalStatus -Checks @((New-Check OK), (New-Check WARNING)) | Should -Be "WARNING"
    }

    It "devuelve OK si todo está OK" {
        Get-DevForgeGlobalStatus -Checks @((New-Check OK), (New-Check OK)) | Should -Be "OK"
    }
}

Describe "Test-DevForgeTool" {
    BeforeAll {
        function global:devforge-fake-ok { "fake-tool 1.2.3"; "segunda línea" }
        function global:devforge-fake-empty { }
        function global:devforge-fake-broken { throw "sin versión" }
        $missing = "devforge-comando-que-no-existe-$(Get-Random)"
    }

    AfterAll {
        Remove-Item function:global:devforge-fake-ok, function:global:devforge-fake-empty,
            function:global:devforge-fake-broken -ErrorAction SilentlyContinue
    }

    It "RF-2: marca OK y usa solo la primera línea de la versión" {
        $check = Test-DevForgeTool -Id "f" -Name "Fake" -Category "CORE" -Command "devforge-fake-ok"
        $check.Status | Should -Be "OK"
        $check.Installed | Should -BeTrue
        $check.Version | Should -Be "fake-tool 1.2.3"
    }

    It "RF-2: usa 'Detectado' si la versión sale vacía" {
        $check = Test-DevForgeTool -Id "f" -Name "Fake" -Category "CORE" -Command "devforge-fake-empty"
        $check.Status | Should -Be "OK"
        $check.Version | Should -Be "Detectado"
    }

    It "RF-3: marca ERROR si falta un componente requerido" {
        $check = Test-DevForgeTool -Id "m" -Name "Missing" -Category "CORE" -Command $missing -Required $true
        $check.Status | Should -Be "ERROR"
        $check.Installed | Should -BeFalse
    }

    It "RF-4: marca WARNING si falta un componente opcional" {
        $check = Test-DevForgeTool -Id "m" -Name "Missing" -Category "AI" -Command $missing -Required $false
        $check.Status | Should -Be "WARNING"
    }

    It "RF-5: marca WARNING si existe pero no se obtiene la versión" {
        $check = Test-DevForgeTool -Id "b" -Name "Broken" -Category "CORE" -Command "devforge-fake-broken"
        $check.Status | Should -Be "WARNING"
        $check.Installed | Should -BeTrue
    }
}

Describe "Invoke-DevForgeDoctor -Json (RF-1, RF-7, RF-8)" {
    BeforeAll {
        $raw = & $pwshPath -NoProfile -File $doctorScript -Json
        $exitCode = $LASTEXITCODE
        $report = ($raw -join "`n") | ConvertFrom-Json
    }

    It "RF-8: imprime JSON válido con el esquema acordado" {
        $report.PSObject.Properties.Name | Should -Be @("tool", "version", "timestamp", "status", "summary", "checks")
        $report.status | Should -BeIn @("OK", "WARNING", "ERROR")
        $report.summary.ok + $report.summary.warnings + $report.summary.errors | Should -Be $report.checks.Count
    }

    It "RF-8: el timestamp está en UTC (ISO 8601)" {
        # Se valida el texto crudo: ConvertFrom-Json convierte la fecha a DateTime y pierde la "Z".
        ($raw -join "`n") | Should -Match '"timestamp":\s*"\d{4}-\d{2}-\d{2}T[\d:.]+Z"'
    }

    It "RF-1: comprueba los siete componentes" {
        $report.checks.Id | Sort-Object |
            Should -Be @("docker", "git", "node", "ollama", "powershell", "python", "vscode")
    }

    It "RF-7: el código de salida corresponde al estado global" {
        $expected = @{ OK = 0; WARNING = 1; ERROR = 2 }[$report.status]
        $exitCode | Should -Be $expected
    }
}
