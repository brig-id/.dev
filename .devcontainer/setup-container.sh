#!/usr/bin/env bash
set -euo pipefail

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

# Nightly (requis par cargo-fuzz) + composants pour cargo-llvm-cov
rustup toolchain install nightly \
  --component rust-src,llvm-tools-preview \
  --no-self-update \
  --quiet

# Cible WASM pour Leptos
rustup target add wasm32-unknown-unknown --quiet

echo "✓ Rust toolchain ready (stable + nightly, wasm32)."

# ── cargo-binstall ─────────────────────────────────────────────────────────────
if ! command -v cargo-binstall >/dev/null 2>&1; then
  echo ""
  echo "Installing cargo-binstall (pré-compilés rapides)..."
  curl -L --proto '=https' --tlsv1.2 -sSf \
    https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh \
    | bash
  echo "✓ cargo-binstall ready."
fi

# ── Outils Rust via binaires pré-compilés ─────────────────────────────────────
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

# ── cargo-fuzz (nightly uniquement, pas de binaire pré-compilé) ───────────────
if ! command -v cargo-fuzz >/dev/null 2>&1; then
  echo ""
  echo "Installing cargo-fuzz (nightly)..."
  cargo +nightly install cargo-fuzz --quiet
  echo "✓ cargo-fuzz ready."
fi

# ── mold linker (2-5× plus rapide que lld pour les builds incrémentaux) ───────
if ! command -v mold >/dev/null 2>&1; then
  echo ""
  echo "Installing mold linker..."
  sudo apt-get install -y --no-install-recommends mold 2>/dev/null \
    || echo "! mold: installation failed, lld sera utilisé en fallback"
fi

echo ""
echo "✓ brig·id workspace ready."
