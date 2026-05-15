# Package Manager GUI — Planning Document

A SvelteKit web app that provides a GUI for managing system packages across winget, apt, brew, npm, and other package managers.

---

## Concept

A local web dashboard (like Docker Desktop but for all packages) that lets you:
- View all installed packages across managers in one place
- Search for and install new packages
- Update outdated packages (individually or bulk)
- Remove packages with dependency awareness
- Track what you've installed (separate from system packages)
- Export/import package lists (for machine migration — directly useful for the Windows setup)

## Tech Stack

- **Frontend:** SvelteKit + Tailwind CSS + TypeScript (your main stack)
- **Backend:** SvelteKit server routes calling CLI tools
- **Database:** SQLite (via better-sqlite3, same as bounty-hunter)
- **Styling:** Nord theme, clean minimal UI
- **Runs locally:** `npm run dev` or built as a standalone app

## Architecture Questions to Discuss

1. **Scope:** Start with winget + apt (WSL) only? Or brew + npm too?
2. **Deployment:** Local dev server, or package as Electron/Tauri app?
3. **Auth:** Needed? It's local-only, probably not
4. **Real-time:** Stream package install output via SSE (like bounty-hunter's scan progress)?
5. **Cross-platform:** Run on Windows natively, or inside WSL serving to Windows browser?

## Core Features (MVP)

- [ ] Package list view with search/filter
- [ ] Install/uninstall packages
- [ ] Update checker + bulk update
- [ ] Package details panel (version, description, dependencies)
- [ ] "My packages" list (user-curated, exportable as a script)

## Stretch Features

- [ ] System health dashboard (disk usage, running services)
- [ ] Dotfiles manager (edit configs from the GUI)
- [ ] Scheduled update checks
- [ ] Install history / changelog

## Prior Art

- **Winget UI (UniGetUI)** — Windows GUI for winget/scoop/choco, but Windows-only and not web-based
- **Homebrew Cask Room** — abandoned
- **Cockpit** — Linux server admin GUI, too heavyweight

## Next Steps

- Decide on MVP scope
- Scaffold SvelteKit project
- Build the winget/apt adapter layer
- Design the UI (wireframes or straight to code?)

---

*This is a separate project from the Windows setup. Discuss in its own conversation.*
