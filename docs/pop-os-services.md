# pop-os — Tailnet Services

`pop-os` (tag:`workstation`, Tailscale IP `100.120.184.78`) hosts always-on
services reachable only over the tailnet. Nothing here is exposed on the LAN
or the public internet — isolation comes from Tailscale itself plus `ufw`.

Everything lives under a single root, `/stef`, so the whole setup is
self-contained and easy to find on a machine that isn't primarily mine:

```
/stef/
├── couchdb/   CouchDB data + config (Docker volumes) — NOT network-shared
└── share/     Samba share root (mounted as smb://.../stef)
    ├── ableton/
    └── obsidian/
```

`couchdb/` is deliberately kept out of `share/` — otherwise its internal
data files would be browsable/deletable from Finder over the network drive.

---

## Tailnet ACL — SSH access

By default Tailscale denies SSH entirely unless the policy file's `ssh`
block explicitly grants it — this applies even to your own devices, and
even to the admin-console "SSH" button (it's gated by the same policy, not
a bypass).

Current policy (`https://login.tailscale.com/admin/acls/file`):

```json
{
    "tagOwners": {
        "tag:workstation": ["autogroup:admin"]
    },

    "acls": [
        {"action": "accept", "src": ["*"], "dst": ["*:*"]}
    ],

    "ssh": [
        {
            "action": "accept",
            "src":    ["autogroup:member"],
            "dst":    ["autogroup:self", "tag:workstation"],
            "users":  ["autogroup:nonroot", "root"]
        }
    ]
}
```

- `autogroup:self` — every device you personally own (covers stef-desktop,
  stef-mba, etc.)
- `tag:workstation` — tagged boxes like pop-os, which aren't "owned" by a
  user in Tailscale's model so `autogroup:self` alone doesn't cover them
- `autogroup:member` as `dst` is **not valid** — Tailscale rejects it
  ("invalid dst"); use `autogroup:self` instead

Note: Tailscale SSH auth is identity-based, not password-based — a target
user must exist as a real local account on the destination machine, or the
connection is refused with a policy error that looks identical to an actual
ACL rejection (misleading when debugging — check `getent passwd <user>` on
the remote box before assuming the ACL is wrong).

---

## Obsidian Sync — CouchDB

Canonical CouchDB instance for Obsidian's Self-hosted LiveSync plugin, so
this Mac, stef-desktop, and any future device sync through one shared
backend. **This supersedes the earlier plan of running CouchDB on
stef-desktop** (see `windows/obsidian-livesync-setup.ps1` — kept for
reference but superseded, do not run it, it would spin up a second,
disconnected sync backend).

**Setup (Docker, on pop-os):**

- Container: `couchdb:3`, `--restart unless-stopped`
- Port published as `100.120.184.78:5984:5984` — bound to the Tailscale
  interface specifically (not `0.0.0.0`), so it's unreachable even on the
  local LAN
- Data: `/stef/couchdb/data`, config: `/stef/couchdb/etc/local.ini`
- `local.ini` sets `single_node=true`, `[cluster] n=1` (without this,
  CouchDB's default `n=3` replica setting silently fails to create the
  `_users`/`_replicator` system databases on a one-node instance), and CORS
  headers for `app://obsidian.md` / `capacitor://localhost`
- Auth user: `stef` (CouchDB-internal login, not a Unix account)
- Vault database: `obsidian`

**Obsidian "Self-hosted LiveSync" plugin settings (every device):**

```
Remote Type: CouchDB
URI:         http://100.120.184.78:5984/obsidian
Username:    stef
Password:    (see 1Password — generated per-setup, not stored in this repo)
```

Run "Test Database Connection" then "Check database configuration" in the
plugin after entering these.

---

## File share — `/srv/stef` (Samba)

Plain directory, not a home directory — no login-capable Unix account
behind it. Mounted from macOS/Windows as a network drive over Tailscale.
Backed by `/stef/share` on disk (see layout above).

```
/stef/share/
├── ableton/     Ableton Live projects — see note on network-mount latency below
└── obsidian/    (reserved — not the sync path; that's the CouchDB DB above)
```

**Connect:**

```
smb://100.120.184.78/stef
```

Username `stef` / password in 1Password (separate credential from the
CouchDB one above, same account name is a coincidence of both being called
`stef`, not a shared login).

**Setup notes:**

- Samba auth user is a `--system --no-create-home --shell /usr/sbin/nologin`
  account — exists only so Samba has something to authenticate against,
  can't be logged into directly.
- Samba's own interface-binding (`interfaces =` / `bind interfaces only`)
  doesn't work reliably against Tailscale's point-to-point `/32` interface
  — it silently falls back to binding loopback only. Fix: don't fight it —
  let `smbd` bind all interfaces (default) and rely on `ufw` for isolation
  instead (see below). Same effective result, less fragile.
- **Ableton over SMB:** works for lighter sessions; large sessions may see
  audio dropouts or lock contention reading/writing directly over the
  network mount. Treat this as a sync/backup point rather than the live
  working location if a project gets heavy — untested at scale so far.

---

## Firewall (`ufw`)

```
Default: deny (incoming), allow (outgoing), deny (routed)

Anywhere on tailscale0     ALLOW IN
22/tcp  from 192.168.0.0/16 ALLOW IN
22/tcp  from 10.0.0.0/8     ALLOW IN
22/tcp  from 172.16.0.0/12  ALLOW IN
```

Everything (5984, 445, 139, etc.) is only reachable via `tailscale0` —
this is what actually enforces isolation, not per-service binding tricks.
SSH additionally allows from private LAN ranges directly (pre-existing
rule, unrelated to this setup).

---

## Credentials

Generated passwords for both services above are **not** committed here
(this repo is public). They were generated during setup and need moving
into 1Password — check there before assuming a value below is current;
if missing, regenerate via `smbpasswd -a stef` / CouchDB's admin API and
update 1Password.
