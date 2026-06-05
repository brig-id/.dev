# Phase 2 — UI Qwik (`brig-id/web`)

**Repo :** `brig-id/web` (nouveau repo, ou `server-leaf/ui/`)
**Prérequis :** Phase 1 terminée (API complète)
**Objectif :** Interface web fonctionnelle — login, register, gestion passkeys — en TypeScript Qwik, consommant `brigid-api`.

---

## Contexte

Stack retenu après évaluation (voir historique décisions) :

- **Qwik** — resumability, SSR-first, minimal JS en production
- **Vite** — bundler, dev server HMR
- **pnpm** — store content-addressable, isolation stricte, pas de phantom deps
- **TypeScript strict** — `strict: true`, `noUncheckedIndexedAccess: true`
- **Tailwind CSS v4** — via `@tailwindcss/vite` (plugin Vite, pas de CLI séparé)

L'UI appelle `brigid-api` sur la même origine. Pas de Node.js en production :
Qwik génère les pages en SSG (login, register) et en CSR pour `/passkeys`
(données dépendent de l'utilisateur authentifié). Le Rust server sert les fichiers statiques.

---

## Supply chain — mesures de durcissement

- [ ] `pnpm` uniquement (pas de npm ni yarn) — `.npmrc` : `engine-strict=true`
- [ ] Versions exactes dans `package.json` (pas de `^` ni `~`)
- [ ] `pnpm install --frozen-lockfile` en CI
- [ ] `onlyBuiltDependencies` dans `package.json` — liste blanche des paquets autorisés à exécuter des scripts d'install (esbuild, vite uniquement)
- [ ] `pnpm audit --audit-level=moderate` en CI — bloquant
- [ ] `packageManager` field dans `package.json` — enforced par Corepack
- [ ] Pas de dépendances runtime côté serveur (Qwik SSG → fichiers statiques)

---

## Setup projet

- [ ] Init repo `brig-id/web` avec pnpm + Qwik CLI
- [ ] `tsconfig.json` : `"strict": true`, `"noUncheckedIndexedAccess": true`
- [ ] Tailwind CSS v4 via `@tailwindcss/vite` (plugin natif, pas de CLI npm séparé)
- [ ] Lint : ESLint avec `@typescript-eslint/strict`, `eslint-plugin-qwik`
- [ ] Format : Prettier (config commitée)
- [ ] Configurer `vite.config.ts` : proxy `/auth/*` → `http://localhost:8080` en dev
- [ ] Configurer Qwik City pour les routes (`src/routes/`)
- [ ] Types partagés : générer depuis Rust via `ts-rs` ou fichier `api-types.ts` manuel

---

## Types API (`api-types.ts`)

Types miroirs des structs Rust de `brigid-api` :

- [ ] `BeginRegisterRequest`, `BeginRegisterResponse`
- [ ] `FinishRegisterRequest`
- [ ] `BeginLoginRequest`, `BeginLoginResponse`
- [ ] `FinishLoginRequest`, `LoginResponse` (inclut `user_id`)
- [ ] `DeletePasskeyRequest`
- [ ] Erreur API : `{ error: string }`

---

## Client WebAuthn (`src/lib/webauthn.ts`)

- [ ] `register(username)` — begin → `navigator.credentials.create()` → finish
- [ ] `login(username, clientId)` — begin → `navigator.credentials.get()` → finish → retourne `LoginResponse`
- [ ] `deletePasskey(passkeyId, userId, token)` — `DELETE /auth/passkeys/{id}`
- [ ] Gestion d'erreurs typée : `WebAuthnError` avec `kind` (`network` | `browser` | `api`)
- [ ] `storeAuth(token, userId)` / `loadToken()` / `loadUserId()` / `clearAuth()` — localStorage

---

## Thème Tailwind

- [ ] Couleur primaire : `#6C47FF` (violet)
- [ ] Fond : `#0F0F13` (dark)
- [ ] Texte : `#E8E8F0`
- [ ] Radius : `8px`
- [ ] Font : Inter (self-hosted, pas de Google Fonts CDN en production)
- [ ] Dark mode uniquement (MVP)
- [ ] Focus visible sur navigation clavier

---

## Composants (`src/components/`)

- [ ] `Button` — variants `primary`, `secondary`, `danger` ; props : `label`, `loading`, `disabled`
- [ ] `Input` — label + erreur inline ; validation visuelle rouge si erreur
- [ ] `Alert` — variants `info`, `success`, `error`
- [ ] `Card` — container shadow + padding
- [ ] `PasskeyItem` — nom, date, bouton supprimer ; icône inline SVG

---

## Pages (`src/routes/`)

### `/` (root)

- [ ] Redirect vers `/login` si pas de token localStorage
- [ ] Redirect vers `/passkeys` si token présent

### `/login/`

- [ ] Input `username` (`user@server`) avec validation format live (regex `/^[^@]+@[^@]+$/`)
- [ ] Bouton "Se connecter avec une passkey" — loading state pendant WebAuthn
- [ ] Erreurs : format invalide, passkey annulée, user inconnu, serveur unreachable
- [ ] Lien vers `/register`
- [ ] Après succès : stocker `{token, user_id}` → redirect `/passkeys`

### `/register/`

- [ ] Input `username` avec validation format live
- [ ] Bouton "Créer un compte" — loading state
- [ ] Erreurs : format invalide, username déjà pris, passkey annulée
- [ ] Lien vers `/login`
- [ ] Après succès : redirect `/login`

### `/passkeys/`

- [ ] Guard : redirect `/login` si pas de token
- [ ] Charger la liste des passkeys via `GET /auth/passkeys` (endpoint à ajouter en phase 1 ou ici)
- [ ] `PasskeyItem` par passkey — bouton supprimer → `DELETE /auth/passkeys/{id}` → refresh liste
- [ ] Bouton "Ajouter une passkey" — même flux que register/finish
- [ ] Bouton "Se déconnecter" → `POST /auth/logout` + `clearAuth()` → redirect `/login`
- [ ] Feedback : alert succès/erreur inline

---

## Tests

- [ ] `vitest` — tests unitaires composants Qwik (rendu SSR)
- [ ] Test `Button` : rendu correct par variant
- [ ] Test `Input` : affiche label, erreur visible si fournie
- [ ] Test `register()` / `login()` : mock `fetch` + `navigator.credentials` → assertions sur les appels API
- [ ] Test validation username : format invalide → message d'erreur
- [ ] `playwright` — tests E2E avec softpasskey ou mock WebAuthn
  - [ ] Flux register complet → redirect `/login`
  - [ ] Flux login complet → redirect `/passkeys`
  - [ ] Supprimer une passkey → liste mise à jour

---

## Vérification finale

- [ ] `pnpm build` → succès, bundle < 100 KB JS (gzip)
- [ ] `pnpm test` → 100% pass (vitest)
- [ ] `pnpm lint` → zéro erreur ESLint
- [ ] `pnpm typecheck` → zéro erreur TypeScript
- [ ] `pnpm audit` → zéro advisory
- [ ] Ouvrir `http://localhost:5173/login` (vite dev) → page dark theme correcte
- [ ] Flux register dans Chrome : passkey créée
- [ ] Flux login dans Chrome : token reçu, redirect `/passkeys`
- [ ] Suppression passkey → liste mise à jour
- [ ] Lighthouse score accessibilité ≥ 90
