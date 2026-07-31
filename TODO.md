# TODO — Rollout: main / dev/\* / hotfix/\* workflow

One-time migration to the branch/merge model documented in [AGENTS.md](AGENTS.md)'s
"Git Workflow" section. Checked against the real state of every repo on 2026-07-31 —
nothing on GitHub has been changed yet, this is a checklist.

## Current state (as of 2026-07-31)

| Repo | `main` protection | Existing `dev` branch | CI triggers on `dev` |
| --- | --- | --- | --- |
| `.dev` | none | — | — |
| `.github` | none | — | — |
| `crypto` | linear-history only, no PR required | `dev` (legacy plain name) | yes, literal `dev` |
| `core` | linear-history only, no PR required | `dev` (legacy plain name) | yes, literal `dev` |
| `server-leaf` | linear-history only, no PR required | `dev` (legacy plain name) | yes, literal `dev` |
| `server-grove` | none | `dev` (legacy plain name) | no — CI only runs on `main` |
| `server-forest` | none | `dev` (legacy plain name) | no — CI only runs on `main` |
| `spec` | linear-history only, no PR required | `dev` (legacy plain name) | no — CI only runs on `main` |
| `web` | none | none yet | no CI configured |

All repos are public and their GitHub default branch is already `main` — no rename needed.

## Per-repo checklist

- [ ] Repo settings → Pull Requests: enable only "Allow rebase merging"; disable "Allow merge commits" and "Allow squash merging".
- [ ] Branch protection rule for `main`: require a PR before merging, no direct pushes, no force-pushes, no deletions.
- [ ] Branch protection rule (or ruleset) for pattern `dev/*`: same restrictions as `main`.
- [ ] Branch protection rule (or ruleset) for pattern `hotfix/*`: same restrictions.
- [ ] Update CI workflow branch triggers (`.github/workflows/*.yml`): replace the literal `dev` (and bare `main`-only triggers) with patterns that also match `dev/**` and `hotfix/**`. Affects `crypto`, `core`, `server-leaf` (already reference literal `dev`) and `server-grove`, `server-forest`, `spec` (currently only trigger on `main`, so CI doesn't even run on their existing `dev` branch today).

## brig·id-specific migration steps

- [ ] Retire the legacy plain `dev` branch on `crypto`, `core`, `server-leaf`, `server-grove`, `server-forest`, `spec` — cut a first `dev/<cycle>` (e.g. `dev/2026-08`) from `main` instead, migrate any unmerged work from the old `dev`, then delete it.
- [ ] `web` has no `dev` branch yet — cut `dev/<cycle>` from `main`, then rebase the in-flight `feat/webawesome-migration` branch onto it (it's currently based directly on `main`).
- [ ] Decide whether Dependabot PRs should target `dev/*` instead of `main`. `crypto`, `core`, `server-leaf` have `dependabot.yml` with no `target-branch` set, so they currently open PRs against `main` directly. If they should go through `dev/*` like everything else, add `target-branch: dev/<cycle>` to each `dependabot.yml`; otherwise document Dependabot as an intentional exception.

## Not yet done

Nothing on GitHub (repo settings, branch protection, CI workflows, branch renames) has been
touched for this rollout — only this org's `AGENTS.md`/`CLAUDE.md` docs are updated so far.
