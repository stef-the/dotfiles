# ═══════════════════════════════════════════════════════════════════════
#  PowerShell profile — WSL2/zsh-style experience
#  Edit me:  notepad $PROFILE   |   Reload:  . $PROFILE
# ═══════════════════════════════════════════════════════════════════════

# ─── Oh My Posh prompt (blue-owl theme) ────────────────────────────────
oh-my-posh init pwsh --config "$HOME\.config\oh-my-posh\blue-owl.omp.json" | Invoke-Expression

# ─── PSReadLine: ghost-text autosuggestions + syntax highlighting ──────
#     (the zsh-autosuggestions / zsh-syntax-highlighting equivalent)
Import-Module PSReadLine
try {   # predictions need a real interactive terminal; skip quietly otherwise
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView  # popup list of matches
} catch { }
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete    # fish-style menu
Set-PSReadLineKeyHandler -Key RightArrow -Function ForwardChar    # accept suggestion

# ─── Terminal-Icons: file/folder glyphs in directory listings ──────────
Import-Module Terminal-Icons

# ─── eza: modern, colorized `ls` with icons ────────────────────────────
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    $ezaBase = '--icons=auto','--group-directories-first','--git'
    function ls { eza @ezaBase @args }
    function ll { eza @ezaBase -l @args }
    function la { eza @ezaBase -la @args }
    function lt { eza @ezaBase --tree --level=2 @args }
}

# ─── bat: syntax-highlighted `cat` ─────────────────────────────────────
if (Get-Command bat -ErrorAction SilentlyContinue) {
    Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
    $env:BAT_THEME = 'TwoDark'
    function cat { bat --paging=never @args }
}

# ─── zoxide: smarter `cd` that learns your habits (the `z` jump) ────────
#     `cd proj` jumps to the best-matching dir you've visited; `cdi` picks
#     interactively via fzf. Plain `cd <real path>` still works.
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}

# ─── PSFzf: fuzzy finder — Ctrl+R history, Ctrl+T file picker ───────────
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# ─── fastfetch: system info banner on every new shell ──────────────────
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch
}
