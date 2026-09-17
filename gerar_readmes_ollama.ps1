# ============================================================
# GERADOR DE README - OLLAMA + QWEN
# ============================================================

$model = "qwen2.5-coder:3b"
$baseDir = "C:\Users\Dev02\Desktop\meus-repositorios"
$maxChars = 30000
$ollamaUrl = "http://localhost:11434/api/generate"

Clear-Host

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       GERADOR DE README - OLLAMA + QWEN" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# VERIFICAR OLLAMA
# ============================================================

Write-Host "[1] Verificando Ollama..." -ForegroundColor Yellow

try {

    $test = Invoke-RestMethod `
        -Uri "http://localhost:11434/api/tags" `
        -Method Get `
        -TimeoutSec 5

    Write-Host "Ollama encontrado e funcionando." -ForegroundColor Green

}
catch {

    Write-Host "ERRO: O Ollama nao esta funcionando." -ForegroundColor Red
    Write-Host ""
    Write-Host "Abra o Ollama e tente novamente." -ForegroundColor Yellow
    exit
}

Write-Host ""

# ============================================================
# VERIFICAR MODELO
# ============================================================

Write-Host "[2] Verificando modelo $model..." -ForegroundColor Yellow

$modelExiste = $test.models | Where-Object {
    $_.name -like "$model*"
}

if (-not $modelExiste) {

    Write-Host "Modelo nao encontrado." -ForegroundColor Yellow
    Write-Host "Baixando modelo..." -ForegroundColor Yellow
    Write-Host ""

    ollama pull $model

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO ao baixar o modelo." -ForegroundColor Red
        exit
    }
}

Write-Host "Modelo pronto." -ForegroundColor Green
Write-Host ""

# ============================================================
# REPOSITÓRIOS
# ============================================================

Write-Host "[3] Verificando repositorios..." -ForegroundColor Yellow

$repos = Get-ChildItem -Path $baseDir -Directory

$totalRepos = $repos.Count

Write-Host "Encontrados $totalRepos repositorios." -ForegroundColor Green
Write-Host ""

# ============================================================
# INICIO DO PROCESSO
# ============================================================

$globalStart = Get-Date
$currentRepo = 0

foreach ($repo in $repos) {

    $currentRepo++
    $repoStart = Get-Date

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "[$currentRepo/$totalRepos] $($repo.Name)" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan

    # --------------------------------------------------------
    # BARRA DE PROGRESSO
    # --------------------------------------------------------

    $percent = [math]::Floor((($currentRepo - 1) / $totalRepos) * 100)

    $barSize = 30
    $filled = [math]::Floor(($percent / 100) * $barSize)
    $empty = $barSize - $filled

    $bar = ("#" * $filled) + ("-" * $empty)

    Write-Host "Progresso: [$bar] $percent%  $($currentRepo - 1)/$totalRepos" -ForegroundColor Cyan
    Write-Host ""

    # --------------------------------------------------------
    # ARQUIVOS
    # --------------------------------------------------------

    $readmeFile = Join-Path $repo.FullName "README.md"

    $files = Get-ChildItem `
        -Path $repo.FullName `
        -Recurse `
        -File |
        Where-Object {
            $_.FullName -notmatch "\\\.git\\" -and
            $_.Name -notmatch "^README\.md$" -and
            $_.Length -lt 1MB
        }

    Write-Host "Arquivos encontrados: $($files.Count)" -ForegroundColor Green

    if ($files.Count -eq 0) {

        Write-Host "Nenhum arquivo encontrado. Pulando..." -ForegroundColor Yellow
        continue
    }

    # --------------------------------------------------------
    # LER PROJETO
    # --------------------------------------------------------

    $projectContent = ""

    foreach ($file in $files) {

        try {

            $relativePath = $file.FullName.Substring(
                $repo.FullName.Length + 1
            )

            $content = [System.IO.File]::ReadAllText(
                $file.FullName,
                [System.Text.Encoding]::UTF8
            )

            $projectContent += "`n"
            $projectContent += "===== ARQUIVO: $relativePath =====`n"
            $projectContent += $content
            $projectContent += "`n"

        }
        catch {

            Write-Host "Nao foi possivel ler $($file.Name)" -ForegroundColor Yellow
        }
    }

    # --------------------------------------------------------
    # LIMITAR TAMANHO
    # --------------------------------------------------------

    if ($projectContent.Length -gt $maxChars) {

        $projectContent = $projectContent.Substring(
            0,
            $maxChars
        )
    }

    # --------------------------------------------------------
    # PROMPT
    # --------------------------------------------------------

    $prompt = @"
Crie um README.md para este projeto.

REGRAS:

- Retorne SOMENTE o conteudo do README.
- Nao escreva explicacoes antes ou depois.
- Nao use codigos ANSI.
- Nao use caracteres de controle do terminal.
- Nao invente funcionalidades.
- Use somente informacoes encontradas nos arquivos.
- Escreva em portugues do Brasil.
- Use acentuacao correta.
- Use UTF-8 corretamente.
- Seja simples e profissional.
- O projeto pertence a um estudante iniciante de programacao.

Use esta estrutura:

# Nome do projeto

## Objetivo

Explique brevemente o objetivo.

## Funcionalidades

Liste as principais funcionalidades encontradas.

## Tecnologias utilizadas

Liste somente as tecnologias realmente utilizadas.

## Como executar

Explique de forma simples como executar.

## Conceitos de programacao presentes

Liste os principais conceitos encontrados no codigo.

ARQUIVOS DO PROJETO:

$projectContent
"@

    # --------------------------------------------------------
    # ENVIAR PARA OLLAMA VIA API LOCAL
    # --------------------------------------------------------

    Write-Host "Enviando projeto para o Qwen..." -ForegroundColor Yellow

    try {

        $body = @{
            model = $model
            prompt = $prompt
            stream = $false
        } | ConvertTo-Json -Depth 5

        # Executa a requisicao em uma tarefa
        $job = Start-Job -ScriptBlock {

            param(
                $url,
                $json
            )

            try {

                $response = Invoke-RestMethod `
                    -Uri $url `
                    -Method Post `
                    -Body $json `
                    -ContentType "application/json; charset=utf-8" `
                    -TimeoutSec 600

                return $response.response

            }
            catch {

                return "ERRO_OLLAMA: $($_.Exception.Message)"
            }

        } -ArgumentList $ollamaUrl, $body

        # ----------------------------------------------------
        # CONTADOR ENQUANTO O QWEN TRABALHA
        # ----------------------------------------------------

        while ($job.State -eq "Running") {

            $elapsed = (Get-Date) - $repoStart

            $timeText = "{0:D2}:{1:D2}:{2:D2}" -f `
                [int]$elapsed.TotalHours,
                $elapsed.Minutes,
                $elapsed.Seconds

            Write-Host "`rTempo neste projeto: $timeText    " `
                -NoNewline `
                -ForegroundColor Yellow

            Start-Sleep -Seconds 1
        }

        Write-Host ""

        $readme = Receive-Job $job -ErrorAction SilentlyContinue

        Remove-Job $job -Force -ErrorAction SilentlyContinue

        if (-not $readme) {

            Write-Host "O Ollama nao retornou uma resposta." -ForegroundColor Red
            continue
        }

        $readme = [string]$readme

        if ($readme.StartsWith("ERRO_OLLAMA:")) {

            Write-Host $readme -ForegroundColor Red
            continue
        }

    }
    catch {

        Write-Host ""
        Write-Host "Erro ao conversar com o Ollama." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        continue
    }

    # --------------------------------------------------------
    # LIMPAR ANSI
    # --------------------------------------------------------

    $readme = $readme -replace "\x1B\[[0-?]*[ -/]*[@-~]", ""

    # --------------------------------------------------------
    # REMOVER CARACTERES DE CONTROLE
    # --------------------------------------------------------

    $readme = $readme -replace "[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", ""

    # --------------------------------------------------------
    # REMOVER CODE FENCE
    # --------------------------------------------------------

    $readme = $readme.Trim()

    if ($readme.StartsWith('```markdown')) {
        $readme = $readme.Substring(11).Trim()
    }

    if ($readme.StartsWith('```md')) {
        $readme = $readme.Substring(5).Trim()
    }

    if ($readme.StartsWith('```')) {
        $readme = $readme.Substring(3).Trim()
    }

    if ($readme.EndsWith('```')) {

        $readme = $readme.Substring(
            0,
            $readme.Length - 3
        ).Trim()
    }

    # --------------------------------------------------------
    # SALVAR UTF-8
    # --------------------------------------------------------

    try {

        [System.IO.File]::WriteAllText(
            $readmeFile,
            $readme,
            [System.Text.UTF8Encoding]::new($false)
        )

        $repoTime = (Get-Date) - $repoStart

        $repoTimeText = "{0:D2}:{1:D2}:{2:D2}" -f `
            [int]$repoTime.TotalHours,
            $repoTime.Minutes,
            $repoTime.Seconds

        Write-Host "README criado com sucesso!" -ForegroundColor Green
        Write-Host "Tempo: $repoTimeText" -ForegroundColor Green
        Write-Host $readmeFile -ForegroundColor Green

    }
    catch {

        Write-Host "Erro ao salvar README." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Start-Sleep -Milliseconds 500
}

# ============================================================
# FINAL
# ============================================================

$globalTime = (Get-Date) - $globalStart

$globalTimeText = "{0:D2}:{1:D2}:{2:D2}" -f `
    [int]$globalTime.TotalHours,
    $globalTime.Minutes,
    $globalTime.Seconds

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "              PROCESSO FINALIZADO" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Repositorios processados: $totalRepos" -ForegroundColor Green
Write-Host "Tempo total: $globalTimeText" -ForegroundColor Green

Write-Host ""
Write-Host "READMEs salvos em:" -ForegroundColor Green
Write-Host $baseDir -ForegroundColor Green
Write-Host ""