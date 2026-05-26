# Phase 8 — Audit Readiness

**Repos :** `crypto`, `core`, `server-leaf`, `spec`
**Prérequis :** Phase 7 terminée (serveur Leaf déployable)
**Objectif :** Préparer le code à un audit tiers professionnel avant la v0.1.0

---

## Fuzzing CI continu (`brig-id/crypto`)

- [x] Configurer `cargo-fuzz` en CI nightly (GitHub Actions)
  - [x] Job `fuzz` déclenché sur push + schedule quotidien
  - [x] Timeout : 300s par target en CI
  - [x] Corpus stocké dans cache GitHub Actions (par target + sha)
- [x] Targets fuzz complètes :
  - [x] `fuzz_decrypt` — AES-GCM
  - [x] `fuzz_hkdf_derive`
  - [x] `fuzz_hybrid_decapsulate` — ML-KEM+X25519
  - [x] `fuzz_hybrid_verify` — ML-DSA+Ed25519
  - [ ] `fuzz_parse_identifier` — parsing identifiants (dans `core/brigid-identity`)
  - [ ] `fuzz_did_web_resolve` — parsing DID:web (dans `core/brigid-did`)
  - [ ] `fuzz_jwt_validate` — validation JWT (dans `core/brigid-oidc`)
- [x] Aucun crash non géré → `panic = "abort"` en release
- [ ] Corpus de seeds : vecteurs FIPS 203/204 comme corpus initiaux

## SBOM (Software Bill of Materials)

- [x] `cargo-cyclonedx` configuré en CI pour chaque repo (workflow réutilisable `sbom.yml`)
- [x] Générer SBOM en format CycloneDX JSON
- [x] Uploader SBOM comme artefact CI à chaque release
- [ ] Vérifier : aucune dépendance avec advisory actif (`cargo audit`)
- [x] Vérifier : toutes licences compatibles MIT/Apache-2.0 (`cargo deny`)

## Rapport de couverture public

- [ ] Configurer Codecov (ou alternative) pour les 3 repos actifs
- [ ] Badge coverage dans chaque README
- [ ] Objectif : ≥ 95% lignes couvertes (100% sur crypto)
- [ ] Rapport consultable publiquement (audit tiers)

## `brig-id/spec` — Documentation technique publique

- [x] `spec/security-model.md` — modèle de menaces (threat model)
  - [x] Acteurs, vecteurs d'attaque, mitigations
  - [x] Hypothèses de sécurité (MASTER_KEY hors DB, TLS obligatoire, etc.)
- [x] `spec/protocol.md` — protocoles utilisés
  - [x] Flux WebAuthn détaillé
  - [x] Flux OIDC complet
  - [x] Flux logout (§8)
  - [x] Calcul VSID (formule, propriétés)
  - [x] Cryptographie : algos, tailles de clés, durées de vie
- [x] `spec/pqc.md` — justification PQC
  - [x] Choix ML-KEM-768 + X25519 (niveau sécurité, FIPS)
  - [x] Choix ML-DSA-65 + Ed25519
  - [x] Plan migration pure PQC (post-standardisation)
- [x] `spec/audit-checklist.md` — checklist pour auditeurs tiers
  - [x] Points critiques à vérifier (incl. logout/blacklist, déploiement leaf)
  - [x] Vecteurs d'attaque à tester
  - [x] Contacts + processus CVD
- [x] `spec/operations.md` — procédures opérationnelles

## Processus CVD (Coordinated Vulnerability Disclosure)

- [x] `SECURITY.md` complet dans chaque repo actif
  - [x] GitHub Security Advisories activé (via GitHub Settings)
  - [x] Email de contact sécurisé (ou clé GPG publique)
  - [ ] SLA de réponse (ex: 48h ack, 90j remediation) — à formaliser dans SECURITY.md
- [ ] GitHub secret scanning activé sur tous les repos (Settings → Security)
- [x] Dependabot activé sur tous les repos (`.github/dependabot.yml` ajouté)
- [x] `cargo deny` bloque les advisories en CI

## Revue code sécurité interne

- [ ] Revue de toutes les manipulations de secrets (pas de log, zeroize)
- [ ] Revue de tous les `unwrap()` / `expect()` (remplacer par erreurs typées)
- [ ] Revue des inputs utilisateur (validation stricte avant traitement)
- [ ] Revue CORS + rate limiting
- [ ] Vérifier : TLS partout, pas de connexion plaintext
- [ ] Vérifier : aucune dépendance OpenSSL dans l'arbre de dépendances

## Procédure de rotation MASTER_KEY

- [ ] Documenter la procédure dans `spec/operations.md` :
  1. Générer une nouvelle `MASTER_KEY_NEW` (32 bytes hex)
  2. Charger les deux clés simultanément (`BRIGID_MASTER_KEY` + `BRIGID_MASTER_KEY_OLD`)
  3. Pour chaque entrée chiffrée en DB : déchiffrer avec OLD, rechiffrer avec NEW
  4. Supprimer `BRIGID_MASTER_KEY_OLD` de l'env
- [ ] Implémenter `leaf rotate-key --old <path> --new <path>` comme sous-commande CLI
- [ ] Test : rotation round-trip → données accessibles après rotation, inaccessibles avec l'ancienne clé

## Préparation audit tiers

- [ ] Contacter ≥ 2 sociétés d'audit (Trail of Bits, Quarkslab, Cure53, etc.)
- [ ] Préparer le dossier : scope, accès repos, spec/, couverture tests, SBOM
- [ ] `spec/audit-checklist.md` finalisé et accessible publiquement
- [ ] Créer issue publique "Audit tiers — appel à candidature" dans spec

---

## Vérification finale (release 0.0.1)

- [ ] `cargo test --workspace` sur crypto + core + server-leaf → 100% pass
- [ ] `cargo llvm-cov` → ≥ 95% (100% sur crypto)
- [ ] `cargo audit` → zéro advisory
- [ ] `cargo deny check` → zéro violation
- [ ] `cargo clippy -- -D warnings` → zéro warning
- [ ] Fuzzing CI : aucun crash connu
- [ ] SBOM générés et archivés
- [ ] `spec/` : security-model.md, protocol.md, pqc.md, audit-checklist.md publiés
- [ ] GitHub Security Advisories activé sur tous les repos
- [ ] Dependabot activé sur tous les repos
- [ ] Déploiement Leaf fonctionnel end-to-end
- [ ] Tag `v0.0.1` créé sur server-leaf + core + crypto
