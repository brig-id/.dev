# Phase 2 — `brig-id/core` : Storage & DID

**Repo :** `brig-id/core`
**Prérequis :** Phase 1 terminée (brigid-crypto publiée ou accessible via git dep)
**Parallèle avec :** Phase 1

---

## Initialisation workspace

- [ ] `Cargo.toml` workspace à la racine de `core/`
- [ ] Structure `crates/` : brigid-store, brigid-did
- [ ] `.cargo/config.toml` : linker mold, `brigid-crypto` via git dep
- [ ] `deny.toml` : configurer licences (MIT/Apache-2.0) + advisories (partagé par tout le workspace)
- [ ] Caller workflows CI, security, coverage (appels reusable .github)

## Crate `brigid-store`

### Dépendances
- [ ] `sqlx` (features: sqlite, runtime-tokio-rustls, migrate, macros)
- [ ] `tokio` (full)
- [ ] `brigid-crypto` (git dep → Phase 1)
- [ ] `uuid` — identifiants uniques
- [ ] `time` — timestamps

### Schema SQLite (migrations sqlx)
- [ ] `migrations/0001_users.sql` — table users (id, username, server, did_web, created_at)
- [ ] `migrations/0002_credentials.sql` — table webauthn_credentials (chiffrée)
- [ ] `migrations/0003_sessions.sql` — table sessions (token_hash, user_id, expires_at)

### Zero-trust encryption layer
- [ ] `EncryptedStore` — wrappeur : toute donnée sensible chiffrée avant INSERT
- [ ] `store_user(pool, master_key, user)` — dérive user_key via HKDF, chiffre et stocke
- [ ] `fetch_user(pool, master_key, user_id)` — déchiffre à la lecture
- [ ] `store_credential(pool, master_key, cred)` — stocke credential WebAuthn chiffrée
- [ ] `fetch_credentials(pool, master_key, user_id)` — déchiffre credentials
- [ ] Jamais de donnée sensible en clair dans la DB (vérifiable par dump SQLite)

### Tests
- [ ] Tests avec SQLite in-memory (`sqlx::test`)
- [ ] Test round-trip : store → fetch → égalité
- [ ] Test : dump de la DB ne contient aucun texte sensible clair
- [ ] 100% coverage

## Crate `brigid-did`

### Dépendances
- [ ] `serde` + `serde_json` — DID documents
- [ ] `reqwest` (rustls-tls) — résolution DID:web distant
- [ ] `url` — validation d'URL
- [ ] `time` — validité temporelle

### DID:web
- [ ] `DIDWebDocument` — structure serde du document DID:web
- [ ] `resolve_did_web(did) -> DIDWebDocument` — fetch `.well-known/did.json`
- [ ] `build_did_web(username, server) -> DID` — `did:web:server:u:username`
- [ ] `did_web_to_url(did) -> Url` — mapping vers `.well-known/did.json`

### DID:peer
- [ ] `generate_did_peer(public_key) -> DID` — `did:peer:2.<encoded_key>`
- [ ] `resolve_did_peer(did) -> PublicKey` — extraction clé depuis DID:peer

### Handler `.well-known/did.json`
- [ ] `did_document_handler(username, server, vk) -> Json<DIDWebDocument>`
- [ ] Structure conforme DID Core spec (verificationMethod, authentication)

### Tests
- [ ] Test build/parse DID:web round-trip
- [ ] Test génération DID:peer
- [ ] Test handler : réponse JSON valide conforme DID Core
- [ ] Mock reqwest pour resolve_did_web
- [ ] 100% coverage

---

## Vérification finale

- [ ] `cargo test --workspace` passe 100%
- [ ] `cargo llvm-cov --workspace --summary-only` → 100%
- [ ] `cargo audit` clean
- [ ] `cargo deny check` clean
- [ ] `cargo clippy -- -D warnings` clean
- [ ] Dump SQLite de test : aucune donnée sensible en clair lisible
