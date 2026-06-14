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
- shared AI / agent guidance

## Workspace structure

All repositories are mounted as siblings under `/workspaces/`:

| Path | Repo | Purpose |
| --- | --- | --- |
| `/workspaces/.dev` | `brig-id/.dev` | This repo — orchestration |
| `/workspaces/.github` | `brig-id/.github` | Org-level GitHub config + reusable workflows |
| `/workspaces/crypto` | `brig-id/crypto` | Cryptographic primitives |
| `/workspaces/core` | `brig-id/core` | Business logic crates |
| `/workspaces/server-leaf` | `brig-id/server-leaf` | Single-server deployment binary |
| `/workspaces/server-grove` | `brig-id/server-grove` | Multi-server orchestration (future) |
| `/workspaces/server-forest` | `brig-id/server-forest` | Global federation layer (future) |
| `/workspaces/spec` | `brig-id/spec` | Technical specs for audit |
| `/workspaces/web` | `brig-id/web` | Qwik UI (phase 2) |

## Devcontainer — available tools

The container is self-contained; no host Rust installation is needed.

- **Rust stable** (via devcontainer feature) + **nightly** (for `cargo-fuzz`)
- **wasm32-unknown-unknown** target
- **mold** linker (faster incremental builds)
- `cargo-binstall`, `cargo-audit`, `cargo-deny`, `cargo-vet`
- `cargo-nextest`, `cargo-llvm-cov`, `cargo-fuzz`
- `cargo-edit`, `cargo-watch`, `cargo-cyclonedx`
- `just`, `wasm-pack`
- `gh` CLI, `docker` CLI

Cargo volumes are Docker named volumes (`brigid-cargo-*`) — nothing written to the host.
`CARGO_TARGET_DIR=/cargo-target` (named volume, not inside any repo).

## Phase tracking (v2 plan)

Implementation phases are in `/workspaces/.dev/phases/`:

| File | Phase | Repo | Status |
| --- | --- | --- | --- |
| `phase-1.md` | API finalization | `core` | ⬜ |
| `phase-2.md` | Qwik UI | `web` (new repo) | ⬜ |
| `phase-3.md` | Integration & E2E | `server-leaf` | ⬜ |
| `phase-4.md` | Release v0.1.0 | all | ⬜ |

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
```

## Rules

- Treat this repository as orchestration only — no product runtime code here.
- Add future repositories as siblings of `.dev/`, not nested inside it.
- Update `brig-id.code-workspace` and `.devcontainer/devcontainer.json`
  together when a new sibling repository is added.
- Do not implement the product plan here unless the task is explicitly about shared tooling.
- When updating a phase file, mark completed items with `[x]` and never delete items.

## Commit conventions

Format: `type(scope): <emoji> description`

| Type | Emoji | When |
| --- | --- | --- |
| `feat` | ✨ | New feature or file |
| `fix` | 🐛 | Correction |
| `docs` | 📝 | Documentation only |
| `chore` | 🔧 | Maintenance, config |
| `ci` | 👷 | CI/CD |
| `revert` | ⏪ | Reverts a previous commit |

### Allowed scopes

| Scope | Maps to |
| --- | --- |
| `phases` | `phases/` — implementation phase checklists |
| `memory` | `memory/` — persistent agent memory files |
| `workspace` | `brig-id.code-workspace`, root-level config |
| `devcontainer` | `.devcontainer/` |
| `ai` | Agent guidance, prompt files |
| `ci` | `.github/workflows/` (if any) |

**Do not use a scope outside this list.** If a new top-level concern is added,
update this table and `.vscode/settings.json`.

```text
docs(phases): 📝 rewrite plan v1 to v2 — Qwik UI
chore(devcontainer): 🔧 add pnpm to devcontainer features
ci(ci): 👷 add conventional commit check
```
