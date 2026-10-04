# Tests de Doctor -Project (spec 003). Requiere Pester 5.5 o superior.
# Cada test crea un proyecto falso dentro de $TestDrive (carpeta temporal que Pester borra sola).

BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $repoRoot "scripts/core/DevForge-Types.ps1")
    . (Join-Path $repoRoot "scripts/doctor/Test-Harness.ps1")

    # Arnés válido mínimo: sin marcadores, dentro de los límites y con los dos imports.
    $validHarness = @{
        "AGENTS.md" = "# AGENTS.md — Demo`nProyecto de prueba.`n"
        "CLAUDE.md" = "# CLAUDE.md`n@AGENTS.md`n@MEMORY.md`n"
        "MEMORY.md" = "# MEMORY.md — Demo`n"
    }

    # Crea un proyecto falso con los archivos indicados (ruta relativa → contenido) y devuelve su ruta.
    function New-TestProject([hashtable]$Files = @{}) {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $root | Out-Null
        foreach ($relative in $Files.Keys) {
            [IO.File]::WriteAllText((Join-Path $root $relative), [string]$Files[$relative])
        }
        return $root
    }

    # Copia del arnés válido sin los archivos indicados.
    function Get-HarnessWithout([string[]]$Missing = @()) {
        $files = @{}
        foreach ($name in $validHarness.Keys) { if ($name -notin $Missing) { $files[$name] = $validHarness[$name] } }
        return $files
    }

    # Foto de una carpeta: ruta relativa, tamaño y fecha de cada archivo.
    function Get-Snapshot([string]$Root) {
        @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Sort-Object FullName | ForEach-Object {
            "{0}|{1}|{2}" -f $_.FullName.Substring($Root.Length), $_.Length, $_.LastWriteTimeUtc.Ticks
        })
    }
}

Describe "Test-DevForgeHarness: existencia y caso OK (RF-2, RF-3, RF-7, RF-12)" {
    It "RF-2: devuelve tres checks HARNESS en orden y no requeridos" {
        $checks = @(Test-DevForgeHarness -Path (New-TestProject $validHarness))
        $checks.Id | Should -Be @("harness-agents", "harness-claude", "harness-memory")
        $checks.Name | Should -Be @("AGENTS.md", "CLAUDE.md", "MEMORY.md")
        $checks.Category | Sort-Object -Unique | Should -Be "HARNESS"
        $checks.Required | Sort-Object -Unique | Should -Be $false
    }

    It "RF-7: un arnés completo y correcto da tres OK" {
        $checks = @(Test-DevForgeHarness -Path (New-TestProject $validHarness))
        $checks.Status | Should -Be @("OK", "OK", "OK")
        $checks.Installed | Sort-Object -Unique | Should -Be $true
        $checks[0].Message | Should -Be "Completo (2 líneas)."
    }

    It "RF-3: si falta <Archivo> su check es WARNING y sugiere Init; los demás siguen OK" -ForEach @(
        @{ Archivo = "AGENTS.md"; Indice = 0 }
        @{ Archivo = "CLAUDE.md"; Indice = 1 }
        @{ Archivo = "MEMORY.md"; Indice = 2 }
    ) {
        $checks = @(Test-DevForgeHarness -Path (New-TestProject (Get-HarnessWithout @($Archivo))))
        $checks[$Indice].Status | Should -Be "WARNING"
        $checks[$Indice].Installed | Should -BeFalse
        $checks[$Indice].Message | Should -Match "DevForge Init"
        @($checks | Where-Object Status -eq "OK").Count | Should -Be 2
    }

    It "RF-3: un proyecto sin arnés da tres WARNING" {
        @(Test-DevForgeHarness -Path (New-TestProject)).Status | Should -Be @("WARNING", "WARNING", "WARNING")
    }

    It "RF-12: no modifica ningún archivo del proyecto" {
        $project = New-TestProject ((Get-HarnessWithout @("MEMORY.md")) + @{ "README.md" = "# Demo" })
        $before = Get-Snapshot $project
        Test-DevForgeHarness -Path $project | Out-Null
        Get-Snapshot $project | Should -Be $before
    }
}

Describe "Test-DevForgeHarness: imports de CLAUDE.md (RF-4)" {
    BeforeAll {
        # Revisa un proyecto con el arnés válido pero el CLAUDE.md indicado y devuelve su check.
        function Get-ClaudeCheck([string]$Claude) {
            $files = Get-HarnessWithout
            $files["CLAUDE.md"] = $Claude
            return @(Test-DevForgeHarness -Path (New-TestProject $files))[1]
        }
    }

    It "RF-4: si falta <Falta> es WARNING y nombra solo ese import" -ForEach @(
        @{ Falta = "@AGENTS.md"; Otro = "@MEMORY.md" }
        @{ Falta = "@MEMORY.md"; Otro = "@AGENTS.md" }
    ) {
        $check = Get-ClaudeCheck "# CLAUDE.md`n$Otro`n"
        $check.Status | Should -Be "WARNING"
        $check.Message | Should -Match ([regex]::Escape("falta el import $Falta"))
        $check.Message | Should -Not -Match ([regex]::Escape("falta el import $Otro"))
    }

    It "RF-4: si faltan los dos nombra ambos" {
        $check = Get-ClaudeCheck "# CLAUDE.md`nSolo texto.`n"
        $check.Status | Should -Be "WARNING"
        $check.Message | Should -Match ([regex]::Escape("falta el import @AGENTS.md"))
        $check.Message | Should -Match ([regex]::Escape("falta el import @MEMORY.md"))
    }

    It "un CLAUDE.md vacío es WARNING porque le faltan los dos imports" {
        $check = Get-ClaudeCheck ""
        $check.Status | Should -Be "WARNING"
        $check.Message | Should -Match ([regex]::Escape("falta el import @AGENTS.md"))
        $check.Message | Should -Match ([regex]::Escape("falta el import @MEMORY.md"))
    }

    It "un import con espacios al final cuenta" {
        (Get-ClaudeCheck "# CLAUDE.md`n@AGENTS.md  `n@MEMORY.md`t`n").Status | Should -Be "OK"
    }

    It "los imports con saltos de línea CRLF cuentan" {
        (Get-ClaudeCheck "# CLAUDE.md`r`n@AGENTS.md`r`n@MEMORY.md`r`n").Status | Should -Be "OK"
    }

    It "un @AGENTS.md dentro de una frase no cuenta como import" {
        $check = Get-ClaudeCheck "# CLAUDE.md`nLas reglas están en @AGENTS.md y nada más.`n@MEMORY.md`n"
        $check.Status | Should -Be "WARNING"
        $check.Message | Should -Match ([regex]::Escape("falta el import @AGENTS.md"))
    }
}

Describe "Test-DevForgeHarness: líneas, marcadores y varios problemas (RF-5, RF-6, RF-8)" {
    BeforeAll {
        # Texto de N líneas, cada una terminada en salto de línea.
        function New-Lines([int]$Count, [string]$Newline = "`n") {
            if ($Count -eq 0) { return "" }
            return ((1..$Count | ForEach-Object { "línea $_" }) -join $Newline) + $Newline
        }
        # Revisa un proyecto con el arnés válido pero con el archivo indicado cambiado.
        function Get-HarnessCheck([string]$Name, [string]$Text) {
            $files = Get-HarnessWithout
            $files[$Name] = $Text
            $index = @{ "AGENTS.md" = 0; "CLAUDE.md" = 1; "MEMORY.md" = 2 }[$Name]
            return @(Test-DevForgeHarness -Path (New-TestProject $files))[$index]
        }
    }

    It "RF-5: <Archivo> con <Lineas> líneas es <Estado>" -ForEach @(
        @{ Archivo = "AGENTS.md"; Lineas = 40; Estado = "OK" }
        @{ Archivo = "AGENTS.md"; Lineas = 41; Estado = "WARNING" }
        @{ Archivo = "MEMORY.md"; Lineas = 50; Estado = "OK" }
        @{ Archivo = "MEMORY.md"; Lineas = 51; Estado = "WARNING" }
    ) {
        (Get-HarnessCheck $Archivo (New-Lines $Lineas)).Status | Should -Be $Estado
    }

    It "RF-5: el mensaje indica las líneas y el límite" {
        (Get-HarnessCheck "AGENTS.md" (New-Lines 41)).Message | Should -Be "41 líneas (máximo 40)"
        (Get-HarnessCheck "MEMORY.md" (New-Lines 51)).Message | Should -Be "51 líneas (máximo 50)"
    }

    It "RF-6: cuenta los marcadores [COMPLETAR] de <Archivo>" -ForEach @(
        @{ Archivo = "AGENTS.md" }
        @{ Archivo = "MEMORY.md" }
    ) {
        $check = Get-HarnessCheck $Archivo "# Título`n- [COMPLETAR] uno`n- [COMPLETAR] dos`n"
        $check.Status | Should -Be "WARNING"
        $check.Message | Should -Be "2 marcador(es) [COMPLETAR]"
    }

    It "CLAUDE.md no tiene límite de líneas ni se revisan sus marcadores" {
        $claude = "@AGENTS.md`n@MEMORY.md`n[COMPLETAR]`n" + (New-Lines 60)
        (Get-HarnessCheck "CLAUDE.md" $claude).Status | Should -Be "OK"
    }

    It "RF-8: un archivo con varios problemas los informa todos" {
        $check = Get-HarnessCheck "AGENTS.md" ((New-Lines 40) + "[COMPLETAR] descripción`n")
        $check.Status | Should -Be "WARNING"
        $check.Message | Should -Be "41 líneas (máximo 40); 1 marcador(es) [COMPLETAR]"
    }

    It "un AGENTS.md o MEMORY.md vacío es OK" {
        (Get-HarnessCheck "AGENTS.md" "").Status | Should -Be "OK"
        (Get-HarnessCheck "MEMORY.md" "").Status | Should -Be "OK"
    }

    It "el recuento no cambia con <Caso>" -ForEach @(
        @{ Caso = "salto final"; Texto = "a`nb`n"; Esperado = 2 }
        @{ Caso = "sin salto final"; Texto = "a`nb"; Esperado = 2 }
        @{ Caso = "CRLF"; Texto = "a`r`nb`r`n"; Esperado = 2 }
        @{ Caso = "una línea vacía"; Texto = "`n"; Esperado = 1 }
        @{ Caso = "texto vacío"; Texto = ""; Esperado = 0 }
    ) {
        Get-DevForgeHarnessLineCount -Text $Texto | Should -Be $Esperado
    }

    It "un archivo con BOM y CRLF se cuenta igual (40 líneas es OK, 41 no)" {
        $project = New-TestProject (Get-HarnessWithout)
        $bom = New-Object Text.UTF8Encoding $true
        [IO.File]::WriteAllText((Join-Path $project "AGENTS.md"), (New-Lines 40 "`r`n"), $bom)
        @(Test-DevForgeHarness -Path $project)[0].Status | Should -Be "OK"
        [IO.File]::WriteAllText((Join-Path $project "AGENTS.md"), (New-Lines 41 "`r`n"), $bom)
        @(Test-DevForgeHarness -Path $project)[0].Message | Should -Be "41 líneas (máximo 40)"
    }
}

Describe "Test-DevForgeHarness: ruta inválida (RF-9)" {
    It "acepta una ruta relativa a la ubicación actual de PowerShell" {
        $project = New-TestProject (Get-HarnessWithout @("CLAUDE.md"))
        Push-Location -LiteralPath $project
        try { $checks = @(Test-DevForgeHarness -Path ".") } finally { Pop-Location }
        $checks.Status | Should -Be @("OK", "WARNING", "OK")
    }

    It "RF-9: una ruta que no existe da un único check ERROR y no crea la carpeta" {
        $missing = Join-Path $TestDrive "no-existe-$(Get-Random)"
        $checks = @(Test-DevForgeHarness -Path $missing)
        $checks.Count | Should -Be 1
        $checks[0].Id | Should -Be "harness-project"
        $checks[0].Category | Should -Be "HARNESS"
        $checks[0].Status | Should -Be "ERROR"
        $checks[0].Required | Should -BeTrue
        $checks[0].Message | Should -Match "no existe"
        $missing | Should -Not -Exist
    }

    It "RF-9: una ruta que es un archivo da un único check ERROR" {
        $file = Join-Path (New-TestProject @{ "notas.txt" = "" }) "notas.txt"
        $checks = @(Test-DevForgeHarness -Path $file)
        $checks.Count | Should -Be 1
        $checks[0].Status | Should -Be "ERROR"
        $checks[0].Message | Should -Match "no es una carpeta"
    }
}

Describe "Invoke-DevForgeDoctor.ps1 -Project (RF-1, RF-10, RF-11, RF-13)" {
    BeforeAll {
        $doctorScript = Join-Path $repoRoot "scripts/doctor/Invoke-DevForgeDoctor.ps1"
        $pwshPath = (Get-Process -Id $PID).Path

        # Ejecuta Doctor en un proceso hijo (misma versión de PowerShell) y devuelve salida, JSON y código.
        function Invoke-Doctor([string[]]$Arguments, [string]$WorkingDirectory = $PWD.Path) {
            Push-Location -LiteralPath $WorkingDirectory
            try { $output = & $pwshPath -NoProfile -File $doctorScript @Arguments 2>&1; $code = $LASTEXITCODE }
            finally { Pop-Location }
            $text = $output -join "`n"
            $json = if ($Arguments -contains "-Json") { $text | ConvertFrom-Json } else { $null }
            [PSCustomObject]@{ Output = $text; Json = $json; ExitCode = $code }
        }

        $expectedExit = @{ OK = 0; WARNING = 1; ERROR = 2 }
    }

    It "RF-10, RF-13: con -Project -Json incluye los checks HARNESS, la versión 0.2.0 y un resumen coherente" {
        $run = Invoke-Doctor @("-Project", (New-TestProject (Get-HarnessWithout @("MEMORY.md"))), "-Json")
        $harness = @($run.Json.checks | Where-Object Category -eq "HARNESS")
        $harness.Id | Should -Be @("harness-agents", "harness-claude", "harness-memory")
        $harness[2].Status | Should -Be "WARNING"
        $run.Json.version | Should -Be "0.2.0"
        $run.Json.summary.ok + $run.Json.summary.warnings + $run.Json.summary.errors | Should -Be $run.Json.checks.Count
        $run.Json.status | Should -Not -Be "OK"
        $run.ExitCode | Should -Be $expectedExit[$run.Json.status]
    }

    It "RF-10: un proyecto inexistente deja el estado en ERROR y sale con 2" {
        $run = Invoke-Doctor @("-Project", (Join-Path $TestDrive "no-existe-$(Get-Random)"), "-Json")
        @($run.Json.checks | Where-Object Id -eq "harness-project").Status | Should -Be "ERROR"
        $run.Json.status | Should -Be "ERROR"
        $run.ExitCode | Should -Be 2
    }

    It "RF-1, RF-13: sin -Project no aparece ningún check HARNESS y la versión es 0.2.0" {
        $run = Invoke-Doctor @("-Json")
        @($run.Json.checks | Where-Object Category -eq "HARNESS").Count | Should -Be 0
        $run.Json.version | Should -Be "0.2.0"
    }

    It "RF-11: en consola muestra la sección HARNESS con el nombre del proyecto" {
        $project = Join-Path (New-TestProject) "Mi Proyecto Clínica"
        New-Item -ItemType Directory -Path $project | Out-Null
        foreach ($name in $validHarness.Keys) { [IO.File]::WriteAllText((Join-Path $project $name), $validHarness[$name]) }
        $run = Invoke-Doctor @("-Project", $project)
        $run.Output | Should -Match 'HARNESS \(Mi Proyecto Cl'
        $run.Output | Should -Match '\[OK\]\s+AGENTS\.md'
    }

    It "acepta una ruta relativa al directorio actual" {
        $project = New-TestProject (Get-HarnessWithout @("CLAUDE.md"))
        $run = Invoke-Doctor @("-Project", ".", "-Json") -WorkingDirectory $project
        @($run.Json.checks | Where-Object Category -eq "HARNESS").Status | Should -Be @("OK", "WARNING", "OK")
    }
}
