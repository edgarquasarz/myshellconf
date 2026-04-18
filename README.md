# myshellconf

Dotfiles to set up a development environment on a new machine.

## Requirements

- macOS or Linux
- [Homebrew](https://brew.sh) (macOS only)

## Installation

```bash
# 1. Clone the repo
git clone git@github.com:edgarquasarz/myshellconf.git ~/myshellconf
cd ~/myshellconf

# 2. Run the installer (installs packages + links dotfiles)
./install.sh

# 3. Restart terminal or run: source ~/.zshrc
```

## What gets installed

### Core Tools (via Homebrew)
| Tool | Purpose |
|------|---------|
| neovim | Text editor (LazyVim config) |
| git | Version control |
| gh | GitHub CLI |
| fzf | Fuzzy finder |
| fd | Find replacement |
| eza | Modern ls |
| ripgrep | Grep replacement |
| lazygit | Git TUI |
| zellij | Terminal multiplexer |
| alacritty | Terminal emulator |
| fnm | Node.js version manager |
| node@22 | JavaScript runtime |
| go | Go compiler |
| rust | Rust compiler |

### Shell
- **Oh My Zsh** with git + fzf plugins
- **zsh-completions** for better tab completion

### Dotfiles linked
- `~/.zshrc` - shell config with aliases
- `~/.gitconfig` - git aliases and colors
- `~/.config/alacritty` - terminal config
- `~/.config/zellij` - multiplexer config
- `~/.config/nvim` - neovim config

## Aliases

### Git
```
st  status     ci  commit     br  branch     co  checkout
df  diff       dc  diff --cached    lg  log -p
lol log --graph
```

### Tools
```
ll  eza -l     lt  eza --tree     cat bat
rg  ripgrep    lg  lazygit       top htop
```

### Docker
```
d   docker         dc  docker compose
dps docker ps      di  docker images
dex docker exec -it
```

## Configure Git

```bash
git config --global user.name "Your Name"
git config --global user.email your@email.com
```