#!/usr/bin/env bash
# test-container.sh — Vérifie que l'environnement du devcontainer est complet.
# À exécuter DANS le container après `postCreateCommand`.
# Usage : bash .devcontainer/test-container.sh
set -uo pipefail

PASS=0
FAIL=0
WARN=0

ok()   { echo "  ✓ $1"; ((PASS++)); }
fail() { echo "  ✗ $1"; ((FAIL++)); }
warn() { echo "  ⚠ $1"; ((WARN++)); }

check_cmd() {
  local cmd=$1 label=${2:-$1}
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$label — $(command -v "$cmd")"
  else
    fail "$label — introuvable"
  fi
}

check_version() {
  local cmd=$1 args=${2:---version} label=${3:-$1}
  if out=$("$cmd" $args 2>&1 | head -1); then
    ok "$label — $out"
  else
    fail "$label — échec ($out)"
  fi
}

echo ""
echo "═══════════════════════════════════════════════════"
echo "  brig·id devcontainer — test de l'environnement"
echo "═══════════════════════════════════════════════════"

# ── GitHub / git ───────────────────────────────────────────────────────────────
echo ""
echo "── GitHub & git ──"

if gh auth status >/dev/null 2>&1; then
  account=$(gh api user --jq '.login' 2>/dev/null || echo "inconnu")
  ok "gh CLI authentifié — compte: $account"
else
  fail "gh CLI non authentifié (GH_TOKEN manquant ou invalide)"
fi

if git ls-remote "https://github.com/brig-id/.github.git" HEAD >/dev/null 2>&1; then
  ok "git — accès en lecture à brig-id/.github"
else
  warn "git — accès HTTPS échoué (SSH peut fonctionner)"
fi

check_cmd git "git"

# ── Rust toolchain ─────────────────────────────────────────────────────────────
echo ""
echo "── Rust toolchain ──"

check_version rustup "show active-toolchain" "rustup stable"

if rustup toolchain list | grep -q nightly; then
  ok "rustup nightly — installé"
else
  fail "rustup nightly — manquant (requis pour cargo-fuzz)"
fi

if rustup target list --installed | grep -q "wasm32-unknown-unknown"; then
  ok "target wasm32-unknown-unknown — installé"
else
  fail "target wasm32-unknown-unknown — manquant (requis pour Leptos)"
fi

if rustup component list --installed | grep -q "llvm-tools"; then
  ok "composant llvm-tools — installé (requis pour cargo-llvm-cov)"
else
  warn "composant llvm-tools — absent (cargo llvm-cov pourrait échouer)"
fi

# ── Outils cargo ──────────────────────────────────────────────────────────────
echo ""
echo "── Outils cargo ──"

check_cmd cargo-audit    "cargo-audit"
check_cmd cargo-deny     "cargo-deny"
check_cmd cargo-vet      "cargo-vet"
check_cmd cargo-nextest  "cargo-nextest"
check_cmd cargo-llvm-cov "cargo-llvm-cov"
check_cmd cargo-watch    "cargo-watch"
check_cmd cargo-leptos   "cargo-leptos (SSR Leptos)"
check_cmd wasm-pack      "wasm-pack"
check_cmd just           "just (task runner)"
check_cmd cargo-fuzz     "cargo-fuzz (nightly)"
check_cmd mprocs         "mprocs (used by brigid dev)"

# ── Variables d'environnement critiques ───────────────────────────────────────
echo ""
echo "── Environnement ──"

if [ -n "${CARGO_TARGET_DIR:-}" ]; then
  ok "CARGO_TARGET_DIR=$CARGO_TARGET_DIR"
else
  warn "CARGO_TARGET_DIR non défini (les target/ iront dans les repos)"
fi

if [ -n "${GH_TOKEN:-}" ]; then
  ok "GH_TOKEN — présent"
else
  fail "GH_TOKEN — absent"
fi

# ── Volumes cargo ─────────────────────────────────────────────────────────────
echo ""
echo "── Volumes cargo ──"

if [ -d "${HOME}/.cargo/registry" ]; then
  ok "~/.cargo/registry — accessible"
else
  warn "~/.cargo/registry — absent (sera créé au 1er cargo build)"
fi

if [ -d "${CARGO_TARGET_DIR:-/cargo-target}" ]; then
  ok "${CARGO_TARGET_DIR:-/cargo-target} — volume target accessible"
else
  warn "${CARGO_TARGET_DIR:-/cargo-target} — absent (sera créé au 1er build)"
fi

# ── Outils système ────────────────────────────────────────────────────────────
echo ""
echo "── Outils système ──"

check_cmd mold   "mold linker"
check_cmd docker "docker (docker-outside-of-docker)"
check_cmd node   "node"
check_cmd mkcert "mkcert (used by brigid setup)"

# ── Repos montés ──────────────────────────────────────────────────────────────
echo ""
echo "── Repos workspace ──"

for repo in .dev .github crypto core server-leaf server-grove server-forest spec; do
  if [ -d "/workspaces/$repo" ]; then
    ok "/workspaces/$repo"
  else
    warn "/workspaces/$repo — non monté (normal si repo pas encore cloné)"
  fi
done

# ── Résumé ────────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
printf "  Résultat : %d ✓  %d ⚠  %d ✗\n" "$PASS" "$WARN" "$FAIL"
echo "═══════════════════════════════════════════════════"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "  Des éléments critiques sont manquants."
  echo "  Reconstruire le container ou relancer setup-container.sh"
  exit 1
fi
exit 0
