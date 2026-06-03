# dotfiles

Cross-platform dotfiles for macOS and WSL (Windows 11 LTSC).

## Structure

```
dotfiles/
├── zsh/.zshrc              # Zsh config (Starship prompt, plugins, aliases)
├── starship/starship.toml  # Starship prompt config (Nord theme)
├── git/.gitconfig           # Git config
├── git/.gitignore_global    # Global gitignore
├── claude/settings.json     # Claude Code settings
├── vscode/settings.json     # VS Code settings (Nord theme)
├── vscode/extensions.txt    # VS Code extensions list
├── windows/
│   ├── powershell/Microsoft.PowerShell_profile.ps1  # PowerShell profile (zsh-style: oh-my-posh, eza, bat, zoxide, fzf)
│   ├── oh-my-posh/blue-owl.omp.json    # Oh My Posh prompt theme
│   ├── windows-terminal/settings.json  # Windows Terminal config
│   ├── fastfetch/config.jsonc          # Fastfetch system-info banner
│   ├── fastfetch/pkgs.ps1              # Fastfetch package-count module
│   ├── windows-setup.md     # Clean install guide for Win11 LTSC
│   └── post-install.ps1     # Automated post-install script
├── scripts/
│   ├── install-macos.sh     # Apply dotfiles on macOS
│   ├── install-wsl.sh       # Full WSL/Linux setup
│   └── backup-discovery.sh  # Pre-wipe backup scanner for Windows
└── docs/
    └── package-manager-gui.md  # Planning doc for package manager app
```

## Quick Start

### macOS
```bash
git clone https://github.com/stef-the/dotfiles.git ~/dotfiles
bash ~/dotfiles/scripts/install-macos.sh
exec zsh
```

### WSL (after Windows setup)
```bash
git clone https://github.com/stef-the/dotfiles.git ~/dotfiles
bash ~/dotfiles/scripts/install-wsl.sh
exec zsh
```

### Windows Post-Install
```powershell
# Run as Administrator
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\dotfiles\windows\post-install.ps1
```
