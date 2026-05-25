# Phase 5 — `brig-id/core` : OIDC

**Repo :** `brig-id/core`
**Prérequis :** Phase 3 + Phase 4 terminées
**Crate :** `brigid-oidc`

---

## Crate `brigid-oidc`

### Dépendances
- [ ] `jsonwebtoken` — JWT signing/verification (supporte EdDSA/Ed25519 depuis v9 ; signature ML-DSA hybride via code custom sur le header)
- [ ] `brigid-crypto` (git dep) — signing keys (Ed25519 + ML-DSA hybride)
- [ ] `brigid-identity` (workspace dep) — VSID, RootId
- [ ] `serde` + `serde_json`
- [ ] `time` — exp, iat
- [ ] `url`
- [ ] `uuid` — jti (JWT ID, anti-replay)
- [ ] `thiserror`

## Clés de signature JWT

- [ ] Clé de signing : Ed25519 (classique, compatible OIDC actuel)
- [ ] Rotation de clés : support JWKS avec kid
- [ ] `JWKSet` exposé via `.well-known/jwks.json`
- [ ] Clé privée stockée chiffrée (brigid-store + brigid-crypto)

## Token OIDC (ID Token)

- [ ] Claims obligatoires :
  - [ ] `sub` = VSID (stable par service)
  - [ ] `iss` = `https://<server>`
  - [ ] `aud` = client_id
  - [ ] `exp` = now + 1h (configurable)
  - [ ] `iat` = now
  - [ ] `jti` = uuid v4 (anti-replay)
- [ ] Claims brig·id custom :
  - [ ] `did` = DID:web root (`did:web:server:u:username`)
  - [ ] `server` = serveur root
  - [ ] `alias_type` = `"public"` (0.0.1, pas d'alias privés encore)
- [ ] `issue_token(vsid, client_id, user_did, signing_key) -> SignedJWT`

## Endpoints `.well-known`

- [ ] `OpenIDConfiguration` — struct serde conforme OpenID Connect Discovery 1.0
  - [ ] `issuer`, `authorization_endpoint`, `token_endpoint`, `jwks_uri`
  - [ ] `response_types_supported`, `subject_types_supported`, `id_token_signing_alg`
- [ ] `build_openid_configuration(base_url) -> OpenIDConfiguration`
- [ ] `build_jwks(verifying_key) -> JWKSet`

## Validation de token (pour ressources protégées)

- [ ] `validate_token(jwt, jwks, expected_aud) -> Claims`
  - [ ] Vérifier signature
  - [ ] Vérifier exp, iss, aud
  - [ ] Vérifier jti pas déjà utilisé (replay protection — store)
  - [ ] Store des jti avec TTL = durée de vie du token (`exp`) — taille bornée, evict à l'expiration (pas de croissance infinie)

## Tests

- [ ] Test issue + validate round-trip
- [ ] Test : token expiré → Err
- [ ] Test : mauvais aud → Err
- [ ] Test : jti replay → Err
- [ ] Test : `sub` = VSID (pas username, pas DID brut)
- [ ] Test : `.well-known` JSON valide (schema check)
- [ ] Test : JWKS contient la bonne clé publique
- [ ] 100% coverage

---

## Vérification finale

- [ ] `cargo test -p brigid-oidc` passe 100%
- [ ] `cargo llvm-cov -p brigid-oidc --summary-only` → 100%
- [ ] `cargo clippy -- -D warnings` clean
- [ ] `sub` ne contient jamais username, alias ou DID brut (testé explicitement)
- [ ] Valider ID Token avec outil tiers (jwt.io ou similar)
