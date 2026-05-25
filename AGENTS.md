# AGENTS.md — brig·id `.dev`

This repository is the **shared workspace** for the brig·id organization.

## Language

**All content in all brig·id repositories must be in English** — code, comments,
doc-comments, commit messages, issues, pull requests, specs, and configuration.
This rule applies to every sibling repository. No exceptions.

## Scope

- VS Code multi-root workspace (`brig-id.code-workspace`)
- devcontainer setup (`.devcontainer/`)
- cross-repo helper scripts (`scripts/`)
- phase planning (`phases/`)
- shared AI / Copilot guidance

## Workspace structure

All repositories are mounted as siblings under `/workspaces/`:

| Path | Repo | Purpose |
|---|---|---|
| `/workspaces/.dev` | `brig-id/.dev` | This repo — orchestration |
| `/workspaces/.github` | `brig-id/.github` | Org-level GitHub config + reusable workflows |
| `/workspaces/crypto` | `brig-id/crypto` | Cryptographic primitives (Phase 1) |
| `/workspaces/core` | `brig-id/core` | Business logic crates (Phases 2–6) |
| `/workspaces/server-leaf` | `brig-id/server-leaf` | Single-server deployment binary (Phase 7) |
| `/workspaces/server-grove` | `brig-id/server-grove` | Multi-server orchestration (future) |
| `/workspaces/server-forest` | `brig-id/server-forest` | Global federation layer (future) |
| `/workspaces/spec` | `brig-id/spec` | Technical specs for audit (Phase 8) |

## Devcontainer — available tools

The container is self-contained; no host Rust installation is needed.

- **Rust stable** (via devcontainer feature) + **nightly** (for `cargo-fuzz`)
- **wasm32-unknown-unknown** target (for Leptos)
- **mold** linker (faster incremental builds)
- `cargo-binstall`, `cargo-audit`, `cargo-deny`, `cargo-vet`
- `cargo-nextest`, `cargo-llvm-cov`, `cargo-fuzz`
- `cargo-edit`, `cargo-watch`, `cargo-cyclonedx`, `cargo-leptos`
- `just`, `wasm-pack`
- `gh` CLI, `docker` CLI

Cargo volumes are Docker named volumes (`brigid-cargo-*`) — nothing written to the host.
`CARGO_TARGET_DIR=/cargo-target` (named volume, not inside any repo).

## Phase tracking

Implementation phases are in `/workspaces/.dev/phases/`:

| File | Phase | Repo | Status |
|---|---|---|---|
| `phase-0.md` | Infrastructure & Org | `.dev`, `.github` | ✅ Complete |
| `phase-1.md` | Crypto primitives | `crypto` | ⬜ Not started |
| `phase-2.md` | Storage & DID | `core` | ⬜ Not started |
| `phase-3.md` | Identity & VSID | `core` | ⬜ Not started |
| `phase-4.md` | WebAuthn | `core` | ⬜ Not started |
| `phase-5.md` | OIDC | `core` | ⬜ Not started |
| `phase-6.md` | API (Axum) + UI (Leptos) | `core` | ⬜ Not started |
| `phase-7.md` | Deployment binary | `server-leaf` | ⬜ Not started |
| `phase-8.md` | Audit readiness | all | ⬜ Not started |

## Common commands

```bash
# Run from any product repo
cargo test --workspace
cargo clippy --all-targets --all-features -- -D warnings
cargo fmt --all --check
cargo audit
cargo deny check
cargo llvm-cov --workspace --summary-only

# Run fuzzing (nightly required)
cargo +nightly fuzz run fuzz_decrypt -- -max_total_time=60

# Cross-repo git operations
node /workspaces/.dev/scripts/git-each.mjs status
```

## Rules

- Treat this repository as orchestration only — no product runtime code here.
- Add future repositories as siblings of `.dev/`, not nested inside it.
- Update `repos.json`, `brig-id.code-workspace`, and `.devcontainer/devcontainer.json`
  together when a new sibling repository is added.
- Do not implement the product plan here unless the task is explicitly about shared tooling.
- When updating a phase file, mark completed items with `[x]` and never delete items.
