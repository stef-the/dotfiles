---
name: rescan
description: Full rescan of Blackboard, eVision, and email for Bristol CS Tracker updates, writes up any un-noted lecture into a full note, and syncs the timetable to Google Calendar (stefan@xopa.com). Use when the user asks to rescan, check for updates, check Blackboard, or sync their calendar.
---

# Bristol CS Tracker — Full Rescan

Runs the complete update sweep across every account/system the tracker depends on, updates the vault + tracker.json, writes up new lecture notes, deploys, and syncs the timetable to the user's personal Google Calendar.

This is the canonical copy of this skill (synced via the `dotfiles` repo to every machine, symlinked to `~/.claude/skills/rescan`). If you're editing it, edit this file — don't fork a divergent copy elsewhere. The bristol-cs-tracker repo also carries a copy of this file as a project skill for when dotfiles isn't set up on a machine yet; keep the two in sync.

## Portability notes (runs on Windows and macOS)

- **Obsidian vault path**: the same vault, synced via Self-hosted LiveSync, but its local path differs per device (Windows: `C:\Users\stef\Documents\Obsidian\Stef\Stef\`). On a new device, use whatever path the local Obsidian install has the vault open at — ask the user if it's not obvious rather than guessing a path.
- **bristol-cs-tracker repo**: Steps 5a's `tracker.json`/build/deploy sub-steps need this repo cloned locally. If it isn't (e.g. a fresh machine), skip those specific sub-steps and say so in the Step 7 report — vault updates and lecture notes (5b) don't depend on it and should still run.

## Accounts involved (do not mix these up)

| Account | Used for | Access method |
|---|---|---|
| UoB SSO (Azure AD) | Blackboard, eVision | Chrome browser (claude-in-chrome tools). Session often expires between sessions — click "Staff and student login" / re-navigate; the underlying Azure AD session carries through with no password needed. If it ever asks for a password, STOP and ask the user to sign in themselves — never enter it. |
| UoB Outlook (qf25937@bristol.ac.uk) | University admin emails (Study Abroad, course admin, etc.) | Chrome, `https://outlook.office.com/mail/` |
| stefan@xopa.com | Personal Gmail + Google Calendar (shopping orders, personal life, **this is where lecture/room calendar events belong**) | Chrome, already signed in as a saved Google account — navigate to `https://mail.google.com/mail/` or `https://calendar.google.com/`. **Do NOT use the `mcp__claude_ai_Gmail__*` / `mcp__claude_ai_Google_Calendar__*` connector tools for this** — those are wired to a completely different account (tac@00start.com, a large unrelated business mailbox) and will silently do the wrong thing. Browser automation only for stefan@xopa.com. |
| tac@00start.com | Unrelated business account (Gmail/Calendar MCP connectors point here) | Only relevant if the user explicitly asks about it. Do not touch for anything Bristol-related. |

## Step 1 — Blackboard

Course IDs (re-verify from the Courses list at `https://www.ole.bris.ac.uk/ultra/course` if any of these 404 or a new one has opened — units change access each teaching block):

- COMS20006 (Software Engineering Project): `_269191_1`
- COMS20007 (Programming Languages and Computation): `_269192_1`
- COMS20008 (Computer Systems A): `_269193_1`
- COMS20017 (Algorithms and Data): `_269196_1`

For each, check:
1. `https://www.ole.bris.ac.uk/ultra/courses/<id>/announcements` — read all, compare against what's already in the vault's per-course notes.
2. `https://www.ole.bris.ac.uk/ultra/courses/<id>/outline` — check Content tab for new items. Expand every folder (some content, like the SEP project list, is nested inside a folder whose own description text is generic and doesn't reveal what's inside — always expand, don't trust the parent folder blurb).

Note: Blackboard's Ultra SPA needs ~3s wait after navigation before content hydrates — a `get_page_text` immediately after navigate often returns a skeleton/placeholder.

## Step 2 — eVision (marks/progression)

`https://www.bristol.ac.uk/assessment-marks` → "View interim transcript" (not "View assessment details" — that link is inert once a year is finalized). Compare unit marks/outcomes against `Uni/Year 1 (2025-26)/Year 1.md` and the current year's equivalent once Year 2 marks start appearing.

## Step 3 — Outlook (UoB email)

Search `https://outlook.office.com/mail/` for anything relevant since the last rescan (Study Abroad, course admin, deadlines). Cross-check any date/deadline claims against the actual email body, not just the subject line — one past rescan found a vault date was wrong (25 Sep vs. the real 29 Sep) because a slide deck had been mis-transcribed; the email itself was the authoritative source.

## Step 4 — Personal (stefan@xopa.com)

Only if relevant to the ask (e.g. shopping orders, personal deadlines) — search `https://mail.google.com/mail/` (already signed in). Don't dig through this account unprompted; it's personal, not part of the standard Bristol sweep.

## Step 5 — Update the vault + tracker

### 5a. Routine updates

- Update `Uni/**` notes and `Planning.md` in the Obsidian vault with anything new.
- Update `web/src/lib/data/tracker.json` (`lastRefreshed`, new todos) in the bristol-cs-tracker repo, if cloned locally (see Portability notes).
- Verify: `cd web && npm run check && npm run test && npm run build`
- Deploy: `CLOUDFLARE_ACCOUNT_ID=711604ba93e8a5de27489a51680b4089 npx wrangler deploy` (multiple Cloudflare accounts exist; this env var picks the right one — omitting it fails non-interactively)
- Commit + push the tracker.json change.

### 5b. Full lecture notes

For every lecture that has already happened since the last rescan and doesn't yet have a proper note — check each course's `Week N - <course>.md` index for a missing link or a bare stub — write a genuine, substantive note. Don't just add a one-line link with a topic guess; this is the main point of the rescan now, not an afterthought. Don't write notes for lectures that haven't happened yet.

Match the depth and structure of the existing template notes in this vault — read one before writing a new one if unsure of the bar: `Uni/Year 2 (2026-27)/TB-4 (year-long)/COMS20017 Algorithms and Data/Week 2/MM03 - Covariance, eigen analysis.md` and `Uni/Year 2 (2026-27)/TB-1/COMS20007 Programming Languages and Computation/Week 2/Monday Lecture - Writing Grammars.md`.

A complete lecture note includes:

- **Header** — lecturer, day/time/room, link to slides (verify it's actually live, not a 404), a note on recording availability.
- **Prereading** — link to the course's background-reading note, if one exists.
- **Intuition / big-picture section** — the core idea in plain language, before any formalism. This is what actually gets read first — see [[feedback_learning_style]] memory (video-first, intuition before notation).
- **Quick-reference section** — tables and/or a formula summary for fast pre-exam lookup.
- **Full worked sections**, one per major concept, each with: (a) intuition, (b) the formal definition, (c) at least one worked numeric/concrete example (from the slides where possible, invented otherwise), (d) a diagram wherever the concept has any spatial, geometric, or structural shape to it — embed as inline SVG (see the Mahalanobis ellipse diagram in the MM03 note for the pattern). Err toward including a diagram, not away from it.
- **Self-check list** at the end — 4-6 questions a shallow read wouldn't survive, written so the student can test themselves from the note alone, without the slides.
- LaTeX for all math — this is a vault file, see [[feedback_obsidian_formatting]] (chat responses use plain text/unicode math instead, per [[feedback_cli_formatting]] — don't let that leak into the note).

Skip lectures that already have a proper note in this style — only backfill missing or stub ones.

## Step 6 — Check the timetable is still live on Google Calendar (stefan@xopa.com)

stefan@xopa.com's Google Calendar already has a **live "University" calendar subscription** that auto-populates all weekly lecture/lab sessions with rooms — this is a pre-existing UoB timetable feed, not something created manually. Do NOT create duplicate events for the regular weekly pattern.

Check via the browser (`https://calendar.google.com/`, signed in as stefan@xopa.com — not the Calendar MCP tool, wrong account, see table above): open the current week and the next, confirm the "University" calendar's events still match `Timetable.md` (day/time/room). This feed already handles rotating-session rooms correctly on its own.

Only take manual action if:
- The feed is missing something Blackboard/tracker.json knows about (e.g. it hasn't caught up with a very recent room change) — in that case, add a one-off event noting the correction, don't fight the feed.
- The user asks for something the feed doesn't cover (e.g. a one-off drop-in, an external deadline like the Study Abroad EOI) — those go on as regular one-off events, same as any other calendar add.

## Step 7 — Report back

Summarise what's actually new (not "nothing new" restated at length) — deadlines, room changes, marks, new lecture notes written, anything actionable. Skip sections where nothing changed rather than listing every unit as "no change." If any 5a sub-step was skipped because the repo wasn't cloned locally, say so in one line.
