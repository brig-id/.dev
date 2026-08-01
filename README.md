# brig·id — `.dev`

Central orchestration workspace for the **brig·id** organization.

This repository is the bootstrap entry point for local development across the organization. It hosts:

- the shared [VS Code multi-root workspace](./brig-id.code-workspace)
- the shared [devcontainer](./.devcontainer/devcontainer.json)
- cross-repo helper scripts for future sibling repositories
- the workspace-level AI guidance used while the org is still being bootstrapped

It does **not** contain product runtime code. Application repositories will be created later next to `.dev/`.

## Current layout

```text
brig-id/
├── .dev/      # workspace, devcontainer, scripts, AI guidance
└── .github/   # org-wide GitHub defaults and profile
```

## Quick start

### 1. Clone the bootstrap repositories side by side

```bash
mkdir brig-id && cd brig-id
gh repo clone brig-id/.dev
gh repo clone brig-id/.github
```

### 2. Open the shared workspace

```bash
code .dev/brig-id.code-workspace
```

### 3. (Optional) Reopen in the devcontainer

The devcontainer gives a consistent toolchain and mounts the `.github` sibling repository next to `.dev/`.
GitHub tooling now comes primarily from the helpers4 devcontainer features, while `.dev` only keeps a few extra editor extensions on top.

If you want `gh` to stay authenticated inside the container, export your host token before reopening:

```bash
export GH_TOKEN="$(gh auth token)"
```

## `brigid` — dev orchestrator

From `.dev/` (already built and on `PATH` by `setup-container.sh`; otherwise
`cargo install --path .`):

```bash
brigid check           # verify local-dev prerequisites (toolchains, mkcert, MASTER_KEY, ...)
brigid setup           # fix what `check` finds missing
brigid dev              # interactively launch dev processes side by side (via mprocs)

brigid repos status     # git status -sb in every repo
brigid repos fetch      # git fetch --all --prune in every repo
brigid repos pull       # git pull --rebase --autostash in every repo
brigid repos branch     # git branch --show-current in every repo
brigid repos install    # cargo fetch / pnpm install, per repo
brigid repos build      # cargo build / pnpm run build, per repo
brigid repos test       # cargo test / pnpm run test, per repo
brigid repos lint       # cargo clippy -D warnings / pnpm run lint, per repo
```

- `repos.json` is the single source of truth for the sibling repository list
- `brigid repos <install|build|test|lint>` detects each repo's project type
  (`Cargo.toml` → cargo, `package.json` → pnpm via corepack) automatically
- source: `Cargo.toml` + `src/` at this repo's root — the one exception to
  "no product runtime code in `.dev`" (see `AGENTS.md`'s Rules section)

When a new repository is added to the organization, update `repos.json`, `brig-id.code-workspace`, and `.devcontainer/devcontainer.json` together.
