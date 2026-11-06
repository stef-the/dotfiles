# mc-server — Minecraft (stef-the/mc-server)

Quick-reference for the Dockerized Paper server + web panel that live in their
own repo (`C:\Users\stef\Dev\repos\mc-server`). This doc tracks what changed
and why; see that repo's own README for day-to-day usage.

Last updated: 2026-11-06.

## What it is

Paper 26.1.2, run via Docker Compose (`mc`, `mc-web` panel, `mc-backup` → R2,
`mc-playit` for public access, `mc-cloudflared` for the panel's own public
URL). World: `survival_82a`. Reachable locally at `http://localhost:8080`
(panel) — admin token in `.env`, not committed.

## Plugins (added/changed 2026-11-06)

- **EssentialsX** — core QoL commands. Kits intentionally disabled (empty
  `kits.yml`, `/kit`/`/kits`/`/kitreset`/`/autokit` in `disabled-commands`) —
  the panel has its own native Kits page, didn't want two systems.
- **CoreProtect-CE** (Community Edition fork — original CoreProtect's Modrinth
  listing now points here) — block-change logging/rollback.
- **Vault** — not on Modrinth; pulled from the official GitHub release
  (`MilkBowl/Vault`, hash-verified). Needed for EssentialsX ↔ LuckPerms
  (chat prefixes/group info) to actually work.
- **ViaVersion** — bridges the gap between Paper's pinned 26.1.2 and the
  protocol version Geyser's Bedrock bridge needs.
- **Geyser-Spigot + Floodgate** — already present; see the NetherNet section
  below, this is where most of tonight went. `auth-type` was wrong (`online`,
  should be `floodgate`) — fixed.

Paper itself stays pinned at **26.1.2**, not 26.3 — WorldEdit and a couple
other plugins crash-loop the whole server on 26.3 (NMS registry changes).
Don't "fix" the outdated-build warning by upgrading Paper without re-checking
plugin compatibility first.

## Bedrock / NetherNet (the big one)

**Root cause of a long night of "Terracotta" errors:** Minecraft Bedrock
dropped RakNet entirely as of client version 26.60 (Mojang's cutover date:
2026-10-27). Any Bedrock client updated after that date — which is now the
default for anyone who's auto-updated — no longer attempts a RakNet
connection at all, full stop. Every earlier RakNet-focused fix that night
(transport settings, Geyser version swaps, MTU tuning, playit tunnel
reachability) was chasing a protocol the client had already stopped using.
None of that was wrong, it was just solving the wrong problem.

**What actually fixed it — NetherNet (WebRTC-based) setup:**
- Geyser `config.yml` (`plugins/Geyser-Spigot/config.yml`), under `bedrock:`:
  - `transport: both` (RakNet kept alive for any legacy client; harmless —
    it fails to bind anyway once NetherNet claims the shared port, see below)
  - `webrtc-port: 19133` — NetherNet needs its own UDP port, separate from
    RakNet's `19132`. `transport: both` with no distinct `webrtc-port` just
    makes NetherNet silently fail to start (logged, not fatal).
  - `signaling.mode: nxs` — external signaling via Warden
    (`https://warden.cloud`), not Geyser's own built-in signaling. Builtin
    needs its own TCP port in addition to UDP, which doesn't fit a
    single-port tunnel setup; `nxs` only needs the UDP media port.
  - `signaling.advertise-addresses: ["chords-way.tun.ply.gg:11325"]` — the
    address Geyser tells connecting clients to use.
- A **second** playit.gg tunnel, separate from the existing Java/RakNet ones:
  plain **UDP** type (playit's own "Minecraft Bedrock (NetherNet)" tunnel
  type wasn't available on this account — generic UDP works fine, NetherNet's
  actual media traffic is just UDP once Warden handles the signaling
  handshake), Local IP `172.28.0.10` (mc's fixed Docker IP), Local Port
  `19133`, assigned public address `chords-way.tun.ply.gg:11325`.
- playit agent bumped from `:0.17` to `:latest` in `docker-compose.yml`
  (now `1.2.0`) — NetherNet support needs `1.1.0`+.
- Confirmed working via the server log line **"Registered with the external
  signaling service"**, and a real client join shortly after.
- **The actual reliable way to connect turned out to be the Warden
  click-to-join link, not typing address:port into "Add Server."** Geyser
  logs `Players can join at https://bluebadger.wdn.gg` on boot — this link
  is stable across restarts (tied to a persisted identity in
  `plugins/Geyser-Spigot/nethernet/`, not regenerated each time), and is now
  surfaced directly in the panel (Dashboard + Bedrock page) as the
  recommended method. Typing the raw tunnel address:port into Bedrock's
  "Add Server" screen was unreliable with NetherNet even though the server
  side was correctly configured — open the link on the device instead.

The **old RakNet tunnel** (`chords-nationalism.tun.ply.gg:11169`) is now
dead weight for Bedrock specifically — no current client will use it — but
it's harmless to leave running.

## Known gaps / open questions

- **LAN Bedrock: confirmed working, but only via the Warden click-to-join
  link — not the raw address:port.** Retested after the NetherNet setup;
  typing the tunnel address into "Add Server" still failed on LAN, but
  `https://bluebadger.wdn.gg` connected successfully. So the earlier
  "Docker Desktop UDP forwarding is broken" conclusion was indeed a red
  herring (it predated discovering the RakNet cutover) — the real fix for
  LAN turned out to be the same as remote: use the Warden link, not a
  manually-typed address.
- CoreProtect-CE's own update-checker throws a harmless
  `NullPointerException` on its network ping (its own bug, not ours).
- The GeyserMC GitHub issue that matched this exact symptom
  (https://github.com/GeyserMC/Geyser/issues/6864) was closed unresolved —
  this fix (full NetherNet setup, not just a config tweak) isn't officially
  documented anywhere as *the* fix for that symptom; arrived at it via the
  official NetherNet migration blog post + playit's own Geyser+NetherNet
  guide, not a single canonical source.
