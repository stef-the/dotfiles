# ═══════════════════════════════════════════════════════════════
# Windows 11 LTSC Post-Install Script
# Run as Administrator in PowerShell
# ═══════════════════════════════════════════════════════════════

#Requires -RunAsAdministrator

param(
    [switch]$SkipActivation,
    [switch]$SkipDebloat,
    [switch]$SkipWSL
)

$ErrorActionPreference = "Continue"

function Write-Step {
    param([string]$Message)
    Write-Host "`n═══ $Message ═══" -ForegroundColor Cyan
}

# ─── Step 1: Windows Activation (MAS - HWID) ─────────────────
if (-not $SkipActivation) {
    Write-Step "Activating Windows (MAS - HWID)"
    Write-Host "This uses Microsoft Activation Scripts for hardware-based activation."
    $confirm = Read-Host "Proceed? (y/n)"
    if ($confirm -eq 'y') {
        irm https://get.activated.win | iex
    }
}

# ─── Step 2: Debloat via Chris Titus WinUtil ─────────────────
if (-not $SkipDebloat) {
    Write-Step "Launching Chris Titus WinUtil for debloat"
    Write-Host "Select 'Desktop' preset, then run tweaks. Close when done."
    Write-Host "Recommended: Disable telemetry, remove Cortana, disable widgets"
    $confirm = Read-Host "Launch WinUtil? (y/n)"
    if ($confirm -eq 'y') {
        irm https://christitus.com/win | iex
    }
}

# ─── Step 3: Install Software via winget ──────────────────────
Write-Step "Installing software via winget"

$packages = @(
    # Gaming
    "Valve.Steam"
    "RiotGames.LeagueOfLegends.EUW"   # Riot Client (Valorant installs from here)
    "PrismLauncher.PrismLauncher"

    # Social / Media
    "Discord.Discord"
    "Spotify.Spotify"

    # Browser
    "Zen-Team.Zen-Browser"

    # Terminal & Shell
    "Microsoft.WindowsTerminal"

    # Dev Tools
    "Microsoft.VisualStudioCode"
    "JetBrains.IntelliJIDEA.Community" # Swap to .Ultimate if you get edu license
    "Git.Git"
    "GitHub.cli"
    "Docker.DockerDesktop"
    "OpenJS.NodeJS.LTS"
    "Python.Python.3.13"
    "EclipseAdoptium.Temurin.17.JDK"   # OpenJDK 17
    "GnuWin32.Make"
    "Rustlang.Rustup"

    # Security & Auth
    "AgileBits.1Password"
    "AgileBits.1Password.CLI"

    # GPU & Hardware
    "Nvidia.GeForceExperience"          # NVIDIA App

    # Networking
    "Tailscale.Tailscale"
    "Cloudflare.cloudflared"

    # Utilities
    "7zip.7zip"
    "Notepad++.Notepad++"
    "VideoLAN.VLC"
    "voidtools.Everything"              # Fast file search
    "Flow-Launcher.Flow-Launcher"       # App launcher (like Spotlight)
    "Microsoft.PowerToys"               # Window management, etc.
)

foreach ($pkg in $packages) {
    Write-Host "Installing $pkg..." -ForegroundColor Yellow
    winget install --id $pkg --accept-package-agreements --accept-source-agreements --silent
}

# ─── Step 4: Registry Tweaks ─────────────────────────────────
Write-Step "Applying registry tweaks"

# Auto-hide taskbar
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" -Name "Settings" -Value ([byte[]](0x30,0x00,0x00,0x00,0xfe,0xff,0xff,0xff,0x03,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x3e,0x00,0x00,0x00,0x28,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0x07,0x00,0x00,0x38,0x04,0x00,0x00,0x78,0x00,0x00,0x00,0x01,0x00,0x00,0x00)) -ErrorAction SilentlyContinue

# Disable web search in Start Menu
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f

# Show file extensions
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f

# Show hidden files
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f

# Disable Bing in search
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f

# Dark mode
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f

# Disable Game Bar (can conflict with some games)
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f

# Enable Hardware-Accelerated GPU Scheduling
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f

# Disable mouse acceleration (for FPS games like Valorant)
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d "0" /f
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d "0" /f
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d "0" /f

Write-Host "Registry tweaks applied. Some require restart." -ForegroundColor Green

# ─── Step 5: Windows Terminal Nord Theme ─────────────────────
Write-Step "Configuring Windows Terminal"

$wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

# Nord color scheme for Windows Terminal
$nordScheme = @'
{
    "name": "Nord",
    "background": "#2E3440",
    "foreground": "#D8DEE9",
    "cursorColor": "#D8DEE9",
    "selectionBackground": "#434C5E",
    "black": "#3B4252",
    "red": "#BF616A",
    "green": "#A3BE8C",
    "yellow": "#EBCB8B",
    "blue": "#81A1C1",
    "purple": "#B48EAD",
    "cyan": "#88C0D0",
    "white": "#E5E9F0",
    "brightBlack": "#4C566A",
    "brightRed": "#BF616A",
    "brightGreen": "#A3BE8C",
    "brightYellow": "#EBCB8B",
    "brightBlue": "#81A1C1",
    "brightPurple": "#B48EAD",
    "brightCyan": "#8FBCBB",
    "brightWhite": "#ECEFF4"
}
'@

Write-Host "Nord color scheme saved. After Windows Terminal installs:"
Write-Host "  1. Open Settings > Color Schemes > Add > paste from nord-theme.json"
Write-Host "  2. Or the install-wsl.sh script will configure this automatically"

# Save Nord scheme to a file for easy import
$nordScheme | Out-File -FilePath "$env:USERPROFILE\nord-terminal-theme.json" -Encoding utf8

# ─── Step 6: Install WSL2 ────────────────────────────────────
if (-not $SkipWSL) {
    Write-Step "Installing WSL2 + Ubuntu"
    wsl --install -d Ubuntu
    Write-Host ""
    Write-Host "WSL will require a RESTART. After restarting:" -ForegroundColor Yellow
    Write-Host "  1. Ubuntu will finish setup (create username/password)"
    Write-Host "  2. Then run: cd ~ && git clone https://github.com/stef-the/dotfiles.git && bash dotfiles/scripts/install-wsl.sh"
    Write-Host ""
}

# ─── Step 7: Power Plan for Gaming ───────────────────────────
Write-Step "Setting power plan to High Performance"
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# ─── Summary ─────────────────────────────────────────────────
Write-Step "POST-INSTALL COMPLETE"
Write-Host ""
Write-Host "Installed:" -ForegroundColor Green
foreach ($pkg in $packages) { Write-Host "  - $pkg" }
Write-Host ""
Write-Host "Manual steps remaining:" -ForegroundColor Yellow
Write-Host "  1. RESTART the computer (for WSL + registry changes)"
Write-Host "  2. Set up WSL (run install-wsl.sh after Ubuntu finishes setup)"
Write-Host "  3. Sign in to: Zen Browser, 1Password, Steam, Discord, Spotify, Tailscale"
Write-Host "  4. Install Behringer UMC22 ASIO drivers from behringer.com"
Write-Host "  5. Install NVIDIA drivers via NVIDIA App"
Write-Host "  6. Set up JetBrains educational license for IntelliJ"
Write-Host "  7. Configure VS Code: Settings Sync or run extensions installer"
Write-Host ""
Write-Host "Press any key to restart, or Ctrl+C to skip restart..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Restart-Computer
