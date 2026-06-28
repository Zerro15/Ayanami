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

    Write-Host "Скачиваю основной установщик..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath -UseBasicParsing

    if (-not (Test-Path -LiteralPath $InstallerPath)) {
        throw "Файл установщика не появился после скачивания."
    }

    Write-Host "Запускаю установщик..." -ForegroundColor Green
    & $InstallerPath
} catch {
    Write-Host ""
    Write-Host "Не удалось скачать или запустить установщик Ayanami." -ForegroundColor Red
    Write-Host "Источник: $InstallerUrl" -ForegroundColor DarkGray
    Write-Host "Ошибка: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Проверь интернет, доступ к GitHub Raw и попробуй снова." -ForegroundColor Yellow
}
