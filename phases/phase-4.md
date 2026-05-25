# Phase 4 — `brig-id/core` : WebAuthn

**Repo :** `brig-id/core`
**Prérequis :** Phase 3 terminée
**Crate :** `brigid-webauthn`
**Statut :** ✅ Complète — commit `03e6b5e` sur `core/dev`

---

## Crate `brigid-webauthn`

### Dépendances
- [x] `webauthn-rs = "0.5"` (features: danger-allow-state-serialisation)
- [x] `brigid-store` (workspace dep) — stockage credentials chiffré via EncryptedStore
- [x] `brigid-crypto` (workspace dep) — clé maître
- [x] `brigid-identity` (workspace dep)
- [x] `serde` + `serde_json`
- [x] `url` — origin validation
- [x] `uuid`
- [x] `thiserror`

## Flux Registration (passkey)

- [x] `begin_registration(user_id, username) -> (CreationChallengeResponse, PasskeyRegistration)`
  - [x] RP ID = domaine du serveur (configuré dans WebauthnService::new)
  - [x] Challenge aléatoire généré par webauthn-rs
  - [x] Algorithmes acceptés : ES256, RS256 (pas de password)
- [x] `finish_registration(state, response) -> Passkey`
  - [x] Valider réponse du client (webauthn-rs)
  - [x] Retourner Passkey prête à stocker

## Flux Authentication (passkey)

- [x] `begin_authentication(credentials) -> (RequestChallengeResponse, PasskeyAuthentication)`
  - [x] Retourne Err(NoCredentials) si slice vide
  - [x] Challenge aléatoire 32 bytes
- [x] `finish_authentication(credentials, state, response) -> AuthResult`
  - [x] Valider réponse (webauthn-rs)
  - [x] Mettre à jour compteur de signature in-place (credential_updated flag)
  - [x] Retourner `AuthResult { credential_id, credential_updated }`

## Sécurité spécifique WebAuthn

- [x] RP ID strict : aucun wildcard (configuré via WebauthnBuilder)
- [x] Origin validée par webauthn-rs contre le RP origin
- [x] Compteur de signature vérifié (update_credential → credential_updated)
- [x] Credentials stockées chiffrées via brigid-store EncryptedStore — jamais en clair
- [x] From<WebauthnError> for Error — pas de closures non couvertes

## Store helpers

- [x] `store_passkey(store, user_id, passkey) -> Result<Credential>` — sérialise + chiffre
- [x] `load_passkeys(store, user_id) -> Result<Vec<Passkey>>` — déchiffre + désérialise

## Tests

- [x] Test registration + authentication round-trip (webauthn-authenticator-rs SoftPasskey)
- [x] Test authentication avec slice vide → Err(NoCredentials)
- [x] Test mauvais RP ID → Err (new_rejects_invalid_rp_id)
- [x] Test finish_registration avec mauvais état → Err (From<WebauthnError> couvert)
- [x] Test finish_authentication avec mauvais état → Err
- [x] Integration test store_passkey + load_passkeys avec EncryptedStore in-memory
- [x] 100% coverage lignes (TOTAL workspace : 841 lignes, 0 manquées)

### Dépendances ajoutées à deny.toml
- [x] MPL-2.0 ajouté (webauthn-rs, webauthn-rs-core, webauthn-rs-proto, webauthn-attestation-ca, base64urlsafedata)
- [x] RUSTSEC-2023-0071 ignoré (rsa via sqlx-macros-core, pas de fix disponible, SQLite only)

---

## Vérification finale

- [x] `cargo test -p brigid-webauthn` — 6/6 tests passent
- [x] `cargo llvm-cov --workspace --summary-only` → 841 lines, 0 missed (100%)
- [x] `cargo clippy --all-targets --all-features -- -D warnings` clean
- [x] `cargo fmt --all --check` clean
- [x] `cargo deny check` — advisories ok, bans ok, licenses ok, sources ok
- [x] `cargo audit --ignore RUSTSEC-2023-0071` — exit 0
- [x] Aucun credential en clair dans les logs ou erreurs
