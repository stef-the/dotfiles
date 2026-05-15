#!/usr/bin/env bash
#
# backup-discovery.sh
# Scans a Windows user profile to identify important files worth backing up
# before a reinstall. Designed to run from WSL or Git Bash.
#
# Usage: ./backup-discovery.sh [output_directory]
#   If output_directory is given, the report is also saved there as backup-report.md

set -euo pipefail

# --- Configuration -----------------------------------------------------------

LARGE_FILE_THRESHOLD=$((100 * 1024 * 1024))  # 100MB in bytes
RECENT_DAYS=30

# Detect Windows user directory
if [[ -d "/mnt/c/Users" ]]; then
    # WSL
    WIN_USERS="/mnt/c/Users"
elif [[ -d "/c/Users" ]]; then
    # Git Bash
    WIN_USERS="/c/Users"
else
    echo "ERROR: Cannot find Windows user directories. Are you running from WSL or Git Bash?" >&2
    exit 1
fi

# Try to auto-detect the active user (skip Default, Public, All Users, etc.)
WIN_USER=""
for dir in "$WIN_USERS"/*/; do
    dirname="$(basename "$dir")"
    case "$dirname" in
        Default|Public|"Default User"|"All Users"|desktop.ini) continue ;;
    esac
    if [[ -d "$dir/Desktop" ]]; then
        WIN_USER="$dir"
        break
    fi
done

if [[ -z "$WIN_USER" ]]; then
    echo "ERROR: Could not detect Windows user profile." >&2
    echo "Available directories in $WIN_USERS:" >&2
    ls "$WIN_USERS" >&2
    exit 1
fi

# Strip trailing slash for cleanliness
WIN_USER="${WIN_USER%/}"
USERNAME="$(basename "$WIN_USER")"

OUTPUT_DIR="${1:-}"

# --- Helper functions --------------------------------------------------------

human_size() {
    local bytes="$1"
    if (( bytes >= 1073741824 )); then
        printf "%.1f GB" "$(echo "scale=1; $bytes / 1073741824" | bc)"
    elif (( bytes >= 1048576 )); then
        printf "%.1f MB" "$(echo "scale=1; $bytes / 1048576" | bc)"
    elif (( bytes >= 1024 )); then
        printf "%.1f KB" "$(echo "scale=1; $bytes / 1024" | bc)"
    else
        printf "%d B" "$bytes"
    fi
}

dir_size() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        du -sb "$dir" 2>/dev/null | awk '{print $1}' || echo "0"
    else
        echo "0"
    fi
}

count_files() {
    local dir="$1"
    local pattern="${2:-*}"
    if [[ -d "$dir" ]]; then
        find "$dir" -maxdepth 5 -type f -iname "$pattern" 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# --- Begin report ------------------------------------------------------------

report() {
cat <<HEADER
# Backup Discovery Report

- **User profile**: \`$WIN_USER\`
- **Username**: $USERNAME
- **Scan date**: $(date '+%Y-%m-%d %H:%M:%S')
- **Large file threshold**: 100 MB
- **Recent file window**: $RECENT_DAYS days

---

HEADER

# ---- 1. Directory overview -------------------------------------------------

echo "## 1. Directory Overview"
echo ""
echo "| Directory | Size | File count |"
echo "|-----------|------|------------|"

SCAN_DIRS=(Documents Pictures Videos Desktop Downloads Music AppData)
for dirname in "${SCAN_DIRS[@]}"; do
    target="$WIN_USER/$dirname"
    if [[ -d "$target" ]]; then
        sz=$(dir_size "$target")
        fc=$(count_files "$target")
        echo "| $dirname | $(human_size "$sz") | $fc |"
    else
        echo "| $dirname | *(not found)* | - |"
    fi
done
echo ""

# ---- 2. File type breakdown ------------------------------------------------

echo "## 2. File Type Breakdown"
echo ""

for dirname in "${SCAN_DIRS[@]}"; do
    target="$WIN_USER/$dirname"
    [[ -d "$target" ]] || continue

    echo "### $dirname"
    echo ""
    echo "| Extension | Count | Total size |"
    echo "|-----------|-------|------------|"

    # Get top 15 extensions by total size
    find "$target" -maxdepth 5 -type f 2>/dev/null | while read -r f; do
        ext="${f##*.}"
        if [[ "$ext" == "$f" ]] || [[ -z "$ext" ]]; then
            ext="(none)"
        else
            ext=".${ext,,}"  # lowercase
        fi
        sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
        echo "$ext $sz"
    done | awk '{
        ext=$1; sz=$2;
        count[ext]++;
        total[ext]+=sz;
    } END {
        for (e in count) {
            printf "%s\t%d\t%d\n", e, count[e], total[e]
        }
    }' | sort -t$'\t' -k3 -nr | head -15 | while IFS=$'\t' read -r ext cnt tot; do
        echo "| $ext | $cnt | $(human_size "$tot") |"
    done

    echo ""
done

# ---- 3. Large files (>100MB) -----------------------------------------------

echo "## 3. Large Files (>100 MB)"
echo ""
echo "| Size | Path |"
echo "|------|------|"

find "$WIN_USER" -maxdepth 6 -type f -size +100M 2>/dev/null | while read -r f; do
    sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
    relpath="${f#$WIN_USER/}"
    echo "| $(human_size "$sz") | \`$relpath\` |"
done | sort -t'|' -k2 -rn | head -50

echo ""

# ---- 4. Recently modified files (last 30 days) -----------------------------

echo "## 4. Recently Modified Files (last $RECENT_DAYS days)"
echo ""
echo "Top 30 most recently modified files (excluding AppData caches):"
echo ""
echo "| Modified | Size | Path |"
echo "|----------|------|------|"

find "$WIN_USER" -maxdepth 5 -type f -mtime -"$RECENT_DAYS" \
    -not -path "*/AppData/Local/Temp/*" \
    -not -path "*/AppData/Local/Microsoft/*" \
    -not -path "*/AppData/Local/Google/Chrome/User Data/Default/Cache/*" \
    -not -path "*/.cache/*" \
    -not -path "*/node_modules/*" \
    2>/dev/null | while read -r f; do
    mod=$(stat -c%Y "$f" 2>/dev/null || echo 0)
    sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
    relpath="${f#$WIN_USER/}"
    echo "$mod|$sz|$relpath"
done | sort -t'|' -k1 -rn | head -30 | while IFS='|' read -r mod sz relpath; do
    moddate=$(date -d "@$mod" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "unknown")
    echo "| $moddate | $(human_size "$sz") | \`$relpath\` |"
done

echo ""

# ---- 5. Project directories ------------------------------------------------

echo "## 5. Project Directories"
echo ""
echo "Directories containing version control or project markers:"
echo ""

PROJECT_MARKERS=(.git .svn .hg package.json Cargo.toml go.mod pom.xml build.gradle
                  CMakeLists.txt Makefile .sln .csproj requirements.txt Pipfile
                  pyproject.toml composer.json Gemfile .idea .vscode)

found_projects=0
for dirname in Documents Desktop Downloads; do
    target="$WIN_USER/$dirname"
    [[ -d "$target" ]] || continue
    for marker in "${PROJECT_MARKERS[@]}"; do
        find "$target" -maxdepth 4 -name "$marker" -type f 2>/dev/null | while read -r f; do
            projdir="$(dirname "$f")"
            relpath="${projdir#$WIN_USER/}"
            sz=$(dir_size "$projdir")
            echo "- \`$relpath\` ($marker) -- $(human_size "$sz")"
        done
    done
done | sort -u | head -40

# Also check common dev locations at the drive root
for devdir in "/mnt/c/dev" "/mnt/c/projects" "/mnt/c/code" "/mnt/c/repos" "/mnt/c/src" \
              "/c/dev" "/c/projects" "/c/code" "/c/repos" "/c/src"; do
    if [[ -d "$devdir" ]]; then
        echo ""
        echo "Found dev directory: \`$devdir\`"
        sz=$(dir_size "$devdir")
        echo "- Total size: $(human_size "$sz")"
        ls -1 "$devdir" 2>/dev/null | head -20 | while read -r sub; do
            echo "  - \`$sub\`"
        done
    fi
done

echo ""

# ---- 6. Game saves ---------------------------------------------------------

echo "## 6. Game Saves"
echo ""
echo "Checking known game save locations:"
echo ""

APPDATA_LOCAL="$WIN_USER/AppData/Local"
APPDATA_ROAMING="$WIN_USER/AppData/Roaming"

# Known game save directories
declare -A GAME_SAVES=(
    # AppData/Local
    ["Minecraft"]="$APPDATA_ROAMING/.minecraft/saves"
    ["Terraria"]="$WIN_USER/Documents/My Games/Terraria"
    ["Stardew Valley"]="$APPDATA_ROAMING/StardewValley/Saves"
    ["Dark Souls III"]="$APPDATA_ROAMING/DarkSoulsIII"
    ["Elden Ring"]="$APPDATA_ROAMING/EldenRing"
    ["Sekiro"]="$APPDATA_ROAMING/Sekiro"
    ["Factorio"]="$APPDATA_ROAMING/Factorio/saves"
    ["Celeste"]="$APPDATA_LOCAL/Celeste/Saves"
    ["Hollow Knight"]="$APPDATA_LOCAL/../LocalLow/Team Cherry/Hollow Knight"
    ["Cyberpunk 2077"]="$APPDATA_LOCAL/CD Projekt Red/Cyberpunk 2077"
    ["Baldurs Gate 3"]="$APPDATA_LOCAL/Larian Studios/Baldur's Gate 3"
    ["Skyrim SE"]="$WIN_USER/Documents/My Games/Skyrim Special Edition/Saves"
    ["Fallout 4"]="$WIN_USER/Documents/My Games/Fallout4/Saves"
    ["Witcher 3"]="$WIN_USER/Documents/The Witcher 3"
    ["GTA V"]="$WIN_USER/Documents/Rockstar Games/GTA V/Profiles"
    ["RDR2"]="$WIN_USER/Documents/Rockstar Games/Red Dead Redemption 2"
    ["Valheim"]="$APPDATA_LOCAL/../LocalLow/IronGate/Valheim"
    ["Subnautica"]="$APPDATA_LOCAL/../LocalLow/Unknown Worlds/Subnautica"
    ["Hades"]="$WIN_USER/Documents/Saved Games/Hades"
    ["Civilization VI"]="$WIN_USER/Documents/My Games/Sid Meier's Civilization VI/Saves"
    ["Cities Skylines"]="$APPDATA_LOCAL/Colossal Order/Cities_Skylines/Saves"
    ["Satisfactory"]="$APPDATA_LOCAL/FactoryGame/Saved/SaveGames"
    ["Palworld"]="$APPDATA_LOCAL/Pal/Saved/SaveGames"
)

for game in $(echo "${!GAME_SAVES[@]}" | tr ' ' '\n' | sort); do
    path="${GAME_SAVES[$game]}"
    if [[ -d "$path" ]]; then
        sz=$(dir_size "$path")
        fc=$(count_files "$path")
        echo "- **$game**: \`${path#$WIN_USER/}\` -- $(human_size "$sz"), $fc files"
    fi
done

# Also scan Documents/My Games generically
MY_GAMES="$WIN_USER/Documents/My Games"
if [[ -d "$MY_GAMES" ]]; then
    echo ""
    echo "### Documents/My Games contents"
    echo ""
    ls -1 "$MY_GAMES" 2>/dev/null | while read -r g; do
        gpath="$MY_GAMES/$g"
        if [[ -d "$gpath" ]]; then
            sz=$(dir_size "$gpath")
            echo "- \`$g\` -- $(human_size "$sz")"
        fi
    done
fi

# Check for Steam userdata (cloud saves, screenshots)
for steam in "$WIN_USER/AppData/Local/Steam" \
             "/mnt/c/Program Files (x86)/Steam/userdata" \
             "/mnt/c/Program Files/Steam/userdata" \
             "/c/Program Files (x86)/Steam/userdata" \
             "/c/Program Files/Steam/userdata"; do
    if [[ -d "$steam" ]]; then
        echo ""
        echo "### Steam userdata"
        echo ""
        sz=$(dir_size "$steam")
        echo "- \`$steam\` -- $(human_size "$sz")"
        break
    fi
done

echo ""

# ---- 7. Browser profiles ---------------------------------------------------

echo "## 7. Browser Profiles & Bookmarks"
echo ""

declare -A BROWSER_PATHS=(
    ["Chrome"]="$APPDATA_LOCAL/Google/Chrome/User Data"
    ["Firefox"]="$APPDATA_ROAMING/Mozilla/Firefox/Profiles"
    ["Edge"]="$APPDATA_LOCAL/Microsoft/Edge/User Data"
    ["Brave"]="$APPDATA_LOCAL/BraveSoftware/Brave-Browser/User Data"
    ["Vivaldi"]="$APPDATA_LOCAL/Vivaldi/User Data"
    ["Opera"]="$APPDATA_ROAMING/Opera Software/Opera Stable"
)

for browser in $(echo "${!BROWSER_PATHS[@]}" | tr ' ' '\n' | sort); do
    bpath="${BROWSER_PATHS[$browser]}"
    if [[ -d "$bpath" ]]; then
        sz=$(dir_size "$bpath")
        echo "### $browser"
        echo ""
        echo "- Path: \`${bpath#$WIN_USER/}\`"
        echo "- Total size: $(human_size "$sz")"

        # Look for bookmarks
        if [[ "$browser" == "Firefox" ]]; then
            find "$bpath" -name "places.sqlite" -o -name "bookmarkbackups" 2>/dev/null | head -3 | while read -r f; do
                echo "- Bookmarks DB: \`${f#$WIN_USER/}\`"
            done
        else
            find "$bpath" -name "Bookmarks" -maxdepth 3 2>/dev/null | head -3 | while read -r f; do
                fsz=$(stat -c%s "$f" 2>/dev/null || echo 0)
                echo "- Bookmarks file: \`${f#$WIN_USER/}\` ($(human_size "$fsz"))"
            done
        fi

        # Check for extensions
        find "$bpath" -maxdepth 3 -name "Extensions" -type d 2>/dev/null | head -1 | while read -r f; do
            ext_count=$(ls -1 "$f" 2>/dev/null | wc -l | tr -d ' ')
            echo "- Extensions: ~$ext_count installed"
        done

        echo ""
    fi
done

# ---- 8. Credentials & keys -------------------------------------------------

echo "## 8. SSH Keys, GPG Keys & Credentials"
echo ""
echo "**IMPORTANT: Back these up securely or you will lose access to services.**"
echo ""

# SSH
SSH_DIR="$WIN_USER/.ssh"
if [[ -d "$SSH_DIR" ]]; then
    echo "### SSH Keys (\`~/.ssh\`)"
    echo ""
    ls -la "$SSH_DIR" 2>/dev/null | while read -r line; do
        echo "    $line"
    done
    echo ""
else
    echo "- No \`.ssh\` directory found"
    echo ""
fi

# GPG
GPG_DIR="$APPDATA_ROAMING/gnupg"
if [[ -d "$GPG_DIR" ]]; then
    echo "### GPG Keys"
    echo ""
    echo "- GPG directory found: \`AppData/Roaming/gnupg\`"
    sz=$(dir_size "$GPG_DIR")
    echo "- Size: $(human_size "$sz")"
    echo ""
fi

# .gitconfig
for gc in "$WIN_USER/.gitconfig" "$WIN_USER/.config/git/config"; do
    if [[ -f "$gc" ]]; then
        echo "### Git Config"
        echo ""
        echo "- \`${gc#$WIN_USER/}\`"
        echo ""
    fi
done

# Credential files and tokens
echo "### Other credential/config files"
echo ""

CRED_PATTERNS=(
    ".npmrc"
    ".pypirc"
    ".netrc"
    ".env"
    ".aws/credentials"
    ".aws/config"
    ".docker/config.json"
    ".kube/config"
    ".config/gh/hosts.yml"
    ".config/github-copilot/hosts.json"
    "AppData/Roaming/NuGet/NuGet.Config"
    ".wakatime.cfg"
)

for pat in "${CRED_PATTERNS[@]}"; do
    target="$WIN_USER/$pat"
    if [[ -f "$target" ]]; then
        echo "- \`$pat\`"
    fi
done

# WSL config
for wslconf in "/mnt/c/Users/$USERNAME/.wslconfig" "$WIN_USER/.wslconfig"; do
    if [[ -f "$wslconf" ]]; then
        echo "- \`.wslconfig\`"
        break
    fi
done

echo ""

# ---- 9. Application configs ------------------------------------------------

echo "## 9. Notable Application Data"
echo ""

declare -A APP_CONFIGS=(
    ["VS Code"]="$APPDATA_ROAMING/Code/User"
    ["VS Code (settings)"]="$APPDATA_ROAMING/Code/User/settings.json"
    ["VS Code (keybindings)"]="$APPDATA_ROAMING/Code/User/keybindings.json"
    ["VS Code (extensions)"]="$WIN_USER/.vscode/extensions"
    ["Windows Terminal"]="$APPDATA_LOCAL/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
    ["PowerShell profile"]="$WIN_USER/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
    ["OBS Studio"]="$APPDATA_ROAMING/obs-studio"
    ["Discord"]="$APPDATA_ROAMING/discord"
    ["Spotify"]="$APPDATA_ROAMING/Spotify"
    ["Notion"]="$APPDATA_ROAMING/Notion"
    ["1Password"]="$APPDATA_LOCAL/1Password"
    ["KeePass"]="$APPDATA_ROAMING/KeePass"
    ["Bitwarden"]="$APPDATA_ROAMING/Bitwarden"
    ["Tailscale"]="$APPDATA_LOCAL/Tailscale"
)

for app in $(echo "${!APP_CONFIGS[@]}" | tr ' ' '\n' | sort); do
    path="${APP_CONFIGS[$app]}"
    if [[ -e "$path" ]]; then
        if [[ -d "$path" ]]; then
            sz=$(dir_size "$path")
            echo "- **$app**: \`${path#$WIN_USER/}\` -- $(human_size "$sz")"
        else
            sz=$(stat -c%s "$path" 2>/dev/null || echo 0)
            echo "- **$app**: \`${path#$WIN_USER/}\` -- $(human_size "$sz")"
        fi
    fi
done

echo ""

# ---- 10. Summary & recommendations -----------------------------------------

echo "## 10. Backup Recommendations"
echo ""
cat <<'RECS'
### Priority 1 -- Cannot be recreated
- [ ] SSH keys (`~/.ssh`)
- [ ] GPG keys
- [ ] Git config
- [ ] Credential files (`.npmrc`, `.aws`, etc.)
- [ ] Browser bookmarks (or ensure sync is on)
- [ ] Game saves you care about
- [ ] Any project directories with uncommitted/unpushed work

### Priority 2 -- Painful to lose
- [ ] VS Code settings & extensions list (`code --list-extensions > extensions.txt`)
- [ ] Documents (personal files, uni work, etc.)
- [ ] Desktop files
- [ ] Application configs (terminal settings, etc.)
- [ ] PowerShell/bash profile customisations

### Priority 3 -- Nice to have
- [ ] Downloads (probably re-downloadable)
- [ ] Pictures/Videos (check if backed up elsewhere)
- [ ] Music (streaming or re-downloadable)
- [ ] Browser extensions (will re-sync)

### Backup command (rsync over Tailscale)
```bash
# Example: rsync important dirs to your Linux box over Tailscale
REMOTE="user@linux-box"  # adjust to your Tailscale hostname
DEST="/path/to/backup/windows-backup-$(date +%Y%m%d)"

rsync -avz --progress \
  ~/.ssh \
  ~/Documents \
  ~/Desktop \
  "$REMOTE:$DEST/"
```
RECS

echo ""
echo "---"
echo "*Report generated by backup-discovery.sh on $(date)*"
}

# --- Run and optionally save -------------------------------------------------

if [[ -n "$OUTPUT_DIR" ]]; then
    mkdir -p "$OUTPUT_DIR"
    OUTPUT_FILE="$OUTPUT_DIR/backup-report-$(date +%Y%m%d-%H%M%S).md"
    report | tee "$OUTPUT_FILE"
    echo "" >&2
    echo "Report saved to: $OUTPUT_FILE" >&2
else
    report
fi
