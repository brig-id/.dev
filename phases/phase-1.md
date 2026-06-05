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

- [ ] Fonction `delete_credential(pool, user_id, cred_id)` — `DELETE WHERE id = ? AND user_id = ?`
  - [ ] Retourner `Error::NotFound` si 0 lignes affectées (credential absente ou cross-user)
- [ ] Méthode wrapper `EncryptedStore::delete_credential`
- [ ] Test : suppression correcte → fetch retourne liste vide
- [ ] Test : mauvais `user_id` → `NotFound`, credential toujours présente

---

## `brigid-api` — `DELETE /auth/passkeys/{id}`

- [ ] `ApiError::Forbidden` (403) — variant manquant
- [ ] `user_id: Uuid` dans `LoginResponse` — UUID interne, non exposé dans le JWT
  - [ ] Permet à l'UI de lier le token au user_id pour les endpoints issuer-facing
- [ ] Handler `delete_passkey` :
  - [ ] Extrait `AuthenticatedClaims` (Bearer token)
  - [ ] Extrait `passkey_id: Uuid` depuis le path
  - [ ] Reçoit `{ user_id: Uuid }` dans le body
  - [ ] Vérifie : `compute_vsid(user.did_web, claims.aud, salt) == claims.sub` → sinon 403
  - [ ] Appelle `store.delete_credential(user_id, passkey_id)` → 200 ou 404
- [ ] Route `DELETE /auth/passkeys/{id}` ajoutée dans le router (rate-limité)
- [ ] Test intégration : register → login → delete passkey → 200
- [ ] Test : tenter de supprimer la passkey d'un autre user → 403
- [ ] Test : passkey_id inconnu → 404
- [ ] Test : token invalide → 401

---

## Vérification finale

- [ ] `cargo build --workspace` → clean, zéro warning
- [ ] `cargo test --workspace` → 100% pass
- [ ] `cargo clippy --all-targets -- -D warnings` clean
- [ ] `cargo fmt --all --check` clean
- [ ] `cargo audit` clean
