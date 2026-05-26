# Phase 6 — `brig-id/core` : API Axum + UI Leptos

**Repo :** `brig-id/core`
**Prérequis :** Phase 5 terminée
**Crates :** `brigid-api`, `brigid-ui`

---

## Crate `brigid-api` (Axum)

### Dépendances
- [x] `axum` (features: macros, ws si besoin)
- [x] `tower` + `tower-http` (cors, trace, compression)
- [x] `tower-governor` — rate limiting par IP
- [x] `tokio` (full)
- [ ] `rustls` + `axum-server` (TLS — **pas d'OpenSSL**) — phase 7
- [x] `brigid-webauthn`, `brigid-oidc`, `brigid-identity`, `brigid-store` (workspace deps)
- [x] `serde` + `serde_json`
- [x] `tracing` + `tracing-subscriber`
- [x] `thiserror` + `axum::response::IntoResponse` pour erreurs HTTP

### Routes

#### Health
- [x] `GET /health` → 200 OK `{ "status": "ok" }`
- [x] `GET /ready` → 200 si DB accessible, 503 sinon

#### Discovery
- [x] `GET /.well-known/openid-configuration` → `OpenIDConfiguration` JSON
- [x] `GET /.well-known/jwks.json` → `JWKSet` JSON
- [x] `GET /.well-known/did.json` → `DIDWebDocument` JSON (pour le serveur lui-même)

#### Auth WebAuthn
- [x] `POST /auth/register/begin` → `CreationChallenge` JSON (body: `{ username }`)
- [x] `POST /auth/register/finish` → 200 ou erreur (body: réponse WebAuthn client)
- [x] `POST /auth/login/begin` → `RequestChallenge` JSON (body: `{ username }`)
- [x] `POST /auth/login/finish` → `{ id_token }` ou erreur

#### Session
- [x] `POST /auth/logout` — blackliste le JTI du Bearer token (invalide le token)
- [x] Middleware `AuthenticatedClaims` : valide Bearer token sur routes protégées

### Sécurité middleware
- [x] Rate limiting : 20 req/min par IP sur `/auth/*`
- [x] CORS : origines strictement configurées (pas de wildcard `*`)
- [x] Validation de toutes les entrées (serde + validators)
- [x] Headers sécurité : `X-Content-Type-Options`, `X-Frame-Options`, `Strict-Transport-Security`
- [x] `Content-Security-Policy` : `default-src 'self'`, interdire `unsafe-inline`
- [ ] TLS 1.3 minimum obligatoire — phase 7
- [ ] TLS uniquement via rustls — phase 7
- [x] Logs structurés tracing — jamais de données sensibles loggées

### Tests
- [x] Integration tests avec `axum::test` (tower::ServiceExt)
- [x] Test : `/health` → 200
- [x] Test : `.well-known/openid-configuration` → JSON valide
- [x] Test : flow register begin/finish complet (SoftPasskey roundtrip)
- [x] Test : flow login begin/finish complet
- [x] Test : rate limit déclenché après 20 req (burst 20, X-Forwarded-For)
- [x] Test : CORS refuse origin non autorisée
- [x] Test : CORS accepte origin configurée
- [x] Test : logout sans token → 401
- [x] Test : logout blackliste le token (deuxième logout → 401)
- [x] 17 integration tests passent, couverture 95.60% lignes

---

## Crate `brigid-ui` (Leptos SSR)

### Dépendances
- [x] `leptos` (features: `ssr` côté serveur)
- [ ] `leptos_axum` — intégration Axum (future)
- [x] `brigid-api` (workspace dep) — partage les routes
- [x] `serde` + `serde_json`
- [ ] Tailwind CSS — future
- [ ] Tabler Icons — future

### Pages
- [ ] `/` → redirect vers `/login`
- [x] `/login` — skeleton page SSR (Leptos 0.8 Owner::new API)
  - [x] Input username (`username@server`)
  - [x] Bouton "Se connecter avec une passkey"
  - [ ] Appel WebAuthn côté client (JS interop via Leptos)
  - [ ] Gestion erreur (mauvais username, passkey échouée)
- [ ] `/passkeys` — gestion des passkeys (protégée, session requise)
  - [ ] Liste des passkeys enregistrées
  - [ ] Bouton "Ajouter une passkey"
  - [ ] Bouton "Supprimer"

### Composants
- [ ] `Button` — variants primary/secondary/danger
- [ ] `Input` — avec label et message d'erreur
- [ ] `Alert` — variants info/success/error
- [ ] `Card` — container visuel
- [ ] `PasskeyList` — liste des credentials

### Style
- [ ] Tailwind config : thème brig·id (couleurs, typo)
- [ ] Dark mode supporté
- [ ] Accessible (ARIA labels, focus visible)
- [ ] Responsive (mobile-first)

### Tests
- [x] Test SSR : rendu HTML valide (login page contains expected elements)
- [ ] Tests composants Leptos (unit)
- [ ] Test : formulaire login — validation username

---

## Vérification finale

- [x] `cargo test --workspace` passe (13 tests + unit tests)
- [x] `cargo llvm-cov --workspace --summary-only` → 94.78% regions, 97.26% lignes
- [x] `cargo clippy -- -D warnings` clean
- [ ] Lancer le serveur en local : `cargo run -p brigid-api` — phase 7
- [ ] `curl localhost:8080/health` → 200 — phase 7
- [ ] `curl localhost:8080/.well-known/openid-configuration` → JSON valide — phase 7
- [ ] Ouvrir `http://localhost:8080/login` dans le browser → page Leptos chargée — phase 7
