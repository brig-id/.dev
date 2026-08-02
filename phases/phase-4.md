# Phase 4 — Release v0.1.0

**Repos :** `crypto`, `core`, `server-leaf`, `web`, `spec`
**Prérequis :** Phase 3 terminée (E2E validé, Docker fonctionnel)
**Objectif :** Tag v0.1.0 propre, pre-audit ready, déployable en production.

> **Note v2 :** Version bumped 0.0.1 → 0.1.0 pour refléter l'UI complète
> et l'intégration E2E validée (scope plus large que le v1 initial).

---

## Rotation MASTER_KEY (`server-leaf`)

- [x] Sous-commande CLI : `leaf rotate-key --old <path> --new <path>`
  - [x] Charger l'ancienne et la nouvelle clé depuis des fichiers hex séparés
  - [x] Pour chaque credential chiffrée en DB : déchiffrer avec OLD, rechiffrer avec NEW (transactionnel)
  - [x] En cas d'erreur partielle : rollback, DB inchangée
  - [x] Après rotation : vérifier que l'ancienne clé ne peut plus déchiffrer
- [x] Test : rotation round-trip → données accessibles avec la nouvelle clé
- [x] Test : déchiffrement avec l'ancienne clé après rotation → erreur

> **Implementation note**: `EncryptedStore::rotate_master_key` (core repo,
> `brigid-store`, `dev/forge`) does the actual re-encryption — `users`
> (username/server/did_web + `username_index`, itself master-key-derived so
> it goes stale on rotation too) and `webauthn_credentials`, all in one
> transaction. 3 tests there: round-trip, old key fails post-rotation, and a
> malformed-blob-mid-rotation rollback proving the *entire* transaction
> reverts, not just the row that failed. `server-leaf`'s `leaf rotate-key`
> CLI (`dev/forge`) wraps it, plus a CLI-level integration test driving the
> full lifecycle over real HTTP with a software passkey (register → stop →
> rotate → restart → login).
>
> **Two consequences the checklist above doesn't mention, found while
> implementing this** — both printed by the CLI itself, not just documented
> in code:
>
> - VSIDs (the OIDC `sub` claim) are derived from the master key
>   (`derive_vsid_salt`) and never stored — recomputed on demand from
>   `(did_root, client_id, salt)`. Rotating changes every user's VSID for
>   every relying party simultaneously; there's no way to preserve that
>   continuity from `rotate-key` alone.
> - The OIDC signing key is also master-key-derived (not stored), so every
>   `id_token` issued before a rotation becomes invalid immediately, not
>   just at natural expiry.
>
> **Blocked on `core` being pushed**: `server-leaf`'s `dev/forge` now pins
> `core` to a commit (`8dfe4db...`) that only exists locally — `cargo build`
> will fail with "revision not found" until `core`'s `dev/forge` is pushed
> to GitHub. Confirmed this is the *only* issue (verified the integration
> locally via a temporary `[patch]` override, removed before committing).

---

## Fuzz targets (`core`)

- [x] `fuzz_parse_identifier` — entrées aléatoires dans `RootId::parse` (must not panic)
- [x] `fuzz_did_web_resolve` — parsing de DIDs aléatoires (must not panic)
- [x] `fuzz_jwt_validate` — JWTs aléatoires dans `validate_token` (must not panic)
- [x] Ajouter les 3 targets au CI `core` (nightly, 120s en CI)
- [ ] Seeds FIPS 203/204 comme corpus initiaux pour `crypto`

> **Implementation note**: `core/fuzz/` (`dev/forge`) — `fuzz_did_web_resolve`
> actually fuzzes `did_web_to_url` (the pure, synchronous parsing step), not
> `resolve_did_web` itself, which makes a real network request per call and
> would be neither hermetic nor deterministic to fuzz directly; the checklist
> wording ("parsing de DIDs aléatoires") already pointed at parsing, not
> resolution. Smoke-tested each target for 10s locally (millions of
> iterations, zero crashes) before committing. `.github/workflows/fuzz.yml`
> added (standalone, not a `brig-id/.github` reusable workflow — none exists
> for fuzzing yet), 120s/target, mirrors `brig-id/crypto`'s fuzz.yml
> (corpus caching, crash-artifact upload).
>
> FIPS 203/204 seed corpus is a separate `crypto`-repo item (its own fuzz
> targets already exist, just without seeds) — left undone; sourcing real
> NIST test vectors deserves its own pass rather than being rushed here.

---

## Couverture & Badges

- [ ] Codecov configuré pour `crypto`, `core`, `server-leaf`
  - [ ] Token dans GitHub Secrets de chaque repo
  - [ ] Upload automatique en CI
- [ ] Badge coverage dans chaque `README.md`
- [ ] Seuils : `crypto` ≥ 98%, `core` ≥ 95%, `server-leaf` ≥ 80%

---

## Finalisation sécurité

- [x] Revue finale `unwrap()` / `expect()` dans `core` et `server-leaf` — tous justifiés ou remplacés
- [x] Vérifier : aucune donnée sensible dans les logs tracing (grep `password|secret|key|token`)
- [ ] Activer GitHub secret scanning sur tous les repos
- [ ] Activer GitHub push protection
- [x] `SECURITY.md` : SLA de réponse (48h ack, 90j remediation) dans chaque repo

> **Implementation note**: `unwrap()`/`expect()` audit via `cargo clippy -W
> clippy::unwrap_used -W clippy::expect_used` on both repos, test modules
> filtered out by hand (checked each hit's line against where `mod tests`
> starts in its file). `core`: one real gap found and fixed —
> `GovernorConfigBuilder::finish().unwrap()` in `brigid-api/router.rs` had
> no justification, even though it's provably infallible (`finish()` only
> returns `None` for a zero `burst_size`/`period`, both non-zero literals
> right above); now says so. Everything else in both repos already carried
> a clear message or comment matching the existing convention. Log
> scrubbing: only `brigid-api` (core) and `server-leaf`'s own `main.rs` call
> `tracing::*` at all — none of it touches password/secret/master/token/
> key/credential data; `ApiError::Internal`'s logged `Display` is a fixed
> scrubbed string, not the inner error.
>
> `SECURITY.md`: `crypto`/`core`/`server-leaf` already had one, with a
> more nuanced tiered SLA (Critical 48h/7d, High 72h/30d, Medium/Low
> 7d/90d) than the checklist's single-tier wording — `web` was the only
> repo missing it; added, byte-for-byte matching the existing template.
>
> GitHub secret scanning / push protection are repo admin settings — not
> something to flip from here; see the session's final report for what's
> blocked and why.

---

## `spec/` — Finalisation

- [ ] `spec/operations.md` : procédure rotation MASTER_KEY
- [ ] `spec/operations.md` : procédure déploiement (Docker + variables d'environnement)
- [ ] `spec/audit-checklist.md` : checklist rotation key, fuzz targets, couverture, supply chain UI
- [ ] Créer issue publique "Audit tiers v0.1.0 — appel à candidature" dans `brig-id/spec`

---

## Branch protection finale

- [ ] "Require status checks" activé sur `main` dans tous les repos
  - [ ] Rust : `ci`, `security`, `coverage`
  - [ ] UI : `typecheck`, `test`, `build`, `audit`

---

## Release v0.1.0

- [ ] `CHANGELOG.md` dans `crypto`, `core`, `server-leaf`, `web`
- [ ] Tag `v0.1.0` sur `crypto`, `core`, `server-leaf`, `web`
- [ ] Docker image `brigid/leaf:0.1.0` buildée (multi-stage : UI + Rust)
- [ ] Image poussée sur ghcr.io
- [ ] SBOM archivé comme artefact GitHub Release (CycloneDX JSON)

---

## Vérification finale

- [ ] `cargo test --workspace` → 100% pass (crypto + core + server-leaf)
- [ ] `cargo llvm-cov` → crypto ≥ 98%, core ≥ 95%, server-leaf ≥ 80%
- [ ] `cargo audit` → zéro advisory (les 3 repos Rust)
- [ ] `cargo deny check` → zéro violation
- [ ] `cargo clippy -- -D warnings` → zéro warning
- [ ] `pnpm audit` → zéro advisory (web)
- [ ] `pnpm build && pnpm test` → pass
- [ ] Fuzzing CI : aucun crash connu
- [ ] SBOM générés et archivés
- [ ] Docker image `brigid/leaf:0.1.0` fonctionnelle (flux E2E)
- [ ] Tags v0.1.0 présents sur les 4 repos
- [ ] `spec/` consultable publiquement
