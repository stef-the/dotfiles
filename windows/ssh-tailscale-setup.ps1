# ═══════════════════════════════════════════════════════════════
# OpenSSH Server — Tailscale-only
#
# Installs and starts Windows' built-in OpenSSH Server, then
# restricts inbound port 22 to the Tailscale CIDR (no port
# forwarding, no public exposure) — same model as the Obsidian
# CouchDB setup.
#
# Windows' default sshd_config requires admin accounts to use
# key-based auth (via administrators_authorized_keys) rather than
# a password — that default is kept as-is. Pass -PublicKey with
# your client's public key (e.g. contents of ~/.ssh/id_ed25519.pub
# on the connecting machine) to install it; otherwise add it
# manually afterward (see the summary this script prints).
# ═══════════════════════════════════════════════════════════════

#Requires -RunAsAdministrator

param(
    [string]$PublicKey = ""
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

# ─── Step 2: Install OpenSSH Server ─────────────────────────────
Write-Step "Installing OpenSSH Server"

$capability = Get-WindowsCapability -Online -Name "OpenSSH.Server*"
if ($capability.State -ne "Installed") {
    Add-WindowsCapability -Online -Name $capability.Name | Out-Null
    Write-Host "OpenSSH Server installed." -ForegroundColor Green
} else {
    Write-Host "OpenSSH Server already installed." -ForegroundColor Yellow
}

# ─── Step 3: Start and enable the service ──────────────────────
Write-Step "Starting sshd"

Set-Service -Name sshd -StartupType Automatic
Start-Service sshd
Write-Host "sshd running, set to start automatically." -ForegroundColor Green

# ─── Step 4: Windows Firewall — restrict to Tailscale CIDR ─────
Write-Step "Restricting port 22 to the Tailscale network"

Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue |
    Disable-NetFirewallRule

$ruleName = "SSH (Tailscale only)"
Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName $ruleName `
    -Direction Inbound -Protocol TCP -LocalPort 22 `
    -RemoteAddress 100.64.0.0/10 -Action Allow | Out-Null
Write-Host "Firewall restricted: only 100.64.0.0/10 (Tailscale) can reach port 22." -ForegroundColor Green

# ─── Step 5: Default shell -> PowerShell 7 if available ────────
Write-Step "Setting default SSH shell"

$pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwsh) {
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell `
        -Value $pwsh.Source -PropertyType String -Force | Out-Null
    Write-Host "Default shell: $($pwsh.Source)" -ForegroundColor Green
} else {
    Write-Host "pwsh not found, leaving default shell (cmd.exe)." -ForegroundColor Yellow
}

# ─── Step 6: Authorize a public key for admin login ────────────
Write-Step "Authorizing your public key"

$authKeysFile = "$env:ProgramData\ssh\administrators_authorized_keys"
if ($PublicKey) {
    Add-Content -Path $authKeysFile -Value $PublicKey
    # sshd refuses this file if it's not locked down to SYSTEM + Administrators only.
    icacls $authKeysFile /inheritance:r | Out-Null
    icacls $authKeysFile /grant "SYSTEM:F" "Administrators:F" | Out-Null
    Write-Host "Public key installed and permissions locked down." -ForegroundColor Green
} else {
    Write-Host "No -PublicKey given — you'll need to add one before you can log in (see below)." -ForegroundColor Yellow
}

# ─── Summary ─────────────────────────────────────────────────
Write-Step "DONE"
Write-Host ""
Write-Host "SSH is running, reachable only via Tailscale at:" -ForegroundColor Green
Write-Host "  ssh $env:USERNAME@$tsIp" -ForegroundColor White
Write-Host ""
if (-not $PublicKey) {
    Write-Host "To finish, on the connecting device run 'ssh-keygen' (if you don't already have a key)," -ForegroundColor Yellow
    Write-Host "then append its .pub contents to this file on this machine, locked to SYSTEM+Administrators only:" -ForegroundColor Yellow
    Write-Host "  $authKeysFile" -ForegroundColor White
    Write-Host "  icacls `"$authKeysFile`" /inheritance:r" -ForegroundColor White
    Write-Host "  icacls `"$authKeysFile`" /grant SYSTEM:F Administrators:F" -ForegroundColor White
}
Write-Host "That device must be on your tailnet (Tailscale running + signed in) to reach it." -ForegroundColor Yellow
