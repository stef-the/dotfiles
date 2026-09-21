# ═══════════════════════════════════════════════════════════════
# Windows 11 LTSC Post-Install Script
# Run as Administrator in PowerShell
# ═══════════════════════════════════════════════════════════════

#Requires -RunAsAdministrator

param(
    [switch]$SkipActivation,
    [switch]$SkipDebloat,
    [switch]$SkipWSL,
    [switch]$WizardOnly    # Jump straight to interactive wizard
)

$ErrorActionPreference = "Continue"

function Write-Step {
    param([string]$Message)
    Write-Host "`n═══ $Message ═══" -ForegroundColor Cyan
}

if ($WizardOnly) { goto wizard }

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
    "EpicGames.EpicGamesLauncher"     # Rocket League
    "PrismLauncher.PrismLauncher"

    # Social / Media
    "Discord.Discord"
    "Spotify.Spotify"

    # Browser
    "Zen-Team.Zen-Browser"

    # Terminal & Shell
    "Microsoft.WindowsTerminal"

    # Notes
    "Obsidian.Obsidian"

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
    "Guru3D.Afterburner"                # MSI Afterburner — GPU undervolt + monitoring

    # Networking
    "Tailscale.Tailscale"
    "Cloudflare.cloudflared"

    # Utilities
    "7zip.7zip"
    "Notepad++.Notepad++"
    "VideoLAN.VLC"
    "voidtools.Everything"              # Fast file search
    "Flow-Launcher.Flow-Launcher"       # App launcher (like Spotlight)
    "Microsoft.PowerToys"               # Window management, FancyZones, etc.
    "AntibodySoftware.WizTree"          # Fast disk space analyzer
    "OBSProject.OBSStudio"              # Screen recording / streaming
    "REALiX.HWiNFO"                    # Hardware monitoring
)

foreach ($pkg in $packages) {
    Write-Host "Installing $pkg..." -ForegroundColor Yellow
    winget install --id $pkg --accept-package-agreements --accept-source-agreements --silent
}

# ─── Step 4: Create Folder Structure ─────────────────────────
Write-Step "Creating folder structure"

$folders = @(
    "$env:USERPROFILE\Dev",
    "$env:USERPROFILE\Dev\projects",
    "$env:USERPROFILE\Dev\repos",
    "$env:USERPROFILE\Dev\scripts",
    "$env:USERPROFILE\Dev\tools",
    "C:\Games",
    "C:\Games\Steam",
    "C:\Media",
    "C:\Media\Photography",
    "C:\Media\Video",
    "C:\Media\Music",
    "C:\Backups"
)

foreach ($dir in $folders) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "  Created: $dir" -ForegroundColor Gray
}

# ─── Step 5: Registry Tweaks ─────────────────────────────────
Write-Step "Applying registry tweaks"

# === Taskbar & UI ===

# Auto-hide taskbar
$taskbarSettings = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" -Name "Settings" -ErrorAction SilentlyContinue).Settings
if ($taskbarSettings) {
    $taskbarSettings[8] = 3  # bit flag for auto-hide
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" -Name "Settings" -Value $taskbarSettings
}

# Align taskbar to left (not center)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f

# Remove Task View button
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f

# Remove Search from taskbar
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f

# Remove Chat/Teams from taskbar
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarMn /t REG_DWORD /d 0 /f

# Remove Widgets
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f

# Small taskbar icons (optional, more compact)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarSmallIcons /t REG_DWORD /d 1 /f

# === File Explorer ===

# Show file extensions
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f

# Show hidden files
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f

# Show full path in title bar
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" /v FullPath /t REG_DWORD /d 1 /f

# Open Explorer to "This PC" instead of "Home"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 1 /f

# Disable recent files in Quick Access
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowRecent /t REG_DWORD /d 0 /f

# Disable frequent folders in Quick Access
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowFrequent /t REG_DWORD /d 0 /f

# === Dark Mode ===
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f

# Transparency effects on
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f

# === Search ===

# Disable web search in Start Menu
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f

# Disable Bing in search
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f

# === Gaming Performance ===

# Enable Game Mode
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f

# Disable Game Bar overlay (causes stutters)
reg add "HKCU\Software\Microsoft\GameBar" /v UseNexusForGameBarEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f

# Disable Game DVR / background recording
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f

# Enable Hardware-Accelerated GPU Scheduling
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f

# Disable mouse acceleration (for FPS games like Valorant)
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d "0" /f
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d "0" /f
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d "0" /f

# Disable fullscreen optimizations globally (can cause input lag)
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehavior /t REG_DWORD /d 2 /f
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 2 /f

# === Telemetry & Privacy ===

# Disable telemetry
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f

# Disable advertising ID
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f

# Disable activity history
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /t REG_DWORD /d 0 /f

# Disable location tracking
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v Value /t REG_SZ /d "Deny" /f

# Disable feedback requests
reg add "HKCU\Software\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f

# Disable diagnostic data
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" /v ShowedToastAtLevel /t REG_DWORD /d 1 /f

# === Performance ===

# Disable startup delay
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f

# Disable Nagle's algorithm (reduces network latency for gaming)
# Applied per network adapter — this sets the system-wide preference
reg add "HKLM\SOFTWARE\Microsoft\MSMQ\Parameters" /v TCPNoDelay /t REG_DWORD /d 1 /f

# Disable hibernation (saves space on NVMe, not needed for desktop)
powercfg /hibernate off

# Disable USB selective suspend (prevents USB audio dropouts on UMC22)
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setactive SCHEME_CURRENT

Write-Host "Registry tweaks applied." -ForegroundColor Green

# ─── Step 6: Disable Unnecessary Services ────────────────────
Write-Step "Disabling unnecessary services"

$servicesToDisable = @(
    "DiagTrack"                 # Connected User Experiences and Telemetry
    "dmwappushservice"          # WAP Push Message Routing
    "SysMain"                   # Superfetch (not needed on NVMe)
    "WSearch"                   # Windows Search indexing (use Everything instead)
    "MapsBroker"                # Downloaded Maps Manager
    "lfsvc"                     # Geolocation Service
    "RetailDemo"                # Retail Demo Service
    "wisvc"                     # Windows Insider Service
    "WerSvc"                    # Windows Error Reporting
    "Fax"                       # Fax service
    "XblAuthManager"            # Xbox Live Auth Manager
    "XblGameSave"               # Xbox Live Game Save
    "XboxGipSvc"                # Xbox Accessory Management
    "XboxNetApiSvc"             # Xbox Live Networking
)

foreach ($svc in $servicesToDisable) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  Disabled: $svc ($($service.DisplayName))" -ForegroundColor Gray
    }
}

# Disable scheduled tasks related to telemetry
$tasksToDisable = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
    "\Microsoft\Windows\Feedback\Siuf\DmClient"
    "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
)

foreach ($task in $tasksToDisable) {
    schtasks /Change /TN $task /Disable 2>$null
}

Write-Host "Unnecessary services and telemetry tasks disabled." -ForegroundColor Green

# ─── Step 7: Power Plan — Ultimate Performance ──────────────
Write-Step "Enabling Ultimate Performance power plan"

# Unhide and activate Ultimate Performance plan
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
$ultimatePlan = powercfg /list | Select-String "Ultimate Performance" | ForEach-Object {
    ($_ -replace '.*GUID:\s*' -replace '\s*\(.*' -replace '\s*\*.*').Trim()
}
if ($ultimatePlan) {
    powercfg /setactive $ultimatePlan
    Write-Host "Ultimate Performance plan activated." -ForegroundColor Green
} else {
    # Fallback to High Performance
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-Host "High Performance plan activated (Ultimate not available)." -ForegroundColor Yellow
}

# Disable power throttling (keeps CPU at max)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f

# Set min/max CPU to 100% on AC power
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg /setactive SCHEME_CURRENT

# Disable core parking (keep all 12 cores active)
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100
powercfg /setactive SCHEME_CURRENT

# PCIe Link State Power Management — Off (prevents GPU power saving stutter)
powercfg /setacvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 0
powercfg /setactive SCHEME_CURRENT

Write-Host "Power optimizations applied." -ForegroundColor Green

# ─── Step 8: WSL2 Configuration ─────────────────────────────
Write-Step "Configuring WSL2"

# Create .wslconfig for optimal resource allocation
# 64GB RAM: give WSL 16GB (plenty for dev, leaves 48GB for Windows/games)
# Limit swap to prevent WSL from eating disk
$wslConfig = @"
[wsl2]
memory=16GB
swap=4GB
processors=8
localhostForwarding=true
nestedVirtualization=true

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
"@

$wslConfig | Out-File -FilePath "$env:USERPROFILE\.wslconfig" -Encoding utf8
Write-Host "WSL2 config written (~/.wslconfig): 16GB RAM, 8 cores, 4GB swap" -ForegroundColor Green

if (-not $SkipWSL) {
    wsl --install -d Ubuntu
    Write-Host "WSL Ubuntu installing. Restart required." -ForegroundColor Yellow
}

# ─── Step 9: Windows Terminal Nord Theme ─────────────────────
Write-Step "Configuring Windows Terminal"

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

$nordScheme | Out-File -FilePath "$env:USERPROFILE\nord-terminal-theme.json" -Encoding utf8

# ─── Step 10: PowerToys Configuration ────────────────────────
Write-Step "Configuring PowerToys"

$ptSettingsDir = "$env:LOCALAPPDATA\Microsoft\PowerToys"
New-Item -ItemType Directory -Path $ptSettingsDir -Force | Out-Null

# PowerToys Run (Spotlight-like launcher) — Alt+Space
# FancyZones — window tiling
# Always On Top — pin windows (Win+Ctrl+T)
# Color Picker — pick colors from screen (Win+Shift+C)
# File Locksmith — find what's locking a file
# Hosts File Editor — edit hosts file easily
# Keyboard Manager — remap keys
# Paste as Plain Text — Ctrl+Win+V

Write-Host "PowerToys installed. Recommended settings:" -ForegroundColor Green
Write-Host "  - PowerToys Run: Alt+Space (spotlight search)" -ForegroundColor Gray
Write-Host "  - FancyZones: set up monitor zones for window tiling" -ForegroundColor Gray
Write-Host "  - Always On Top: Win+Ctrl+T to pin windows" -ForegroundColor Gray
Write-Host "  - Color Picker: Win+Shift+C" -ForegroundColor Gray
Write-Host "  - Enable: Paste as Plain Text, File Locksmith, Hosts Editor" -ForegroundColor Gray

# ─── Step 11: Scheduled Maintenance ─────────────────────────
Write-Step "Setting up maintenance tasks"

# Create a weekly disk cleanup task
$cleanupAction = New-ScheduledTaskAction -Execute "cleanmgr.exe" -Argument "/sagerun:1"
$cleanupTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3am
Register-ScheduledTask -TaskName "Weekly Disk Cleanup" -Action $cleanupAction -Trigger $cleanupTrigger -RunLevel Highest -ErrorAction SilentlyContinue

# Configure disk cleanup presets (run once to set up)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files" /v StateFlags0001 /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin" /v StateFlags0001 /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Update Cleanup" /v StateFlags0001 /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache" /v StateFlags0001 /t REG_DWORD /d 2 /f

Write-Host "Weekly disk cleanup scheduled (Sundays 3am)." -ForegroundColor Green

# ─── Step 12: Startup App Cleanup ────────────────────────────
Write-Step "Disabling unnecessary startup apps"

# Apps that SHOULD auto-start:
#   - Vanguard (Valorant anti-cheat) — required
#   - MSI Afterburner — GPU undervolt profile
#   - Tailscale — network connectivity
#   - 1Password — password manager
#   - Everything — file search indexing
#   - PowerToys — window management

# Apps that should NOT auto-start:
$startupToDisable = @(
    "Discord"
    "Spotify"
    "Steam"
    "Docker Desktop"
    "Microsoft Edge"
    "Microsoft Teams"
    "OneDrive"
    "Cortana"
    "Skype"
    "NVIDIA GeForce Experience"    # Only need it for driver updates, not always
    "Epic Games Launcher"
    "Flow Launcher"                # Use PowerToys Run instead (Alt+Space)
    "Windows Terminal"
    "Riot Client"
)

# Disable via registry (current user Run key)
$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$runEntries = Get-ItemProperty -Path $runKey -ErrorAction SilentlyContinue
if ($runEntries) {
    foreach ($app in $startupToDisable) {
        $match = $runEntries.PSObject.Properties | Where-Object { $_.Name -like "*$app*" -or $_.Value -like "*$app*" }
        foreach ($entry in $match) {
            Remove-ItemProperty -Path $runKey -Name $entry.Name -ErrorAction SilentlyContinue
            Write-Host "  Removed startup: $($entry.Name)" -ForegroundColor Gray
        }
    }
}

# Also check machine-wide Run key
$runKeyLM = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
$runEntriesLM = Get-ItemProperty -Path $runKeyLM -ErrorAction SilentlyContinue
if ($runEntriesLM) {
    foreach ($app in $startupToDisable) {
        $match = $runEntriesLM.PSObject.Properties | Where-Object { $_.Name -like "*$app*" -or $_.Value -like "*$app*" }
        foreach ($entry in $match) {
            Remove-ItemProperty -Path $runKeyLM -Name $entry.Name -ErrorAction SilentlyContinue
            Write-Host "  Removed startup (system): $($entry.Name)" -ForegroundColor Gray
        }
    }
}

# Disable via Task Manager startup folder
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$startupShortcuts = Get-ChildItem -Path $startupFolder -Filter "*.lnk" -ErrorAction SilentlyContinue
foreach ($shortcut in $startupShortcuts) {
    $name = $shortcut.BaseName
    $shouldKeep = $name -match "Afterburner|Tailscale|1Password|Everything|PowerToys|Vanguard"
    if (-not $shouldKeep) {
        Remove-Item $shortcut.FullName -Force
        Write-Host "  Removed startup shortcut: $name" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Startup apps that WILL auto-start:" -ForegroundColor Green
Write-Host "  - Vanguard (Valorant anti-cheat)" -ForegroundColor Gray
Write-Host "  - MSI Afterburner (GPU undervolt)" -ForegroundColor Gray
Write-Host "  - Tailscale (network)" -ForegroundColor Gray
Write-Host "  - 1Password (passwords)" -ForegroundColor Gray
Write-Host "  - Everything (file search)" -ForegroundColor Gray
Write-Host "  - PowerToys (window management)" -ForegroundColor Gray
Write-Host ""
Write-Host "Everything else launches on demand." -ForegroundColor Green

# ─── Summary ─────────────────────────────────────────────────
:wizard
Write-Step "AUTOMATED INSTALL COMPLETE"
Write-Host ""
Write-Host "Installed:" -ForegroundColor Green
if ($packages) { foreach ($pkg in $packages) { Write-Host "  - $pkg" } }

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
Write-Host "A RESTART is needed for WSL, registry, and power plan changes." -ForegroundColor Red
Write-Host "After restart, run:" -ForegroundColor Yellow
Write-Host '  .\post-install.ps1 -WizardOnly' -ForegroundColor White
Write-Host ""
$restart = Read-Host "Restart now? (y = restart, n = continue wizard)"
if ($restart -eq 'y') {
    Write-Host "Restarting in 5 seconds..." -ForegroundColor Cyan
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

# --- Claude Code in WSL ---
Wait-ForUser `
    "Verify Claude Code in WSL" `
    "In WSL, run: claude --version (should be installed by install-wsl.sh)" `
    "Run 'claude' to authenticate. Claude agents will use WSL for most work."

# --- SSH Keys ---
Wait-ForUser `
    "Generate SSH keys for GitHub" `
    "In WSL, run: ssh-keygen -t ed25519 -C '75397677+stef-the@users.noreply.github.com'" `
    "Then: cat ~/.ssh/id_ed25519.pub | clip.exe   and add it at github.com/settings/keys"

# --- Git Credential Manager ---
Wait-ForUser `
    "Set up Git Credential Manager" `
    "Git for Windows includes GCM. In WSL, run:" `
    "git config --global credential.helper /mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"

# --- Docker ---
Wait-ForUser `
    "Configure Docker Desktop" `
    "Open Docker Desktop > Settings > Resources > WSL Integration > enable Ubuntu" `
    "This lets you use 'docker' commands inside WSL. Also set memory limit to 8GB."

# --- Obsidian Sync ---
Wait-ForUser `
    "Set up Obsidian self-hosted sync" `
    "In an elevated PowerShell, run: ~\dotfiles\windows\obsidian-livesync-setup.ps1" `
    "Spins up CouchDB in Docker, locked to this PC's Tailscale IP. See windows/obsidian-livesync-setup.ps1 for the plugin config to use on each device."

# --- NVIDIA ---
Wait-ForUser `
    "Set up NVIDIA drivers" `
    "Open NVIDIA App > Download 'Game Ready Driver' for 3080 Ti." `
    "In NVIDIA Control Panel: enable Resizable BAR, set Power Management to 'Prefer Maximum Performance'."

# --- GPU Undervolt ---
Write-Host ""
Write-Host "═══ GPU UNDERVOLT GUIDE (3080 Ti) ═══" -ForegroundColor Magenta
Write-Host ""
Write-Host "Your EVGA FTW3 3080 Ti draws 350W+ stock. Undervolting can:" -ForegroundColor Gray
Write-Host "  - Drop temps by 10-15C" -ForegroundColor Gray
Write-Host "  - Save 50-80W of power" -ForegroundColor Gray
Write-Host "  - Maintain or IMPROVE performance (less thermal throttling)" -ForegroundColor Gray
Write-Host ""
Write-Host "Steps in MSI Afterburner:" -ForegroundColor Yellow
Write-Host "  1. Open MSI Afterburner (installed via winget)" -ForegroundColor White
Write-Host "  2. Press Ctrl+F to open the Voltage/Frequency curve" -ForegroundColor White
Write-Host "  3. Find 1900-1950 MHz on the curve (good target for 3080 Ti)" -ForegroundColor White
Write-Host "  4. Click that point, press L to lock it" -ForegroundColor White
Write-Host "  5. Drag it down to ~875mV (sweet spot for most 3080 Ti cards)" -ForegroundColor White
Write-Host "  6. Click the checkmark to apply" -ForegroundColor White
Write-Host "  7. Run a stress test (Superposition, 3DMark, or heavy game)" -ForegroundColor White
Write-Host "  8. If stable, save as Profile 1 in Afterburner" -ForegroundColor White
Write-Host "  9. Enable 'Start with Windows' + 'Start minimized' in Afterburner settings" -ForegroundColor White
Write-Host ""
Write-Host "  Recommended starting points for EVGA FTW3 3080 Ti:" -ForegroundColor Cyan
Write-Host "    Conservative: 1875 MHz @ 900mV (very stable)" -ForegroundColor Cyan
Write-Host "    Balanced:     1920 MHz @ 875mV (most cards hit this)" -ForegroundColor Cyan
Write-Host "    Aggressive:   1950 MHz @ 850mV (silicon lottery)" -ForegroundColor Cyan
Write-Host ""
Write-Host "  If you crash, increase voltage by 25mV or decrease clock by 30MHz." -ForegroundColor DarkCyan
Write-Host ""

Wait-ForUser `
    "Undervolt GPU in MSI Afterburner" `
    "Follow the guide above. Test with a game for 30+ minutes." `
    "Save profile and enable start with Windows when stable."

# --- Audio ---
Wait-ForUser `
    "Install Behringer UMC22 drivers" `
    "Download ASIO driver from: behringer.com/downloads > UMC22" `
    "After install, set UMC22 as default audio output in Sound Settings."

# --- Tailscale ---
Wait-ForUser `
    "Sign in to Tailscale" `
    "Open Tailscale from system tray > Sign in with your account." `
    "This reconnects you to your Linux box with 4TB storage for backups."

# --- Browser ---
Wait-ForUser `
    "Set up Zen Browser" `
    "Open Zen Browser > Sign in with Firefox account to sync from Mac." `
    "Bookmarks, extensions, and settings should sync automatically."

# --- 1Password ---
Wait-ForUser `
    "Sign in to 1Password" `
    "Open 1Password > Sign in with your account." `
    "Install the browser extension in Zen Browser too."

# --- Steam ---
Wait-ForUser `
    "Sign in to Steam" `
    "Open Steam > Sign in. Set library folder to C:\Games\Steam." `
    "Enable Steam > Settings > Downloads > 'Allow downloads during gameplay' OFF for Valorant perf."

# --- Valorant ---
Wait-ForUser `
    "Install Valorant" `
    "Open Riot Client > Sign in > Install Valorant." `
    "Vanguard anti-cheat requires a restart after first install."

# --- Rocket League ---
Wait-ForUser `
    "Install Rocket League" `
    "Open Epic Games Launcher > Sign in > Install Rocket League (free to play)." `
    ""

# --- Discord ---
Wait-ForUser `
    "Sign in to Discord" `
    "Open Discord > Sign in with your account." `
    "Settings > Appearance > Dark mode. Disable 'Open Discord' on startup if you want."

# --- Spotify ---
Wait-ForUser `
    "Sign in to Spotify" `
    "Open Spotify > Sign in." `
    ""

# --- PowerToys Setup ---
Wait-ForUser `
    "Configure PowerToys" `
    "Open PowerToys. Enable: FancyZones, PowerToys Run (Alt+Space), Always On Top, Color Picker, Paste as Plain Text." `
    "FancyZones: hold Shift while dragging windows to snap to zones. Create your layout in the editor."

# --- VS Code ---
Wait-ForUser `
    "Configure VS Code" `
    "Open VS Code. Sign in with GitHub for Settings Sync, or install manually:" `
    "PowerShell: Get-Content ~\dotfiles\vscode\extensions.txt | Where { `$_ -notmatch '^#|^$' } | ForEach { code --install-extension `$_ }"

Wait-ForUser `
    "Apply VS Code settings" `
    "Copy-Item ~\dotfiles\vscode\settings.json `$env:APPDATA\Code\User\settings.json" `
    "Nord theme, fonts, and formatter settings will be applied."

# --- IntelliJ ---
Wait-ForUser `
    "Set up IntelliJ IDEA Ultimate" `
    "Open IntelliJ > Sign in with your JetBrains account (edu license)." `
    "Apply at jetbrains.com/shop/eform/students with your @bristol.ac.uk email if you haven't already."

# --- Windows Terminal ---
Wait-ForUser `
    "Set up Windows Terminal Nord theme" `
    "Open Windows Terminal Settings > Open JSON > Add Nord scheme from ~\nord-terminal-theme.json." `
    "Set Ubuntu profile: color scheme 'Nord', font 'MesloLGS NF', opacity 90%, acrylic on."

# --- Nerd Font ---
Wait-ForUser `
    "Install MesloLGS Nerd Font" `
    "Download from: github.com/ryanoasis/nerd-fonts/releases > MesloLGS NF" `
    "Extract, select all .ttf files, right-click > Install for all users. Required for terminal/VS Code icons."

# --- Everything Search ---
Wait-ForUser `
    "Configure Everything (file search)" `
    "Open Everything > Options > enable 'Start with Windows', 'Run as Administrator'." `
    "Bind to Ctrl+Shift+F or use via Flow Launcher / PowerToys Run."

# --- HWiNFO ---
Wait-ForUser `
    "Set up HWiNFO (hardware monitoring)" `
    "Open HWiNFO > Sensors only mode. Check your GPU temps, CPU temps, voltages." `
    "Useful for verifying your undervolt. Enable 'Minimize to tray' and 'Start with Windows'."

# --- Prism Launcher ---
Wait-ForUser `
    "Set up Prism Launcher (Minecraft)" `
    "You said you'd handle this yourself!" `
    ""

# --- Dev Environment Notes ---
Write-Host ""
Write-Host "═══ DEV ENVIRONMENT NOTES ═══" -ForegroundColor Magenta
Write-Host ""
Write-Host "Your setup for Claude Code agents:" -ForegroundColor Cyan
Write-Host "  - WSL2 Ubuntu: 16GB RAM, 8 CPU cores (plenty for builds + AI)" -ForegroundColor Gray
Write-Host "  - Docker: available in WSL via Docker Desktop integration" -ForegroundColor Gray
Write-Host "  - Node.js: managed via NVM in WSL" -ForegroundColor Gray
Write-Host "  - Git: configured in WSL with your GitHub account" -ForegroundColor Gray
Write-Host "  - SSH keys: generate new ones in WSL (ssh-keygen), add to GitHub" -ForegroundColor Gray
Write-Host "  - Claude Code: installed globally via npm in WSL" -ForegroundColor Gray
Write-Host ""
Write-Host "Folder structure:" -ForegroundColor Cyan
Write-Host "  ~\Dev\projects\    Windows-side projects (if any)" -ForegroundColor Gray
Write-Host "  ~\Dev\repos\       Cloned repos on Windows side" -ForegroundColor Gray
Write-Host "  ~\Dev\scripts\     PowerShell scripts" -ForegroundColor Gray
Write-Host "  ~\Dev\tools\       Portable tools" -ForegroundColor Gray
Write-Host "  C:\Games\Steam\    Steam library (steamapps, workshop, etc.)" -ForegroundColor Gray
Write-Host "  C:\Media\          Photography, video, music" -ForegroundColor Gray
Write-Host "  C:\Backups\        Local backups" -ForegroundColor Gray
Write-Host "  (WSL) ~/           Linux home — main dev work happens here" -ForegroundColor Gray
Write-Host ""
Write-Host "Tip: for best performance, keep code in the WSL filesystem (~/projects)" -ForegroundColor Yellow
Write-Host "NOT on the Windows side (/mnt/c/...) — cross-filesystem IO is slow." -ForegroundColor Yellow
Write-Host ""

# --- Done ---
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  SETUP COMPLETE! Your PC is ready." -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Dotfiles: ~/dotfiles (synced via git)" -ForegroundColor Cyan
Write-Host "Update configs: edit dotfiles repo, push, pull on other machine" -ForegroundColor Cyan
Write-Host ""
Write-Host "Quick reference:" -ForegroundColor Yellow
Write-Host "  Alt+Space         PowerToys Run (app launcher)" -ForegroundColor Gray
Write-Host "  Win+Ctrl+T        Always On Top (pin window)" -ForegroundColor Gray
Write-Host "  Win+Shift+C       Color Picker" -ForegroundColor Gray
Write-Host "  Ctrl+Win+V        Paste as Plain Text" -ForegroundColor Gray
Write-Host "  Shift+drag        FancyZones snap" -ForegroundColor Gray
Write-Host ""
