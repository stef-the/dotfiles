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
- All software installation via winget
- WSL2 + Ubuntu setup
- Registry tweaks for clean UI + gaming
- NVIDIA driver setup prompt

---

## Phase 4: WSL Setup (run inside WSL after install)

```bash
# The post-install script will prompt you to run this:
cd ~/dotfiles && bash scripts/install-wsl.sh
```

---

## Phase 5: Manual Steps

These can't be fully automated:

1. **Zen Browser** — sign in with Firefox account to sync
2. **1Password** — sign in and set up browser extension
3. **Steam** — sign in, install games to D:\Games
4. **Valorant** — install Riot Client, download Valorant
5. **Discord** — sign in
6. **Spotify** — sign in
7. **Prism Launcher** — set up Minecraft (you said you'll handle this)
8. **Behringer UMC22** — install ASIO driver from behringer.com/downloads
9. **Tailscale** — sign in, reconnect to your network
10. **VS Code** — Settings Sync should pull everything, or run extensions installer
11. **IntelliJ IDEA** — sign in with JetBrains educational license

---

## Notes

- **Drivers:** NVIDIA App handles GPU drivers. Motherboard drivers (LAN, audio, chipset) — check manufacturer's site.
- **Windows Update:** LTSC gets security patches only. Run Windows Update after install to get latest patches.
- **Backup:** Run `backup-discovery.sh` in WSL/Git Bash BEFORE wiping the drive (when you have the PSU).
