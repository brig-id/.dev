# Phase 6 — `brig-id/core` : API Axum + UI Leptos

**Repo :** `brig-id/core`
**Prérequis :** Phase 5 terminée
**Crates :** `brigid-api`, `brigid-ui`

---

## Crate `brigid-api` (Axum)

### Dépendances
- [ ] `axum` (features: macros, ws si besoin)
- [ ] `tower` + `tower-http` (cors, trace, compression)
- [ ] `tower-governor` — rate limiting par IP
- [ ] `tokio` (full)
- [ ] `rustls` + `axum-server` (TLS — **pas d'OpenSSL**)
- [ ] `brigid-webauthn`, `brigid-oidc`, `brigid-identity`, `brigid-store` (workspace deps)
- [ ] `serde` + `serde_json`
- [ ] `tracing` + `tracing-subscriber`
- [ ] `thiserror` + `axum::response::IntoResponse` pour erreurs HTTP

### Routes

#### Health
- [ ] `GET /health` → 200 OK `{ "status": "ok" }`
- [ ] `GET /ready` → 200 si DB accessible, 503 sinon

#### Discovery
- [ ] `GET /.well-known/openid-configuration` → `OpenIDConfiguration` JSON
- [ ] `GET /.well-known/jwks.json` → `JWKSet` JSON
- [ ] `GET /.well-known/did.json` → `DIDWebDocument` JSON (pour le serveur lui-même)

#### Auth WebAuthn
- [ ] `POST /auth/register/begin` → `CreationChallenge` JSON (body: `{ username }`)
- [ ] `POST /auth/register/finish` → 200 ou erreur (body: réponse WebAuthn client)
- [ ] `POST /auth/login/begin` → `RequestChallenge` JSON (body: `{ username }`)
- [ ] `POST /auth/login/finish` → `{ id_token }` ou erreur

#### Session
- [ ] `POST /auth/logout` — invalider session
- [ ] Middleware : valider session chiffrée sur routes protégées

### Sécurité middleware
- [ ] Rate limiting : 20 req/min par IP sur `/auth/*`
- [ ] CORS : origines strictement configurées (pas de wildcard `*`)
- [ ] Validation de toutes les entrées (serde + validators)
- [ ] Headers sécurité : `X-Content-Type-Options`, `X-Frame-Options`, `Strict-Transport-Security`
- [ ] `Content-Security-Policy` : `default-src 'self'`, interdire `unsafe-inline`, nonce-based pour les scripts Leptos hydration — empêche le vol de tokens par XSS
- [ ] TLS 1.3 minimum obligatoire (configurer rustls avec `ServerConfig::builder_with_protocol_versions(&[&TLS13])`)
- [ ] TLS uniquement via rustls (pas d'OpenSSL en dépendance)
- [ ] Logs structurés tracing — jamais de données sensibles loggées

### Tests
- [ ] Integration tests avec `axum::test` (tower::ServiceExt)
- [ ] Test : `/health` → 200
- [ ] Test : `.well-known/openid-configuration` → JSON valide
- [ ] Test : flow register begin/finish complet (mock WebAuthn)
- [ ] Test : flow login begin/finish complet
- [ ] Test : rate limit déclenché après 20 req
- [ ] Test : CORS refuse origin non autorisée
- [ ] 100% coverage sur les routes

---

## Crate `brigid-ui` (Leptos SSR)

### Dépendances
- [ ] `leptos` (features: `ssr` côté serveur, `hydrate` côté client — `csr` n'existe pas dans Leptos)
- [ ] `leptos_axum` — intégration Axum
- [ ] `brigid-api` (workspace dep) — partage les routes
- [ ] `serde` + `serde_json`
- [ ] Tailwind CSS (via build script ou plugin)
- [ ] Tabler Icons (via cargo ou assets statiques)

### Pages
- [ ] `/` → redirect vers `/login`
- [ ] `/login` — login page
  - [ ] Input username (`username@server`)
  - [ ] Bouton "Se connecter avec une passkey"
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
- [ ] Tests composants Leptos (unit)
- [ ] Test SSR : rendu HTML valide
- [ ] Test : formulaire login — validation username

---

## Vérification finale

- [ ] `cargo test --workspace` passe
- [ ] `cargo llvm-cov --workspace --summary-only` → 100% sur brigid-api
- [ ] `cargo clippy -- -D warnings` clean
- [ ] Lancer le serveur en local : `cargo run -p brigid-api`
- [ ] `curl localhost:8080/health` → 200
- [ ] `curl localhost:8080/.well-known/openid-configuration` → JSON valide
- [ ] Ouvrir `http://localhost:8080/login` dans le browser → page Leptos chargée
