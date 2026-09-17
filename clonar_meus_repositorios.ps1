# clonar_meus_repositorios.ps1
#
# O que este script faz:
#   1. Verifica se o GitHub CLI (gh) esta instalado.
#   2. Autentica voce na sua conta do GitHub (se ainda nao estiver logado).
#   3. Lista TODOS os seus repositorios (publicos e privados).
#   4. Clona cada um deles numa pasta local "meus-repositorios".
#
# Depois de rodar este script, abra o Claude Code apontando para a pasta
# "meus-repositorios" e peca para ele gerar/atualizar o README.md de cada
# repositorio automaticamente.
#
# Como rodar:
#   1. Abra o PowerShell na pasta onde salvou este arquivo.
#   2. Se for a primeira vez rodando scripts .ps1, talvez precise liberar a
#      execucao (rode uma vez, como Administrador):
#         Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#   3. Rode:  .\clonar_meus_repositorios.ps1

$ErrorActionPreference = "Stop"
$PastaDestino = "meus-repositorios"

Write-Host "=== Passo 1: verificando se o GitHub CLI (gh) esta instalado ===" -ForegroundColor Cyan
$ghInstalado = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghInstalado) {
    Write-Host "O GitHub CLI nao foi encontrado." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Instale rodando este comando e depois execute o script de novo:"
    Write-Host "  winget install --id GitHub.cli"
    Write-Host ""
    Write-Host "Ou baixe o instalador em: https://github.com/cli/cli/releases/latest"
    exit 1
}
Write-Host "GitHub CLI encontrado."
Write-Host ""

Write-Host "=== Passo 2: verificando autenticacao ===" -ForegroundColor Cyan
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Voce ainda nao esta logado. Vamos autenticar agora."
    gh auth login
} else {
    Write-Host "Voce ja esta autenticado."
}
Write-Host ""

Write-Host "=== Passo 3: listando todos os seus repositorios ===" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $PastaDestino | Out-Null
Set-Location $PastaDestino

$repos = gh repo list --limit 1000 --json nameWithOwner --jq ".[].nameWithOwner"
$listaRepos = $repos -split "`n" | Where-Object { $_ -ne "" }
$total = $listaRepos.Count
Write-Host "Encontrados $total repositorios."
Write-Host ""

Write-Host "=== Passo 4: clonando cada repositorio em .\$PastaDestino ===" -ForegroundColor Cyan
$contador = 0
foreach ($repo in $listaRepos) {
    $contador++
    $nomePasta = $repo -replace ".*/", ""
    if (Test-Path $nomePasta) {
        Write-Host "[$contador/$total] Ja existe, pulando: $repo"
    } else {
        Write-Host "[$contador/$total] Clonando: $repo"
        gh repo clone $repo $nomePasta -- --quiet
    }
}

Write-Host ""
Write-Host "=== Concluido! ===" -ForegroundColor Green
Write-Host "Todos os repositorios foram clonados em: $(Get-Location)"
Write-Host ""
Write-Host "Proximo passo: abra o Claude Code nesta pasta e peca, por exemplo:"
Write-Host '  "Para cada repositorio dentro desta pasta, leia o codigo e crie ou'
Write-Host '   atualize um README.md completo e profissional."'
