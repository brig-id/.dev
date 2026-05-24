# brig·id — Plan d’architecture (v1)

Objectif : document de référence pour implémentation (backend + frontend) avec GitHub Copilot.

## 1. Vision

brig·id = système d’identité :

- **Décentralisé**
- **Sans mot de passe** (passkeys / WebAuthn)
- **Compatible OIDC + DID**
- **Respectueux de la vie privée**
- **Basé sur un identifiant root unique** + alias privés + identités virtuelles

Trois couches d’identité :

1. **Identifiant root public** (un “corps humain” unique)
2. **Alias privés** (masques, fixes ou temporaires)
3. **Identités virtuelles** (cercles de vie : perso, travail, etc.)

## 2. Formats d’identifiants

### 2.1 Identifiant root public (unique globalement)

Format UX :

- `username@server`

Exemples :

- `berenger@brig.id`
- `alice@company.com`

Mapping DID :

- `username@server` → `did:web:server:u:username`

Propriétés :

- unique globalement
- lisible
- compatible décentralisation (multi ‑serveurs)
- base de dérivation pour la VSID

### 2.2 Alias privés (fixes et temporaires)

Format UX :

- chaîne alphanumérique contenant **au moins un `_`**
- `_` est **obligatoire** et **ignoré** dans le mapping DID

Exemples :

- alias privé fixe : `x8Fj_29K`
- alias privé temporaire : `tmpA_74Pq1`

Mapping DID :

- `x8Fj_29K` → `did:peer:2.x8Fj29K`
- `tmpA_74Pq1` → `did:peer:2.tmpA74Pq1`

Règles :

- générés automatiquement (jamais choisis par l’utilisateur)
- alias fixe : stable, renouvelable (rotation manuelle)
- alias temporaire : durée courte, non réutilisable
- `_` peut apparaître plusieurs fois, mais jamais être le seul caractère

Propriétés :

- ne révèlent pas le serveur
- non résolvables publiquement
- non corrélables
- parfaits pour sessions privées / anonymes

### 2.3 Identités virtuelles (internes)

Format UX :

- préfixe `§` + nom

Exemples :

- `§perso`
- `§travail`
- `§famille`
- `§anonyme`

Propriétés :

- **pas** des DIDs
- **pas** des identifiants root
- internes à brig·id
- servent à filtrer / structurer les claims envoyés au service
- choisies au moment du login

## 3. Décentralisation

Chaque serveur brig·id gère son propre namespace :

- `username@brig.id`
- `username@company.com`
- `username@selfhosted.net`

Discovery :

- `https://server/.well-known/did.json`
- `https://server/.well-known/openid-configuration`
- éventuellement WebFinger pour compatibilité avec d’autres écosystèmes

Mapping :

- `username@server` → `did:web:server:u:username`

## 4. VSID (Virtual Stable ID)

Objectif : identifiant stable **par utilisateur et par service**, non corrélable entre services.

Formule (conceptuelle) :

- `VSID = hash(DID_ROOT + CLIENT_ID + SALT)`

Propriétés :

- stable pour un même couple (utilisateur, service)
- différent entre services
- indépendant :
  - de l’alias utilisé (public / privé / temporaire)
  - de l’identité virtuelle choisie
- utilisé comme `sub` dans OIDC

## 5. Stockage sécurisé (Zero Trust)

Hypothèse : PostgreSQL, Redis, backups, snapshots peuvent être compromis.

Principe :

- aucune donnée sensible en clair
- toutes les données sensibles chiffrées
- clé maître (MASTER_KEY) **hors base** (env, fichier sécurisé, HSM, etc.)
- clés dérivées par utilisateur / usage via HKDF

Données chiffrées :

- tokens OAuth2 / refresh tokens
- alias privés (fixes + temporaires)
- identités virtuelles (contenu + métadonnées sensibles)
- clés internes (signatures, chiffrement)
- secrets de fédération

Algorithmes recommandés :

- chiffrement : AES 6–256–GCM
- dérivation : HKDF (SHA 3 idéalement)
- signatures : Ed25519 (actuel), Dilithium/Falcon (PQC futur)
- KEM : Kyber (PQC futur)

## 6. Gestion des alias privés

### 6.1 Alias privé fixe

- généré automatiquement à la création du compte
- stocké chiffré
- mappé vers `did:peer`
- peut être régénéré via un bouton “Regénérer alias privé”
  - ancien alias → déplacé dans une liste `revoked`
  - jamais réutilisé
  - VSID inchangée (dépend du root, pas de l’alias)

### 6.2 Alias privés temporaires

- générés automatiquement à chaque session privée/anonyme
- durée de vie courte (configurable : session, 10 min, 1h…)
- stockés chiffrés pendant leur validité
- à expiration :
  - déplacés dans `revoked`
  - jamais réutilisés

### 6.3 Pool d’IDs jetés

- table `revoked_aliases`
- contient les alias privés (fixes ou temporaires) invalidés
- jamais réacceptés
- jamais régénérés
- peut être purgé partiellement, mais **sans réutilisation** des valeurs

## 7. Flux de login brig·id

### 7.1 Entrée utilisateur

L’utilisateur saisit :

- un identifiant root : `username@server`
- ou un alias privé : `x8Fj_29K` / `tmpA_74Pq1`

Le backend :

1. détecte le type :
   - présence de `@` → root public
   - présence de `_` sans `@` → alias privé
2. résolt vers un DID :
   - root → `did:web`
   - alias → `did:peer`

### 7.2 Authentification

- challenge‑response via passkey / WebAuthn
- éventuellement support PQC plus tard
- aucune gestion de mot de passe

### 7.3 Sélection d’identité virtuelle

Après authentification root :

- liste des identités virtuelles disponibles :
  - `§perso`, `§travail`, `§famille`, etc.
- l’utilisateur en choisit une (ou plusieurs, plus tard)
- cette identité influence :
  - les claims envoyés au service
  - les autorisations
  - les données exposées

### 7.4 Génération de la VSID

- basée sur le DID root + client OIDC
- indépendante :
  - de l’alias utilisé
  - de l’identité virtuelle

### 7.5 Construction du token OIDC

Claims typiques :

- `sub` : VSID
- `did` : DID root
- `identity` : identité virtuelle choisie (`perso`, `travail`, etc.)
- `server` : serveur root ([`brig.id`](https://brig.id), [`company.com`](https://company.com), etc.)
- éventuellement : `alias_type` (`public`, `private_fixed`, `private_temp`)

Token :

- signé (Ed25519, puis PQC plus tard)
- compatible OIDC standard

## 8. Backend — à implémenter

### 8.1 Modules principaux

- **DID Resolver**
  - `did:web` → via HTTPS
  - `did:peer` → via stockage interne
- **Générateur d’alias privés**
  - génère des chaînes alphanumériques contenant `_`
  - garantit unicité
  - applique la règle “_ ignoré dans DID”
- **Gestion des identités virtuelles**
  - CRUD interne
  - association à l’utilisateur root
- **Générateur de VSID**
  - fonction pure basée sur DID root + client_id + salt
- **Secure Vault**
  - chiffrement/déchiffrement des données sensibles
  - gestion de MASTER_KEY + dérivations
- **Serveur OIDC**
  - endpoints standard (`/authorize`, `/token`, `/userinfo`, `.well-known/openid-configuration`)
- **Gestion des passkeys**
  - enregistrement
  - authentification
  - rotation
- **Services et Proxies d’intégration**
  - gestion des services tiers liés aux identités virtuelles
  - proxy API vidéo : agrégation des services vidéo (YouTube, Dailymotion, etc.) par identité
  - serveur central KDE Connect : dispatch des appareils par identité
  - intégration OpenID Connect pour services SaaS avec accès contrôlé par identité

### 8.2 Stockage

- PostgreSQL :
  - utilisateurs root
  - identités virtuelles
  - alias privés (chiffrés)
  - métadonnées OIDC
- Redis :
  - sessions
  - états temporaires (PKCE, nonce, etc.)
- Table `revoked_aliases` :
  - alias invalidés (chiffrés)

## 9. Frontend — à implémenter

### 9.1 Écrans

- **Écran de login**
  - champ identifiant (accepte `username@server` ou alias privé)
  - détection automatique du type
- **Écran de sélection d’identité virtuelle**
  - liste des `§identités`
  - possibilité d’en créer/éditer (plus tard)
- **Écran de gestion des alias privés**
  - afficher l’alias privé fixe (copiable)
  - bouton “Regénérer”
- **Écran de gestion des passkeys**
  - ajouter / supprimer / renommer un appareil
- **Écran de gestion des services et proxies**
  - configuration des services tiers liés aux identités virtuelles
  - gestion des proxys d’agrégation et d’intégration

## 10. Interopérabilité

- OIDC standard
- OIDC Federation (plus tard)
- DID (web + peer)
- WebAuthn / Passkeys
- cryptographie post quantique (en option, mais anticipée)

## 11. Contraintes à respecter (pour Copilot)

- respecter strictement les formats :
  - root : `username@server`
  - alias privés : alphanumériques avec `_` obligatoire
  - identités virtuelles : `§nom` (interne)
- ne jamais stocker de données sensibles en clair
- toujours chiffrer :
  - tokens
  - alias
  - identités virtuelles
- ne jamais dériver la VSID à partir d’un alias
- toujours dériver la VSID à partir du DID root
- ne jamais réutiliser un alias révoqué
- ne jamais exposer les DIDs internes directement à l’utilisateur final (sauf debug / expert)

## 12. Sécurité et conformité

### 12.1 Gestion des clés

- MASTER_KEY stockée hors base (HSM, fichier sécurisé, variable d’environnement)
- rotation périodique recommandée
- gestion des clés dérivées par utilisateur et usage

### 12.2 Audits et logs

- journalisation des accès et opérations sensibles
- surveillance des anomalies
- conformité RGPD et autres normes applicables

### 12.3 Protection contre les attaques

- protection contre les attaques par injection
- protection contre les attaques par rejeu
- protection contre les attaques par force brute
- protection contre les attaques par phishing

## 13. Roadmap et perspectives

### 13.1 Version 1 (MVP)

- implémentation des fonctions de base : login, gestion des alias, OIDC, passkeys
- déploiement sur un serveur unique

### 13.2 Versions futures

- support multi-serveurs et federation OIDC
- intégration cryptographie post-quantique
- gestion avancée des identités virtuelles
- interface utilisateur enrichie
- audit et conformité renforcés

## 14. Annexes

### 14.1 Glossaire

- DID : Decentralized Identifier
- OIDC : OpenID Connect
- VSID : Virtual Stable ID
- HKDF : HMAC-based Extract-and-Expand Key Derivation Function
- PQC : Post-Quantum Cryptography
- HSM : Hardware Security Module

### 14.2 Références

- [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html)
- [DID Core Specification](https://www.w3.org/TR/did-core/)
- [WebAuthn Specification](https://www.w3.org/TR/webauthn/)
- [NIST PQC Project](https://csrc.nist.gov/projects/post-quantum-cryptography)

## 15. Services et Proxies dans le projet Levrier

Le projet Levrier, dont brig·id fait partie, prévoit d’ajouter des services et des proxies qui combinent les identités virtuelles avec des services tiers pour offrir une expérience unifiée et sécurisée.

### 15.1 Objectifs

- Agréger et orchestrer plusieurs services autour d’une même identité virtuelle.
- Maintenir la confidentialité, la décentralisation et le contrôle utilisateur.
- Faciliter l’interopérabilité et l’intégration avec des services externes.

### 15.2 Exemples de services/proxies

- **Proxy API vidéo** : agrégation des services vidéo liés à l’identité (YouTube, Dailymotion, etc.) pour un accès simplifié et unifié.
- **Serveur central KDE Connect** : dispatch des appareils par identité virtuelle pour une gestion multi-appareils sécurisée.
- **Intégration OpenID Connect** : utilisation de l’OpenID de l’identité pour un service SaaS qui donne accès à tout ou partie d’une information d’un autre service lié à cette identité, avec contrôle d’accès fin.

### 15.3 Architecture et intégration

- Ces proxies/services agissent comme des intermédiaires intelligents respectant les principes brig·id.
- Ils s’intègrent au backend via des modules dédiés à la gestion des proxys et à l’orchestration des identités virtuelles.
- Ils exploitent la VSID pour assurer un accès stable et non corrélable entre services.
- La sécurité est assurée par le chiffrement des données et l’authentification via passkeys/OpenID.

### 15.4 Perspectives

- Ouverture à des scénarios d’interopérabilité avancée.
- Possibilité d’ajouter d’autres types de services et proxys selon les besoins.
- Renforcement de l’expérience utilisateur par une gestion centralisée des identités virtuelles et des services associés.