# Phase 0 — Infrastructure & Organisation

**Repos concernés :** `.dev`, `.github`, `crypto`, `core`, `server-leaf`, `spec`
**Prérequis :** aucun

---

## Repos GitHub

- [x] Créer `brig-id/crypto`
- [x] Créer `brig-id/core`
- [x] Créer `brig-id/server-leaf`
- [x] Créer `brig-id/server-grove` (placeholder)
- [x] Créer `brig-id/server-forest` (placeholder)
- [x] Créer `brig-id/spec`
- [x] Cloner tous les repos en local
- [x] Mettre à jour `repos.json` + `brig-id.code-workspace`

## Devcontainer

- [x] Feature Rust `stable` + nightly + wasm32 target
- [x] Named volumes cargo (registry, git, target) — pas de pollution du host
- [x] Bind mounts pour tous les repos siblings
- [x] `CARGO_TARGET_DIR=/cargo-target`
- [x] Installer cargo-binstall, cargo-audit, cargo-deny, cargo-vet, cargo-nextest,
      cargo-llvm-cov, cargo-edit, cargo-watch, cargo-cyclonedx, just, wasm-pack
- [x] Installer cargo-fuzz (nightly)
- [x] Installer mold linker
- [x] Extensions VS Code : rust-analyzer, even-better-toml, vscode-lldb, crates, dependi

## Reusable GitHub Actions Workflows (dans `.github`)

- [x] `.github/workflows/ci-rust.yml` — fmt check, clippy, cargo nextest
- [x] `.github/workflows/security-audit.yml` — cargo audit, cargo deny check
- [x] `.github/workflows/coverage.yml` — cargo llvm-cov + upload Codecov

## Branch protection (repos actifs : crypto, core, server-leaf, spec)

- [x] Require linear history
- [x] No force push on `main`
- [x] No branch deletion
- [ ] Require status checks (CI) when workflows existent (à activer après 1er run CI)

## Labels (dans chaque repo actif)

- [x] `area:crypto` `area:identity` `area:oidc` `area:webauthn`
      `area:ui` `area:deploy` `area:spec`
- [x] `priority:critical` `priority:high` `priority:normal`
- [x] `type:security` `type:bug` `type:feature` `type:chore`

## Milestones (dans chaque repo actif)

- [x] `infrastructure` — Phase 0
- [x] `crypto` — Phase 1
- [x] `identity` — Phases 2–3
- [x] `webauthn` — Phase 4
- [x] `oidc` — Phase 5
- [x] `api-ui` — Phase 6
- [x] `leaf-deploy` — Phase 7
- [x] `audit-ready` — Phase 8

## GitHub Project

- [ ] Créer project "brig·id 0.0.1" dans l'org brig-id ⚠️ manuel (token sans scope `project`)
- [ ] Ajouter les repos actifs au project
- [ ] Configurer les vues (Board, Table, Roadmap)

## CODEOWNERS

- [x] `CODEOWNERS` dans `crypto` — `* @baxyz`
- [x] `CODEOWNERS` dans `core` — `* @baxyz`
- [x] `CODEOWNERS` dans `server-leaf` — `* @baxyz`
- [x] `CODEOWNERS` dans `spec` — `* @baxyz`

## SECURITY.md

- [x] `SECURITY.md` dans `crypto`
- [x] `SECURITY.md` dans `core`
- [x] `SECURITY.md` dans `server-leaf`
- [x] `SECURITY.md` dans `spec`

---

## Vérification

- [ ] `gh repo list brig-id` affiche les 7 repos
- [ ] Ouvrir le devcontainer — workspace ready sans erreur
- [ ] `cargo --version` et `rustup show` fonctionnent dans le container
- [ ] `cargo audit` et `cargo deny` disponibles
- [ ] GitHub Project visible sur github.com/orgs/brig-id/projects
