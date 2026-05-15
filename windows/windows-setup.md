# Windows 11 IoT Enterprise LTSC 2024 — Clean Install Guide

**Hardware:** i7-12700F / RTX 3080 Ti / 64GB DDR5 / 2TB NVMe
**USB:** 64GB Kingston flash drive

---

## Phase 0: Prepare USB (on Mac)

### Option A: Ventoy (Recommended)
Ventoy lets you keep the ISO + scripts + docs all on one USB.

```bash
# Download Ventoy
brew install ventoy  # or download from https://ventoy.net

# Find USB device
diskutil list
# Look for your 64GB Kingston (e.g., /dev/disk4)

# Install Ventoy to USB (WARNING: erases the drive)
sudo ventoy -i /dev/disk4

# Mount the USB (Ventoy creates an exFAT partition)
# Copy the LTSC ISO onto the main partition
# Copy this dotfiles/ folder onto the USB too
```

### Option B: Direct ISO Flash (if Ventoy doesn't cooperate)
```bash
diskutil list                          # find USB (e.g., disk4)
diskutil unmountDisk /dev/disk4
sudo dd if=Win11_LTSC.iso of=/dev/rdisk4 bs=4m status=progress
```

### Getting the LTSC ISO
- Microsoft VLSC (if you have access via Bristol)
- Or search for "Windows 11 IoT Enterprise LTSC 2024" on Microsoft Evaluation Center
- Verify SHA256 hash after download

---

## Phase 1: BIOS Setup

1. Boot into BIOS (DEL or F2 on startup)
2. Set **UEFI mode** (not Legacy/CSM)
3. Enable **Secure Boot** (LTSC supports it)
4. Set **NVMe as first boot device** after USB
5. Enable **XMP/EXPO** for DDR5 (check your RAM's rated speed)
6. Enable **Resizable BAR** (for 3080 Ti)
7. Save and boot from USB

---

## Phase 2: Windows Installation

1. Boot from USB → Windows Setup
2. Select **Windows 11 IoT Enterprise LTSC** edition
3. **Delete ALL existing partitions** on the 2TB NVMe
4. Select unallocated space → Next (Windows creates partitions automatically)
5. Skip Microsoft account: use `no@thankyou.com` or disconnect network
6. Create local account
7. Decline all telemetry/tracking options

### Partition Suggestion (optional, for dual-purpose)
- **C:** 500GB — Windows + Programs
- **D:** 1.5TB — Games, Projects, Media
- Or just one big partition, your call

---

## Phase 3: Post-Install (run post-install.ps1)

Open **PowerShell as Administrator** and run:

```powershell
# If scripts are on USB (e.g., E:\dotfiles\windows\)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
E:\dotfiles\windows\post-install.ps1

# Or if you have internet, one-liner from your repo:
# irm https://raw.githubusercontent.com/stef-the/dotfiles/main/windows/post-install.ps1 | iex
```

This script handles:
- Windows activation (MAS/HWID)
- Debloat via Chris Titus WinUtil
- All software installation via winget (30+ packages)
- Folder structure creation (Dev, Games, Media, Backups)
- Registry tweaks: clean UI, dark mode, taskbar auto-hide, left-align, no search/widgets
- Telemetry and tracking fully disabled
- Unnecessary services disabled (15+ services)
- Ultimate Performance power plan enabled
- CPU: all cores unparked, no throttling
- GPU: hardware-accelerated scheduling, Game Bar disabled
- PCIe power saving disabled, USB selective suspend off (for UMC22)
- Nagle's algorithm disabled (lower network latency)
- Startup apps cleaned (only essential apps auto-start)
- WSL2 configured (.wslconfig: 16GB RAM, 8 cores)
- PowerToys installed + config guidance
- Weekly disk cleanup scheduled
- Interactive wizard walks through all manual steps
- GPU undervolt guide for the 3080 Ti

---

## Phase 4: WSL Setup (run inside WSL after install)

```bash
# The post-install script will prompt you to run this:
git clone https://github.com/stef-the/dotfiles.git ~/dotfiles
bash ~/dotfiles/scripts/install-wsl.sh
```

---

## Phase 5: Manual Steps (Interactive Wizard)

The post-install script has an interactive wizard that walks you through every step.
After restart, run `.\post-install.ps1 -WizardOnly` to resume the wizard.

Key manual steps:
1. **WSL Ubuntu** — create user, run install-wsl.sh
2. **NVIDIA drivers** — Game Ready Driver via NVIDIA App
3. **GPU Undervolt** — MSI Afterburner, target ~1920MHz @ 875mV (see wizard guide)
4. **Behringer UMC22** — ASIO driver from behringer.com
5. **Tailscale** — sign in, reconnect to Linux box
6. **Browser/Apps** — Zen Browser, 1Password, Steam, Valorant, Discord, Spotify
7. **VS Code** — Settings Sync or manual extension install
8. **IntelliJ Ultimate** — JetBrains edu license (bristol.ac.uk email)
9. **PowerToys** — FancyZones layout, PowerToys Run (Alt+Space)
10. **Windows Terminal** — Nord theme, MesloLGS NF font, acrylic background

---

## Partition Recommendation

Split the 2TB NVMe:
- **C: 500GB** — Windows + Programs + WSL
- **D: 1.5TB** — Games, Media, Backups

This keeps Windows clean and lets you reinstall C: without losing game data.

---

## Startup Apps (after cleanup)

**Auto-start (essential):**
- Vanguard (Valorant anti-cheat)
- MSI Afterburner (GPU undervolt profile)
- Tailscale (network)
- 1Password (passwords)
- Everything (file search)
- PowerToys (window management)

**Launch on demand (everything else):**
- Steam, Discord, Spotify, Docker, Zen Browser, etc.

---

## Notes

- **Drivers:** NVIDIA App handles GPU. Motherboard drivers (LAN, audio, chipset) — check manufacturer site.
- **Windows Update:** LTSC gets security patches only. Run Windows Update after install.
- **Backup:** Run `backup-discovery.sh` BEFORE wiping the drive.
- **WSL performance:** Keep code in WSL filesystem (`~/`), NOT on `/mnt/c/` — cross-FS IO is 10x slower.
- **Claude Code agents:** Primary dev work in WSL. 16GB RAM + 8 cores allocated. Docker available via Desktop integration.
