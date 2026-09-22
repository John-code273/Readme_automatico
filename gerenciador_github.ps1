# ============================================================
# GERENCIADOR DE GITHUB - JOHN
# ============================================================

$baseDir = "C:\Users\Dev02\Desktop\meus-repositorios"
$desktopDir = "C:\Users\Dev02\Desktop"

$gerarReadmes = Join-Path $desktopDir "gerar_readmes_ollama.ps1"
$pushRepos = Join-Path $desktopDir "push_todos_repos.ps1"
$verReadmes = Join-Path $desktopDir "ver_readmes.ps1"

# ============================================================
# FUNCOES
# ============================================================

function Pause-Menu {
    Write-Host ""
    Read-Host "Pressione ENTER para continuar"
}

function Get-Repos {
    return @(Get-ChildItem -Path $baseDir -Directory)
}

function Open-RepoFolder {
    param($repo)

    explorer.exe $repo.FullName
}

function Get-GitRemote {
    param($repoPath)

    Push-Location $repoPath

    try {
        $remote = git remote get-url origin 2>$null
        return $remote
    }
    finally {
        Pop-Location
    }
}

# ============================================================
# STATUS DOS REPOSITORIOS
# ============================================================

function Show-Status {

    Clear-Host

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "              STATUS DOS REPOSITORIOS" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    $repos = Get-Repos

    $contador = 0

    foreach ($repo in $repos) {

        $contador++

        Push-Location $repo.FullName

        try {

            $status = @(git status --porcelain 2>$null)

            Write-Host "[$contador] $($repo.Name)" -ForegroundColor Cyan

            if (-not (Test-Path ".git")) {

                Write-Host "    Git: nao encontrado" -ForegroundColor Red

            }
            elseif ($status.Count -eq 0) {

                Write-Host "    Git: LIMPO" -ForegroundColor Green

            }
            else {

                Write-Host "    Git: possui alteracoes" -ForegroundColor Yellow

                foreach ($line in $status) {
                    Write-Host "        $line" -ForegroundColor DarkYellow
                }
            }

            $readme = Join-Path $repo.FullName "README.md"

            if (Test-Path $readme) {

                $info = Get-Item $readme

                Write-Host "    README: presente" -ForegroundColor Green
                Write-Host "    Alterado: $($info.LastWriteTime)"

            }
            else {

                Write-Host "    README: AUSENTE" -ForegroundColor Red

            }

            Write-Host ""

        }
        finally {

            Pop-Location
        }
    }

    Pause-Menu
}

# ============================================================
# ATUALIZAR REPOSITORIOS
# ============================================================

function Update-Repos {

    Clear-Host

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "             ATUALIZAR REPOSITORIOS" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Este processo usa git pull --ff-only." -ForegroundColor Yellow
    Write-Host "Ele nao cria merges automaticos." -ForegroundColor Yellow
    Write-Host ""

    $repos = Get-Repos

    $current = 0
    $success = 0
    $skipped = 0
    $errors = 0

    foreach ($repo in $repos) {

        $current++

        Write-Host ""
        Write-Host "[$current/$($repos.Count)] $($repo.Name)" -ForegroundColor Cyan

        Push-Location $repo.FullName

        try {

            if (-not (Test-Path ".git")) {

                Write-Host "Nao e um repositorio Git." -ForegroundColor Yellow
                $skipped++
                continue
            }

            $status = @(git status --porcelain 2>$null)

            if ($status.Count -gt 0) {

                Write-Host "Possui alteracoes locais. Pulando por seguranca." -ForegroundColor Yellow
                $skipped++
                continue
            }

            git pull --ff-only

            if ($LASTEXITCODE -eq 0) {

                Write-Host "Atualizado." -ForegroundColor Green
                $success++

            }
            else {

                Write-Host "Erro ao atualizar." -ForegroundColor Red
                $errors++
            }

        }
        finally {

            Pop-Location
        }
    }

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "ATUALIZACAO FINALIZADA" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Atualizados: $success" -ForegroundColor Green
    Write-Host "Ignorados:   $skipped" -ForegroundColor Yellow
    Write-Host "Erros:       $errors" -ForegroundColor Red

    Pause-Menu
}

# ============================================================
# ABRIR REPOSITORIO NO GITHUB
# ============================================================

function Open-GitHub {

    Clear-Host

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "               ABRIR NO GITHUB" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    $repos = Get-Repos

    for ($i = 0; $i -lt $repos.Count; $i++) {

        Write-Host "[$($i + 1)] $($repos[$i].Name)" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "[0] Voltar" -ForegroundColor Red
    Write-Host ""

    $choice = Read-Host "Escolha o repositorio"

    if ($choice -eq "0") {
        return
    }

    $number = 0

    if (-not [int]::TryParse($choice, [ref]$number)) {

        Write-Host "Opcao invalida." -ForegroundColor Red
        Pause-Menu
        return
    }

    if ($number -lt 1 -or $number -gt $repos.Count) {

        Write-Host "Numero invalido." -ForegroundColor Red
        Pause-Menu
        return
    }

    $repo = $repos[$number - 1]

    $url = Get-GitRemote $repo.FullName

    if (-not $url) {

        Write-Host "Esse repositorio nao possui remote origin." -ForegroundColor Red
        Pause-Menu
        return
    }

    Write-Host ""
    Write-Host "Abrindo: $url" -ForegroundColor Green

    Start-Process $url

    Start-Sleep -Seconds 1
}

# ============================================================
# ABRIR PASTA
# ============================================================

function Open-Folder {

    Clear-Host

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "              ABRIR PROJETO" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    $repos = Get-Repos

    for ($i = 0; $i -lt $repos.Count; $i++) {

        Write-Host "[$($i + 1)] $($repos[$i].Name)" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "[0] Voltar" -ForegroundColor Red
    Write-Host ""

    $choice = Read-Host "Escolha o projeto"

    if ($choice -eq "0") {
        return
    }

    $number = 0

    if (-not [int]::TryParse($choice, [ref]$number)) {

        Write-Host "Opcao invalida." -ForegroundColor Red
        Pause-Menu
        return
    }

    if ($number -lt 1 -or $number -gt $repos.Count) {

        Write-Host "Numero invalido." -ForegroundColor Red
        Pause-Menu
        return
    }

    Open-RepoFolder $repos[$number - 1]

    Start-Sleep -Seconds 1
}

# ============================================================
# BUSCAR PROJETO
# ============================================================

function Search-Repo {

    Clear-Host

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "               BUSCAR PROJETO" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    $term = Read-Host "Digite o nome ou parte do nome"

    if ([string]::IsNullOrWhiteSpace($term)) {
        return
    }

    $repos = Get-Repos |
        Where-Object {
            $_.Name -like "*$term*"
        }

    Write-Host ""

    if ($repos.Count -eq 0) {

        Write-Host "Nenhum projeto encontrado." -ForegroundColor Yellow

    }
    else {

        Write-Host "Projetos encontrados:" -ForegroundColor Green
        Write-Host ""

        foreach ($repo in $repos) {

            Write-Host " - $($repo.Name)" -ForegroundColor Cyan
        }
    }

    Pause-Menu
}

# ============================================================
# ESTATISTICAS
# ============================================================

function Show-Statistics {

    Clear-Host

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "                 ESTATISTICAS" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    $repos = Get-Repos

    $total = $repos.Count

    $withReadme = 0
    $withoutReadme = 0
    $clean = 0
    $modified = 0

    $java = 0
    $html = 0
    $css = 0
    $javascript = 0

    foreach ($repo in $repos) {

        $readme = Join-Path $repo.FullName "README.md"

        if (Test-Path $readme) {
            $withReadme++
        }
        else {
            $withoutReadme++
        }

        Push-Location $repo.FullName

        try {

            $status = @(git status --porcelain 2>$null)

            if ($status.Count -eq 0) {
                $clean++
            }
            else {
                $modified++
            }

        }
        finally {

            Pop-Location
        }

        if (Get-ChildItem $repo.FullName -Recurse -Filter "*.java" -File -ErrorAction SilentlyContinue) {
            $java++
        }

        if (Get-ChildItem $repo.FullName -Recurse -Filter "*.html" -File -ErrorAction SilentlyContinue) {
            $html++
        }

        if (Get-ChildItem $repo.FullName -Recurse -Filter "*.css" -File -ErrorAction SilentlyContinue) {
            $css++
        }

        if (Get-ChildItem $repo.FullName -Recurse -Filter "*.js" -File -ErrorAction SilentlyContinue) {
            $javascript++
        }
    }

    Write-Host "Total de repositorios: $total" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "READMEs:" -ForegroundColor Yellow
    Write-Host "  Com README:    $withReadme" -ForegroundColor Green
    Write-Host "  Sem README:    $withoutReadme" -ForegroundColor Red

    Write-Host ""
    Write-Host "Git:" -ForegroundColor Yellow
    Write-Host "  Limpos:        $clean" -ForegroundColor Green
    Write-Host "  Com alteracoes: $modified" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Tecnologias encontradas:" -ForegroundColor Yellow
    Write-Host "  Java:          $java"
    Write-Host "  HTML:          $html"
    Write-Host "  CSS:           $css"
    Write-Host "  JavaScript:    $javascript"

    Pause-Menu
}

# ============================================================
# EXECUTAR OUTRO SCRIPT
# ============================================================

function Run-Script {
    param(
        [string]$scriptPath
    )

    if (-not (Test-Path $scriptPath)) {

        Write-Host ""
        Write-Host "Script nao encontrado:" -ForegroundColor Red
        Write-Host $scriptPath -ForegroundColor Red
        Pause-Menu
        return
    }

    Clear-Host

    & powershell.exe `
        -NoProfile `
        -ExecutionPolicy Bypass `
        -File $scriptPath

    Write-Host ""
    Pause-Menu
}

# ============================================================
# MENU PRINCIPAL
# ============================================================

while ($true) {

    Clear-Host

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "           GERENCIADOR DE GITHUB - JOHN" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "[1] Gerar READMEs com Ollama" -ForegroundColor Green
    Write-Host "[2] Ver README" -ForegroundColor Green
    Write-Host "[3] Enviar READMEs para o GitHub" -ForegroundColor Green
    Write-Host "[4] Atualizar repositorios" -ForegroundColor Green
    Write-Host "[5] Ver status dos repositorios" -ForegroundColor Green
    Write-Host "[6] Abrir pasta de um projeto" -ForegroundColor Green
    Write-Host "[7] Abrir projeto no GitHub" -ForegroundColor Green
    Write-Host "[8] Procurar projeto" -ForegroundColor Green
    Write-Host "[9] Ver estatisticas" -ForegroundColor Green
    Write-Host "[0] Sair" -ForegroundColor Red

    Write-Host ""

    $option = Read-Host "Escolha uma opcao"

    switch ($option) {

        "1" {
            Run-Script $gerarReadmes
        }

        "2" {
            Run-Script $verReadmes
        }

        "3" {
            Run-Script $pushRepos
        }

        "4" {
            Update-Repos
        }

        "5" {
            Show-Status
        }

        "6" {
            Open-Folder
        }

        "7" {
            Open-GitHub
        }

        "8" {
            Search-Repo
        }

        "9" {
            Show-Statistics
        }

        "0" {
            Clear-Host
            Write-Host ""
            Write-Host "Ate mais!" -ForegroundColor Cyan
            Write-Host ""
            exit
        }

        default {
            Write-Host ""
            Write-Host "Opcao invalida." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}