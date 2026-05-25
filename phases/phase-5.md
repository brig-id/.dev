# Phase 5 — `brig-id/core` : OIDC

**Repo :** `brig-id/core`
**Prérequis :** Phase 3 + Phase 4 terminées
**Crate :** `brigid-oidc`
**Commit :** `9cfa632` (branch `dev`)
**Status :** ✅ Complete

---

## Crate `brigid-oidc`

### Dépendances
- [x] `jsonwebtoken` v9 — JWT signing/verification (EdDSA/Ed25519 via ring)
- [x] `brigid-identity` (workspace dep) — VSID
- [x] `serde` + `serde_json`
- [x] `url`
- [x] `uuid` — jti (JWT ID, anti-replay)
- [x] `thiserror`
- [x] `ed25519-dalek` (with pkcs8 feature) — key generation + PKCS8 DER encoding
- [x] `base64ct` — base64url encoding for JWKS

## Clés de signature JWT

- [x] Clé de signing : Ed25519 (classique, compatible OIDC actuel)
- [x] Rotation de clés : support JWKS avec kid
- [x] `JWKSet` exposé via `.well-known/jwks.json`
- [x] `OidcSigningKey::to_raw_bytes` / `from_raw_bytes` pour stockage chiffré par l'appelant

## Token OIDC (ID Token)

- [x] Claims obligatoires :
  - [x] `sub` = VSID (stable par service)
  - [x] `iss` = `https://<server>`
  - [x] `aud` = client_id
  - [x] `exp` = now + ttl_secs (configurable)
  - [x] `iat` = now
  - [x] `jti` = uuid v4 (anti-replay)
- [x] Claims brig·id custom :
  - [x] `did` = DID:web root
  - [x] `server` = serveur root
  - [x] `alias_type` = `"public"` (0.0.1, pas d'alias privés encore)
- [x] `issue_token(params: &IssuanceParams, key, now_unix) -> Result<String>`

## Endpoints `.well-known`

- [x] `OpenIDConfiguration` — struct serde conforme OpenID Connect Discovery 1.0
  - [x] `issuer`, `authorization_endpoint`, `token_endpoint`, `jwks_uri`
  - [x] `response_types_supported`, `subject_types_supported`, `id_token_signing_alg_values_supported`
- [x] `build_openid_configuration(base_url) -> OpenIDConfiguration`
- [x] `build_jwks(keys) -> JwkSet`

## Validation de token (pour ressources protégées)

- [x] `validate_token(jwt, expected_issuer, expected_aud, key, jti_store) -> Result<Claims>`
  - [x] Vérifier signature
  - [x] Vérifier exp, iss, aud
  - [x] Vérifier jti pas déjà utilisé (replay protection)
  - [x] `JtiStore` : taille bornée, evict à l'expiration (pas de croissance infinie)

## Tests

- [x] Test issue + validate round-trip
- [x] Test : token expiré → `Err(Expired)`
- [x] Test : mauvais aud → `Err(InvalidAudience)`
- [x] Test : jti replay → `Err(JtiReplay)`
- [x] Test : `sub` = VSID (pas username, pas DID brut)
- [x] Test : `.well-known` JSON valide (schema check)
- [x] Test : JWKS contient la bonne clé publique
- [x] Test : signature invalide → `Err(Jwt(...))`
- [x] Test : JtiStore eviction (expired entries réutilisables)
- [x] Test : `OidcSigningKey` round-trip from raw bytes
- [x] 100% line coverage, 100% function coverage

---

## Vérification finale

- [x] `cargo test -p brigid-oidc` → 15 passed, 0 failed
- [x] `cargo llvm-cov --workspace --summary-only` → 1150 lines, 0 missed (100%)
- [x] `cargo clippy --all-targets --all-features -- -D warnings` clean
- [x] `cargo fmt --all --check` clean
- [x] `cargo deny check` ok (ring MPL-2.0 via jsonwebtoken transitif)
- [x] `cargo audit --ignore RUSTSEC-2023-0071` exit 0
- [x] `sub` ne contient jamais username, alias ou DID brut (testé explicitement)
