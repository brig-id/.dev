#!/usr/bin/env bash
set -euo pipefail

# ── Fix volume ownership (volumes created as root by Docker) ────────────────────
# CARGO_TARGET_DIR points to a named volume — must be writable by node.
if [ -d "${CARGO_TARGET_DIR:-/cargo-target}" ]; then
  sudo chown -R node:node "${CARGO_TARGET_DIR:-/cargo-target}"
fi

ORG="${BRIG_ID_ORG:-brig-id}"
REPOS="${BRIG_ID_REPOS:-.github}"

# ── Clone missing sibling repositories ────────────────────────────────────────
echo "Setting up ${ORG} workspace..."

for repo in $REPOS; do
  target="/workspaces/${repo}"

  if [ -d "${target}/.git" ] || [ -n "$(ls -A "${target}" 2>/dev/null || true)" ]; then
    echo "✓ ${repo}: already available"
    continue
  fi

  echo "→ ${repo}: cloning missing sibling repository"
  if command -v gh >/dev/null 2>&1; then
    gh repo clone "${ORG}/${repo}" "${target}" || echo "! ${repo}: clone failed"
  else
    git clone "https://github.com/${ORG}/${repo}.git" "${target}" || echo "! ${repo}: clone failed"
  fi
done

echo "✓ Workspace repos ready."

# ── Rust toolchain ─────────────────────────────────────────────────────────────
echo ""
echo "Setting up Rust toolchain..."

# Nightly (required by cargo-fuzz) + components for cargo-llvm-cov
rustup toolchain install nightly \
  --component rust-src,llvm-tools-preview \
  --no-self-update

# WASM target for Leptos
rustup target add wasm32-unknown-unknown

echo "✓ Rust toolchain ready (stable + nightly, wasm32)."

# ── cargo-binstall ─────────────────────────────────────────────────────────────
if ! command -v cargo-binstall >/dev/null 2>&1; then
  echo ""
  echo "Installing cargo-binstall (fast pre-compiled binaries)..."
  curl -L --proto '=https' --tlsv1.2 -sSf \
    https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh \
    | bash
  echo "✓ cargo-binstall ready."
fi

# ── Rust tools via pre-compiled binaries ──────────────────────────────────────
echo ""
echo "Installing Rust tools (cargo-binstall)..."

cargo binstall --no-confirm --quiet \
  cargo-audit \
  cargo-deny \
  cargo-vet \
  cargo-nextest \
  cargo-llvm-cov \
  cargo-edit \
  cargo-watch \
  cargo-cyclonedx \
  cargo-leptos \
  just \
  wasm-pack

echo "✓ Rust tools installed."

# ── cargo-fuzz (nightly only, no pre-compiled binary available) ────────────────
if ! command -v cargo-fuzz >/dev/null 2>&1; then
  echo ""
  echo "Installing cargo-fuzz (nightly)..."
  cargo +nightly install cargo-fuzz --quiet
  echo "✓ cargo-fuzz ready."
fi

# ── mold linker (2-5× faster than lld for incremental builds) ──────────────────
if ! command -v mold >/dev/null 2>&1; then
  echo ""
  echo "Installing mold linker..."
  sudo apt-get install -y --no-install-recommends mold 2>/dev/null \
    || echo "! mold: installation failed, falling back to lld"
fi

echo ""
echo "✓ brig·id workspace ready."
