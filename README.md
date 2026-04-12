# myshellconf

Dotfiles to set up a development environment on a new machine.

## Requirements

- macOS or Linux
- [Homebrew](https://brew.sh)

## Installation

```bash
# 1. Clone the repo
git clone git@github.com:edgarquasarz/myshellconf.git ~/myshellconf
cd ~/myshellconf

# 2. Install brew packages
./brew.sh

# 3. Configure dotfiles
./install.sh

# 4. Restart terminal
```

## Included packages

- **zellij**: terminal multiplexer (replaced tmux)
- **neovim**: text editor (LazyVim config)
- **lazygit**: git UI
- **eza**: modern ls replacement
- **fzf**: fuzzy finder
- **ripgrep**: modern grep
- **fd**: find replacement
- **fnm**: Node.js version manager

## Terminal

Uses **Alacritty** with **Hack Nerd Font** (installed via brew).

## Git configuration

The gitconfig includes useful aliases:
- `st` → status
- `ci` → commit
- `br` → branch
- `co` → checkout
- `df` → diff
- `lg` → log with changes
- `lol` → graph log

Configure git before using:
```bash
git config --global user.name "Your Name"
git config --global user.email your@email.com
```