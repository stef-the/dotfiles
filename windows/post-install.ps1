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
    "JetBrains.IntelliJIDEA.Ultimate"  # Free via JetBrains edu license (bristol.ac.uk email)
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
Write-Step "AUTOMATED INSTALL COMPLETE"
Write-Host ""
Write-Host "Installed:" -ForegroundColor Green
foreach ($pkg in $packages) { Write-Host "  - $pkg" }

# ─── Interactive Setup Wizard ─────────────────────────────────
Write-Step "SETUP WIZARD — Manual Steps"
Write-Host "I'll walk you through everything that needs manual attention." -ForegroundColor Cyan
Write-Host ""

function Wait-ForUser {
    param([string]$Task, [string]$Detail, [string]$Hint = "")
    Write-Host ""
    Write-Host "[ ] $Task" -ForegroundColor Yellow
    if ($Detail) { Write-Host "    $Detail" -ForegroundColor Gray }
    if ($Hint) { Write-Host "    Hint: $Hint" -ForegroundColor DarkCyan }
    Write-Host ""
    $done = Read-Host "    Done? (y to continue, s to skip)"
    if ($done -eq 'y') {
        Write-Host "    [x] $Task" -ForegroundColor Green
    } else {
        Write-Host "    [-] Skipped: $Task" -ForegroundColor DarkGray
    }
}

# --- Restart prompt ---
Write-Host ""
Write-Host "A RESTART is needed for WSL and registry changes to take effect." -ForegroundColor Red
Write-Host "After restart, run this script again with:" -ForegroundColor Yellow
Write-Host '  .\post-install.ps1 -SkipActivation -SkipDebloat -SkipWSL' -ForegroundColor White
Write-Host "to resume the interactive wizard, or continue now if you don't need WSL yet." -ForegroundColor Yellow
Write-Host ""
$restart = Read-Host "Restart now? (y = restart, n = continue wizard without restart)"
if ($restart -eq 'y') {
    Write-Host "Restarting in 5 seconds... Run the wizard again after reboot." -ForegroundColor Cyan
    Start-Sleep -Seconds 5
    Restart-Computer
    exit
}

Write-Host ""
Write-Host "═══ Continuing setup wizard... ═══" -ForegroundColor Cyan
Write-Host ""

# --- WSL Setup ---
Wait-ForUser `
    "Set up WSL Ubuntu" `
    "Open Ubuntu from Start Menu. Create your username and password." `
    "Use the same username as your Mac (stefanluke) for consistency."

Wait-ForUser `
    "Install dotfiles in WSL" `
    "In the Ubuntu terminal, run:" `
    "git clone https://github.com/stef-the/dotfiles.git ~/dotfiles && bash ~/dotfiles/scripts/install-wsl.sh"

# --- NVIDIA ---
Wait-ForUser `
    "Set up NVIDIA drivers" `
    "Open NVIDIA App (installed via winget). It will detect your 3080 Ti and offer the latest driver." `
    "Use 'Game Ready Driver' for gaming. Enable Resizable BAR in NVIDIA Control Panel."

# --- Audio ---
Wait-ForUser `
    "Install Behringer UMC22 drivers" `
    "Download ASIO driver from: behringer.com/downloads > UMC22" `
    "After install, set UMC22 as default audio output in Sound Settings."

# --- Tailscale ---
Wait-ForUser `
    "Sign in to Tailscale" `
    "Open Tailscale from system tray > Sign in with your account." `
    "This reconnects you to your Linux box with 4TB storage."

# --- Browser ---
Wait-ForUser `
    "Set up Zen Browser" `
    "Open Zen Browser > Sign in with your Firefox account to sync from your Mac." `
    "Bookmarks, extensions, and settings should sync automatically."

# --- 1Password ---
Wait-ForUser `
    "Sign in to 1Password" `
    "Open 1Password > Sign in with your account." `
    "Install the browser extension in Zen Browser too."

# --- Steam ---
Wait-ForUser `
    "Sign in to Steam" `
    "Open Steam > Sign in." `
    "Set game install location to D:\Games (or your preferred drive/partition)."

# --- Valorant ---
Wait-ForUser `
    "Install Valorant" `
    "Open Riot Client (installed as 'League of Legends EUW' package — it's the Riot launcher)." `
    "Sign in to Riot account > Install Valorant from the launcher."

# --- Discord ---
Wait-ForUser `
    "Sign in to Discord" `
    "Open Discord > Sign in with your account." `
    ""

# --- Spotify ---
Wait-ForUser `
    "Sign in to Spotify" `
    "Open Spotify > Sign in with your account." `
    ""

# --- VS Code ---
Wait-ForUser `
    "Configure VS Code" `
    "Open VS Code. Either enable Settings Sync (GitHub account) or install extensions manually:" `
    "In terminal: cat ~/dotfiles/vscode/extensions.txt | grep -v '^#' | grep -v '^$' | ForEach-Object { code --install-extension `$_ }"

Wait-ForUser `
    "Apply VS Code settings" `
    "Copy settings: cp ~/dotfiles/vscode/settings.json `$env:APPDATA/Code/User/settings.json" `
    "The Nord theme and all preferences will be applied."

# --- IntelliJ ---
Wait-ForUser `
    "Set up IntelliJ IDEA Ultimate" `
    "Open IntelliJ > Sign in with your JetBrains account (edu license)." `
    "Apply at jetbrains.com/shop/eform/students with your @bristol.ac.uk email if you haven't already."

# --- Windows Terminal ---
Wait-ForUser `
    "Set up Windows Terminal Nord theme" `
    "Open Windows Terminal > Settings > Color Schemes > Open JSON file." `
    "Add the Nord scheme from ~/nord-terminal-theme.json. Set Ubuntu profile to use 'Nord' scheme + 'MesloLGS NF' font."

# --- Prism Launcher ---
Wait-ForUser `
    "Set up Prism Launcher (Minecraft)" `
    "You said you'd handle this yourself!" `
    ""

# --- Done ---
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  SETUP COMPLETE! Your PC is ready." -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Your dotfiles are in ~/dotfiles (synced via git)." -ForegroundColor Cyan
Write-Host "To update configs on both machines, edit the dotfiles repo and push." -ForegroundColor Cyan
Write-Host ""
