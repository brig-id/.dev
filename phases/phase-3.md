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
- [x] CSP header updated: `script-src 'self'` (Qwik assets are same-origin)
- [x] `leaf.toml` config: `ui_dist_dir` field (path to the UI build output)
- [x] Test: `GET /login` → HTML 200 with `Content-Type: text/html`
- [x] Test: `GET /assets/q-*.js` → 200, `Content-Type: application/javascript`

> **Implementation note**: `apply_ui_fallback(router, dist)` in `src/lib.rs` —
> `ServeDir::new(dist).fallback(ServeFile::new(dist/index.html))` wired as a
> fallback service on the API router. Configured via `LEAF_SERVER__UI_DIST_DIR`.
> 5 integration tests in `tests/static_files.rs` (13/13 pass total).
> `[patch.crates-io]` + `vendor/` copied from core for Rust 1.96 compatibility.
>
> **CSP finding (dev/forge, `fix(leaf): 🔒️ ...`)**: `brigid-api::build_router()`
> (core) already sets CSP/X-Frame-Options/HSTS/nosniff, but only around the
> routes it defines *before* returning. In axum 0.8, `.layer()` doesn't cover
> routes/fallback added afterwards — and `server-leaf` always attaches the UI
> fallback *after* `build_router()` returns, so none of those headers ever
> reached `/login`, `/register`, or any static asset. Fixed by re-applying
> the same header set as the true outermost layer in `apply_ui_fallback`,
> after the fallback is attached (`if_not_present` makes it a no-op for API
> routes). Same latent gap would hit `server-grove`/`server-forest` if they
> ever call `build_router()` and add their own fallback the same way — worth
> a look in `core` when those phases start.

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

File: `server-leaf/tests/smoke.rs` (flat file, not a `smoke/` directory —
matches this repo's existing `tests/binary.rs`/`tests/static_files.rs`
convention; shared spawn/port helpers factored into `tests/common/mod.rs`,
also now used by `tests/binary.rs`)

- [x] `GET /health` → 200
- [x] `GET /.well-known/openid-configuration` → JSON, `issuer` field present
- [x] `GET /.well-known/did.json` → JSON, `id` field present
- [x] `GET /.well-known/jwks.json` → JSON, `keys` array non-empty
- [x] `GET /login` → HTML 200
- [x] WebAuthn registration flow via SoftPasskey:
  - [x] `POST /auth/register/begin` → challenge
  - [x] `POST /auth/register/finish` → 200
- [x] WebAuthn login flow + OIDC token:
  - [x] `POST /auth/login/begin` → challenge
  - [x] `POST /auth/login/finish` → `{"id_token": "...", "user_id": "..."}`
  - [x] Decode JWT → `sub` = VSID, `aud` = client_id
- [x] `DELETE /auth/passkeys/{id}` → 200 (after login)
- [x] Rate limit: 21st request on `/auth/*` → 429

> **Implementation note**: 8 tests, each spawning its own `leaf` subprocess
> (fresh rate-limit bucket per test — needed, since `/auth/*`'s real limiter,
> 1 token/3s + burst 5, is exercised for real, not mocked). Two non-obvious
> findings while writing these, both fixed in the tests themselves (not
> app bugs): (1) the WebAuthn ceremony's origin must match
> `LEAF_SERVER__DOMAIN` exactly (used `localhost` for both — `127.0.0.1`
> fails with a `Security` error even though it resolves to the same
> address); (2) `sub` (the VSID) is a deliberately distinct pseudonymous
> identifier from `user_id` (raw UUID) — checked for presence/non-equality,
> not equality, once that became clear from a failing assertion.

---

## Browser E2E tests (Playwright, `brig-id/web` repo)

- [x] Full register flow in Chrome with software passkey
- [x] Login flow → redirect to `/passkeys`, token in localStorage
- [x] Passkey list displayed
- [x] Delete passkey → list updated
- [x] Sign out → redirect to `/login`, localStorage cleared
- [x] Tests repeated in Firefox

> **Implementation note**: `web/e2e/` (`dev/forge`, commit `test(e2e): ✅
> add Playwright suite...`). "Tests repeated in Firefox" needed a caveat:
> Playwright's WebAuthn virtual authenticator is Chrome DevTools Protocol
> only, no Firefox equivalent exists, so the 5 passkey-dependent specs
> skip themselves under `firefox` with a stated reason rather than
> silently not running; 2 non-WebAuthn specs (form validation, static
> rendering) run on both and actually pass on Firefox. Runs against
> `pnpm dev`, not the static build — see the "Static SSG build breaks Qwik
> hydration" backlog entry for why. `/auth/*`'s real rate limiter (1
> token/3s, burst 5) is genuinely exercised, not mocked, which surfaced
> a real product question (`/passkeys` "Add a passkey" registers an
> unrelated identity, not a second credential — separate backlog entry)
> along the way.

---

## Final checklist

- [x] `cargo test --workspace` → 100% pass (core + server-leaf)
- [x] `pnpm build && pnpm test` → pass (web)
- [x] `cargo build --release -p leaf` → success
- [x] `docker build -t brigid/leaf:dev .` → success, image < 60 MB
- [ ] `docker compose -f deploy/compose.dev.yaml up` → server starts and responds
- [x] Rust smoke tests → all pass
- [x] Playwright → all pass (Chrome + Firefox)
- [x] `cargo clippy --all-targets -- -D warnings` clean
- [x] `cargo audit` clean
- [x] `pnpm audit` clean

> **Implementation note**: all green except the literal `docker compose
> ... up` (see "Docker Compose dev" section above — blocked by this
> devcontainer's nested-Docker bind-mount limitation, not a code issue).
> `cargo audit`/`cargo deny check` also turned up real, now-fixed issues
> along the way in both `server-leaf` and `core`: a high-severity
> `quinn-proto` advisory and a yanked `spin` version (both transitive via
> `reqwest`, dev-only), plus two stale `deny.toml` ignore entries for
> advisories that no longer match anything in either tree. `pnpm audit`
> needed a `sharp` override (bundled libvips CVEs, dev-only build tool) and
> picked up an automatic `brace-expansion` fix; one low-severity
> Windows-only `esbuild` issue remains, out of scope for a Linux-only
> project.
