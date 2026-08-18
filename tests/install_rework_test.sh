#!/usr/bin/env bash
set -euo pipefail

INSTALL_SCRIPT="${1:-install.sh}"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local pattern="$1"
  local message="$2"
  grep -qE "$pattern" "$INSTALL_SCRIPT" || fail "$message"
}

assert_not_contains() {
  local pattern="$1"
  local message="$2"
  if grep -qE "$pattern" "$INSTALL_SCRIPT"; then
    fail "$message"
  fi
}

assert_contains 'lazygit_\$\{LAZYGIT_VERSION\}_linux_\$\{LG_ARCH\}\.tar\.gz' \
  'lazygit fallback must use the versioned lowercase release asset name'
assert_contains 'releases/download/\$\{LAZYGIT_VERSION\}/\$LAZYGIT_TARBALL' \
  'lazygit fallback must download from the resolved version tag'
assert_contains 'aarch64\)[[:space:]]+NVIM_TARBALL_ARCH="arm64"' \
  'Neovim aarch64 mapping must use the arm64 asset suffix'
assert_contains '"digest"' \
  'Neovim fallback must read the release asset digest'
assert_not_contains 'neovim/releases/download/\$\{NVIM_TAG\}/SHA256SUMS' \
  'Neovim fallback must not request the nonexistent SHA256SUMS asset'
assert_contains 'if \[ -z "\$GO_VERSION" \]' \
  'Go fallback must handle an empty version response'

while IFS= read -r line; do
  case "$line" in
    *'curl '*|*'brew install '*|*'npm install '*)
      [[ "$line" != *'2>/dev/null'* ]] || fail "download/install stderr is suppressed: $line"
      ;;
  esac
done < "$INSTALL_SCRIPT"

if LC_ALL=C grep -n $'\357\277\275' "$INSTALL_SCRIPT" >/dev/null; then
  fail 'install.sh contains Unicode replacement characters'
fi

bash -n "$INSTALL_SCRIPT" || fail 'install.sh has invalid Bash syntax'
printf 'PASS: targeted SYSTEM-0953 regressions\n'
