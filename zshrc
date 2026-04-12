# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="robbyrussell"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# HYPHEN_INSENSITIVE="true"

# Change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Enable command auto-correction.
# ENABLE_CORRECTION="true"

# Display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Disable marking untracked files under VCS as dirty.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which plugins would you like to load?
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration
# export MANPATH="/usr/local/man:$MANPATH"
# export LANG=en_US.UTF-8
# export EDITOR='nvim'
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases
# alias zshconfig="~/.config/zshrc"

# Add brew to PATH
eval "$(/usr/local/bin/brew shellenv zsh)"

#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH=/Users/user/.local/bin:$PATH

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="/usr/local/opt/node@22/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/user/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export PATH="/usr/local/bin:$PATH"

if [ -f "$HOME/.zshrc00" ]; then
  source "$HOME/.zshrc00"
fi
