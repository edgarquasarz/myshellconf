#!/bin/bash
set -e

echo "Installing Homebrew packages..."

brew install \
    git \
    neovim \
    zellij \
    lazygit \
    eza \
    fzf \
    ripgrep \
    fd \
    fnm \
    rust \
    coreutils \
    gnu-sed \
    gh \
    node@22 \
    htop \
    cmake \
    go \
    yarn \
    ruby \
    font-hack-nerd-font

echo "Done!"