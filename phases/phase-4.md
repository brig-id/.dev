# Phase 4 — Release v0.1.0

**Repos :** `crypto`, `core`, `server-leaf`, `web`, `spec`
**Prérequis :** Phase 3 terminée (E2E validé, Docker fonctionnel)
**Objectif :** Tag v0.1.0 propre, pre-audit ready, déployable en production.

> **Note v2 :** Version bumped 0.0.1 → 0.1.0 pour refléter l'UI complète
> et l'intégration E2E validée (scope plus large que le v1 initial).

---

## Rotation MASTER_KEY (`server-leaf`)

- [ ] Sous-commande CLI : `leaf rotate-key --old <path> --new <path>`
  - [ ] Charger l'ancienne et la nouvelle clé depuis des fichiers hex séparés
  - [ ] Pour chaque credential chiffrée en DB : déchiffrer avec OLD, rechiffrer avec NEW (transactionnel)
  - [ ] En cas d'erreur partielle : rollback, DB inchangée
  - [ ] Après rotation : vérifier que l'ancienne clé ne peut plus déchiffrer
- [ ] Test : rotation round-trip → données accessibles avec la nouvelle clé
- [ ] Test : déchiffrement avec l'ancienne clé après rotation → erreur

---

## Fuzz targets (`core`)

- [ ] `fuzz_parse_identifier` — entrées aléatoires dans `RootId::parse` (must not panic)
- [ ] `fuzz_did_web_resolve` — parsing de DIDs aléatoires (must not panic)
- [ ] `fuzz_jwt_validate` — JWTs aléatoires dans `validate_token` (must not panic)
- [ ] Ajouter les 3 targets au CI `core` (nightly, 120s en CI)
- [ ] Seeds FIPS 203/204 comme corpus initiaux pour `crypto`

---

## Couverture & Badges

- [ ] Codecov configuré pour `crypto`, `core`, `server-leaf`
  - [ ] Token dans GitHub Secrets de chaque repo
  - [ ] Upload automatique en CI
- [ ] Badge coverage dans chaque `README.md`
- [ ] Seuils : `crypto` ≥ 98%, `core` ≥ 95%, `server-leaf` ≥ 80%

---

## Finalisation sécurité

- [ ] Revue finale `unwrap()` / `expect()` dans `core` et `server-leaf` — tous justifiés ou remplacés
- [ ] Vérifier : aucune donnée sensible dans les logs tracing (grep `password|secret|key|token`)
- [ ] Activer GitHub secret scanning sur tous les repos
- [ ] Activer GitHub push protection
- [ ] `SECURITY.md` : SLA de réponse (48h ack, 90j remediation) dans chaque repo

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
