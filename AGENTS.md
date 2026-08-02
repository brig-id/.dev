# AGENTS.md — brig·id `.dev`

This repository is the **shared workspace** for the brig·id organization.

## Language

**All content in all brig·id repositories must be in English** — code, comments,
doc-comments, commit messages, issues, pull requests, specs, and configuration.
This rule applies to every sibling repository. No exceptions.

## Scope

- VS Code multi-root workspace (`brig-id.code-workspace`)
- devcontainer setup (`.devcontainer/`)
- `brigid` — the dev orchestrator CLI (`Cargo.toml`, `src/`)
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
| `/workspaces/app` | `brig-id/app` | Qwik UI — login, register, account management |
| `/workspaces/site` | `brig-id/site` | Public marketing/landing site |

## Devcontainer — available tools

The container is self-contained; no host Rust installation is needed.

- **Rust stable** (via devcontainer feature) + **nightly** (for `cargo-fuzz`)
- **wasm32-unknown-unknown** target
- **mold** linker (faster incremental builds)
- `cargo-binstall`, `cargo-audit`, `cargo-deny`, `cargo-vet`
- `cargo-nextest`, `cargo-llvm-cov`, `cargo-fuzz`
- `cargo-edit`, `cargo-watch`, `cargo-cyclonedx`
- `just`, `wasm-pack`, `mprocs` (split-pane process runner, used by `brigid dev`)
- `mkcert` (local HTTPS, used by `brigid setup`)
- `gh` CLI, `docker` CLI

Cargo volumes are Docker named volumes (`brigid-cargo-*`) — nothing written to the host.
`CARGO_TARGET_DIR=/cargo-target` (named volume, not inside any repo).

## Roadmap & planning

TODOs, backlog ideas, and phase/release tracking live in the org's GitHub Project,
not in local files: **[brig-id Project 1](https://github.com/orgs/brig-id/projects/1)**
(cross-repo — items belong to whichever `brig-id/*` repo they concern). Check it
before starting product work, same way `phases/*.md` used to be read. Open a card
there for new work instead of adding a local TODO/roadmap file.

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

# Run from .dev — the dev orchestrator
brigid check   # verify local-dev prerequisites
brigid setup   # fix what `check` finds missing (mkcert, dev cert, MASTER_KEY)
brigid dev     # interactively launch dev processes side by side
brigid repos <status|fetch|pull|branch|install|build|test|lint>
```

## Rules

- Treat this repository as orchestration only — no product runtime code here.
  The one exception is `brigid` itself (`Cargo.toml`, `src/`): it's dev
  tooling that never ships, not product code — the CLI equivalent of the old
  `scripts/*.mjs` it replaced.
- Add future repositories as siblings of `.dev/`, not nested inside it.
- Update `brig-id.code-workspace` and `.devcontainer/devcontainer.json`
  together when a new sibling repository is added.
- Do not implement the product plan here unless the task is explicitly about shared tooling.
- Track TODOs, backlog ideas, and release/phase status as cards in
  [Project 1](https://github.com/orgs/brig-id/projects/1), not as local
  Markdown files (`TODO.md`, `phases/*.md`, etc. — retired in favor of the
  project board).

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

Scopes live in `scopes.json` at this repo's root (machine-readable source of truth,
also read by the `/commit` slash command):

| Scope | Maps to |
| --- | --- |
| `memory` | `memory/` — persistent agent memory files |
| `workspace` | `brig-id.code-workspace`, root-level config |
| `devcontainer` | `.devcontainer/` |
| `ai` | Agent guidance, prompt files |
| `ci` | `.github/workflows/` (if any) |
| `cli` | `brigid` — `Cargo.toml`, `src/` |

**Do not use a scope outside this list.** If a new top-level concern is added,
update `scopes.json` (and this table) and `.vscode/settings.json` together.

```text
docs(ai): 📝 point AGENTS.md at the GitHub Project instead of phases/
chore(devcontainer): 🔧 add pnpm to devcontainer features
ci(ci): 👷 add conventional commit check
```

## Git Workflow

brig·id ships to production, so branches go through an intermediate stage before `main`.
Every merge is **rebase + fast-forward only** — no merge commits, no squash merges, anywhere.

**Branches:**

| Branch | Purpose | Lifetime |
| --- | --- | --- |
| `main` | Production | Permanent |
| `dev/*` (e.g. `dev/2026-08`) | Internal/staging release train | One per cycle — deleted after merging into `main` |
| `hotfix/*` | Urgent production fix, bypasses `dev/*` | One per fix — deleted after merging into `main` |
| `feat/*`, `bug/*` | Regular work | One per change — deleted after merging into the current `dev/*` |

**Merging (always via PR, never a direct push to `main` or `dev/*`):**

- `feat/*` / `bug/*` → rebase onto the current `dev/*` tip, then fast-forward merge into `dev/*`.
- `dev/*` → rebase onto `main`'s tip, then fast-forward merge into `main`.
- `hotfix/*` → branched from `main`, rebase onto `main`'s tip, then fast-forward merge into `main`.
- If a `hotfix/*` lands on `main` while a `dev/*` is still in flight, rebase that `dev/*` onto the
  new `main` before its own merge — fast-forward tolerates no divergence.
- Releases are tracked with **tags on `main`** (there's no merge commit to mark them, since every
  merge is a fast-forward).

## Inheritance

This repo's *shape* (`CLAUDE.md`, `scopes.json`, `commit-convention.json`,
`.claude/commands/commit.md`) is ported from
[helpers4/.dev](https://github.com/helpers4/.dev)'s canonical setup. Deltas from that shape:
- **Stack: Rust/cargo**, not TypeScript — `core`/`crypto`/`server-*` are cargo crates; `app`
  is a pnpm/Qwik project; `site`'s stack isn't decided yet.
- **License: LGPL-3.0-or-later**, same as helpers4.
- `test-container.sh` (environment self-check) and the cargo-volume-heavy, nightly/wasm/mold
  install logic in `setup-container.sh` are brig·id-specific and intentionally not shared with
  the TypeScript-only orgs.
- Roadmap/phase tracking uses a GitHub Project (org-level, cross-repo) instead of
  local Markdown files — a brig·id-specific choice, not part of helpers4's template.
