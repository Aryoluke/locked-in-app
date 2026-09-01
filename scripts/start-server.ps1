# LOCKED IN - Server start script (Windows)
# Runs the self-hosted backend. Set an alternate port with $env:PORT.
$ErrorActionPreference = "Stop"
$ServerDir = Join-Path $PSScriptRoot "..\server"
Set-Location $ServerDir

# Set production password / secret via env or .env (see .env.example)
if (-not $env:SECRET_KEY) {
    Write-Host "NOTE: SECRET_KEY not set - falling back to dev default. Set it in .env for production." -ForegroundColor Yellow
}

if (-not (Test-Path ".venv")) {
    Write-Host "Creating virtual environment..." -ForegroundColor Cyan
    python -m venv .venv
    & ".venv\Scripts\pip.exe" install -r requirements.txt
}

$port = if ($env:PORT) { $env:PORT } else { "8000" }
Write-Host "Starting LOCKED IN server on :$port (docs at /docs)" -ForegroundColor Green
& ".venv\Scripts\python.exe" -m uvicorn main:app --host 0.0.0.0 --port $port
