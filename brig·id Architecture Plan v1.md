- # brig·id — Architecture Plan (v1)

  Système d’identité décentralisé, sécurisé, full‑Rust.

  # 1. Vision

  brig·id repose sur trois couches d’identité :

  1. Identifiant root public — unique globalement (`username@server`)
  2. Alias privés — fixes ou temporaires, masqués, non corrélables
  3. Identités virtuelles — cercles de vie (`§perso`, `§travail`, etc.)

  Objectifs :

  - sécurité maximale
  - décentralisation
  - compatibilité OIDC + DID
  - WebAuthn (passkeys)
  - stockage chiffré (zero‑trust)
  - UX simple et rapide

  # 2. Identifiants

  ## 2.1 Identifiant root public

  Format : `username@server`

  Exemples :

  - `berenger@brig.id`
  - `alice@company.com`

  Mapping DID :

  - `did:web:server:u:username`

  Propriétés :

  - unique globalement
  - lisible
  - base de dérivation pour la VSID

  ## 2.2 Alias privés

  Format : chaîne alphanumérique contenant au moins un `_`.

  Exemples :

  - `x8Fj_29K`
  - `tmpA_74Pq1`

  Règles :

  - `_` obligatoire
  - `_` ignoré dans le mapping DID
  - générés automatiquement
  - alias fixe = stable
  - alias temporaire = jetable

  Mapping DID :

  - `x8Fj_29K` → `did:peer:2.x8Fj29K`

  Propriétés :

  - non corrélables
  - non résolvables
  - parfaits pour sessions privées

  ## 2.3 Identités virtuelles

  Format : `§nom`

  Exemples :

  - `§perso`
  - `§travail`
  - `§famille`

  Propriétés :

  - internes à brig·id
  - influencent les claims OIDC
  - choisies au login

  # 3. Décentralisation

  Chaque serveur gère son propre namespace :

  - `username@brig.id`
  - `username@company.com`
  - `username@selfhosted.net`

  Discovery :

  - `.well-known/did.json`
  - `.well-known/openid-configuration`

  Mapping :

  - `did:web:server:u:username`

  # 4. VSID (Virtual Stable ID)

  Objectif : identifiant stable par utilisateur et par service, non corrélable.

  Formule (conceptuelle) : `VSID = hash(DID_ROOT + CLIENT_ID + SALT)`

  Propriétés :

  - stable pour un même service
  - différent entre services
  - indépendant de l’alias utilisé
  - indépendant de l’identité virtuelle

  # 5. Stockage sécurisé (Zero‑Trust)

  Hypothèse : PostgreSQL, Redis, backups = compromis.

  Règles :

  - aucune donnée sensible en clair
  - toutes les données sensibles chiffrées
  - MASTER_KEY hors base
  - dérivation HKDF par utilisateur

  Données chiffrées :

  - alias privés
  - identités virtuelles
  - tokens OAuth2
  - clés internes
  - secrets de fédération

  Algorithmes :

  - AES‑256‑GCM
  - HKDF‑SHA3
  - Ed25519 (actuel)
  - Kyber / Dilithium (PQC futur)

  # 6. Alias privés : gestion interne

  ## 6.1 Alias fixe

  - généré automatiquement
  - stocké chiffré
  - renouvelable
  - mappé vers `did:peer`

  ## 6.2 Alias temporaires

  - générés automatiquement
  - durée courte
  - non réutilisables

  ## 6.3 Pool d’IDs jetés

  - alias révoqués
  - jamais réutilisés
  - stockés chiffrés

  # 7. Flux de login brig·id

  ## 7.1 Entrée utilisateur

  Accepte :

  - `username@server`
  - `x8Fj_29K`
  - `tmpA_74Pq1`

  Détection :

  - `@` → root public
  - `_` sans `@` → alias privé

  ## 7.2 Résolution DID

  - root → `did:web`
  - alias → `did:peer`

  ## 7.3 Authentification

  - WebAuthn (passkeys)
  - challenge‑response

  ## 7.4 Sélection d’identité virtuelle

  - `§perso`, `§travail`, etc.

  ## 7.5 Génération VSID

  - stable pour le service

  ## 7.6 Token OIDC

  Claims :

  - `sub` = VSID
  - `did` = DID root
  - `identity` = identité virtuelle
  - `server` = serveur root
  - `alias_type` = public / privé / temporaire

  # 8. Backend (Rust)

  Stack :

  - Axum (HTTP)
  - Leptos (SSR + UI)
  - PostgreSQL (données chiffrées)
  - Redis (sessions)
  - Tailwind (CSS)
  - Tabler Icons (icônes)

  Modules :

  - DID resolver (web + peer)
  - Secure Vault (AES‑GCM + HKDF)
  - Alias privés
  - Identités virtuelles
  - VSID
  - WebAuthn
  - OIDC server
  - `.well-known` endpoints

  # 9. Frontend (Rust, Leptos)

  Pages :

  - login
  - sélection d’identité virtuelle
  - gestion alias privés
  - gestion passkeys

  Composants :

  - boutons
  - inputs
  - modals
  - alerts
  - cards
  - icônes Tabler

  Style :

  - Tailwind CSS
  - thèmes personnalisés brig·id

  # 10. Interopérabilité

  - OIDC standard
  - OIDC Federation (futur)
  - DID (web + peer)
  - WebAuthn
  - PQC (futur)

  # 11. Contraintes pour GitHub Copilot

  - respecter les formats d’identifiants
  - ne jamais stocker en clair
  - toujours chiffrer alias + identités + tokens
  - ne jamais dériver VSID depuis un alias
  - ne jamais réutiliser un alias révoqué
  - ne jamais exposer les DIDs internes à l’utilisateur final