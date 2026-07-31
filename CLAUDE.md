# Claude Code — brig·id workspace

Full canonical rules (commit format, restrictions, language) live in
[AGENTS.md](AGENTS.md). This file adds Claude Code-specific context.

## Workspace layout

All repos are bind-mounted at `/workspaces/<name>` and open together in
`brig-id.code-workspace`:

| Path | Repo | Role |
| ---- | ---- | ---- |
| `/workspaces/.dev` | `.dev` | Orchestration — canonical AGENTS.md, devcontainer, phases |
| `/workspaces/.github` | `.github` | Org-level GitHub config + reusable workflows |
| `/workspaces/crypto` | `crypto` | Cryptographic primitives |
| `/workspaces/core` | `core` | Business logic crates |
| `/workspaces/server-leaf` | `server-leaf` | Single-server deployment binary |
| `/workspaces/server-grove` | `server-grove` | Multi-server orchestration (future) |
| `/workspaces/server-forest` | `server-forest` | Global federation layer (future) |
| `/workspaces/spec` | `spec` | Technical specs for audit |
| `/workspaces/web` | `web` | Qwik UI |

## Common commands (run from any product repo)

```bash
cargo test --workspace
cargo clippy --all-targets --all-features -- -D warnings
cargo fmt --all --check
cargo audit
cargo deny check
cargo llvm-cov --workspace --summary-only

# fuzzing (nightly required)
cargo +nightly fuzz run fuzz_decrypt -- -max_total_time=60
```

## Common gotchas

**Commit scopes**: always read `scopes.json` at the active repo root before choosing a scope.
Never invent a scope that isn't listed. Full type→emoji mapping: `/workspaces/.dev/commit-convention.json`.
Use `/commit` (Claude Code slash command) to auto-generate a message from staged changes.

**Cargo target/volumes**: `CARGO_TARGET_DIR=/cargo-target` and the cargo registry/git caches are
Docker named volumes (`brigid-cargo-*`), never on the host — don't assume a `target/` dir exists
inside a repo checkout.

**Toolchain**: stable Rust is the devcontainer base; nightly is installed separately (rust-src +
llvm-tools-preview) only for `cargo-fuzz`. `wasm32-unknown-unknown` is added for the `web` crate.
See `.devcontainer/setup-container.sh` for the full list of installed cargo tools.

**Environment self-check**: run `.devcontainer/test-container.sh` after a container rebuild to
verify the Rust toolchain, cargo tools, GH auth, and mounted repos are all in the expected state.

**Phase tracking**: read `phases/*.md` before starting product work — mark completed items with
`[x]` and never delete items, per AGENTS.md's Rules section.

## AI persistence

`~/.claude` is bind-mounted from the host and symlinked at every container start by
`claude-dev`. Memory, credentials, and settings survive all rebuilds.
