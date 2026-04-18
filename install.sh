#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"
OS="$(uname -s)"

echo "🔧 Setting up development environment..."

# Detect package manager
if [ "$OS" = "Darwin" ]; then
    PKG_MGR="brew"
elif command -v apt-get &> /dev/null; then
    PKG_MGR="apt"
elif command -v yum &> /dev/null; then
    PKG_MGR="yum"
fi

# Install Homebrew on macOS if not present
if [ "$OS" = "Darwin" ] && ! command -v brew &> /dev/null; then
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install core tools (macOS)
if [ "$OS" = "Darwin" ]; then
    echo "📦 Installing core tools..."
    [ ! -d "$HOME/.local/bin" ] && mkdir -p "$HOME/.local/bin"

    CORE_TOOLS=(
        neovim
        git
        gh
        fzf
        fd
        eza
        ripgrep
        lazygit
        node@22
        go
        rust
        zellij
        alacritty
        fnm
    )

    for tool in "${CORE_TOOLS[@]}"; do
        if brew list "$tool" &> /dev/null; then
            echo "  ✓ $tool already installed"
        else
            echo "  ↳ installing $tool..."
            brew install "$tool" 2>/dev/null || echo "  ⚠ $tool failed to install"
        fi
    done
fi

# Link dotfiles
echo "🔗 Linking dotfiles..."
ln -sf "$DOTFILES_DIR/zshrc" "$HOME_DIR/.zshrc"
ln -sf "$DOTFILES_DIR/gitconfig" "$HOME_DIR/.gitconfig"
mkdir -p "$HOME_DIR/.config"
ln -sf "$DOTFILES_DIR/config/alacritty" "$HOME_DIR/.config/alacritty"
ln -sf "$DOTFILES_DIR/config/zellij" "$HOME_DIR/.config/zellij"

if [ ! -d "$HOME_DIR/.config/nvim" ] || [ ! -L "$HOME_DIR/.config/nvim" ]; then
    rm -rf "$HOME_DIR/.config/nvim"
    ln -sf "$DOTFILES_DIR/config/nvim" "$HOME_DIR/.config/nvim"
fi

# Setup Oh My Zsh if not present
if [ ! -d "$HOME_DIR/.oh-my-zsh" ]; then
    echo "📝 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --skip-chsh --skip-ag
fi

# Install useful Oh My Zsh plugins
echo "🧩 Setting up Oh My Zsh plugins..."
ZSH_PLUGINS_DIR="$HOME_DIR/.oh-my-zsh/custom/plugins"
USEFUL_PLUGINS=(
    "zsh-users/zsh-completions"
)

for plugin in "${USEFUL_PLUGINS[@]}"; do
    plugin_name=$(basename "$plugin")
    plugin_dir="$ZSH_PLUGINS_DIR/$plugin_name"
    if [ ! -d "$plugin_dir" ]; then
        echo "  ↳ cloning $plugin..."
        git clone "https://github.com/$plugin.git" "$plugin_dir" 2>/dev/null || echo "  ⚠ failed to clone $plugin"
    else
        echo "  ✓ $plugin_name already installed"
    fi
done

# Update Oh My Zsh theme to match terminal
if [ -f "$HOME_DIR/.zshrc" ]; then
    sed -i '' 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="robbyrussell"/' "$HOME_DIR/.zshrc" 2>/dev/null || true
fi

# Run Neovim LazySync if nvim is available
if command -v nvim &> /dev/null; then
    echo "⚡ Running LazySync..."
    nvim --headless +LazySync +qall 2>/dev/null || true
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "💡 Restart your terminal or run: source ~/.zshrc"