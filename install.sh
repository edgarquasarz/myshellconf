#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"
OS="$(uname -s)"

echo "🔧 Setting up development environment..."

# Detect package manager
if [ "$OS" = "Darwin" ]; then
  PKG_MGR="brew"
elif command -v apt-get &>/dev/null; then
  PKG_MGR="apt"
elif command -v yum &>/dev/null; then
  PKG_MGR="yum"
fi

# Linux without apt-get is not supported — bail out with a clear message
# rather than silently falling through to a no-op.
if [ "$OS" != "Darwin" ] && [ "$PKG_MGR" != "apt" ]; then
  echo "❌ Linux distribution not supported: no apt-get found."
  echo "   This installer currently supports Debian/Ubuntu/Zorin/Mint (apt)."
  echo "   Detected OS: $OS"
  exit 1
fi

# Install Homebrew on macOS if not present
if [ "$OS" = "Darwin" ] && ! command -v brew &>/dev/null; then
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
  if ! command -v jq &>/dev/null; then
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

  # Install @rivolink/leaf globally
  echo "  ↳ installing @rivolink/leaf..."
  npm install -g @rivolink/leaf 2>/dev/null || echo "  ⚠ @rivolink/leaf failed to install"

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
    if brew list "$tool" &>/dev/null; then
      echo "  ✓ $tool already installed"
    else
      echo "  ↳ installing $tool..."
      brew install "$tool" 2>/dev/null || echo "  ⚠ $tool failed to install"
    fi
  done
fi

# Install core tools (Linux / Debian/Ubuntu/Zorin/Mint via apt)
if [ "$PKG_MGR" = "apt" ]; then
  echo "📦 Installing core tools (Linux / apt)..."

  # Single sudo timestamp refresh for the whole Linux block.
  # sudo -v can fail in non-tty/non-sudo contexts; bail out clearly if so.
  if ! sudo -v; then
    echo "❌ sudo authentication failed or unavailable — cannot install apt packages."
    echo "   Re-run this script from an interactive shell with passwordless or TTY sudo."
    exit 1
  fi

  # Ensure ~/.local/bin exists and precedes /usr/bin in PATH for this session.
  # Distros vary; we pin it explicitly so nvim AppImage and user-local installs
  # always shadow system packages (e.g. older neovim from apt).
  [ ! -d "$HOME/.local/bin" ] && mkdir -p "$HOME/.local/bin"
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH" ;;
  esac
  export PATH

  # Helper: install via apt only if the binary isn't already on PATH.
  # Each call is wrapped so a single failed apt install never aborts the script
  # under `set -e` (the trailing `|| echo` traps the non-zero exit).
  apt_install() {
    local pkg="$1"
    local bin="${2:-$1}"
    if command -v "$bin" &>/dev/null; then
      echo "  ✓ $bin already installed"
    else
      echo "  � installing $pkg via apt..."
      sudo apt-get install -y "$pkg" &>/dev/null || echo "  ⚠ $pkg failed to install"
    fi
  }

  # Install zoxide (binary into ~/.local/bin; no apt package)
  if [ -x "$HOME/.local/bin/zoxide" ]; then
    echo "  ✓ zoxide already installed"
  else
    echo "  ↳ installing zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh 2>/dev/null || echo "  ⚠ zoxide failed to install"
  fi

  # Install jq (required for zellij-send-keys)
  apt_install jq

  # Install zellij plugins (same releases as macOS branch)
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

  # Install @rivolink/leaf globally (requires node/npm on PATH; we install node via fnm later).
  # Skip silently here if npm isn't on PATH yet — re-run after fnm/node is in place.
  if command -v npm &>/dev/null; then
    if npm list -g --depth=0 2>/dev/null | grep -q '@rivolink/leaf'; then
      echo "  ✓ @rivolink/leaf already installed"
    else
      echo "  ↳ installing @rivolink/leaf..."
      npm install -g @rivolink/leaf 2>/dev/null || echo "  ⚠ @rivolink/leaf failed to install"
    fi
  else
    echo "  ⚠ skipping @rivolink/leaf (npm not on PATH yet — run again after fnm/node install)"
  fi

  # Tools available as apt packages — install via apt_install helper.
  apt_install neovim
  apt_install git
  apt_install gh
  apt_install fzf
  # fd-find ships as `fdfind` on Debian/Ubuntu (name collision with another tool).
  # Verify against the actual binary name, then expose `fd` via ~/.local/bin symlink
  # so the user's PATH resolves the familiar command.
  apt_install fd-find fdfind
  if command -v fdfind &>/dev/null && [ ! -e "$HOME/.local/bin/fd" ]; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    echo "  ↳ symlinked ~/.local/bin/fd -> $(command -v fdfind)"
  fi
  apt_install ripgrep
  # bat may install as `batcat` on Debian 12+ (name conflict). Try `bat` first;
  # if absent, fall back to `batcat` and symlink the canonical `bat` name into
  # ~/.local/bin so user config and aliases resolve it deterministically.
  if command -v bat &>/dev/null; then
    echo "  ✓ bat already installed"
  elif command -v batcat &>/dev/null; then
    echo "  ✓ batcat already installed (creating 'bat' symlink if missing)"
    [ ! -e "$HOME/.local/bin/bat" ] && ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  else
    echo "  ↳ installing bat via apt..."
    sudo apt-get install -y bat &>/dev/null || echo "  � bat failed to install"
    # Post-install: if apt shipped `batcat`, surface it as `bat` for consistency.
    if command -v batcat &>/dev/null && [ ! -e "$HOME/.local/bin/bat" ]; then
      ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    fi
  fi
  apt_install htop
  apt_install zellij

  # eza: not in Debian/Ubuntu stock apt — install via community package (no checksum, accepted risk).
  if command -v eza &>/dev/null; then
    echo "  ✓ eza already installed"
  else
    echo "  ↳ installing eza..."
    sudo apt-get install -y eza &>/dev/null \
      || (sudo apt-get install -y wget gpg &>/dev/null \
          && wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb-package-maketar.sh | bash &>/dev/null \
          && sudo apt-get install -y ./eza_*.deb &>/dev/null) \
      || echo "  ⚠ eza failed to install"
  fi

  # lazygit: not in stock apt on most distros — install via official GitHub release (accepted risk).
  if command -v lazygit &>/dev/null; then
    echo "  ✓ lazygit already installed"
  else
    echo "  ↳ installing lazygit..."
    LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest 2>/dev/null | grep -Po '"tag_name": "v\K[^"]*' || echo "0.40.2")
    sudo apt-get install -y lazygit &>/dev/null \
      || (curl -sLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
          && tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit \
          && sudo install -m 755 /tmp/lazygit /usr/local/bin/lazygit \
          && rm -f /tmp/lazygit /tmp/lazygit.tar.gz) \
      || echo "  ⚠ lazygit failed to install"
  fi

  # alacritty: not in stock apt on older Debian/Ubuntu — install via apt with fallback to cargo.
  if command -v alacritty &>/dev/null; then
    echo "  ✓ alacritty already installed"
  else
    echo "  ↳ installing alacritty..."
    sudo apt-get install -y alacritty &>/dev/null \
      || (sudo apt-get install -y cargo rustc cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev python3 &>/dev/null \
          && cargo install alacritty &>/dev/null) \
      || echo "  ⚠ alacritty failed to install"
  fi

  # yazi: not in stock apt — install via official installer script (accepted risk).
  if command -v yazi &>/dev/null; then
    echo "  ✓ yazi already installed"
  else
    echo "  ↳ installing yazi..."
    curl -sS https://raw.githubusercontent.com/sxyazi/yazi/main/install.sh | sh 2>/dev/null \
      || (sudo apt-get install -y yazi &>/dev/null) \
      || echo "  ⚠ yazi failed to install"
  fi

  # starship: official curl|sh installer (accepted risk, parity with macOS branch).
  if command -v starship &>/dev/null; then
    echo "  ✓ starship already installed"
  else
    echo "  ↳ installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y &>/dev/null || echo "  ⚠ starship failed to install"
  fi

  # delta (git-delta): not in stock apt — install via official GitHub release .deb.
  if command -v delta &>/dev/null; then
    echo "  ✓ delta already installed"
  else
    echo "  ↳ installing git-delta..."
    DELTA_VERSION=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest 2>/dev/null | grep -Po '"tag_name": "\K[^"]*' || echo "0.16.5")
    DELTA_DEB="git-delta_${DELTA_VERSION}_amd64.deb"
    (curl -sLo "/tmp/$DELTA_DEB" "https://github.com/dandavison/delta/releases/latest/download/$DELTA_DEB" \
       && sudo apt-get install -y "/tmp/$DELTA_DEB" &>/dev/null \
       && rm -f "/tmp/$DELTA_DEB") \
      || echo "  ⚠ delta failed to install"
  fi

  # fnm (Fast Node Manager): install via official curl|sh script to ~/.local/share/fnm + ~/.local/bin/fnm.
  if command -v fnm &>/dev/null; then
    echo "  ✓ fnm already installed"
  else
    echo "  ↳ installing fnm..."
    curl -sSf https://raw.githubusercontent.com/Schniz/fnm/master/.ci/install.sh | sh -s -- --skip-shell 2>/dev/null || echo "  ⚠ fnm failed to install"
  fi

  # node@22 via fnm — needs fnm on PATH first.
  if command -v fnm &>/dev/null; then
    if fnm list 2>/dev/null | grep -q 'v22\.'; then
      echo "  ✓ node@22 already installed (via fnm)"
    else
      echo "  ↳ installing node@22 via fnm..."
      fnm install 22 &>/dev/null || echo "  � node@22 failed to install"
      fnm default 22 &>/dev/null || true
    fi
    # Make node/npm available to subsequent commands in this script.
    eval "$(fnm env 2>/dev/null)" 2>/dev/null || true
    export PATH
  else
    echo "  ⚠ skipping node@22 (fnm not installed)"
  fi

  # go: prefer apt's golang-go (fast); fallback to official tarball into /usr/local/go (no checksum).
  if command -v go &>/dev/null; then
    echo "  ✓ go already installed"
  else
    echo "  ↳ installing go..."
    sudo apt-get install -y golang-go &>/dev/null \
      || (GO_VERSION=$(curl -s https://go.dev/VERSION?m=text 2>/dev/null | head -1 || echo "go1.22.5") \
          && curl -sLo /tmp/go.tar.gz "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz" \
          && sudo rm -rf /usr/local/go \
          && sudo tar -C /usr/local -xzf /tmp/go.tar.gz \
          && rm -f /tmp/go.tar.gz \
          && echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' | sudo tee /etc/profile.d/go.sh >/dev/null 2>&1) \
      || echo "  ⚠ go failed to install"
  fi

  # rust: official rustup-init (accepted risk; no checksum).
  if command -v rustup &>/dev/null || command -v cargo &>/dev/null; then
    echo "  ✓ rust already installed"
  else
    echo "  ↳ installing rust..."
    curl -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal &>/dev/null || echo "  ⚠ rust failed to install"
    # Source cargo env if rustup succeeded so subsequent cargo-based steps (e.g. alacritty) can find it.
    [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
    export PATH
  fi

  # Neovim AppImage fallback — apt's neovim is often < 0.10 on older distros.
  # Per spec: download AppImage to ~/.local/bin/nvim (which we put ahead of /usr/bin above)
  # instead of uninstalling the apt package, so existing apt deps stay intact.
  if command -v nvim &>/dev/null; then
    NVIM_VERSION_RAW=$(nvim --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    NVIM_MAJOR=$(echo "$NVIM_VERSION_RAW" | cut -d. -f1)
    NVIM_MINOR=$(echo "$NVIM_VERSION_RAW" | cut -d. -f2)
    if [ "${NVIM_MAJOR:-0}" -ge 1 ] || { [ "${NVIM_MAJOR:-0}" -eq 0 ] && [ "${NVIM_MINOR:-0}" -ge 10 ]; }; then
      echo "  ✓ neovim $NVIM_VERSION_RAW ≥ 0.10"
    else
      echo "  ↳ neovim apt version $NVIM_VERSION_RAW < 0.10 — installing AppImage..."
      # AppImage requires FUSE (fusermount) at runtime. Containers, WSL, and
      # some locked-down distros lack it. Detect FUSE; if absent, extract the
      # AppImage and symlink the AppRun binary so nvim remains executable.
      (curl -sLo /tmp/nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim.appimage \
         && chmod +x /tmp/nvim.appimage \
         && if command -v fusermount &>/dev/null; then
              mv /tmp/nvim.appimage "$HOME/.local/bin/nvim"
              echo "  ↳ using AppImage runtime (FUSE available)"
            else
              echo "  ⚠ fusermount not found — extracting AppImage (FUSE-less mode)..."
              mkdir -p /tmp/nvim-extracted
              (cd /tmp/nvim-extracted && /tmp/nvim.appimage --appimage-extract &>/dev/null) \
                && rm -f "$HOME/.local/bin/nvim" \
                && ln -sf /tmp/nvim-extracted/squashfs-root/AppRun "$HOME/.local/bin/nvim" \
                && rm -f /tmp/nvim.appimage \
                && echo "  ↳ extracted AppImage to /tmp/nvim-extracted, symlinked AppRun"
            fi) \
        || echo "  ⚠ neovim AppImage failed to install"
      if [ -x "$HOME/.local/bin/nvim" ] || [ -L "$HOME/.local/bin/nvim" ]; then
        echo "  ✓ neovim AppImage installed to ~/.local/bin/nvim"
      fi
    fi
  else
    echo "  ⚠ neovim not on PATH — AppImage fallback skipped (install via apt first)"
  fi
fi

# Link dotfiles
echo "🔗 Linking dotfiles..."
ln -sf "$DOTFILES_DIR/zshrc" "$HOME_DIR/.zshrc"
ln -sf "$DOTFILES_DIR/gitconfig" "$HOME_DIR/.gitconfig"
mkdir -p "$HOME_DIR/.config"
rm -rf "$HOME_DIR/.config/nvim" "$HOME_DIR/.config/alacritty" "$HOME_DIR/.config/zellij" "$HOME_DIR/.config/starship.toml"
ln -sf "$DOTFILES_DIR/config/nvim" "$HOME_DIR/.config/nvim"
ln -sf "$DOTFILES_DIR/config/alacritty" "$HOME_DIR/.config/alacritty"
ln -sf "$DOTFILES_DIR/config/zellij" "$HOME_DIR/.config/zellij"
ln -sf "$DOTFILES_DIR/config/starship.toml" "$HOME_DIR/.config/starship.toml"

# Linux: swap Apple logo glyph for Tux. cp breaks the symlink so the
# repo's canonical starship.toml (macOS-targeted) is not mutated.
if [ "$OS" != "Darwin" ]; then
  cp "$DOTFILES_DIR/config/starship.toml" "$HOME_DIR/.config/starship.toml"
  sed -i 's/\xee\x9c\x91/\xef\x85\xbc/g' "$HOME_DIR/.config/starship.toml"
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

# Run Neovim LazySync if nvim is available
if command -v nvim &>/dev/null; then
  echo "⚡ Running LazySync..."
  nvim --headless +LazySync +qall 2>/dev/null || true
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "💡 Restart your terminal or run: source ~/.zshrc"
