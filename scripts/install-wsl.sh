#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# WSL / Linux Setup Script
# Run inside WSL Ubuntu after initial setup
# ═══════════════════════════════════════════════════════════════

set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "═══ WSL / Linux Setup Script ═══"
echo ""

# ─── Clone dotfiles if not already present ────────────────────
if [[ ! -d "$DOTFILES_DIR" ]]; then
    echo "Cloning dotfiles..."
    git clone https://github.com/stef-the/dotfiles.git "$DOTFILES_DIR"
fi

# ─── System packages ─────────────────────────────────────────
echo "═══ Installing system packages ═══"
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    zsh \
    git \
    curl \
    wget \
    unzip \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    ripgrep \
    tree \
    jq \
    htop \
    fastfetch \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    python3 \
    python3-pip \
    python3-venv \
    default-jdk \
    sqlite3 \
    libssl-dev \
    pkg-config \
    gpg

# ─── Install eza (modern ls) ─────────────────────────────────
echo "═══ Installing eza ═══"
if ! command -v eza &>/dev/null; then
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
fi

# ─── Install CLI tools (bat, fzf, zoxide, lazygit) ───────────
echo "═══ Installing CLI tools ═══"
sudo apt install -y bat fzf zoxide

# bat is installed as 'batcat' on Ubuntu — symlink it
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    mkdir -p ~/.local/bin
    ln -sf "$(which batcat)" ~/.local/bin/bat
fi

# lazygit (not in apt, install from GitHub)
if ! command -v lazygit &>/dev/null; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin
    rm /tmp/lazygit /tmp/lazygit.tar.gz
fi

# ─── Set Zsh as default shell ────────────────────────────────
echo "═══ Setting Zsh as default shell ═══"
if [[ "$SHELL" != *"zsh"* ]]; then
    chsh -s $(which zsh)
fi

# ─── Install Starship ────────────────────────────────────────
echo "═══ Installing Starship ═══"
if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# ─── Install NVM + Node ──────────────────────────────────────
echo "═══ Installing NVM + Node.js ═══"
if [[ ! -d "$HOME/.nvm" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

# ─── Install Claude Code ─────────────────────────────────────
echo "═══ Installing Claude Code ═══"
npm install -g @anthropic-ai/claude-code

# ─── Install Rust ────────────────────────────────────────────
echo "═══ Installing Rust ═══"
if ! command -v rustc &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# ─── Install GHCup (Haskell) ─────────────────────────────────
echo "═══ Installing Haskell (GHCup) ═══"
if ! command -v ghcup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
        BOOTSTRAP_HASKELL_NONINTERACTIVE=1 sh
fi

# ─── Install GitHub CLI ──────────────────────────────────────
echo "═══ Installing GitHub CLI ═══"
if ! command -v gh &>/dev/null; then
    (type -p wget >/dev/null || sudo apt install wget -y) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y
fi

# ─── Install Docker (inside WSL) ─────────────────────────────
echo "═══ Setting up Docker ═══"
echo "Docker Desktop on Windows integrates with WSL automatically."
echo "Make sure Docker Desktop > Settings > Resources > WSL Integration > Ubuntu is enabled."

# ─── Install pfetch ──────────────────────────────────────────
echo "═══ Installing pfetch ═══"
if ! command -v pfetch &>/dev/null; then
    cargo install pfetch 2>/dev/null || {
        # Fallback: install pfetch shell script
        wget -O ~/.local/bin/pfetch https://raw.githubusercontent.com/dylanaraps/pfetch/master/pfetch
        chmod +x ~/.local/bin/pfetch
    }
fi

# ─── Symlink dotfiles ────────────────────────────────────────
echo "═══ Linking dotfiles ═══"

# Backup existing configs
for f in ~/.zshrc ~/.gitconfig ~/.gitignore_global; do
    [[ -f "$f" ]] && mv "$f" "${f}.bak" 2>/dev/null || true
done

# Symlink configs
ln -sf "$DOTFILES_DIR/zsh/.zshrc" ~/.zshrc
ln -sf "$DOTFILES_DIR/git/.gitconfig" ~/.gitconfig
ln -sf "$DOTFILES_DIR/git/.gitignore_global" ~/.gitignore_global
mkdir -p ~/.config
ln -sf "$DOTFILES_DIR/starship/starship.toml" ~/.config/starship.toml

# Claude config
mkdir -p ~/.claude
ln -sf "$DOTFILES_DIR/claude/settings.json" ~/.claude/settings.json

echo ""
echo "═══ SETUP COMPLETE ═══"
echo ""
echo "What's installed:"
echo "  - Zsh + Starship + autosuggestions + syntax highlighting"
echo "  - Node.js (LTS via NVM)"
echo "  - Python 3 + pip"
echo "  - Java 17 (OpenJDK)"
echo "  - Rust (rustup)"
echo "  - Haskell (GHCup)"
echo "  - C/C++ (gcc, g++, make, cmake)"
echo "  - Claude Code"
echo "  - GitHub CLI"
echo "  - ripgrep, tree, jq, htop"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: exec zsh)"
echo "  2. Run: gh auth login"
echo "  3. Run: tailscale up (if tailscale is installed on Windows)"
echo "  4. Open VS Code, install extensions from dotfiles/vscode/extensions.txt"
echo ""
