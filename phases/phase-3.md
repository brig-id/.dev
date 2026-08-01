# Phase 3 — Integration & E2E Validation (`server-leaf`)

**Repos:** `brig-id/core`, `brig-id/server-leaf`, `brig-id/web`
**Prerequisites:** Phase 2 complete (functional Qwik UI)
**Goal:** Unified deployment — Rust API + Qwik static UI — validated end to end.

---

## Context

The `leaf` binary serves both the `brigid-api` and Qwik static files.
The Qwik UI builds to `dist/` — either embedded in the Docker image or mounted as a volume.
No Node.js in production.

---

## server-leaf integration

- [x] Add `tower-http::services::ServeDir` to serve `ui/dist/` on `/`
- [x] Fallback route: any non-API URL → `index.html` (SPA fallback)
- [ ] CSP header updated: `script-src 'self'` (Qwik assets are same-origin)
- [x] `leaf.toml` config: `ui_dist_dir` field (path to the UI build output)
- [x] Test: `GET /login` → HTML 200 with `Content-Type: text/html`
- [x] Test: `GET /assets/q-*.js` → 200, `Content-Type: application/javascript`

> **Implementation note**: `apply_ui_fallback(router, dist)` in `src/lib.rs` —
> `ServeDir::new(dist).fallback(ServeFile::new(dist/index.html))` wired as a
> fallback service on the API router. Configured via `LEAF_SERVER__UI_DIST_DIR`.
> 5 integration tests in `tests/static_files.rs` (13/13 pass total).
> `[patch.crates-io]` + `vendor/` copied from core for Rust 1.96 compatibility.

---

## Missing route: `GET /auth/passkeys`

> Identified during phase 2 — the `/passkeys` UI page needs to list passkeys.

- [x] `list_passkeys` handler:
  - [x] Extracts `AuthenticatedClaims`
  - [x] Receives `user_id` (query param — same pattern as DELETE)
  - [x] Verifies VSID → 403 if mismatch
  - [x] `store.fetch_credentials(user_id)` → returns `[{id, created_at}]`
- [x] Route `GET /auth/passkeys` added to the router
- [x] Test: list returns registered passkeys (24/24 core tests pass)
- [x] Test: another user's `user_id` → 403

---

## `leaf` binary validation

- [x] Test: startup without `BRIGID_MASTER_KEY` → non-zero exit + readable message
- [x] Test: `--config` pointing to a missing file → non-zero exit
- [x] Test: valid config + MASTER_KEY → server listens on the configured port
- [x] Test: graceful shutdown (`SIGTERM`) → DB not corrupted, exit 0
- [x] Test: port already in use → non-zero exit + clear message

> **Implementation note**: `server-leaf/tests/binary.rs` (branch `dev/forge`,
> committed directly per the prototyping-phase branch policy). Spawns the
> compiled binary as a subprocess for each case. Along the way, fixed a real
> gap: figment's TOML file provider treats a missing `--config` file as "no
> data" rather than an error, so a typo'd path silently produced an
> unrelated "missing field `server`" error — `main.rs` now checks file
> existence upfront and panics with the actual path.

---

## Docker

- [x] `docker build -t brigid/leaf:dev .` → success
- [x] Final image < 60 MB (Rust binary + static UI assets) — 15.8 MB
- [x] `docker run --rm -e BRIGID_MASTER_KEY=... brigid/leaf:dev --help` → help printed
- [x] Verify: process runs as `nonroot:nonroot`
- [x] Verify: no unnecessary binaries (`sh`, `curl`, etc. absent in distroless image)
- [x] Multi-stage build: `ui-builder` (Node.js) → `rust-builder` → `runtime` (distroless)

> **Implementation note**: found and fixed two bugs blocking this section
> (`server-leaf` branch `feat/docker-compose-dev`): (1) `rust-builder` was
> pinned to `1.85-slim`, but `Cargo.lock` now needs rustc ≥1.88
> (`time`/`aws-lc-sys`) — re-pinned to `1.88-slim`, the last tag still on
> Debian 12 (bookworm), keeping the libssl3/libcrypto3 ABI match with the
> distroless runtime; (2) the distroless runtime never created `/data`, so a
> fresh named volume inherited `root:root` and the `nonroot` user (UID
> 65532) couldn't create the SQLite file — pre-created it nonroot-owned in
> the builder stage and `COPY --chown`'d it in.
>
> Separately, `web`'s `pnpm build` produced zero HTML — no Qwik City
> adapter had ever been installed (`web` branch `feat/qwik-static-adapter`
> adds the `static` adapter — see "Browser E2E" note below for details).

---

## Docker Compose dev

- [ ] `docker compose -f deploy/compose.dev.yaml up` → server starts without TLS
- [x] `curl http://localhost:8080/health` → `{"status":"ok"}`
- [x] `curl http://localhost:8080/login` → HTML (Qwik page)
- [x] `curl http://localhost:8080/.well-known/openid-configuration` → valid JSON
- [ ] `docker compose -f deploy/compose.dev.yaml down` → clean, no residual data

> **Implementation note**: the three `curl` checks are verified — against a
> native `cargo run -p leaf` pointed at a real `pnpm build` output for the
> HTML check, and against the fixed Docker image directly for the others —
> but not through the literal `docker compose ... up` command itself. In
> the `.dev` devcontainer specifically (`docker-outside-of-docker`), the
> Docker daemon is the *real host's*, so `compose.dev.yaml`'s bind mount
> (`/workspaces/web/dist:/ui/dist:ro`) resolves against a path that only
> exists inside the devcontainer's own mount namespace — it silently
> mounts empty. The compose file itself is unchanged and should work as
> written on a real host (or any non-nested Docker setup); confirming that,
> or reworking the mount to survive nested Docker, is unstarted.

## E2E smoke tests (Rust + `reqwest`)

File: `server-leaf/tests/smoke/`

- [ ] `GET /health` → 200
- [ ] `GET /.well-known/openid-configuration` → JSON, `issuer` field present
- [ ] `GET /.well-known/did.json` → JSON, `id` field present
- [ ] `GET /.well-known/jwks.json` → JSON, `keys` array non-empty
- [ ] `GET /login` → HTML 200
- [ ] WebAuthn registration flow via SoftPasskey:
  - [ ] `POST /auth/register/begin` → challenge
  - [ ] `POST /auth/register/finish` → 200
- [ ] WebAuthn login flow + OIDC token:
  - [ ] `POST /auth/login/begin` → challenge
  - [ ] `POST /auth/login/finish` → `{"id_token": "...", "user_id": "..."}`
  - [ ] Decode JWT → `sub` = VSID, `aud` = client_id
- [ ] `DELETE /auth/passkeys/{id}` → 200 (after login)
- [ ] Rate limit: 21st request on `/auth/*` → 429

---

## Browser E2E tests (Playwright, `brig-id/web` repo)

- [ ] Full register flow in Chrome with software passkey
- [ ] Login flow → redirect to `/passkeys`, token in localStorage
- [ ] Passkey list displayed
- [ ] Delete passkey → list updated
- [ ] Sign out → redirect to `/login`, localStorage cleared
- [ ] Tests repeated in Firefox

---

## Final checklist

- [ ] `cargo test --workspace` → 100% pass (core + server-leaf)
- [ ] `pnpm build && pnpm test` → pass (web)
- [ ] `cargo build --release -p leaf` → success
- [ ] `docker build -t brigid/leaf:dev .` → success, image < 60 MB
- [ ] `docker compose -f deploy/compose.dev.yaml up` → server starts and responds
- [ ] Rust smoke tests → all pass
- [ ] Playwright → all pass (Chrome + Firefox)
- [ ] `cargo clippy --all-targets -- -D warnings` clean
- [ ] `cargo audit` clean
- [ ] `pnpm audit` clean
