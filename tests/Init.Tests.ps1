# Tests de DevForge Init (spec 002). Requiere Pester 5.5 o superior.
# Cada test crea un proyecto falso dentro de $TestDrive (carpeta temporal que Pester borra sola).

BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $repoRoot "scripts/init/Get-DevForgeProjectStack.ps1")
    . (Join-Path $repoRoot "scripts/init/New-DevForgeHarnessContent.ps1")
    . (Join-Path $repoRoot "scripts/init/Install-DevForgeHarnessFile.ps1")
    $templatesPath = Join-Path $repoRoot "templates/harness"
    $initScript = Join-Path $repoRoot "scripts/init/Invoke-DevForgeInit.ps1"
    $pwshPath = (Get-Process -Id $PID).Path

    # Ejecuta init en un proceso hijo (misma versión de PowerShell) y devuelve salida y código.
    function Invoke-Init([string[]]$Arguments) {
        $output = & $pwshPath -NoProfile -File $initScript @Arguments 2>&1
        [PSCustomObject]@{ Output = ($output -join "`n"); ExitCode = $LASTEXITCODE }
    }

    # Crea un proyecto falso con los archivos indicados (ruta relativa → contenido) y devuelve su ruta.
    function New-TestProject([hashtable]$Files = @{}) {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $root | Out-Null
        foreach ($relative in $Files.Keys) {
            $full = Join-Path $root $relative
            $parent = Split-Path -Parent $full
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
            [IO.File]::WriteAllText($full, [string]$Files[$relative])
        }
        return $root
    }
}

Describe "Get-DevForgeProjectStack en la raíz (RF-4)" {
    It "devuelve una lista vacía en un proyecto vacío" {
        @(Get-DevForgeProjectStack -Path (New-TestProject)).Count | Should -Be 0
    }

    It "detecta Django por manage.py" {
        $stacks = @(Get-DevForgeProjectStack -Path (New-TestProject @{ "manage.py" = "" }))
        $stacks.Stack | Should -Be @("Django")
        $stacks[0].Folder | Should -Be "."
    }

    It "detecta Python por <Indicador>" -ForEach @(
        @{ Indicador = "requirements.txt" }
        @{ Indicador = "pyproject.toml" }
    ) {
        $stacks = @(Get-DevForgeProjectStack -Path (New-TestProject @{ $Indicador = "" }))
        $stacks.Stack | Should -Be @("Python")
    }

    It "Django oculta a Python en la misma carpeta" {
        $project = New-TestProject @{ "manage.py" = ""; "requirements.txt" = "django" }
        @(Get-DevForgeProjectStack -Path $project).Stack | Should -Be @("Django")
    }

    It "detecta Node.js por un package.json sin vue" {
        $project = New-TestProject @{ "package.json" = '{ "name": "app", "dependencies": { "express": "^4.0.0" } }' }
        @(Get-DevForgeProjectStack -Path $project).Stack | Should -Be @("Node.js")
    }

    It "detecta Vue (y oculta a Node.js) si vue está en <Seccion>" -ForEach @(
        @{ Seccion = "dependencies" }
        @{ Seccion = "devDependencies" }
    ) {
        $project = New-TestProject @{ "package.json" = "{ `"$Seccion`": { `"vue`": `"^3.4.0`" } }" }
        @(Get-DevForgeProjectStack -Path $project).Stack | Should -Be @("Vue")
    }

    It "detecta PowerShell por un archivo <Archivo>" -ForEach @(
        @{ Archivo = "setup.ps1" }
        @{ Archivo = "Module.psd1" }
    ) {
        @(Get-DevForgeProjectStack -Path (New-TestProject @{ $Archivo = "" })).Stack | Should -Be @("PowerShell")
    }

    It "detecta varios stacks en la misma carpeta" {
        $project = New-TestProject @{ "manage.py" = ""; "package.json" = "{}"; "build.ps1" = "" }
        @(Get-DevForgeProjectStack -Path $project).Stack | Sort-Object |
            Should -Be @("Django", "Node.js", "PowerShell")
    }
}

Describe "Get-DevForgeProjectStack en subcarpetas (RF-4)" {
    It "detecta stacks en subcarpetas de primer nivel e indica la carpeta" {
        $project = New-TestProject @{
            "backend/manage.py"     = ""
            "frontend/package.json" = '{ "dependencies": { "vue": "^3.4.0" } }'
        }
        $stacks = @(Get-DevForgeProjectStack -Path $project)
        ($stacks | ForEach-Object { "$($_.Stack)@$($_.Folder)" }) |
            Should -Be @("Django@backend", "Vue@frontend")
    }

    It "lista primero la raíz y luego cada subcarpeta con el mismo stack" {
        $project = New-TestProject @{ "package.json" = "{}"; "web/package.json" = "{}" }
        $stacks = @(Get-DevForgeProjectStack -Path $project)
        $stacks.Folder | Should -Be @(".", "web")
        $stacks.Stack | Should -Be @("Node.js", "Node.js")
    }

    It "ignora la carpeta <Carpeta>" -ForEach @(
        @{ Carpeta = "node_modules"; Archivo = "package.json" }
        @{ Carpeta = ".git"; Archivo = "hook.ps1" }
        @{ Carpeta = ".venv"; Archivo = "requirements.txt" }
        @{ Carpeta = "venv"; Archivo = "requirements.txt" }
    ) {
        $project = New-TestProject @{ "$Carpeta/$Archivo" = "{}" }
        @(Get-DevForgeProjectStack -Path $project).Count | Should -Be 0
    }

    It "no mira más allá del primer nivel" {
        $project = New-TestProject @{ "apps/api/manage.py" = "" }
        @(Get-DevForgeProjectStack -Path $project).Count | Should -Be 0
    }
}

Describe "Get-DevForgeProjectStack: comandos de tests (RF-6, RF-7)" {
    It "RF-6: Django da 'python manage.py test'" {
        $stacks = @(Get-DevForgeProjectStack -Path (New-TestProject @{ "backend/manage.py" = "" }))
        $stacks[0].TestCommand | Should -Be "python manage.py test"
    }

    It "RF-7: un package.json con script test da 'npm test'" {
        $project = New-TestProject @{ "package.json" = '{ "scripts": { "test": "vitest run" } }' }
        @(Get-DevForgeProjectStack -Path $project)[0].TestCommand | Should -Be "npm test"
    }

    It "RF-7: también da 'npm test' en un proyecto Vue" {
        $project = New-TestProject @{ "package.json" = '{ "scripts": { "test": "vitest" }, "dependencies": { "vue": "^3" } }' }
        $stack = @(Get-DevForgeProjectStack -Path $project)[0]
        $stack.Stack | Should -Be "Vue"
        $stack.TestCommand | Should -Be "npm test"
    }

    It "el script test por defecto de npm cuenta como sin tests" {
        $project = New-TestProject @{ "package.json" = '{ "scripts": { "test": "echo \"Error: no test specified\" && exit 1" } }' }
        @(Get-DevForgeProjectStack -Path $project)[0].TestCommand | Should -BeNullOrEmpty
    }

    It "un package.json sin scripts no tiene comando" {
        @(Get-DevForgeProjectStack -Path (New-TestProject @{ "package.json" = "{}" }))[0].TestCommand |
            Should -BeNullOrEmpty
    }

    It "un package.json inválido cuenta como Node.js sin comando y no falla" {
        $project = New-TestProject @{ "package.json" = '{ "scripts": { "test": ' }
        $stacks = @(Get-DevForgeProjectStack -Path $project)
        $stacks.Stack | Should -Be @("Node.js")
        $stacks[0].TestCommand | Should -BeNullOrEmpty
    }

    It "Python y PowerShell no tienen comando de tests" {
        $project = New-TestProject @{ "requirements.txt" = ""; "build.ps1" = "" }
        $stacks = @(Get-DevForgeProjectStack -Path $project)
        $stacks.Count | Should -Be 2
        foreach ($stack in $stacks) { $stack.TestCommand | Should -BeNullOrEmpty }
    }
}

Describe "Plantillas del arnés" {
    It "existe la plantilla <Nombre>" -ForEach @(
        @{ Nombre = "AGENTS.md" }
        @{ Nombre = "CLAUDE.md" }
        @{ Nombre = "MEMORY.md" }
    ) {
        Join-Path $templatesPath $Nombre | Should -Exist
    }
}

Describe "New-DevForgeClaudeContent" {
    It "solo importa AGENTS.md y MEMORY.md" {
        $content = New-DevForgeClaudeContent
        $imports = @($content -split "\r?\n" | Where-Object { $_ -match '^@' })
        $imports | Should -Be @("@AGENTS.md", "@MEMORY.md")
    }

    It "no deja marcadores de plantilla sin reemplazar" {
        New-DevForgeClaudeContent | Should -Not -Match '\{\{'
    }
}

Describe "New-DevForgeMemoryContent (RF-9)" {
    It "RF-9: usa el nombre del proyecto en el título" {
        $content = New-DevForgeMemoryContent -ProjectName "MedAlert"
        ($content -split "\r?\n")[0] | Should -Be "# MEMORY.md — MedAlert"
    }

    It "conserva tildes y caracteres especiales del nombre" {
        $content = New-DevForgeMemoryContent -ProjectName 'Clínica $1 (beta)'
        $content | Should -Match ([regex]::Escape('# MEMORY.md — Clínica $1 (beta)'))
    }

    It "tiene como máximo 50 líneas y no deja marcadores de plantilla" {
        $content = New-DevForgeMemoryContent -ProjectName "MedAlert"
        @($content -split "\r?\n").Count | Should -BeLessOrEqual 50
        $content | Should -Not -Match '\{\{'
    }
}

Describe "New-DevForgeAgentsContent (RF-5 a RF-9, RF-15)" {
    BeforeAll {
        function New-Stack([string]$Stack, [string]$Folder = ".", [string]$TestCommand = $null) {
            [PSCustomObject]@{ Stack = $Stack; Folder = $Folder; TestCommand = $(if ($TestCommand) { $TestCommand } else { $null }) }
        }
        # Devuelve las líneas no vacías de una sección "## <Titulo>" hasta la siguiente sección.
        function Get-Section([string]$Content, [string]$Title) {
            $lines = $Content -split "\r?\n"
            $start = [array]::IndexOf($lines, "## $Title")
            if ($start -lt 0) { return @() }
            $section = @()
            for ($i = $start + 1; $i -lt $lines.Count -and $lines[$i] -notmatch '^## '; $i++) {
                if ($lines[$i].Trim()) { $section += $lines[$i] }
            }
            return $section
        }
        $medAlert = @(
            (New-Stack "Django" "backend" "python manage.py test")
            (New-Stack "Vue" "frontend" "npm test")
        )
    }

    It "RF-9: usa el nombre del proyecto en el título" {
        $content = New-DevForgeAgentsContent -ProjectName "MedAlert" -Stacks $medAlert
        ($content -split "\r?\n")[0] | Should -Be "# AGENTS.md — MedAlert"
    }

    It "RF-5: lista cada stack con su carpeta si no es la raíz" {
        $stacks = @(@(New-Stack "PowerShell") + $medAlert)
        $section = Get-Section (New-DevForgeAgentsContent -ProjectName "x" -Stacks $stacks) "Stack y estructura"
        $section | Should -Be @("- PowerShell", "- Django (en ``backend/``)", "- Vue (en ``frontend/``)")
    }

    It "RF-6, RF-7: lista los comandos de tests con la carpeta desde la que se ejecutan" {
        $section = Get-Section (New-DevForgeAgentsContent -ProjectName "x" -Stacks $medAlert) "Comandos"
        $section | Should -Be @(
            "- Tests Django: ``python manage.py test`` (desde ``backend/``)"
            "- Tests Vue: ``npm test`` (desde ``frontend/``)"
        )
    }

    It "RF-7: un comando en la raíz no indica carpeta" {
        $section = Get-Section (New-DevForgeAgentsContent -ProjectName "x" -Stacks @(New-Stack "Node.js" "." "npm test")) "Comandos"
        $section | Should -Be @("- Tests Node.js: ``npm test``")
    }

    It "RF-8: sin stacks, stack y comandos quedan con [COMPLETAR]" {
        $content = New-DevForgeAgentsContent -ProjectName "x" -Stacks @()
        (Get-Section $content "Stack y estructura") -join "`n" | Should -Match '\[COMPLETAR\]'
        (Get-Section $content "Comandos") -join "`n" | Should -Match '\[COMPLETAR\]'
    }

    It "RF-8: con stacks pero sin comandos, solo los comandos quedan con [COMPLETAR]" {
        $content = New-DevForgeAgentsContent -ProjectName "x" -Stacks @(New-Stack "Python")
        (Get-Section $content "Stack y estructura") | Should -Be @("- Python")
        (Get-Section $content "Comandos") -join "`n" | Should -Match '\[COMPLETAR\]'
    }

    It "RF-15: incluye la sección Límites con sus tres reglas" {
        $section = (Get-Section (New-DevForgeAgentsContent -ProjectName "x" -Stacks $medAlert) "Límites") -join "`n"
        $section | Should -Match 'claves ni tokens en el repo'
        $section | Should -Match 'Tests en verde antes de dar algo por hecho'
        $section | Should -Match 'Actualizar MEMORY\.md al terminar cada tarea'
    }

    It "tiene como máximo 40 líneas con Django + Vue + PowerShell y no deja marcadores de plantilla" {
        $stacks = @($medAlert + (New-Stack "PowerShell" "scripts"))
        $content = New-DevForgeAgentsContent -ProjectName "MedAlert" -Stacks $stacks
        @($content -split "\r?\n").Count | Should -BeLessOrEqual 40
        $content | Should -Not -Match '\{\{'
    }
}

Describe "Install-DevForgeHarnessFile (RF-1, RF-2, RF-3, RF-14)" {
    BeforeAll {
        $past = [datetime]"2020-01-01T00:00:00"
        # Crea un archivo existente con fecha antigua para detectar cualquier escritura.
        function New-ExistingFile([string]$Text = "original") {
            $file = Join-Path (New-TestProject) "AGENTS.md"
            [IO.File]::WriteAllText($file, $Text)
            (Get-Item -LiteralPath $file).LastWriteTime = $past
            return $file
        }
    }

    It "RF-1: crea el archivo si no existe y devuelve Created" {
        $file = Join-Path (New-TestProject) "AGENTS.md"
        $result = Install-DevForgeHarnessFile -Path $file -Content "nuevo"
        $result.Result | Should -Be "Created"
        $result.File | Should -Be "AGENTS.md"
        $result.DryRun | Should -BeFalse
        [IO.File]::ReadAllText($file) | Should -Be "nuevo"
    }

    It "RF-2: si existe, devuelve Skipped y no cambia contenido ni fecha" {
        $file = New-ExistingFile
        $result = Install-DevForgeHarnessFile -Path $file -Content "nuevo"
        $result.Result | Should -Be "Skipped"
        [IO.File]::ReadAllText($file) | Should -Be "original"
        (Get-Item -LiteralPath $file).LastWriteTime | Should -Be $past
    }

    It "RF-3: con -Force sobrescribe y devuelve Overwritten" {
        $file = New-ExistingFile
        $result = Install-DevForgeHarnessFile -Path $file -Content "nuevo" -Force
        $result.Result | Should -Be "Overwritten"
        [IO.File]::ReadAllText($file) | Should -Be "nuevo"
    }

    It "RF-14: con -WhatIf no crea el archivo e informa lo que haría" {
        $file = Join-Path (New-TestProject) "AGENTS.md"
        $result = Install-DevForgeHarnessFile -Path $file -Content "nuevo" -WhatIf
        $result.Result | Should -Be "Created"
        $result.DryRun | Should -BeTrue
        $file | Should -Not -Exist
    }

    It "RF-14: con -WhatIf y -Force no sobrescribe" {
        $file = New-ExistingFile
        $result = Install-DevForgeHarnessFile -Path $file -Content "nuevo" -Force -WhatIf
        $result.Result | Should -Be "Overwritten"
        $result.DryRun | Should -BeTrue
        [IO.File]::ReadAllText($file) | Should -Be "original"
        (Get-Item -LiteralPath $file).LastWriteTime | Should -Be $past
    }

    It "RF-14: con -WhatIf un archivo existente sigue siendo Skipped" {
        $result = Install-DevForgeHarnessFile -Path (New-ExistingFile) -Content "nuevo" -WhatIf
        $result.Result | Should -Be "Skipped"
        $result.DryRun | Should -BeTrue
    }

    It "escribe en UTF-8 sin BOM y conserva las tildes" {
        $file = Join-Path (New-TestProject) "MEMORY.md"
        Install-DevForgeHarnessFile -Path $file -Content "# Clínica — ñandú ✅" | Out-Null
        $bytes = [IO.File]::ReadAllBytes($file)
        ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) | Should -BeFalse
        [Text.Encoding]::UTF8.GetString($bytes) | Should -Be "# Clínica — ñandú ✅"
    }
}

Describe "Invoke-DevForgeInit.ps1 (RF-10, RF-11, RF-12)" {
    It "RF-11: en un proyecto vacío crea los tres archivos y sale con 0" {
        $project = New-TestProject
        (Invoke-Init @("-Path", $project)).ExitCode | Should -Be 0
        foreach ($name in @("AGENTS.md", "CLAUDE.md", "MEMORY.md")) { Join-Path $project $name | Should -Exist }
    }

    It "RF-11: si ya existe CLAUDE.md lo omite, crea los otros dos y sale con 1" {
        $project = New-TestProject @{ "CLAUDE.md" = "mío" }
        (Invoke-Init @("-Path", $project)).ExitCode | Should -Be 1
        [IO.File]::ReadAllText((Join-Path $project "CLAUDE.md")) | Should -Be "mío"
        Join-Path $project "AGENTS.md" | Should -Exist
        Join-Path $project "MEMORY.md" | Should -Exist
    }

    It "RF-12: si la ruta no existe sale con 2 y no crea nada" {
        $missing = Join-Path $TestDrive "no-existe-$(Get-Random)"
        $run = Invoke-Init @("-Path", $missing)
        $run.ExitCode | Should -Be 2
        $run.Output | Should -Match 'no existe'
        $missing | Should -Not -Exist
    }

    It "RF-12: si la ruta es un archivo sale con 2 y no crea nada a su lado" {
        $project = New-TestProject @{ "notas.txt" = "" }
        $run = Invoke-Init @("-Path", (Join-Path $project "notas.txt"))
        $run.ExitCode | Should -Be 2
        $run.Output | Should -Match 'no es una carpeta'
        @(Get-ChildItem -LiteralPath $project).Name | Should -Be @("notas.txt")
    }

    It "RF-11: si no puede escribir un archivo sale con 2" {
        # Una carpeta llamada AGENTS.md impide escribir el archivo.
        $project = New-TestProject
        New-Item -ItemType Directory -Path (Join-Path $project "AGENTS.md") | Out-Null
        (Invoke-Init @("-Path", $project)).ExitCode | Should -Be 2
    }

    It "RF-10: muestra el resultado de cada archivo, los stacks y los marcadores" {
        $project = New-TestProject @{ "CLAUDE.md" = "mío"; "backend/manage.py" = "" }
        $run = Invoke-Init @("-Path", $project)
        $run.Output | Should -Match '\[CREADO\]\s+AGENTS\.md'
        $run.Output | Should -Match '\[OMITIDO\]\s+CLAUDE\.md'
        $run.Output | Should -Match '\[CREADO\]\s+MEMORY\.md'
        $run.Output | Should -Match 'Django \(backend\)'

        # Los marcadores se cuentan en los archivos que init escribió (AGENTS.md y MEMORY.md).
        $written = [IO.File]::ReadAllText((Join-Path $project "AGENTS.md")) + [IO.File]::ReadAllText((Join-Path $project "MEMORY.md"))
        $expected = ([regex]::Matches($written, '\[COMPLETAR\]')).Count
        $run.Output | Should -Match "Marcadores \[COMPLETAR\]: $expected\b"
    }

    It "RF-10: indica cuando no detecta ningún stack" {
        (Invoke-Init @("-Path", (New-TestProject))).Output | Should -Match 'Stacks detectados: ninguno'
    }
}

Describe "Invoke-DevForgeInit.ps1: -WhatIf, idempotencia y límites (RF-13, RF-14)" {
    BeforeAll {
        $harness = @("AGENTS.md", "CLAUDE.md", "MEMORY.md")
        # Foto de una carpeta: ruta relativa, tamaño y fecha de cada archivo (recursivo).
        function Get-Snapshot([string]$Root) {
            @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Sort-Object FullName | ForEach-Object {
                "{0}|{1}|{2}" -f $_.FullName.Substring($Root.Length), $_.Length, $_.LastWriteTimeUtc.Ticks
            })
        }
    }

    It "RF-14: -WhatIf en un proyecto vacío no crea nada y sale con 0" {
        $project = New-TestProject
        $run = Invoke-Init @("-Path", $project, "-WhatIf")
        $run.ExitCode | Should -Be 0
        $run.Output | Should -Match 'WhatIf'
        $run.Output | Should -Match '\[CREADO\]\s+AGENTS\.md'
        @(Get-ChildItem -LiteralPath $project -Force).Count | Should -Be 0
    }

    It "RF-14: -WhatIf sale con 1 si omitiría algún archivo, sin escribir nada" {
        $project = New-TestProject @{ "CLAUDE.md" = "mío" }
        $before = Get-Snapshot $project
        (Invoke-Init @("-Path", $project, "-WhatIf")).ExitCode | Should -Be 1
        Get-Snapshot $project | Should -Be $before
    }

    It "RF-14: -WhatIf -Force no sobrescribe nada y sale con 0" {
        $project = New-TestProject @{ "AGENTS.md" = "a"; "CLAUDE.md" = "c"; "MEMORY.md" = "m" }
        $before = Get-Snapshot $project
        $run = Invoke-Init @("-Path", $project, "-WhatIf", "-Force")
        $run.ExitCode | Should -Be 0
        $run.Output | Should -Match '\[SOBRESCRITO\]\s+AGENTS\.md'
        Get-Snapshot $project | Should -Be $before
    }

    It "ejecutar init dos veces sin -Force no cambia nada la segunda vez" {
        $project = New-TestProject @{ "backend/manage.py" = "" }
        (Invoke-Init @("-Path", $project)).ExitCode | Should -Be 0
        $before = Get-Snapshot $project
        Start-Sleep -Milliseconds 50
        $second = Invoke-Init @("-Path", $project)
        $second.ExitCode | Should -Be 1
        foreach ($name in $harness) { $second.Output | Should -Match "\[OMITIDO\]\s+$([regex]::Escape($name))" }
        Get-Snapshot $project | Should -Be $before
    }

    It "RF-13: solo aparecen los tres archivos del arnés y no se toca nada más, dentro ni fuera" {
        $container = New-TestProject @{
            "vecino.txt"                = "fuera del proyecto"
            "app/.gitignore"            = "node_modules/"
            "app/README.md"             = "# App"
            "app/backend/manage.py"     = ""
            "app/frontend/package.json" = '{ "dependencies": { "vue": "^3" } }'
        }
        $before = Get-Snapshot $container
        (Invoke-Init @("-Path", (Join-Path $container "app"))).ExitCode | Should -Be 0
        $after = Get-Snapshot $container

        # Todo lo que había sigue igual y lo único nuevo son los tres archivos en la raíz del proyecto.
        foreach ($entry in $before) { $after | Should -Contain $entry }
        $new = @($after | Where-Object { $_ -notin $before } | ForEach-Object { ($_ -split '\|')[0] })
        $new | Sort-Object | Should -Be @($harness | ForEach-Object { [IO.Path]::DirectorySeparatorChar + "app" + [IO.Path]::DirectorySeparatorChar + $_ })
    }

    It "funciona con una ruta con espacios y tildes" {
        $project = Join-Path (New-TestProject) "Mi Proyecto Clínica"
        New-Item -ItemType Directory -Path $project | Out-Null
        [IO.File]::WriteAllText((Join-Path $project "manage.py"), "")
        (Invoke-Init @("-Path", $project)).ExitCode | Should -Be 0
        $agents = [IO.File]::ReadAllText((Join-Path $project "AGENTS.md"), [Text.Encoding]::UTF8)
        ($agents -split "\r?\n")[0] | Should -Be "# AGENTS.md — Mi Proyecto Clínica"
    }

    It "sin -Path usa la carpeta actual" {
        $project = New-TestProject
        Push-Location -LiteralPath $project
        try { $output = & $pwshPath -NoProfile -File $initScript 2>&1; $code = $LASTEXITCODE }
        finally { Pop-Location }
        $code | Should -Be 0
        foreach ($name in $harness) { Join-Path $project $name | Should -Exist }
    }
}
