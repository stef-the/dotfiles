# ─── Environment ──────────────────────────────────────────────
export EDITOR="code --wait"
export LANG="en_US.UTF-8"

# ─── Homebrew (macOS only) ────────────────────────────────────
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ─── Cargo / Rust ─────────────────────────────────────────────
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# ─── NVM (Node Version Manager) ──────────────────────────────
export NVM_DIR="$HOME/.nvm"
if [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
  # macOS (Homebrew)
  source "/opt/homebrew/opt/nvm/nvm.sh"
  source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
elif [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # Linux / WSL
  source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
fi

# ─── Java ─────────────────────────────────────────────────────
if [[ -d "/opt/homebrew/opt/openjdk@17/bin" ]]; then
  export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
fi

# ─── Zsh Plugins ──────────────────────────────────────────────
# Homebrew-installed plugins (macOS)
if [[ -d /opt/homebrew/share ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
  fpath=(/opt/homebrew/share/zsh-completions $fpath)
fi

# apt-installed plugins (Linux / WSL)
if [[ -d /usr/share/zsh-autosuggestions ]]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
if [[ -d /usr/share/zsh-syntax-highlighting ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# ─── Completion ───────────────────────────────────────────────
autoload -Uz compinit
if [[ "$(uname)" == "Darwin" ]]; then
  # Rebuild once per day on macOS
  if [[ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]]; then
    compinit
  else
    compinit -C
  fi
else
  compinit -C
fi

# ─── History ──────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# ─── Key Bindings ─────────────────────────────────────────────
bindkey -e  # emacs mode (ctrl-a, ctrl-e, etc.)

# ─── Aliases ──────────────────────────────────────────────────
# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ~="cd ~"
alias ll="ls -lAh"
alias la="ls -A"

# Git
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph -20"
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"
alias gpull="git pull"

# Node / npm
alias ni="npm install"
alias nd="npm run dev"
alias nb="npm run build"
alias nr="npm run"

# Quick edits
alias zshrc="code ~/.zshrc"
alias reload="source ~/.zshrc"

# System
alias ports="lsof -i -P -n | grep LISTEN"
alias ip="curl -s ifconfig.me"

# Docker
alias dc="docker compose"
alias dps="docker ps"

# ─── iTerm2 Integration (macOS only) ─────────────────────────
[[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"

# ─── Startup ─────────────────────────────────────────────────
if command -v pfetch &>/dev/null; then
  pfetch
fi

# ─── Starship Prompt (must be last) ──────────────────────────
eval "$(starship init zsh)"
