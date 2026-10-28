# Hardware Archive

A durable record of the physical setup on the main desktop (`stef`), kept
alongside `windows/windows-setup.md` (the software/OS side). Update this
whenever something physical changes — it's meant to be the one place that
has the full picture, model numbers included.

Last verified: 2026-10-27.

## PC internals

| Part | Model | Notes |
|---|---|---|
| CPU | Intel Core i7-12700F | 12 cores / 20 threads |
| GPU | EVGA RTX 3080 Ti FTW3 | ~350W+ stock; undervolt via MSI Afterburner, see `windows-setup.md` |
| RAM | 2x 32GB Micron Crucial Pro DDR5-5600 CL46 (`CP32G56C46U5.C16D`) | 64GB total |
| Storage | Samsung SSD 970 EVO Plus 2TB NVMe | single drive, ~1.86TB usable |
| Motherboard | ASUS (exact model not exposed by BIOS/SMBIOS strings) | onboard Intel I226-V 2.5GbE + Intel AX211 Wi-Fi 6E — **verify exact model physically or from BIOS splash screen** |
| CPU cooler | **TBD — not yet recorded** | |
| Case | Lian Li TU150 | small ITX/mATX case; PSU intake draws from inside the chassis, no dedicated external vent |
| Case fans | front intake + rear exhaust (air-tunnel layout) | no bottom fans |
| PSU | Cooler Master V850 SFX Gold → RMA'd 2026-05/06 for fan-bearing failure → replaced with Cooler Master's "ATX 3.1 SFX" successor unit (same wattage class, updated spec since the original V850 SFX Gold is discontinued) | second unit also showing bearing wear as of 2026-10; suspected heat/airflow or Hybrid-mode start-stop cycling, see RMA ticket #1454205 with `consumer_care@coolermaster.eu` |
| OS | Windows 11 Enterprise LTSC, build 26100 (24H2 LTSC 2024) | |

## Display

- **Monitor:** ASUS ROG Strix XG32UCWG — 32" 4K (3840x2160), QD-OLED.
  (Supersedes an earlier, incorrect "BenQ ZOWIE XL" note elsewhere — this is
  the one actually connected, confirmed via EDID.)

## Input

- **Mouse:** Hitscan Hyperlight (configured via the Hitscan Utility app).
- **Keyboard:** Logitech G, managed through Logitech G HUB — **exact model
  unconfirmed, verify next time you're at the desk** (G HUB may now only be
  managing the keyboard, since the mouse is Hitscan rather than Logitech).
- **MIDI controller:** Novation Launchkey Mini MK4 — Custom Mode 4 knobs
  send CC 21-28 on channel 1 (set up via Novation Components), feeding
  AutoMIDIcally for per-app Windows volume control.

## Audio

- **Microphone:** Fifine K688 (USB).
- **Audio interface:** Arturia MiniFuse 4 — replaced a Behringer UMC22.
- **Headphones:** Sennheiser HD490 Pro.
- **Studio monitors:** Edifier MR5 (pair).
- **Other audio:** Realtek HD Audio (onboard), NVIDIA HDMI audio, Sonic
  Studio Virtual Mixer (motherboard audio suite), VB-Audio Virtual Cable.

## Other peripherals

- A USB macro pad — not friendly-named in Device Manager; identify visually
  if it ever needs replacing.

## Networking

- Intel I226-V 2.5GbE (wired), Intel AX211 Wi-Fi 6E.
- Tailscale mesh VPN to a Pop!_OS box (`pop-os`), mapped as `Z:\` via SMB —
  used as the offsite backup target (Ableton library, AI denoise models).

## Pending / TODO

- **Sign into Amazon together** to shop for a microphone boom arm, cables,
  and other desk accessories — Claude can search/compare once you're signed
  in yourself (never hands credentials itself). See memory:
  `project_amazon-accessories-todo.md`.
- Confirm CPU cooler model.
- Confirm exact ASUS motherboard model (BIOS/SMBIOS strings are blank).
- Confirm exact Logitech keyboard model.
