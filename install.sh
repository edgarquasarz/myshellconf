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

    # Install zoxide
    if [ ! -f "$HOME/.local/bin/zoxide" ]; then
        echo "  ↳ installing zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh 2>/dev/null || echo "  ⚠ zoxide failed to install"
    else
        echo "  ✓ zoxide already installed"
    fi

    # Install jq (required for zellij-send-keys)
    if ! command -v jq &> /dev/null; then
        echo "  ↳ installing jq..."
        brew install jq 2>/dev/null || echo "  ⚠ jq failed to install"
    else
        echo "  ✓ jq already installed"
    fi

    # Install zellij plugins
    mkdir -p "$HOME/.config/zellij/plugins"
    if [ ! -f "$HOME/.config/zellij/plugins/zellij-favs.wasm" ]; then
        echo "  ↳ installing zellij-favs..."
        curl -L https://github.com/JoseMM2002/zellij-favs/releases/download/v1.0.1/zellij-favs.wasm \
            -o "$HOME/.config/zellij/plugins/zellij-favs.wasm" 2>/dev/null || echo "  ⚠ zellij-favs failed"
    else
        echo "  ✓ zellij-favs already installed"
    fi
    if [ ! -f "$HOME/.config/zellij/plugins/zellij-send-keys.wasm" ]; then
        echo "  ↳ installing zellij-send-keys..."
        curl -L https://github.com/atani/zellij-send-keys/releases/latest/download/zellij-send-keys.wasm \
            -o "$HOME/.config/zellij/plugins/zellij-send-keys.wasm" 2>/dev/null || echo "  ⚠ zellij-send-keys failed"
    else
        echo "  ✓ zellij-send-keys already installed"
    fi

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
        bat
        htop
        yazi
        starship
        delta
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
rm -rf "$HOME_DIR/.config/nvim" "$HOME_DIR/.config/alacritty" "$HOME_DIR/.config/zellij"
ln -sf "$DOTFILES_DIR/config/nvim" "$HOME_DIR/.config/nvim"
ln -sf "$DOTFILES_DIR/config/alacritty" "$HOME_DIR/.config/alacritty"
ln -sf "$DOTFILES_DIR/config/zellij" "$HOME_DIR/.config/zellij"

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