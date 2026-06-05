# Phase 3 — Intégration & Validation E2E (`server-leaf`)

**Repos :** `brig-id/core`, `brig-id/server-leaf`, `brig-id/web`
**Prérequis :** Phase 2 terminée (UI Qwik fonctionnelle)
**Objectif :** Déploiement unifié — Rust API + UI statique Qwik — validé de bout en bout.

---

## Contexte

Le binary `leaf` sert à la fois l'API `brigid-api` et les fichiers statiques Qwik.
L'UI Qwik build vers `dist/` — copié dans l'image Docker ou monté en volume.
Aucun Node.js en production.

---

## Intégration server-leaf

- [ ] Ajouter `tower-http::services::ServeDir` pour servir `ui/dist/` sur `/`
- [ ] Route fallback : toute URL non-API → `index.html` (SPA fallback)
- [ ] CSP header mis à jour : `script-src 'self'` (les assets Qwik sont sur la même origine)
- [ ] Config `leaf.toml` : champ `ui_dist_dir` (chemin vers le dossier de build UI)
- [ ] Test : `GET /login` → HTML 200 avec `Content-Type: text/html`
- [ ] Test : `GET /assets/q-*.js` → 200, `Content-Type: application/javascript`

---

## Route manquante : `GET /auth/passkeys`

> Identifié pendant la phase 2 — l'UI `/passkeys` a besoin de lister les passkeys.

- [ ] Handler `list_passkeys` :
  - [ ] Extrait `AuthenticatedClaims`
  - [ ] Reçoit `user_id` (header ou query param — même pattern que DELETE)
  - [ ] Vérifie VSID → sinon 403
  - [ ] `store.fetch_credentials(user_id)` → retourne liste `[{id, created_at}]`
- [ ] Route `GET /auth/passkeys` ajoutée dans le router
- [ ] Test : liste retourne les passkeys enregistrées
- [ ] Test : user_id d'un autre user → 403

---

## Validation binary `leaf`

- [ ] Test : démarrage sans `BRIGID_MASTER_KEY` → exit non-zéro + message lisible
- [ ] Test : `--config` vers fichier inexistant → exit non-zéro
- [ ] Test : config valide + MASTER_KEY → serveur écoute sur le port configuré
- [ ] Test : graceful shutdown (`SIGTERM`) → DB non corrompue, exit 0
- [ ] Test : port déjà occupé → exit non-zéro + message clair

---

## Docker

- [ ] `docker build -t brigid/leaf:dev .` → succès
- [ ] Image finale < 60 Mo (Rust binary + assets UI statiques)
- [ ] `docker run --rm -e BRIGID_MASTER_KEY=... brigid/leaf:dev --help` → aide affichée
- [ ] Vérifier : process tourne en `nonroot:nonroot`
- [ ] Vérifier : aucun binaire inutile (`sh`, `curl`, etc. absents dans l'image distroless)
- [ ] Multi-stage build : stage `ui-build` (Node.js) → stage `rust-build` → stage final (distroless)

---

## Docker Compose dev

- [ ] `docker compose -f deploy/compose.dev.yaml up` → serveur démarre sans TLS
- [ ] `curl http://localhost:8080/health` → `{"status":"ok"}`
- [ ] `curl http://localhost:8080/login` → HTML (page Qwik)
- [ ] `curl http://localhost:8080/.well-known/openid-configuration` → JSON valide
- [ ] `docker compose -f deploy/compose.dev.yaml down` → propre, aucune donnée résiduelle

---

## Tests E2E smoke (Rust + `reqwest`)

Fichier : `server-leaf/tests/smoke/`

- [ ] `GET /health` → 200
- [ ] `GET /.well-known/openid-configuration` → JSON, champ `issuer` présent
- [ ] `GET /.well-known/did.json` → JSON, champ `id` présent
- [ ] `GET /.well-known/jwks.json` → JSON, champ `keys` non vide
- [ ] `GET /login` → HTML 200
- [ ] Flux WebAuthn registration via SoftPasskey :
  - [ ] `POST /auth/register/begin` → challenge
  - [ ] `POST /auth/register/finish` → 200
- [ ] Flux WebAuthn login + token OIDC :
  - [ ] `POST /auth/login/begin` → challenge
  - [ ] `POST /auth/login/finish` → `{"id_token": "...", "user_id": "..."}`
  - [ ] Décoder JWT → `sub` = VSID, `aud` = client_id
- [ ] `DELETE /auth/passkeys/{id}` → 200 (après login)
- [ ] Rate limit : 21ème requête sur `/auth/*` → 429

---

## Tests E2E navigateur (Playwright, repo `brig-id/web`)

- [ ] Flux register complet dans Chrome avec passkey logicielle
- [ ] Flux login → redirect `/passkeys`, token dans localStorage
- [ ] Liste passkeys affichée
- [ ] Supprimer passkey → liste mise à jour
- [ ] Déconnexion → redirect `/login`, localStorage vidé
- [ ] Tests répétés dans Firefox

---

## Vérification finale

- [ ] `cargo test --workspace` → 100% pass (core + server-leaf)
- [ ] `pnpm build && pnpm test` → pass (web)
- [ ] `cargo build --release -p leaf` → succès
- [ ] `docker build -t brigid/leaf:dev .` → succès, image < 60 Mo
- [ ] `docker compose -f deploy/compose.dev.yaml up` → serveur démarre et répond
- [ ] Smoke tests Rust → tous pass
- [ ] Playwright → tous pass (Chrome + Firefox)
- [ ] `cargo clippy --all-targets -- -D warnings` clean
- [ ] `cargo audit` clean
- [ ] `pnpm audit` clean
