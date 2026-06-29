$ErrorActionPreference = "Stop"

try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
} catch {
}

$Title = "Ayanami StoneBlock 4 Installer"
$InstallerUrl = "https://raw.githubusercontent.com/Zerro15/Ayanami/main/src/AyanamiInstaller.ps1"
$TempDir = Join-Path $env:TEMP "AyanamiStoneBlock4Installer"
$InstallerPath = Join-Path $TempDir "AyanamiInstaller.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " $Title" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    if (-not (Test-Path -LiteralPath $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    }

    if ([Net.ServicePointManager]::SecurityProtocol -band [Net.SecurityProtocolType]::Tls12) {
        # TLS 1.2 is already enabled.
    } else {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }

    Write-Host "Скачиваю основной установщик..." -ForegroundColor Yellow
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "Ayanami-StoneBlock4-Installer")
    $installerBytes = $webClient.DownloadData($InstallerUrl)

    if (-not $installerBytes -or $installerBytes.Length -eq 0) {
        throw "GitHub Raw вернул пустой файл установщика."
    }

    [System.IO.File]::WriteAllBytes($InstallerPath, $installerBytes)
    $installerText = [System.Text.Encoding]::UTF8.GetString($installerBytes)

    Write-Host "Запускаю установщик..." -ForegroundColor Green
    $scriptBlock = [ScriptBlock]::Create($installerText)
    & $scriptBlock
} catch {
    Write-Host ""
    Write-Host "Не удалось скачать или запустить установщик Ayanami." -ForegroundColor Red
    Write-Host "Источник: $InstallerUrl" -ForegroundColor DarkGray
    Write-Host "Ошибка: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Проверь интернет, доступ к GitHub Raw и попробуй снова." -ForegroundColor Yellow
}
