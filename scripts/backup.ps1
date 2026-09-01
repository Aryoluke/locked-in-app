# LOCKED IN - Automatic daily backup (Windows)
# Copies the SQLite database to a dated file, pruning backups older than KEEP_DAYS.
# Schedule daily via Task Scheduler:  schtasks /create /tn "LockedInBackup" /tr "<this script>" /sc daily /st 03:00
$ErrorActionPreference = "Stop"
$ServerDir = Join-Path $PSScriptRoot "..\server"
$Db = Join-Path $ServerDir "locked_in.db"
$BackupRoot = Join-Path $PSScriptRoot "..\backups"
$KeepDays = 30

if (-not (Test-Path $Db)) {
    Write-Host "No database found at $Db - skipping." -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path $BackupRoot)) { New-Item -ItemType Directory -Path $BackupRoot | Out-Null }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$dest = Join-Path $BackupRoot "locked_in_$stamp.db"
Copy-Item $Db $dest
Write-Host "Backed up to $dest" -ForegroundColor Green

# Prune old backups
$cutoff = (Get-Date).AddDays(-$KeepDays)
Get-ChildItem $BackupRoot -Filter "locked_in_*.db" | Where-Object { $_.LastWriteTime -lt $cutoff } | ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Host "Pruned $($_.Name)" -ForegroundColor DarkGray
}
