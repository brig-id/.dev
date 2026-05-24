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

## Cross-repo scripts

From `.dev/`:

```bash
npm run install:all
npm run build:all
npm run test:all
npm run lint:all
npm run status:all
npm run branch:all
npm run fetch:all
npm run pull:all
```

- `scripts/run-each.mjs` runs an npm script in every sibling repository that exposes it
- `scripts/git-each.mjs` runs a git command in every available sibling repository
- `repos.json` is the single source of truth for the sibling repository list

When a new repository is added to the organization, update `repos.json`, `brig-id.code-workspace`, and `.devcontainer/devcontainer.json` together.
