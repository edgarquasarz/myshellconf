# Add brew to PATH
eval "$(/usr/local/bin/brew shellenv zsh 2>/dev/null || true)"

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
plugins=(git fzf)

source $ZSH/oh-my-zsh.sh

# User configuration
export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8

# Set personal aliases
alias zz="source ~/.zshrc"
alias zrc="nvim ~/.zshrc"
alias zrc00="nvim ~/.zshrc00"
alias ghconfig="nvim ~/.gitconfig"

# Dev shortcuts
alias dev="cd ~/dev"
alias dt="cd ~/dev/tasks"

# Git shortcuts (complement OMZ git plugin)
alias gs="git status -s"
alias ga="git add"
alias gaa="git add ."
alias gc="git commit -v"
alias gca="git commit --amend"
alias gcp="git cherry-pick"
alias gb="git branch"
alias gco="git checkout"
alias gcom="git checkout main"
alias gcod="git checkout develop"
alias gd="git diff"
alias gds="git diff --staged"
alias gll="git log --oneline"
alias gld="git log --graph --oneline --decorate"
alias gps="git push"
alias gpl="git pull"
alias gplr="git pull --rebase"
alias gr="git reset"
alias grh="git reset --hard"
alias gsh="git show"
alias gt="git stash"
alias gtp="git stash pop"
alias gtl="git stash list"

# Tools
alias cat="bat"
alias ll="eza -l --icons"
alias lt="eza -l --tree --icons"
alias ls="eza"
alias find="fd"
alias top="htop"
alias lg="lazygit"
alias rg="ripgrep"

# Development
alias ni="npm install"
alias nid="npm install --save-dev"
alias ns="npm start"
alias nb="npm run build"
alias nt="npm test"
alias nd="npm run dev"
alias nr="npm run"

alias pi="pnpm install"
alias pd="pnpm add"
alias pdd="pnpm add --save-dev"

# Docker
alias d="docker"
alias dc="docker compose"
alias dps="docker ps"
alias di="docker images"
alias dex="docker exec -it"
alias dlog="docker logs -f"
alias dprune="docker system prune -af"

# Path setup
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/opt/node@22/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/user/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Helpers
alias ~="cd ~"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias cl="clear"
alias path="echo \$PATH | tr ':' '\n'"

# fnm - Fast Node Manager
export FNM_BASEDIR="$HOME/.local/share/fnm"
eval "$(fnm env --use-on-cd 2>/dev/null || true)"

# zoxide - smarter cd
export PATH="$HOME/.local/bin:$PATH"
eval "$(zoxide init zsh)"

# Load personal extra config if present
if [ -f "$HOME/.zshrc00" ]; then
  source "$HOME/.zshrc00"
fi
