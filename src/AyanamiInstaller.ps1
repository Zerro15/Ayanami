$ErrorActionPreference = "Stop"

try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
} catch {
}

$Script:PackName = "Ayanami StoneBlock 4"
$Script:PackFolderName = "Ayanami-StoneBlock4"
$Script:ServerAddress = "199.83.103.157:25845"
$Script:MinecraftVersion = "1.21.1"
$Script:LoaderVersion = "NeoForge 21.1.233"
$Script:JavaVersion = "21"
$Script:RecommendedRam = "8 GB"
$Script:ReleaseApiUrl = "https://api.github.com/repos/Zerro15/Ayanami/releases/latest"
$Script:ReleaseAssetName = "Ayanami-StoneBlock4-client.zip"
$Script:MinimumClientZipBytes = 500MB
$Script:SessionLog = New-Object System.Collections.Generic.List[string]

function Add-SessionLog {
    param([string]$Message)

    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    $Script:SessionLog.Add($line) | Out-Null
}

function Write-Info {
    param([string]$Message)

    Write-Host $Message -ForegroundColor Cyan
    Add-SessionLog $Message
}

function Write-Warn {
    param([string]$Message)

    Write-Host $Message -ForegroundColor Yellow
    Add-SessionLog "WARN: $Message"
}

function Write-Problem {
    param([string]$Message)

    Write-Host $Message -ForegroundColor Red
    Add-SessionLog "ERROR: $Message"
}

function Get-MinecraftDir {
    if (-not $env:APPDATA) {
        throw "APPDATA не найден. Запусти установщик в обычном Windows PowerShell."
    }

    return Join-Path $env:APPDATA ".minecraft"
}

function Get-JavaVersionInfo {
    $result = [ordered]@{
        Found = $false
        IsJava21 = $false
        Raw = ""
        Major = $null
    }

    try {
        $output = & java -version 2>&1 | Out-String
        $result.Raw = $output.Trim()
        $result.Found = $true

        $match = [regex]::Match($output, 'version "([^"]+)"')
        if (-not $match.Success) {
            $match = [regex]::Match($output, 'openjdk\s+([0-9][^\s]*)')
        }

        if ($match.Success) {
            $version = $match.Groups[1].Value
            if ($version.StartsWith("1.")) {
                $major = ($version -split "\.")[1]
            } else {
                $major = ($version -split "\.")[0]
            }

            $result.Major = $major
            $result.IsJava21 = ($major -eq "21")
        }
    } catch {
        $result.Raw = $_.Exception.Message
    }

    return [pscustomobject]$result
}

function Show-Java21Help {
    Write-Host ""
    Write-Warn "Java 21 не найдена или java в PATH указывает на другую версию."
    Write-Host "Что поставить:" -ForegroundColor Yellow
    Write-Host "1. Eclipse Temurin / OpenJDK 21 x64 для Windows."
    Write-Host "2. После установки перезапусти PowerShell."
    Write-Host "3. Проверь командой: java -version"
    Write-Host ""
    Write-Host "Установщик Java сам не ставит и ничего молча не меняет." -ForegroundColor DarkGray
}

function Test-Java21 {
    Write-Info "Проверяю Java 21..."
    $java = Get-JavaVersionInfo

    if ($java.Found) {
        Write-Host ""
        Write-Host $java.Raw -ForegroundColor DarkGray
    }

    if ($java.IsJava21) {
        Write-Host ""
        Write-Host "Java 21 найдена." -ForegroundColor Green
        Add-SessionLog "Java 21 found."
        return $true
    }

    Show-Java21Help
    return $false
}

function New-ClientReadme {
    param([string]$InstallDir)

    return @"
Сервер: Ayanami StoneBlock 4
Адрес: $Script:ServerAddress
Minecraft: $Script:MinecraftVersion
Loader: $Script:LoaderVersion
Java: $Script:JavaVersion
RAM: $Script:RecommendedRam, ориентируйся от максимального доступного у клиента
Папка сборки: $InstallDir

Инструкция:
1. Открой TLauncher.
2. Выбери/создай версию Minecraft 1.21.1 с NeoForge.
3. Укажи папку игры:
   $InstallDir
4. Выдели 8 GB RAM.
5. Запусти игру.
6. Подключись к серверу:
   $Script:ServerAddress

Если TLauncher не видит сборку, лучше использовать Prism Launcher / FTB App / CurseForge App.
"@
}

function Copy-ExtractedPack {
    param(
        [string]$ExtractDir,
        [string]$TargetDir
    )

    $contentRoot = $ExtractDir
    $rootMods = Join-Path $ExtractDir "mods"
    $rootConfig = Join-Path $ExtractDir "config"

    if (-not ((Test-Path -LiteralPath $rootMods) -and (Test-Path -LiteralPath $rootConfig))) {
        $directories = @(Get-ChildItem -LiteralPath $ExtractDir -Directory)
        if ($directories.Count -eq 1) {
            $candidate = $directories[0].FullName
            if ((Test-Path -LiteralPath (Join-Path $candidate "mods")) -and (Test-Path -LiteralPath (Join-Path $candidate "config"))) {
                $contentRoot = $candidate
                Write-Info "В архиве найдена одна корневая папка. Переношу её содержимое без лишнего уровня вложенности."
            }
        }
    }

    Get-ChildItem -LiteralPath $contentRoot -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $TargetDir -Recurse -Force
    }
}

function Install-ZipPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ZipPath,

        [string]$SourceLabel = "zip"
    )

    Write-Host ""
    Write-Info "Установка сборки из $SourceLabel."
    $zipPath = $ZipPath.Trim().Trim('"')

    if (-not (Test-Path -LiteralPath $zipPath -PathType Leaf)) {
        Write-Problem "Файл не найден: $zipPath"
        return $false
    }

    $minecraftDir = Get-MinecraftDir
    if (-not (Test-Path -LiteralPath $minecraftDir)) {
        Write-Warn "Папка .minecraft не найдена: $minecraftDir"
        $answer = Read-Host "Создать её? Введи Y для подтверждения"
        if ($answer -notin @("Y", "y", "Д", "д")) {
            Write-Warn "Установка отменена пользователем."
            return $false
        }
        New-Item -ItemType Directory -Path $minecraftDir -Force | Out-Null
        Write-Info "Создана папка: $minecraftDir"
    }

    $targetDir = Join-Path $minecraftDir $Script:PackFolderName
    if (Test-Path -LiteralPath $targetDir) {
        $backupDir = Join-Path $minecraftDir ("{0}.backup-{1}" -f $Script:PackFolderName, (Get-Date -Format "yyyyMMdd-HHmmss"))
        Write-Warn "Папка сборки уже существует. Переименовываю в backup:"
        Write-Host $backupDir -ForegroundColor Yellow
        Rename-Item -LiteralPath $targetDir -NewName (Split-Path -Leaf $backupDir)
        Add-SessionLog "Existing pack folder moved to $backupDir"
    }

    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Add-SessionLog "Target folder created: $targetDir"

    $extractDir = Join-Path ([System.IO.Path]::GetTempPath()) ("AyanamiExtract-{0}" -f ([guid]::NewGuid().ToString("N")))
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

    try {
        Write-Info "Распаковываю архив..."
        Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force
        Copy-ExtractedPack -ExtractDir $extractDir -TargetDir $targetDir

        $modsDir = Join-Path $targetDir "mods"
        $configDir = Join-Path $targetDir "config"
        $kubejsDir = Join-Path $targetDir "kubejs"
        $modsOk = Test-Path -LiteralPath $modsDir -PathType Container
        $configOk = Test-Path -LiteralPath $configDir -PathType Container
        $kubejsOk = Test-Path -LiteralPath $kubejsDir -PathType Container
        $jarCount = 0

        if ($modsOk) {
            $jarCount = @(Get-ChildItem -LiteralPath $modsDir -Filter "*.jar" -File -ErrorAction SilentlyContinue).Count
        }

        Write-Info "Проверка результата:"
        Write-Host "mods/: $modsOk"
        Write-Host "config/: $configOk"
        Write-Host "kubejs/: $kubejsOk"
        Write-Host "Количество jar в mods/: $jarCount"

        if (-not $modsOk -or -not $configOk) {
            Write-Warn "Архив распакован, но mods/ или config/ не найдены. Проверь, что выбран именно клиентский zip сборки."
        }

        $readmePath = Join-Path $targetDir "README_CLIENT.txt"
        New-ClientReadme -InstallDir $targetDir | Set-Content -LiteralPath $readmePath -Encoding UTF8
        Add-SessionLog "README_CLIENT.txt written."

        Add-SessionLog "mods exists: $modsOk"
        Add-SessionLog "config exists: $configOk"
        Add-SessionLog "kubejs exists: $kubejsOk"
        Add-SessionLog "mods jar count: $jarCount"

        $logPath = Join-Path $targetDir "install.log"
        $Script:SessionLog | Set-Content -LiteralPath $logPath -Encoding UTF8

        Write-Host ""
        Write-Host "Готово. Сборка установлена в:" -ForegroundColor Green
        Write-Host $targetDir -ForegroundColor Green
        Write-Host "Лог: $logPath" -ForegroundColor DarkGray
        return $true
    } catch {
        Write-Problem "Ошибка установки: $($_.Exception.Message)"
        $logPath = Join-Path $targetDir "install.log"
        Add-SessionLog "Install failed: $($_.Exception.Message)"
        $Script:SessionLog | Set-Content -LiteralPath $logPath -Encoding UTF8
        return $false
    } finally {
        if (Test-Path -LiteralPath $extractDir) {
            Remove-Item -LiteralPath $extractDir -Recurse -Force
        }
    }
}

function Install-FromLocalZip {
    Write-Host ""
    Write-Info "Установка сборки из локального zip."
    $zipInput = Read-Host "Вставь путь к zip-файлу клиентской сборки"
    [void](Install-ZipPackage -ZipPath $zipInput -SourceLabel "локального zip")
}

function Install-FromGitHubRelease {
    Write-Host ""
    Write-Info "Автоматическая установка из GitHub Releases."
    Write-Host "Ищу latest release: $Script:ReleaseApiUrl" -ForegroundColor DarkGray

    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("AyanamiRelease-{0}" -f ([guid]::NewGuid().ToString("N")))
    $tempZip = Join-Path $tempDir $Script:ReleaseAssetName
    $installed = $false

    try {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        if ([Net.ServicePointManager]::SecurityProtocol -band [Net.SecurityProtocolType]::Tls12) {
            # TLS 1.2 is already enabled.
        } else {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        }

        $headers = @{
            "User-Agent" = "Ayanami-StoneBlock4-Installer"
            "Accept" = "application/vnd.github+json"
        }

        Add-SessionLog "Fetching latest GitHub release metadata."
        $release = Invoke-RestMethod -Uri $Script:ReleaseApiUrl -Headers $headers -ErrorAction Stop
        $asset = @($release.assets) | Where-Object { $_.name -eq $Script:ReleaseAssetName } | Select-Object -First 1

        if (-not $asset) {
            Write-Problem "В latest release не найден asset: $Script:ReleaseAssetName"
            Write-Warn "Используй пункт меню 2: установка из локального zip."
            return
        }

        Write-Info ("Найден архив: {0} ({1:N1} MB)" -f $asset.name, ($asset.size / 1MB))
        if ([double]$asset.size -lt $Script:MinimumClientZipBytes) {
            Write-Problem ("Размер asset меньше 500 MB: {0:N1} MB. Скачивание остановлено." -f ($asset.size / 1MB))
            Write-Warn "Проверь релиз GitHub или используй пункт меню 2."
            return
        }

        Write-Info "Скачиваю клиентский архив во временную папку..."
        Write-Host $tempZip -ForegroundColor DarkGray
        Add-SessionLog "Downloading release asset: $($asset.browser_download_url)"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip -Headers @{ "User-Agent" = "Ayanami-StoneBlock4-Installer" } -UseBasicParsing

        if (-not (Test-Path -LiteralPath $tempZip -PathType Leaf)) {
            throw "Файл не появился после скачивания."
        }

        $downloaded = Get-Item -LiteralPath $tempZip
        Add-SessionLog ("Downloaded zip size: {0} bytes" -f $downloaded.Length)
        if ($downloaded.Length -lt $Script:MinimumClientZipBytes) {
            throw ("Скачанный файл меньше 500 MB: {0:N1} MB" -f ($downloaded.Length / 1MB))
        }

        Write-Info ("Скачано: {0:N1} MB" -f ($downloaded.Length / 1MB))
        $installed = Install-ZipPackage -ZipPath $tempZip -SourceLabel "GitHub Releases"
    } catch {
        Write-Problem "Автоматическая установка не удалась: $($_.Exception.Message)"
        Write-Warn "Можно скачать архив вручную из GitHub Releases и выбрать пункт меню 2."
        Add-SessionLog "GitHub release install failed: $($_.Exception.Message)"
    } finally {
        if ($installed -and (Test-Path -LiteralPath $tempZip)) {
            Remove-Item -LiteralPath $tempZip -Force
            Add-SessionLog "Temporary release zip deleted."
        }

        if (Test-Path -LiteralPath $tempDir) {
            $remaining = @(Get-ChildItem -LiteralPath $tempDir -Force -ErrorAction SilentlyContinue)
            if ($remaining.Count -eq 0) {
                Remove-Item -LiteralPath $tempDir -Force
            }
        }
    }
}

function Show-TLauncherGuide {
    $minecraftDir = Get-MinecraftDir
    $packDir = Join-Path $minecraftDir $Script:PackFolderName

    Write-Host ""
    Write-Host "Инструкция для TLauncher" -ForegroundColor Cyan
    Write-Host "1. Открой TLauncher."
    Write-Host "2. Выбери или создай версию Minecraft $Script:MinecraftVersion с $Script:LoaderVersion."
    Write-Host "3. Укажи папку игры:"
    Write-Host "   $packDir" -ForegroundColor Yellow
    Write-Host "4. Выдели примерно $Script:RecommendedRam RAM, если хватает памяти."
    Write-Host "5. Запусти игру."
    Write-Host "6. Подключись к серверу:"
    Write-Host "   $Script:ServerAddress" -ForegroundColor Green
    Write-Host ""
    Write-Host "Если TLauncher не видит сборку, лучше использовать Prism Launcher / FTB App / CurseForge App." -ForegroundColor Yellow
}

function Format-BytesGiB {
    param([double]$Bytes)

    if ($Bytes -le 0) {
        return "неизвестно"
    }

    return ("{0:N1} GB" -f ($Bytes / 1GB))
}

function Write-SpecLine {
    param(
        [string]$Name,
        [string]$Value
    )

    $line = "{0}: {1}" -f $Name, $Value
    Write-Host $line
    Add-SessionLog $line
}

function Show-ComputerSpecs {
    Write-Host ""
    Write-Host "Характеристики компьютера" -ForegroundColor Cyan
    Write-Host "Данные только показываются в консоли и не отправляются." -ForegroundColor DarkGray
    Add-SessionLog "Computer specs requested."

    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $gpus = @(Get-CimInstance Win32_VideoController | Where-Object { $_.Name })
        $drives = @(Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3")
        $java = Get-JavaVersionInfo

        Write-Host ""
        Write-SpecLine "Windows" ("{0} build {1}" -f $os.Caption, $os.BuildNumber)
        Write-SpecLine "Процессор" $cpu.Name.Trim()
        Write-SpecLine "Ядра / потоки" ("{0} / {1}" -f $cpu.NumberOfCores, $cpu.NumberOfLogicalProcessors)
        Write-SpecLine "ОЗУ всего" (Format-BytesGiB -Bytes ([double]$os.TotalVisibleMemorySize * 1KB))
        Write-SpecLine "ОЗУ свободно сейчас" (Format-BytesGiB -Bytes ([double]$os.FreePhysicalMemory * 1KB))

        if ($gpus.Count -gt 0) {
            for ($i = 0; $i -lt $gpus.Count; $i++) {
                $gpu = $gpus[$i]
                $gpuRam = if ($gpu.AdapterRAM) { Format-BytesGiB -Bytes ([double]$gpu.AdapterRAM) } else { "неизвестно" }
                Write-SpecLine ("Видеокарта {0}" -f ($i + 1)) ("{0} ({1})" -f $gpu.Name, $gpuRam)
            }
        } else {
            Write-SpecLine "Видеокарта" "не найдена"
        }

        foreach ($drive in $drives) {
            Write-SpecLine ("Диск {0}" -f $drive.DeviceID) ("свободно {0} из {1}" -f (Format-BytesGiB -Bytes ([double]$drive.FreeSpace)), (Format-BytesGiB -Bytes ([double]$drive.Size)))
        }

        if ($java.Found) {
            Write-SpecLine "Java" ($java.Raw -replace "`r?`n", " | ")
        } else {
            Write-SpecLine "Java" "не найдена в PATH"
        }

        $totalRamGb = ([double]$os.TotalVisibleMemorySize * 1KB) / 1GB
        Write-Host ""
        if ($totalRamGb -ge 12) {
            Write-Host "Для клиента можно пробовать выделить 8 GB RAM." -ForegroundColor Green
        } elseif ($totalRamGb -ge 8) {
            Write-Host "ОЗУ немного впритык: попробуй 6 GB RAM, а 8 GB только если Windows не забита." -ForegroundColor Yellow
        } else {
            Write-Host "ОЗУ мало для комфортного StoneBlock 4. Лучше закрыть лишнее и выделять 4-6 GB." -ForegroundColor Yellow
        }
    } catch {
        Write-Problem "Не удалось прочитать характеристики: $($_.Exception.Message)"
    }
}

function Show-Menu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Ayanami StoneBlock 4 Installer" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "1) Установить сборку автоматически из GitHub Releases"
    Write-Host "2) Установить сборку из локального zip"
    Write-Host "3) Проверить Java 21"
    Write-Host "4) Показать характеристики компьютера"
    Write-Host "5) Показать инструкцию для TLauncher"
    Write-Host "0) Выход"
    Write-Host ""
}

Add-SessionLog "Installer started."

$running = $true
while ($running) {
    Show-Menu
    $choice = Read-Host "Выбери пункт"

    switch ($choice) {
        "1" { Install-FromGitHubRelease }
        "2" { Install-FromLocalZip }
        "3" { [void](Test-Java21) }
        "4" { Show-ComputerSpecs }
        "5" { Show-TLauncherGuide }
        "0" {
            Add-SessionLog "Installer exited."
            Write-Host "Пока. Удачной игры на Ayanami!" -ForegroundColor Green
            $running = $false
        }
        default {
            Write-Warn "Неизвестный пункт меню."
        }
    }
}
