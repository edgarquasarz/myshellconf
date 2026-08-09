# myshellconf

Dotfiles to set up a development environment on a new machine.

## Requirements

- macOS, or Debian/Ubuntu/Zorin/Mint Linux
- [Homebrew](https://brew.sh) (macOS only)

## Installation

```bash
# 1. Clone the repo
git clone git@github.com:txomin-jimenez/myshellconf.git ~/myshellconf
cd ~/myshellconf

# 2. Run the installer (auto-detects macOS vs Linux/apt and installs accordingly)
./install.sh

# 3. Restart terminal or run: source ~/.zshrc
```

On Linux the installer uses `sudo apt-get` for the 17 core tools and falls
back to `curl | sh` installers (fnm, rust, starship, zoxide, eza) where
no apt package is available. A single `sudo -v` at the start of the
Linux block refreshes the sudo timestamp for the whole run.

## What gets installed

### Core Tools (via Homebrew on macOS, apt on Linux)
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
| bat | Cat replacement |
| htop | Process viewer |
| yazi | Terminal file manager |
| starship | Cross-shell prompt |
| delta | Syntax-highlighted git diff |

Plus: zoxide, jq, zellij plugins (`zellij-favs`, `zellij-send-keys`), and
`@rivolink/leaf` (markdown editor, requires node/npm).

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
