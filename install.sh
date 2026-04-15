#!/bin/bash
set -e

echo "Setting up dotfiles..."

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"

ln -sf "$DOTFILES_DIR/zshrc" "$HOME_DIR/.zshrc"
ln -sf "$DOTFILES_DIR/gitconfig" "$HOME_DIR/.gitconfig"
ln -sf "$DOTFILES_DIR/.config/alacritty" "$HOME_DIR/.config/alacritty"
ln -sf "$DOTFILES_DIR/.config/zellij" "$HOME_DIR/.config/zellij"

if [ ! -d "$HOME_DIR/.config/nvim" ] || [ ! -L "$HOME_DIR/.config/nvim" ]; then
    rm -rf "$HOME_DIR/.config/nvim"
    ln -sf "$DOTFILES_DIR/.config/nvim" "$HOME_DIR/.config/nvim"
fi

if command -v nvim &> /dev/null; then
    echo "Running LazySync..."
    nvim --headless +LazySync +qall 2>/dev/null || true
fi

echo "Done!"