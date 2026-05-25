# Phase 7 — `brig-id/server-leaf` : Binary + Déploiement

**Repo :** `brig-id/server-leaf`
**Prérequis :** Phase 6 terminée
**Objectif :** Premier serveur Leaf déployable — single binary, Docker image distroless

---

## Initialisation `server-leaf`

- [ ] `Cargo.toml` workspace avec dépendances sur `core` via git dep
- [ ] Binary `leaf` dans `src/main.rs`
- [ ] Caller workflows CI, security, coverage

## Binary `leaf`

### Dépendances
- [ ] `brigid-api` (core git dep) — app Axum complète
- [ ] `brigid-store` (core git dep) — initialisation DB SQLite
- [ ] `brigid-crypto` (crypto git dep) — chargement MASTER_KEY
- [ ] `clap` — parsing CLI / config
- [ ] `figment` — config TOML + env vars (merge) — plus moderne, mieux intégré avec l'écosystème Axum
- [ ] `tokio` (full)
- [ ] `tracing-subscriber` — logs JSON en prod

### Configuration TOML

- [ ] Fichier `leaf.toml` (ou path configurable via `--config`)
  ```toml
  [server]
  host = "0.0.0.0"
  port = 8080
  domain = "example.com"      # RP ID WebAuthn + issuer OIDC
  tls_cert = "/certs/cert.pem"
  tls_key  = "/certs/key.pem"

  [database]
  path = "/data/brigid.db"

  [security]
  # BRIGID_MASTER_KEY depuis env — jamais dans ce fichier
  session_ttl_seconds = 3600
  cors_origins = ["https://example.com"]
  ```
- [ ] `BRIGID_MASTER_KEY` : uniquement depuis env var ou fichier séparé (jamais dans TOML)
- [ ] Validation config au démarrage (domaine valide, port disponible, master key présente)
- [ ] Refus de démarrer si MASTER_KEY absente ou trop courte (< 32 bytes)

### main.rs

- [ ] Charger config (TOML + env)
- [ ] Vérifier MASTER_KEY présente
- [ ] Initialiser DB SQLite (sqlx migrate run)
- [ ] Construire router Axum (brigid-api)
- [ ] Démarrer serveur TLS rustls
- [ ] Graceful shutdown (SIGTERM/SIGINT)
- [ ] Logs structurés JSON (tracing)

## Docker

### Dockerfile (multi-stage, distroless)
- [ ] Stage `builder` : `rust:latest` (ou image rust toolchain)
  - [ ] Copier workspace Cargo.toml + lock
  - [ ] Cache layers dépendances (dummy build)
  - [ ] Build release : `cargo build --release -p leaf`
- [ ] Stage final : `gcr.io/distroless/cc-debian12` (pas de shell, surface minimale)
  - [ ] Copier uniquement le binary
  - [ ] `USER nonroot:nonroot` — ne jamais tourner en root
  - [ ] `EXPOSE 8080`
  - [ ] `ENTRYPOINT ["/leaf"]`
- [ ] Image finale < 50 Mo idéalement
- [ ] `.dockerignore` : exclure target/, .git, etc.

### Docker Compose (`deploy/compose.yaml`)
- [ ] Service `leaf` : image brig-id/server-leaf, volume `/data`, env BRIGID_MASTER_KEY, `read_only: true` + tmpfs sur `/tmp` (filesystem conteneur en lecture seule)
- [ ] Service `caddy` : Caddy officiel, reverse proxy avec TLS automatique (Let's Encrypt)
  - [ ] `Caddyfile` : `example.com { reverse_proxy leaf:8080 }`
- [ ] Volume nommé `leaf-data` pour SQLite DB
- [ ] Secrets Docker pour MASTER_KEY (pas de valeur en clair dans compose.yaml)
- [ ] `compose.yaml` pour prod, `compose.dev.yaml` pour dev local (HTTP sans TLS)

## Tests E2E (smoke)

- [ ] Script `tests/e2e/smoke.sh` ou binary reqwest
- [ ] `GET /health` → 200
- [ ] `GET /.well-known/openid-configuration` → JSON valide
- [ ] `GET /.well-known/did.json` → JSON valide
- [ ] `GET /.well-known/jwks.json` → JSON valide
- [ ] Flux WebAuthn registration complet (simulé via `webauthn-rs` en mode test avec softkey)
- [ ] Flux WebAuthn authentication + token OIDC (simulé via `webauthn-rs` en mode test avec softkey)

## Tests du binary

- [ ] Test : démarrage sans MASTER_KEY → panique explicite avec message clair
- [ ] Test : démarrage avec config invalide → exit code non-zéro
- [ ] Test : graceful shutdown → DB non corrompue

---

## Vérification finale

- [ ] `cargo build --release -p leaf` → succès
- [ ] `docker build -t brigid/leaf .` → succès, taille < 50 Mo
- [ ] `docker compose -f deploy/compose.dev.yaml up` → serveur démarre
- [ ] `curl http://localhost:8080/health` → `{"status":"ok"}`
- [ ] `curl http://localhost:8080/.well-known/openid-configuration` → JSON valide
- [ ] Flux complet E2E : register passkey → login → ID token → VSID dans claims
- [ ] `docker compose down` → propre, pas de données résiduelles
- [ ] Tester avec Caddy en local : TLS fonctionne avec certificat auto-signé dev
