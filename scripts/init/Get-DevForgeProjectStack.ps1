function Get-DevForgeFolderStack {
    param(
        [Parameter(Mandatory)][string]$FolderPath,
        [Parameter(Mandatory)][string]$Folder
    )

    $stacks = @()
    $has = { param($name) Test-Path -LiteralPath (Join-Path $FolderPath $name) -PathType Leaf }

    # Django oculta a Python en la misma carpeta (spec 002, casos límite).
    if (& $has "manage.py") {
        $stacks += [PSCustomObject]@{ Stack = "Django"; Folder = $Folder; TestCommand = "python manage.py test" }
    } elseif ((& $has "pyproject.toml") -or (& $has "requirements.txt")) {
        $stacks += [PSCustomObject]@{ Stack = "Python"; Folder = $Folder; TestCommand = $null }
    }

    # Vue oculta a Node.js en la misma carpeta; un package.json inválido cuenta como Node.js.
    if (& $has "package.json") {
        $stack = "Node.js"
        $testCommand = $null
        try {
            $package = Get-Content -LiteralPath (Join-Path $FolderPath "package.json") -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($section in @("dependencies", "devDependencies")) {
                $deps = $package.$section
                if ($deps -and ($deps.PSObject.Properties.Name -contains "vue")) { $stack = "Vue" }
            }
            # El script "test" que crea npm init por defecto solo falla: cuenta como sin tests.
            $testScript = if ($package.scripts) { $package.scripts.test } else { $null }
            if ($testScript -and $testScript -notlike "*no test specified*") { $testCommand = "npm test" }
        } catch { }
        $stacks += [PSCustomObject]@{ Stack = $stack; Folder = $Folder; TestCommand = $testCommand }
    }

    $psFiles = @(Get-ChildItem -LiteralPath $FolderPath -File | Where-Object { $_.Extension -in @(".ps1", ".psd1") })
    if ($psFiles.Count -gt 0) {
        $stacks += [PSCustomObject]@{ Stack = "PowerShell"; Folder = $Folder; TestCommand = $null }
    }

    return $stacks
}

function Get-DevForgeProjectStack {
    param([Parameter(Mandatory)][string]$Path)

    # Raíz y subcarpetas de primer nivel; las carpetas pesadas o de herramientas no se miran.
    $ignored = @("node_modules", ".git", ".venv", "venv")
    $stacks = @(Get-DevForgeFolderStack -FolderPath $Path -Folder ".")

    $subfolders = Get-ChildItem -LiteralPath $Path -Directory -Force |
        Where-Object { $_.Name -notin $ignored } |
        Sort-Object Name
    foreach ($subfolder in $subfolders) {
        $stacks += Get-DevForgeFolderStack -FolderPath $subfolder.FullName -Folder $subfolder.Name
    }

    return $stacks
}
