# Phase 4 — `brig-id/core` : WebAuthn

**Repo :** `brig-id/core`
**Prérequis :** Phase 3 terminée
**Crate :** `brigid-webauthn`

---

## Crate `brigid-webauthn`

### Dépendances
- [ ] `webauthn-rs` (features: danger-allow-state-serialisation si tests, attestation)
- [ ] `brigid-store` (workspace dep) — stockage credentials chiffré
- [ ] `brigid-crypto` (git dep) — chiffrement credentials
- [ ] `brigid-identity` (workspace dep) — RootId
- [ ] `serde` + `serde_json`
- [ ] `url` — origin validation
- [ ] `uuid`
- [ ] `thiserror`

## Flux Registration (passkey)

- [ ] `begin_registration(user: &RootId, rp_id: &str, rp_origin: &Url) -> (CreationChallenge, RegistrationState)`
  - [ ] RP ID = domaine du serveur Leaf
  - [ ] Challenge aléatoire 32 bytes
  - [ ] Algorithmes acceptés : ES256, RS256 (pas de password)
  - [ ] `RegistrationState` sérialisé et stocké en session (chiffré)
- [ ] `finish_registration(state, response, pool, master_key) -> StoredCredential`
  - [ ] Valider réponse du client (webauthn-rs)
  - [ ] Stocker credential chiffrée via `brigid-store`
  - [ ] Retourner credential confirmée

## Flux Authentication (passkey)

- [ ] `begin_authentication(user: &RootId, pool, master_key) -> (RequestChallenge, AuthState)`
  - [ ] Charger credentials depuis store (déchiffrées en mémoire)
  - [ ] Challenge aléatoire 32 bytes
  - [ ] `AuthState` stocké en session chiffré
- [ ] `finish_authentication(state, response, pool, master_key) -> AuthResult`
  - [ ] Valider réponse (webauthn-rs)
  - [ ] Mettre à jour compteur de signature en DB
  - [ ] Retourner `AuthResult { user_id, credential_id }`

## Sécurité spécifique WebAuthn

- [ ] RP ID strict : aucun wildcard
- [ ] Origin validée contre liste d'origins autorisées (config)
- [ ] Compteur de signature vérifié (protection contre clonage de credentials)
- [ ] Credentials stockées chiffrées — jamais en clair en DB
- [ ] Challenge à usage unique — invalidé après vérification

## Tests

- [ ] Test registration flow complet (mock client webauthn-rs)
- [ ] Test authentication flow complet
- [ ] Test : counter clone detection (counter régression → Err)
- [ ] Test : challenge replay → Err
- [ ] Test : mauvais RP ID → Err
- [ ] Test : credential dump DB → chiffrée (illisible)
- [ ] Integration test avec brigid-store in-memory
- [ ] 100% coverage

---

## Vérification finale

- [ ] `cargo test -p brigid-webauthn` passe 100%
- [ ] `cargo llvm-cov -p brigid-webauthn --summary-only` → 100%
- [ ] `cargo clippy -- -D warnings` clean
- [ ] Aucun credential en clair dans les logs ou erreurs
