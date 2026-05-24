# Phase 8 — Audit Readiness

**Repos :** `crypto`, `core`, `server-leaf`, `spec`
**Prérequis :** Phase 7 terminée (serveur Leaf déployable)
**Objectif :** Préparer le code à un audit tiers professionnel avant la v0.1.0

---

## Fuzzing CI continu (`brig-id/crypto`)

- [ ] Configurer `cargo-fuzz` en CI nightly (GitHub Actions)
  - [ ] Job `fuzz` déclenché sur push + schedule quotidien
  - [ ] Timeout : 300s par target en CI
  - [ ] Corpus stocké dans `.fuzz/corpus/` (versionné)
- [ ] Targets fuzz complètes :
  - [ ] `fuzz_decrypt` — AES-GCM
  - [ ] `fuzz_hkdf_derive`
  - [ ] `fuzz_hybrid_decapsulate` — ML-KEM+X25519
  - [ ] `fuzz_hybrid_verify` — ML-DSA+Ed25519
  - [ ] `fuzz_parse_identifier` — parsing identifiants
  - [ ] `fuzz_did_web_resolve` — parsing DID:web
  - [ ] `fuzz_jwt_validate` — validation JWT
- [ ] Aucun crash non géré → `panic = "abort"` en release
- [ ] Corpus de seeds : vecteurs FIPS 203/204 comme corpus initiaux

## SBOM (Software Bill of Materials)

- [ ] `cargo-cyclonedx` configuré en CI pour chaque repo
- [ ] Générer SBOM en format CycloneDX JSON
- [ ] Uploader SBOM comme artefact CI à chaque release
- [ ] Vérifier : aucune dépendance avec advisory actif (`cargo audit`)
- [ ] Vérifier : toutes licences compatibles MIT/Apache-2.0 (`cargo deny`)

## Rapport de couverture public

- [ ] Configurer Codecov (ou alternative) pour les 3 repos actifs
- [ ] Badge coverage dans chaque README
- [ ] Objectif : ≥ 95% lignes couvertes (100% sur crypto)
- [ ] Rapport consultable publiquement (audit tiers)

## `brig-id/spec` — Documentation technique publique

- [ ] `spec/security-model.md` — modèle de menaces (threat model)
  - [ ] Acteurs, vecteurs d'attaque, mitigations
  - [ ] Hypothèses de sécurité (MASTER_KEY hors DB, TLS obligatoire, etc.)
- [ ] `spec/protocol.md` — protocoles utilisés
  - [ ] Flux WebAuthn détaillé
  - [ ] Flux OIDC complet
  - [ ] Calcul VSID (formule, propriétés)
  - [ ] Cryptographie : algos, tailles de clés, durées de vie
- [ ] `spec/pqc.md` — justification PQC
  - [ ] Choix ML-KEM-768 + X25519 (niveau sécurité, FIPS)
  - [ ] Choix ML-DSA-65 + Ed25519
  - [ ] Plan migration pure PQC (post-standardisation)
- [ ] `spec/audit-checklist.md` — checklist pour auditeurs tiers
  - [ ] Points critiques à vérifier
  - [ ] Vecteurs d'attaque à tester
  - [ ] Contacts + processus CVD

## Processus CVD (Coordinated Vulnerability Disclosure)

- [ ] `SECURITY.md` complet dans chaque repo actif
  - [ ] GitHub Security Advisories activé
  - [ ] Email de contact sécurisé (ou clé GPG publique)
  - [ ] SLA de réponse (ex: 48h ack, 90j remediation)
- [ ] GitHub secret scanning activé sur tous les repos
- [ ] Dependabot activé sur tous les repos (mises à jour auto)
- [ ] `cargo deny` bloque les advisories en CI

## Revue code sécurité interne

- [ ] Revue de toutes les manipulations de secrets (pas de log, zeroize)
- [ ] Revue de tous les `unwrap()` / `expect()` (remplacer par erreurs typées)
- [ ] Revue des inputs utilisateur (validation stricte avant traitement)
- [ ] Revue CORS + rate limiting
- [ ] Vérifier : TLS partout, pas de connexion plaintext
- [ ] Vérifier : aucune dépendance OpenSSL dans l'arbre de dépendances

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
