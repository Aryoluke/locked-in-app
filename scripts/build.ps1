# LOCKED IN - Build all platform installers from the single Flutter codebase.
# Requires: Flutter SDK installed and on PATH.
$ErrorActionPreference = "Stop"
$AppDir = Join-Path $PSScriptRoot "..\app"
Set-Location $AppDir

if (-not (Test-Path "android")) {
    Write-Host "Platform scaffolding not present. Running 'flutter create .'..." -ForegroundColor Cyan
    flutter create .
}

Write-Host "Fetching dependencies..." -ForegroundColor Cyan
flutter pub get

$target = $args[0]
switch ($target) {
    "android" {
        Write-Host "Building Android APK..." -ForegroundColor Green
        flutter build apk --release
        Write-Host "APK at: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Magenta
    }
    "windows" {
        Write-Host "Building Windows EXE..." -ForegroundColor Green
        flutter build windows --release
        Write-Host "EXE at: build\windows\x64\runner\Release\locked_in.exe" -ForegroundColor Magenta
    }
    "web" {
        Write-Host "Building web app (for iPhone/any browser)..." -ForegroundColor Green
        flutter build web --release
        Write-Host "Web build at: build\web  (host this folder on the server for phone access)" -ForegroundColor Magenta
    }
    default {
        Write-Host "Usage: .\build.ps1 [android|windows|web]" -ForegroundColor Yellow
        Write-Host "   android  -> Android APK"
        Write-Host "   windows  -> Windows EXE"
        Write-Host "   web      -> iPhone web app (HTML)"
    }
}
