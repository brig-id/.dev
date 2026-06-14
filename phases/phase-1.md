# Phase 1 — API finalization (`brigid-api` + `brigid-store`)

**Repo :** `brig-id/core`
**Prérequis :** phases 0 terminée (✅ acquis)
**Objectif :** API complète, sécurisée, prête à être consommée par l'UI Qwik.

---

## Contexte

`brigid-api` expose les endpoints WebAuthn et OIDC.
Routes manquantes pour que l'UI puisse gérer les passkeys :

- `DELETE /auth/passkeys/{id}` — suppression passkey authentifiée
- `user_id` dans `LoginResponse` — nécessaire pour lier le token à l'utilisateur interne

> **Note v2 :** La phase "UI Leptos/WASM" (v1 phase 1) a été annulée.
> L'UI est remplacée par un stack TypeScript Qwik + Vite + pnpm (→ phase 2).

---

## `brigid-store` — `delete_credential`

- [x] Fonction `delete_credential(pool, user_id, cred_id)` — `DELETE WHERE id = ? AND user_id = ?`
  - [x] Retourner `Error::NotFound` si 0 lignes affectées (credential absente ou cross-user)
- [x] Méthode wrapper `EncryptedStore::delete_credential`
- [x] Test : suppression correcte → fetch retourne liste vide
- [x] Test : mauvais `user_id` → `NotFound`, credential toujours présente

---

## `brigid-api` — `DELETE /auth/passkeys/{id}`

- [x] `ApiError::Forbidden` (403) — variant manquant
- [x] `user_id: Uuid` dans `LoginResponse` — UUID interne, non exposé dans le JWT
  - [x] Permet à l'UI de lier le token au user_id pour les endpoints issuer-facing
- [x] Handler `delete_passkey` :
  - [x] Extrait `AuthenticatedClaims` (Bearer token)
  - [x] Extrait `passkey_id: Uuid` depuis le path
  - [x] Reçoit `{ user_id: Uuid }` dans le body
  - [x] Vérifie : `compute_vsid(user.did_web, claims.aud, salt) == claims.sub` → sinon 403
  - [x] Appelle `store.delete_credential(user_id, passkey_id)` → 200 ou 404
- [x] Route `DELETE /auth/passkeys/{id}` ajoutée dans le router (rate-limité)
- [x] Test intégration : register → login → delete passkey → 200
- [x] Test : tenter de supprimer la passkey d'un autre user → 403
- [x] Test : passkey_id inconnu → 404
- [x] Test : token invalide → 401

---

## Vérification finale

- [x] `cargo build --workspace` → clean, zéro warning
- [x] `cargo test --workspace` → 100% pass (35/35)
- [x] `cargo clippy --all-targets -- -D warnings` clean
- [x] `cargo fmt --all --check` clean
- [x] `cargo audit` clean
