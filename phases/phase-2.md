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

- [x] `pnpm` uniquement (pas de npm ni yarn) — `.npmrc` : `engine-strict=true`
- [x] Versions exactes dans `package.json` (pas de `^` ni `~`)
- [x] `pnpm install --frozen-lockfile` en CI
- [x] `onlyBuiltDependencies` dans `package.json` — liste blanche des paquets autorisés à exécuter des scripts d'install (esbuild, tailwindcss/oxide, sharp)
- [x] `pnpm audit --audit-level=moderate` en CI — bloquant (voir note ci-dessous)
- [x] `packageManager` field dans `package.json` — enforced par Corepack
- [x] Pas de dépendances runtime côté serveur (Qwik SSG → fichiers statiques)

> **Note audit (rebuild 2026-07-29)** : le repo `brig-id/web` original n'avait
> jamais été poussé sur GitHub et a été perdu lors de la reconstruction du
> dev-container — Phase 2 a été refaite intégralement. Avec `qwik@1.20.0`
> (contrainte peer `vite >=5 <8`) + `vite@7.3.6` + `vitest@4.1.10` : 2 advisories
> résiduelles, toutes deux profondément transitives et sans lien avec notre
> pipeline — `sharp` (via `qwik-city > vite-imagetools`, dev-only image
> processing) et `brace-expansion` (via `vite > stylus > glob > minimatch`,
> support Stylus non utilisé). Aucune des deux n'affecte le build de
> production (fichiers statiques, pas de serveur Node.js). Résolution prévue
> avec `qwik ≥ 1.21` + `vite 8` (phase 3).

---

## Setup projet

- [x] Init repo `brig-id/web` avec pnpm + Qwik CLI
- [x] `tsconfig.json` : `"strict": true`, `"noUncheckedIndexedAccess": true`
- [x] Tailwind CSS v4 via `@tailwindcss/vite` (plugin natif, pas de CLI npm séparé)
- [x] Lint : ESLint avec `typescript-eslint`, `eslint-plugin-qwik`
- [x] Format : Prettier (config commitée — `prettier.config.ts`)
- [x] Configurer `vite.config.ts` : proxy `/auth/*` → `http://localhost:8080` en dev
- [x] Configurer Qwik City pour les routes (`src/routes/`)
- [x] Types partagés : fichier `src/lib/api-types.ts` manuel

---

## Types API (`api-types.ts`)

Types miroirs des structs Rust de `brigid-api` :

- [x] `BeginRegisterRequest`, `BeginRegisterResponse`
- [x] `FinishRegisterRequest`
- [x] `BeginLoginRequest`, `BeginLoginResponse`
- [x] `FinishLoginRequest`, `LoginResponse` (inclut `user_id`)
- [x] `DeletePasskeyRequest`
- [x] Erreur API : `{ error: string }`

---

## Client WebAuthn (`src/lib/webauthn.ts`)

- [x] `register(username)` — begin → `navigator.credentials.create()` → finish
- [x] `login(username, clientId)` — begin → `navigator.credentials.get()` → finish → retourne `LoginResponse`
- [x] `deletePasskey(passkeyId, userId, token)` — `DELETE /auth/passkeys/{id}`
- [x] Gestion d'erreurs typée : `WebAuthnError` avec `kind` (`network` | `browser` | `api`)
- [x] `storeAuth(token, userId)` / `loadToken()` / `loadUserId()` / `clearAuth()` — localStorage

---

## Thème Tailwind

- [x] Couleur primaire : `#6C47FF` (violet)
- [x] Fond : `#0F0F13` (dark)
- [x] Texte : `#E8E8F0`
- [x] Radius : `8px`
- [x] Font : Inter (stack CSS avec fallback système — pas de Google Fonts CDN)
- [x] Dark mode uniquement (MVP)
- [x] Focus visible sur navigation clavier

---

## Composants (`src/components/`)

- [x] `Button` — variants `primary`, `secondary`, `danger` ; props : `label`, `loading`, `disabled`
- [x] `Input` — label + erreur inline ; validation visuelle rouge si erreur
- [x] `Alert` — variants `info`, `success`, `error`
- [x] `Card` — container shadow + padding
- [x] `PasskeyItem` — icône inline SVG, id tronqué, bouton supprimer

---

## Pages (`src/routes/`)

### `/` (root)

- [x] Redirect vers `/login` si pas de token localStorage
- [x] Redirect vers `/passkeys` si token présent

### `/login/`

- [x] Input `username` (`user@server`) avec validation format live (regex via `src/lib/validation.ts`)
- [x] Bouton "Sign in with passkey" — loading state pendant WebAuthn
- [x] Erreurs : format invalide, passkey annulée, user inconnu, serveur unreachable
- [x] Lien vers `/register`
- [x] Après succès : stocker `{token, user_id}` → redirect `/passkeys`

### `/register/`

- [x] Input `username` avec validation format live
- [x] Bouton "Create account" — loading state
- [x] Erreurs : format invalide, username déjà pris, passkey annulée
- [x] Lien vers `/login`
- [x] Après succès : redirect `/login`

### `/passkeys/`

- [x] Guard : redirect `/login` si pas de token
- [x] Charger la liste des passkeys via `GET /auth/passkeys?user_id=…`
- [x] `PasskeyItem` par passkey — bouton supprimer → `DELETE /auth/passkeys/{id}` → refresh liste
- [x] Bouton "Add a passkey" — même flux que register/finish
- [x] Bouton "Sign out" → `POST /auth/logout` + `clearAuth()` → redirect `/login`
- [x] Feedback : alert succès/erreur inline

---

## Tests

- [x] `vitest` — tests unitaires (35 tests, 4 fichiers)
- [x] Test `Button` : rendu correct par variant (8 tests via `createDOM`)
- [x] Test `Input` : label, erreur visible si fournie, aria-describedby (7 tests)
- [x] Test `register()` / `login()` : mock `fetch` + `navigator.credentials` → assertions sur les appels API (10 tests)
- [x] Test validation username : format invalide → message d'erreur (5 tests)
- [ ] `playwright` — tests E2E avec softpasskey ou mock WebAuthn (phase 3)
  - [ ] Flux register complet → redirect `/login`
  - [ ] Flux login complet → redirect `/passkeys`
  - [ ] Supprimer une passkey → liste mise à jour

---

## Vérification finale

- [x] `pnpm build` → succès, bundle JS gzip ~35 kB (< 100 kB)
- [x] `pnpm test` → 100% pass (35/35 vitest)
- [x] `pnpm lint` → zéro erreur ESLint
- [x] `pnpm typecheck` → zéro erreur TypeScript
- [x] `pnpm audit` → 2 advisories résiduelles esbuild (Deno + Windows, voir note supply chain)
- [ ] Ouvrir `http://localhost:5173/login` (vite dev) → page dark theme correcte (à tester en phase 3 avec server-leaf)
- [ ] Flux register dans Chrome : passkey créée (phase 3 — E2E)
- [ ] Flux login dans Chrome : token reçu, redirect `/passkeys` (phase 3 — E2E)
- [ ] Suppression passkey → liste mise à jour (phase 3 — E2E)
- [ ] Lighthouse score accessibilité ≥ 90 (phase 3)
