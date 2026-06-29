# Ayanami StoneBlock 4 Installer

Простой установщик для друзей сервера **Ayanami StoneBlock 4 / Аянами**.

Он помогает скачать клиентский архив из GitHub Releases или распаковать локальный zip клиентской сборки в отдельную папку игры:

```text
%APPDATA%\.minecraft\Ayanami-StoneBlock4
```

Установщик не скачивает Minecraft, TLauncher, моды или аккаунты. Он не обходит лицензию и не меняет существующую `.minecraft`, кроме создания отдельной папки сборки. Если папка сборки уже существует, она переименовывается в backup.

В меню также есть проверка Java 21 и просмотр характеристик ПК: Windows, CPU, RAM, видеокарта, диски и текущая Java. Данные показываются локально в консоли и не отправляются.

## Быстрый запуск

Открой PowerShell и вставь:

```powershell
irm https://raw.githubusercontent.com/Zerro15/Ayanami/main/install.ps1 | iex
```

## Требования

- Windows 10/11
- PowerShell
- Java 21 x64, например Temurin/OpenJDK 21
- Доступ к GitHub Releases или локальный zip клиентской сборки Ayanami StoneBlock 4
- Лаунчер, который умеет запускать Minecraft 1.21.1 с NeoForge

## Установка через GitHub Releases

1. Запусти команду быстрого запуска.
2. Выбери пункт:

   ```text
   1) Установить сборку автоматически из GitHub Releases
   ```

3. Установщик получит latest release через GitHub API, найдёт asset:

   ```text
   Ayanami-StoneBlock4-client.zip
   ```

4. Архив будет скачан во временную папку, проверен по размеру и установлен в отдельную папку игры.

Если GitHub API недоступен или asset не найден, скачай zip вручную из Releases и выбери установку из локального zip.

## Сервер

- Название: Ayanami StoneBlock 4 / Аянами
- Modpack: FTB StoneBlock 4
- Version: 1.15.3
- Minecraft: 1.21.1
- Loader: NeoForge 21.1.233
- Java: 21
- Адрес: `199.83.103.157:25845`
- Рекомендуемая RAM клиенту: 8 GB

## Ручная установка из zip

1. Установи Java 21 x64.
2. Распакуй клиентский zip в:

   ```text
   %APPDATA%\.minecraft\Ayanami-StoneBlock4
   ```

3. Открой TLauncher или совместимый лаунчер.
4. Выбери/создай профиль Minecraft 1.21.1 с NeoForge 21.1.233.
5. Укажи папку игры:

   ```text
   %APPDATA%\.minecraft\Ayanami-StoneBlock4
   ```

6. Выдели примерно 8 GB RAM, если хватает памяти.
7. Запусти игру и подключись к серверу:

   ```text
   199.83.103.157:25845
   ```

Если TLauncher не видит сборку, лучше использовать Prism Launcher / FTB App / CurseForge App.

## Что логируется

Во время установки создаётся файл:

```text
%APPDATA%\.minecraft\Ayanami-StoneBlock4\install.log
```

В нём записываются шаги установки, проверки папок и количество `.jar` файлов в `mods`.

## Важно

Проект не содержит Minecraft, TLauncher, аккаунты, токены или способы обхода лицензии. Это только прозрачный helper-скрипт для установки уже имеющегося клиентского zip.
