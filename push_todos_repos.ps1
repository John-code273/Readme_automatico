# ============================================================
# PUSH AUTOMATICO DOS READMEs
# ============================================================

$baseDir = "C:\Users\Dev02\Desktop\meus-repositorios"

Clear-Host

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "          PUSH AUTOMATICO - TODOS OS REPOS"
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# VERIFICAR GH
# ------------------------------------------------------------

Write-Host "[1] Verificando GitHub CLI..." -ForegroundColor Yellow

$gh = Get-Command gh -ErrorAction SilentlyContinue

if (-not $gh) {
    Write-Host "ERRO: GitHub CLI nao encontrado." -ForegroundColor Red
    exit
}

$login = gh auth status 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: voce nao esta conectado ao GitHub." -ForegroundColor Red
    Write-Host "Execute: gh auth login" -ForegroundColor Yellow
    exit
}

Write-Host "GitHub conectado." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# REPOSITÓRIOS
# ------------------------------------------------------------

$repos = Get-ChildItem -Path $baseDir -Directory

$total = $repos.Count
$current = 0
$success = 0
$skipped = 0
$errors = 0

Write-Host "Encontrados $total repositorios." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# PROCESSAR
# ------------------------------------------------------------

foreach ($repo in $repos) {

    $current++

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "[$current/$total] $($repo.Name)" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan

    $readme = Join-Path $repo.FullName "README.md"

    # Verificar README
    if (-not (Test-Path $readme)) {

        Write-Host "README.md nao encontrado. Pulando." -ForegroundColor Yellow
        $skipped++
        continue
    }

    Push-Location $repo.FullName

    try {

        # Verificar se e um repositorio Git
        if (-not (Test-Path ".git")) {

            Write-Host "Nao e um repositorio Git. Pulando." -ForegroundColor Yellow
            $skipped++

            Pop-Location
            continue
        }

        # ----------------------------------------------------
        # STATUS
        # ----------------------------------------------------

        $status = git status --porcelain

        # Verificar especificamente se README mudou
        $readmeChanged = $status | Where-Object {
            $_ -match "README\.md"
        }

        if (-not $readmeChanged) {

            Write-Host "README sem alteracoes. Nada para enviar." -ForegroundColor Yellow
            $skipped++

            Pop-Location
            continue
        }

        Write-Host "README alterado." -ForegroundColor Green

        # ----------------------------------------------------
        # ADICIONAR SOMENTE README
        # ----------------------------------------------------

        Write-Host "Adicionando README..." -ForegroundColor Yellow

        git add README.md

        if ($LASTEXITCODE -ne 0) {
            throw "Erro no git add."
        }

        # ----------------------------------------------------
        # COMMIT
        # ----------------------------------------------------

        Write-Host "Criando commit..." -ForegroundColor Yellow

        git commit -m "Adiciona README do projeto"

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Commit nao criado. Talvez nao haja alteracoes." -ForegroundColor Yellow
        }

        # ----------------------------------------------------
        # PUSH
        # ----------------------------------------------------

        Write-Host "Enviando para o GitHub..." -ForegroundColor Yellow

        git push

        if ($LASTEXITCODE -ne 0) {
            throw "Erro no git push."
        }

        Write-Host "PUSH realizado com sucesso!" -ForegroundColor Green

        $success++

    }
    catch {

        Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }

    Pop-Location
}

# ------------------------------------------------------------
# FINAL
# ------------------------------------------------------------

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "                 PROCESSO FINALIZADO"
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Total:       $total" -ForegroundColor Cyan
Write-Host "Enviados:    $success" -ForegroundColor Green
Write-Host "Ignorados:   $skipped" -ForegroundColor Yellow
Write-Host "Com erros:   $errors" -ForegroundColor Red

Write-Host ""
Write-Host "Pronto!" -ForegroundColor Green
Write-Host ""