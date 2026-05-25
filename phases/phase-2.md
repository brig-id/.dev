# Phase 2 — `brig-id/core` : Storage & DID

**Repo :** `brig-id/core`
**Prérequis :** Phase 1 terminée (brigid-crypto publiée ou accessible via git dep)
**Parallèle avec :** Phase 1

---

## Initialisation workspace

- [x] `Cargo.toml` workspace à la racine de `core/`
- [x] Structure `crates/` : brigid-store, brigid-did
- [x] `.cargo/config.toml` : linker mold, `brigid-crypto` via git dep
- [x] `deny.toml` : configurer licences (MIT/Apache-2.0) + advisories (partagé par tout le workspace)
- [x] Caller workflows CI, security, coverage (appels reusable .github)

## Crate `brigid-store`

### Dépendances

- [x] `sqlx` (features: sqlite, runtime-tokio-rustls, migrate, macros)
- [x] `tokio` (full)
- [x] `brigid-crypto` (git dep → Phase 1)
- [x] `uuid` — identifiants uniques
- [x] `time` — timestamps

### Schema SQLite (migrations sqlx)

- [x] `migrations/0001_users.sql` — table users (id, username, server, did_web, created_at)
- [x] `migrations/0002_credentials.sql` — table webauthn_credentials (chiffrée)
- [x] `migrations/0003_sessions.sql` — table sessions (token_hash, user_id, expires_at)

### Zero-trust encryption layer

- [x] `EncryptedStore` — wrappeur : toute donnée sensible chiffrée avant INSERT
- [x] `store_user(pool, master_key, user)` — dérive user_key via HKDF, chiffre et stocke
- [x] `fetch_user(pool, master_key, user_id)` — déchiffre à la lecture
- [x] `store_credential(pool, master_key, cred)` — stocke credential WebAuthn chiffrée
- [x] `fetch_credentials(pool, master_key, user_id)` — déchiffre credentials
- [x] Jamais de donnée sensible en clair dans la DB (vérifiable par dump SQLite)

### Tests

- [x] Tests avec SQLite in-memory (`sqlx::test`)
- [x] Test round-trip : store → fetch → égalité
- [x] Test : dump de la DB ne contient aucun texte sensible clair
- [x] 100% coverage

## Crate `brigid-did`

### Dépendances

- [x] `serde` + `serde_json` — DID documents
- [x] `reqwest` (rustls-tls) — résolution DID:web distant
- [x] `url` — validation d'URL
- [x] `time` — validité temporelle

### DID:web

- [x] `DIDWebDocument` — structure serde du document DID:web
- [x] `resolve_did_web(did) -> DIDWebDocument` — fetch `.well-known/did.json`
- [x] `build_did_web(username, server) -> DID` — `did:web:server:u:username`
- [x] `did_web_to_url(did) -> Url` — mapping vers `.well-known/did.json`

### DID:peer

- [x] `generate_did_peer(public_key) -> DID` — `did:peer:2.<encoded_key>`
- [x] `resolve_did_peer(did) -> PublicKey` — extraction clé depuis DID:peer

### Handler `.well-known/did.json`

- [x] `did_document_handler(username, server, vk) -> Json<DIDWebDocument>`
- [x] Structure conforme DID Core spec (verificationMethod, authentication)

### Tests

- [x] Test build/parse DID:web round-trip
- [x] Test génération DID:peer
- [x] Test handler : réponse JSON valide conforme DID Core
- [x] Mock reqwest pour resolve_did_web
- [x] 100% coverage

---

## Vérification finale

- [x] `cargo test --workspace` passe 100% (27 tests)
- [x] `cargo llvm-cov --workspace --summary-only` → 100% (417 lignes, 0 manquée)
- [x] `cargo audit` clean
- [x] `cargo deny check` clean
- [x] `cargo clippy -- -D warnings` clean
- [x] Dump SQLite de test : aucune donnée sensible en clair lisible
