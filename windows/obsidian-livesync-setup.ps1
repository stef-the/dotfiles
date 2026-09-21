# ═══════════════════════════════════════════════════════════════
# Obsidian Self-Hosted LiveSync — CouchDB backend
# Run as Administrator in PowerShell, on the machine that will
# act as the sync host (stef-desktop).
#
# Sets up CouchDB in Docker, reachable ONLY over Tailscale
# (firewall-restricted to the tailnet CIDR — no port forwarding,
# no public exposure). Any device on your tailnet (Mac, phone,
# other PCs) can then point the "Self-hosted LiveSync" Obsidian
# plugin at this machine's Tailscale IP.
# ═══════════════════════════════════════════════════════════════

#Requires -RunAsAdministrator

param(
    [string]$DbName = "obsidian",
    [string]$InstallDir = "$env:USERPROFILE\Dev\tools\obsidian-sync"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

# ─── Step 1: Find Tailscale IP ─────────────────────────────────
Write-Step "Detecting Tailscale IP"

$tsIp = (& tailscale ip -4 2>$null | Select-Object -First 1)
if (-not $tsIp) {
    Write-Host "Could not detect a Tailscale IP. Is Tailscale installed and signed in?" -ForegroundColor Red
    Write-Host "Run 'tailscale up' first, then re-run this script." -ForegroundColor Yellow
    exit 1
}
Write-Host "Tailscale IP: $tsIp" -ForegroundColor Green

# ─── Step 2: Check Docker ──────────────────────────────────────
Write-Step "Checking Docker"

$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
    Write-Host "Docker not found. Install Docker Desktop first (winget install Docker.DockerDesktop)." -ForegroundColor Red
    exit 1
}
docker info > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker daemon not running. Start Docker Desktop and re-run this script." -ForegroundColor Red
    exit 1
}
Write-Host "Docker is running." -ForegroundColor Green

# ─── Step 3: Generate config ────────────────────────────────────
Write-Step "Writing CouchDB config to $InstallDir"

New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
New-Item -ItemType Directory -Path "$InstallDir\data" -Force | Out-Null

$envFile = "$InstallDir\.env"
if (Test-Path $envFile) {
    Write-Host ".env already exists, reusing existing credentials." -ForegroundColor Yellow
    $couchPassword = (Get-Content $envFile | Select-String "COUCHDB_PASSWORD=(.+)").Matches.Groups[1].Value
} else {
    Add-Type -AssemblyName System.Web
    $couchPassword = [System.Web.Security.Membership]::GeneratePassword(24, 4) -replace '[^a-zA-Z0-9]', ''
    @"
COUCHDB_USER=admin
COUCHDB_PASSWORD=$couchPassword
"@ | Out-File -FilePath $envFile -Encoding utf8 -NoNewline
    Write-Host "Generated new admin credentials -> $envFile" -ForegroundColor Green
}

$localIni = @"
[couchdb]
single_node=true
max_document_size = 50000000

[chttpd]
require_valid_user = true
max_http_request_size = 4294967296
enable_cors = true
bind_address = 0.0.0.0

[chttpd_auth]
require_valid_user = true

[httpd]
WWW-Authenticate = Basic realm="couchdb"
enable_cors = true

[cors]
origins = app://obsidian.md,capacitor://localhost,http://localhost
credentials = true
methods = GET, PUT, POST, HEAD, DELETE
headers = accept, authorization, content-type, origin, referer
"@
$localIni | Out-File -FilePath "$InstallDir\local.ini" -Encoding utf8

$composeFile = @"
services:
  couchdb:
    image: couchdb:3
    container_name: obsidian-couchdb
    restart: unless-stopped
    env_file: .env
    ports:
      - "5984:5984"
    volumes:
      - ./data:/opt/couchdb/data
      - ./local.ini:/opt/couchdb/etc/local.ini
"@
$composeFile | Out-File -FilePath "$InstallDir\docker-compose.yml" -Encoding utf8

# ─── Step 4: Windows Firewall — restrict to Tailscale CIDR ─────
Write-Step "Restricting port 5984 to the Tailscale network"

$ruleName = "Obsidian CouchDB (Tailscale only)"
Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName $ruleName `
    -Direction Inbound -Protocol TCP -LocalPort 5984 `
    -RemoteAddress 100.64.0.0/10 -Action Allow | Out-Null
# Do NOT add a separate "block others" rule: Windows Firewall gives Block rules
# precedence over Allow rules regardless of scope, so a generic block here would
# also block the Tailscale traffic we just allowed. Windows already default-denies
# inbound connections with no matching Allow rule, so scoping this one rule to the
# Tailscale CIDR is sufficient on its own.
Write-Host "Firewall restricted: only 100.64.0.0/10 (Tailscale) can reach port 5984." -ForegroundColor Green

# ─── Step 5: Start CouchDB ──────────────────────────────────────
Write-Step "Starting CouchDB"

Push-Location $InstallDir
docker compose up -d
Pop-Location

Write-Host "Waiting for CouchDB to come up..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# ─── Step 6: Create the sync database ──────────────────────────
Write-Step "Creating database '$DbName'"

$authHeader = "admin:$couchPassword"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($authHeader)
$b64 = [Convert]::ToBase64String($bytes)
$headers = @{ Authorization = "Basic $b64" }

try {
    Invoke-RestMethod -Uri "http://127.0.0.1:5984/$DbName" -Method Put -Headers $headers -ErrorAction Stop | Out-Null
    Write-Host "Database '$DbName' created." -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 412) {
        Write-Host "Database '$DbName' already exists." -ForegroundColor Yellow
    } else {
        Write-Host "Failed to create database: $_" -ForegroundColor Red
    }
}

# ─── Summary ─────────────────────────────────────────────────
Write-Step "DONE"
Write-Host ""
Write-Host "CouchDB is running, reachable only via Tailscale at:" -ForegroundColor Green
Write-Host "  http://${tsIp}:5984/$DbName" -ForegroundColor White
Write-Host ""
Write-Host "In the Obsidian 'Self-hosted LiveSync' plugin settings on EACH device:" -ForegroundColor Cyan
Write-Host "  URI:      http://${tsIp}:5984/$DbName" -ForegroundColor Gray
Write-Host "  Username: admin" -ForegroundColor Gray
Write-Host "  Password: (see $envFile on this machine)" -ForegroundColor Gray
Write-Host ""
Write-Host "Credentials saved to: $envFile — back this up somewhere safe (e.g. 1Password)." -ForegroundColor Yellow
Write-Host "That device must be on your tailnet (Tailscale running + signed in) to reach it." -ForegroundColor Yellow
