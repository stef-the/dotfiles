#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# macOS Dotfiles Installer
# Links dotfiles and applies config on this Mac
# ═══════════════════════════════════════════════════════════════

set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "═══ macOS Dotfiles Installer ═══"
echo ""

# ─── Backup existing configs ─────────────────────────────────
echo "Backing up existing configs..."
for f in ~/.zshrc ~/.gitconfig ~/.gitignore_global ~/.spaceshiprc.zsh; do
    if [[ -f "$f" && ! -L "$f" ]]; then
        mv "$f" "${f}.bak.$(date +%s)"
        echo "  Backed up $f"
    fi
done

# ─── Symlink dotfiles ────────────────────────────────────────
echo "Linking dotfiles..."

ln -sf "$DOTFILES_DIR/zsh/.zshrc" ~/.zshrc
ln -sf "$DOTFILES_DIR/git/.gitconfig" ~/.gitconfig
ln -sf "$DOTFILES_DIR/git/.gitignore_global" ~/.gitignore_global

mkdir -p ~/.config
ln -sf "$DOTFILES_DIR/starship/starship.toml" ~/.config/starship.toml

# Claude config
mkdir -p ~/.claude
ln -sf "$DOTFILES_DIR/claude/settings.json" ~/.claude/settings.json

echo ""
echo "═══ DONE ═══"
echo ""
echo "Linked:"
echo "  ~/.zshrc -> dotfiles/zsh/.zshrc"
echo "  ~/.gitconfig -> dotfiles/git/.gitconfig"
echo "  ~/.gitignore_global -> dotfiles/git/.gitignore_global"
echo "  ~/.config/starship.toml -> dotfiles/starship/starship.toml"
echo "  ~/.claude/settings.json -> dotfiles/claude/settings.json"
echo ""
echo "Run: exec zsh   to reload your shell"
echo ""
