#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"
OS="$(uname -s)"

echo "🔧 Setting up development environment..."

# Detect package manager. Only macOS (brew) and Debian/Ubuntu-family (apt)
# are supported — yum/dnf/rpm distros are not, so the yum branch is intentionally
# omitted; the bail-out below turns unsupported Linux into a clear error.
PKG_MGR=""
if [ "$OS" = "Darwin" ]; then
  PKG_MGR="brew"
elif command -v apt-get &>/dev/null; then
  PKG_MGR="apt"
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
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || echo "  ⚠ zoxide failed to install"
  else
    echo "  ✓ zoxide already installed"
  fi

  # Install jq (required for zellij-send-keys)
  if ! command -v jq &>/dev/null; then
    echo "  ↳ installing jq..."
    brew install jq || echo "  ⚠ jq failed to install"
  else
    echo "  ✓ jq already installed"
  fi

  # Install zellij plugins
  mkdir -p "$HOME/.config/zellij/plugins"
  if [ ! -f "$HOME/.config/zellij/plugins/zellij-favs.wasm" ]; then
    echo "  ↳ installing zellij-favs..."
    curl -L https://github.com/JoseMM2002/zellij-favs/releases/download/v1.0.1/zellij-favs.wasm \
      -o "$HOME/.config/zellij/plugins/zellij-favs.wasm" || echo "  ⚠ zellij-favs failed"
  else
    echo "  ✓ zellij-favs already installed"
  fi
  if [ ! -f "$HOME/.config/zellij/plugins/zellij-send-keys.wasm" ]; then
    echo "  ↳ installing zellij-send-keys..."
    curl -L https://github.com/atani/zellij-send-keys/releases/latest/download/zellij-send-keys.wasm \
      -o "$HOME/.config/zellij/plugins/zellij-send-keys.wasm" || echo "  ⚠ zellij-send-keys failed"
  else
    echo "  ✓ zellij-send-keys already installed"
  fi

  # Install @rivolink/leaf globally
  echo "  ↳ installing @rivolink/leaf..."
  npm install -g @rivolink/leaf || echo "  ⚠ @rivolink/leaf failed to install"

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
      brew install "$tool" || echo "  ⚠ $tool failed to install"
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

  # Ensure ~/.local/bin exists for user-local installs (nvim AppImage, fnm
  # shims, eza/lazygit fallbacks). Prepend it to PATH for this script's
  # session — order is best-effort, it just needs to be ahead of the system
  # PATHs we expect (apt's /usr/bin, snap, etc.). To survive across login
  # shells, we also append the export to ~/.zshrc (idempotent, see below).
  [ ! -d "$HOME/.local/bin" ] && mkdir -p "$HOME/.local/bin"
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH" ;;
  esac
  export PATH

  # Persist ~/.local/bin in ~/.zshrc so newly-installed tools (nvim AppImage,
  # fnm shims, etc.) shadow older apt binaries in every new shell. Idempotent:
  # only append when the exact export line is not already present.
  ZSHRC="$HOME/.zshrc"
  PATH_EXPORT_LINE='export PATH="$HOME/.local/bin:$PATH"'
  if [ -f "$ZSHRC" ] && grep -qxF "$PATH_EXPORT_LINE" "$ZSHRC" 2>/dev/null; then
    echo "  ✓ ~/.local/bin PATH already in $ZSHRC"
  else
    printf '\n# Added by myshellconf install.sh — keep ~/.local/bin ahead of system PATH\n%s\n' \
      "$PATH_EXPORT_LINE" >> "$ZSHRC"
    echo "  ↳ appended ~/.local/bin to PATH in $ZSHRC"
  fi

  # Helper: install via apt only if the binary isn't already on PATH.
  # Each call is wrapped so a single failed apt install never aborts the script
  # under `set -e` (the trailing `|| echo` traps the non-zero exit).
  apt_install() {
    local pkg="$1"
    local bin="${2:-$1}"
    if command -v "$bin" &>/dev/null; then
      echo "  ✓ $bin already installed"
    else
      echo "  ↳ installing $pkg via apt..."
      if sudo apt-get install -y "$pkg"; then
        :
      else
        echo "  ⚠ $pkg failed to install"
      fi
    fi
  }

  # Install zoxide (binary into ~/.local/bin; no apt package)
  if [ -x "$HOME/.local/bin/zoxide" ]; then
    echo "  ✓ zoxide already installed"
  else
    echo "  ↳ installing zoxide..."
    if curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
      :
    else
      echo "  ⚠ zoxide failed to install"
    fi
  fi

  # Install jq (required for zellij-send-keys)
  apt_install jq

  # Install zellij plugins (same releases as macOS branch)
  mkdir -p "$HOME/.config/zellij/plugins"
  if [ ! -f "$HOME/.config/zellij/plugins/zellij-favs.wasm" ]; then
    echo "  ↳ installing zellij-favs..."
    curl -L https://github.com/JoseMM2002/zellij-favs/releases/download/v1.0.1/zellij-favs.wasm \
      -o "$HOME/.config/zellij/plugins/zellij-favs.wasm" || echo "  ⚠ zellij-favs failed"
  else
    echo "  ✓ zellij-favs already installed"
  fi
  if [ ! -f "$HOME/.config/zellij/plugins/zellij-send-keys.wasm" ]; then
    echo "  ↳ installing zellij-send-keys..."
    curl -L https://github.com/atani/zellij-send-keys/releases/latest/download/zellij-send-keys.wasm \
      -o "$HOME/.config/zellij/plugins/zellij-send-keys.wasm" || echo "  ⚠ zellij-send-keys failed"
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
      npm install -g @rivolink/leaf || echo "  ⚠ @rivolink/leaf failed to install"
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
  # ripgrep ships as `ripgrep` on Debian/Ubuntu (no name collision — unlike
  # fd-find→fd or bat→batcat) so no symlink dance is needed.
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
    if sudo apt-get install -y bat; then
      :
    else
      echo "  ⚠ bat failed to install"
    fi
    # Post-install: if apt shipped `batcat`, surface it as `bat` for consistency.
    if command -v batcat &>/dev/null && [ ! -e "$HOME/.local/bin/bat" ]; then
      ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    fi
  fi
  apt_install htop
  apt_install zellij

  # eza: not in Debian/Ubuntu stock apt — install via community package (no checksum, accepted risk).
  # Build the .deb inside a temp dir so the user's CWD stays clean.
  if command -v eza &>/dev/null; then
    echo "  ✓ eza already installed"
  else
    echo "  ↳ installing eza..."
    if sudo apt-get install -y eza; then
      :
    else
      EZA_TMP="$(mktemp -d)"
      if (cd "$EZA_TMP" \
            && sudo apt-get install -y wget gpg \
            && curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb-package-maketar.sh | bash \
            && sudo apt-get install -y ./eza_*.deb); then
        :
      else
        echo "  ⚠ eza failed to install"
      fi
      rm -rf "$EZA_TMP"
    fi
  fi

  # lazygit: not in stock apt on most distros — install via official GitHub release (accepted risk).
  # The upstream filename embeds both version and arch
  # (`lazygit_<version>_linux_x86_64.tar.gz`, with arm64/armv6 variants), so
  # resolve the release version and derive the architecture from `uname -m`.
  # Note: lazygit does not publish an armv7 asset; the armv6 build (GOARM=6)
  # is the one that runs on armv7l hardware.
  LG_ARCH=""
  case "$(uname -m)" in
    x86_64)  LG_ARCH="x86_64" ;;
    aarch64) LG_ARCH="arm64" ;;
    armv7l)  LG_ARCH="armv6" ;;
    *)       LG_ARCH="" ;;
  esac
  if command -v lazygit &>/dev/null; then
    echo "  ✓ lazygit already installed"
  else
    echo "  ↳ installing lazygit..."
    sudo apt-get install -y lazygit \
      || (
        if [ -z "$LG_ARCH" ]; then
          echo "  ⚠ lazygit: unsupported arch ($(uname -m)) — skipping GitHub fallback"
        else
          LAZYGIT_VERSION="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
            | grep -Po '"tag_name": "v\K[^"]*' || true)"
          if [ -z "$LAZYGIT_VERSION" ]; then
            echo "  ⚠ lazygit: could not determine latest version"
          else
            LG_TMP="$(mktemp -d)"
            LAZYGIT_TARBALL="lazygit_${LAZYGIT_VERSION}_linux_${LG_ARCH}.tar.gz"
            if curl -fsSL -o "$LG_TMP/lazygit.tar.gz" \
                "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/$LAZYGIT_TARBALL" \
              && tar -xzf "$LG_TMP/lazygit.tar.gz" -C "$LG_TMP" lazygit \
              && sudo install -m 755 "$LG_TMP/lazygit" /usr/local/bin/lazygit; then
              :
            else
              echo "  ⚠ lazygit tarball install failed"
            fi
            rm -rf "$LG_TMP"
          fi
        fi
      ) \
      || echo "  ⚠ lazygit failed to install"
  fi

  # alacritty: not in stock apt on older Debian/Ubuntu — install via apt with fallback to cargo.
  # The cargo build is long; refresh the sudo timestamp before kicking it off
  # so a mid-build expiration does not abort subsequent sudo calls.
  if command -v alacritty &>/dev/null; then
    echo "  ✓ alacritty already installed"
  else
    echo "  ↳ installing alacritty..."
    sudo apt-get install -y alacritty \
      || (
        sudo -v
        sudo apt-get install -y cargo rustc cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev python3 \
          && cargo install alacritty
      ) \
      || echo "  ⚠ alacritty failed to install"
  fi

  # yazi: not in stock apt — install via official installer script (accepted risk).
  if command -v yazi &>/dev/null; then
    echo "  ✓ yazi already installed"
  else
    echo "  ↳ installing yazi..."
    if curl -fsSL https://raw.githubusercontent.com/sxyazi/yazi/main/install.sh | sh; then
      :
    elif sudo apt-get install -y yazi; then
      :
    else
      echo "  ⚠ yazi failed to install"
    fi
  fi

  # starship: official curl|sh installer (accepted risk, parity with macOS branch).
  if command -v starship &>/dev/null; then
    echo "  ✓ starship already installed"
  else
    echo "  ↳ installing starship..."
    if curl -fsSL https://starship.rs/install.sh | sh -s -- -y; then
      :
    else
      echo "  ⚠ starship failed to install"
    fi
  fi

  # delta (git-delta): not in stock apt — install via official GitHub release .deb.
  # Upstream ships `git-delta_<ver>_<arch>.deb` for both amd64 and arm64;
  # derive the arch suffix from `dpkg --print-architecture` (fallback amd64).
  DEB_ARCH="$(dpkg --print-architecture 2>/dev/null || echo amd64)"
  if command -v delta &>/dev/null; then
    echo "  ✓ delta already installed"
  else
    echo "  ↳ installing git-delta..."
    DELTA_VERSION=$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest \
      | grep -Po '"tag_name": "\K[^"]*' || true)
    if [ -z "$DELTA_VERSION" ]; then
      echo "  ⚠ delta: could not determine latest version"
    else
      DELTA_DEB="git-delta_${DELTA_VERSION}_${DEB_ARCH}.deb"
      DELTA_TMP="$(mktemp -d)"
      if curl -fsSL -o "$DELTA_TMP/$DELTA_DEB" \
          "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/$DELTA_DEB" \
        && sudo apt-get install -y "$DELTA_TMP/$DELTA_DEB"; then
        :
      else
        echo "  ⚠ delta failed to install"
      fi
      rm -rf "$DELTA_TMP"
    fi
  fi

  # fnm (Fast Node Manager): install via official curl|sh script to ~/.local/share/fnm + ~/.local/bin/fnm.
  if command -v fnm &>/dev/null; then
    echo "  ✓ fnm already installed"
  else
    echo "  ↳ installing fnm..."
    if curl -fsSf https://raw.githubusercontent.com/Schniz/fnm/master/.ci/install.sh | sh -s -- --skip-shell; then
      :
    else
      echo "  ⚠ fnm failed to install"
    fi
  fi

  # node@22 via fnm — needs fnm on PATH first.
  if command -v fnm &>/dev/null; then
    if fnm list 2>/dev/null | grep -q 'v22\.'; then
      echo "  ✓ node@22 already installed (via fnm)"
    else
      echo "  ↳ installing node@22 via fnm..."
      fnm install 22 &>/dev/null || echo "  ⚠ node@22 failed to install"
      fnm default 22 &>/dev/null || true
    fi
    # Make node/npm available to subsequent commands in this script.
    # `fnm env` can legitimately return empty if fnm is mid-install or its
    # internal state is unset; eval'ing an empty string is a silent no-op,
    # leaving subsequent npm calls bound to a stale binary. Verify non-empty
    # output before eval'ing, so we surface a warning instead of degrading
    # silently.
    FNM_ENV_OUT="$(fnm env 2>/dev/null || true)"
    if [ -n "$FNM_ENV_OUT" ]; then
      eval "$FNM_ENV_OUT"
    else
      echo "  ⚠ fnm env returned nothing — node/npm may not be on PATH"
    fi
    export PATH
  else
    echo "  ⚠ skipping node@22 (fnm not installed)"
  fi

  # go: prefer apt's golang-go (fast); fallback to official tarball into /usr/local/go (no checksum).
  # The upstream tarball embeds the arch (linux-amd64 / linux-arm64); derive
  # the suffix from `uname -m` so aarch64 resolves too. PATH is appended to
  # ~/.zshrc (idempotent) instead of /etc/profile.d, which most zsh setups do
  # not source — writing to /etc/profile.d leaves Go invisible interactively.
  GO_TARBALL_ARCH=""
  case "$(uname -m)" in
    x86_64)  GO_TARBALL_ARCH="amd64" ;;
    aarch64) GO_TARBALL_ARCH="arm64" ;;
    *)       GO_TARBALL_ARCH="" ;;
  esac
  if command -v go &>/dev/null; then
    echo "  ✓ go already installed"
  else
    echo "  ↳ installing go..."
    sudo apt-get install -y golang-go \
      || (
        if [ -z "$GO_TARBALL_ARCH" ]; then
          echo "  ⚠ go: unsupported arch ($(uname -m)) — skipping tarball fallback"
        else
          GO_VERSION="$(curl -fsSL https://go.dev/VERSION?m=text | head -1 || true)"
          if [ -z "$GO_VERSION" ]; then
            GO_VERSION="go1.22.5"
          fi
          GO_TMP="$(mktemp -d)"
          if curl -fsSL -o "$GO_TMP/go.tar.gz" \
              "https://go.dev/dl/${GO_VERSION}.linux-${GO_TARBALL_ARCH}.tar.gz" \
            && sudo rm -rf /usr/local/go \
            && sudo tar -C /usr/local -xzf "$GO_TMP/go.tar.gz"; then
            # Append Go's PATH to ~/.zshrc (idempotent).
            GOPATH_LINE='export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"'
            ZSHRC="$HOME/.zshrc"
            if [ -f "$ZSHRC" ] && grep -qxF "$GOPATH_LINE" "$ZSHRC" 2>/dev/null; then
              echo "  ✓ go PATH already in $ZSHRC"
            else
              printf '\n# Added by myshellconf install.sh — Go toolchain PATH\n%s\n' \
                "$GOPATH_LINE" >> "$ZSHRC"
              echo "  ↳ appended go PATH to $ZSHRC"
            fi
          else
            echo "  ⚠ go tarball install failed"
          fi
          rm -rf "$GO_TMP"
        fi
      ) \
      || echo "  ⚠ go failed to install"
  fi

  # rust: official rustup-init (accepted risk; no checksum).
  if command -v rustup &>/dev/null || command -v cargo &>/dev/null; then
    echo "  ✓ rust already installed"
  else
    echo "  ↳ installing rust..."
    if curl -fsSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal; then
      :
    else
      echo "  ⚠ rust failed to install"
    fi
    # Source cargo env if rustup succeeded so subsequent cargo-based steps (e.g. alacritty) can find it.
    [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
    export PATH
  fi

  # Neovim newer-version fallback — apt's neovim is often < 0.10 on older distros.
  # Download the arch-specific upstream tarball, verify it against the SHA-256
  # digest exposed by GitHub's release-assets API, then extract under
  # $HOME/.local/share/nvim-stable. The apt package remains installed so its
  # dependencies still resolve.
  if command -v nvim &>/dev/null; then
    NVIM_VERSION_RAW="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    NVIM_MAJOR=$(echo "$NVIM_VERSION_RAW" | cut -d. -f1)
    NVIM_MINOR=$(echo "$NVIM_VERSION_RAW" | cut -d. -f2)
    if [ "${NVIM_MAJOR:-0}" -ge 1 ] || { [ "${NVIM_MAJOR:-0}" -eq 0 ] && [ "${NVIM_MINOR:-0}" -ge 10 ]; }; then
      echo "  ✓ neovim $NVIM_VERSION_RAW ≥ 0.10"
    else
      echo "  ↳ neovim apt version $NVIM_VERSION_RAW < 0.10 — installing newer nvim..."
      NVIM_TARBALL_ARCH=""
      case "$(uname -m)" in
        x86_64)  NVIM_TARBALL_ARCH="x86_64" ;;
        aarch64) NVIM_TARBALL_ARCH="arm64" ;;
        *)       NVIM_TARBALL_ARCH="" ;;
      esac
      if [ -z "$NVIM_TARBALL_ARCH" ]; then
        echo "  ⚠ neovim: unsupported arch ($(uname -m)) — skipping"
      else
        NVIM_TARBALL="nvim-linux-${NVIM_TARBALL_ARCH}.tar.gz"
        NVIM_TMP="$(mktemp -d)"
        NVIM_RELEASE_JSON="$NVIM_TMP/release.json"
        if curl -fsSL -o "$NVIM_RELEASE_JSON" \
            https://api.github.com/repos/neovim/neovim/releases/latest; then
          NVIM_TAG="$(jq -r '.tag_name // empty' "$NVIM_RELEASE_JSON")"
          NVIM_EXPECTED_SHA="$(jq -r --arg name "$NVIM_TARBALL" \
            '.assets[] | select(.name == $name) | .digest // empty' "$NVIM_RELEASE_JSON" \
            | sed 's/^sha256://')"
          if [ -z "$NVIM_TAG" ] || [ -z "$NVIM_EXPECTED_SHA" ]; then
            echo "  ⚠ neovim: release tag or asset digest unavailable — refusing to install"
          elif curl -fsSL -o "$NVIM_TMP/$NVIM_TARBALL" \
              "https://github.com/neovim/neovim/releases/download/${NVIM_TAG}/$NVIM_TARBALL"; then
            NVIM_ACTUAL_SHA="$(sha256sum "$NVIM_TMP/$NVIM_TARBALL" | awk '{print $1}')"
            if [ "$NVIM_EXPECTED_SHA" = "$NVIM_ACTUAL_SHA" ]; then
              NVIM_SHARE="$HOME/.local/share/nvim-stable"
              rm -rf "$NVIM_SHARE"
              mkdir -p "$NVIM_SHARE"
              tar -xzf "$NVIM_TMP/$NVIM_TARBALL" -C "$NVIM_SHARE" --strip-components=1
              ln -sf "$NVIM_SHARE/bin/nvim" "$HOME/.local/bin/nvim"
              echo "  ✓ neovim $NVIM_TAG installed to $NVIM_SHARE (sha256 verified)"
            else
              echo "  ⚠ neovim sha256 mismatch — refusing to install"
            fi
          else
            echo "  ⚠ neovim tarball download failed"
          fi
        else
          echo "  ⚠ neovim release metadata download failed"
        fi
        rm -rf "$NVIM_TMP"
      fi
    fi
  else
    echo "  ⚠ neovim not on PATH — newer-version fallback skipped (install via apt first)"
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
    if git clone "https://github.com/$plugin.git" "$plugin_dir"; then
      :
    else
      echo "  ⚠ failed to clone $plugin"
    fi
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
