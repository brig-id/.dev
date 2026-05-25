# Phase 3 — `brig-id/core` : Identity & VSID

**Repo :** `brig-id/core`
**Prérequis :** Phase 2 terminée
**Crate :** `brigid-identity`

---

## Crate `brigid-identity`

### Dépendances

- [x] `brigid-crypto` (git dep)
- [x] `sha3` — hachage pour VSID
- [x] `thiserror` — erreurs typées
- [x] `base64ct` — encodage base64url (VSID et DID:peer)

## Formats d'identifiants

### Root public identity

- [x] Type `RootId { username: String, server: String }`
- [x] `RootId::parse(input: &str) -> Result<RootId>` — valide `username@server`
  - [x] `username` : alphanumérique + `-_`, 3–64 chars, pas de `@` ni `_` seul
  - [x] `server` : domaine valide (RFC 1123)
- [x] `RootId::to_string()` → `username@server`
- [x] `RootId::to_did_web()` → `did:web:server:u:username`

### Alias privés (structure, pas encore exposé en 0.0.1)

- [x] Type `PrivateAlias(String)` — contient au moins un `_`, pas de `@`
- [x] `PrivateAlias::is_valid(s: &str) -> bool`
- [x] `PrivateAlias::to_did_peer()` — strip `_`, SHA3-256, encode en DID:peer:2.z (placeholder phase 4)

### Détection du type d'entrée utilisateur

- [x] `parse_identifier(input) -> IdentifierKind`
  - [x] `@` présent → `RootPublic(RootId)`
  - [x] `_` présent sans `@` → `PrivateAlias(PrivateAlias)`
  - [x] sinon → `Err(InvalidIdentifier)`

## VSID (Virtual Stable ID)

- [x] `compute_vsid(did_root: &str, client_id: &str, salt: &[u8]) -> Vsid`
  - [x] Formule : `SHA3-256(len_u32_be(did_root) || did_root || len_u32_be(client_id) || client_id || salt)`
  - [x] Longueurs préfixées en big-endian 4 bytes — évite les collisions (`:` est présent dans les DIDs)
  - [x] Salt : dérivé depuis MASTER_KEY via HKDF avec info = `"brigid-vsid-salt"`
  - [x] Résultat encodé en base64url (sans padding)
- [x] `VSID` est stable pour même (did, client_id, salt)
- [x] `VSID` différent si client_id change (non corrélable entre services)
- [x] `VSID` ne dérive jamais depuis un alias (contrainte stricte)
- [x] `VSID` ne dérive jamais depuis une identité virtuelle (contrainte stricte)

## Tests

- [x] `RootId::parse("berenger@brig.id")` → Ok
- [x] `RootId::parse("berenger")` → Err (pas de @)
- [x] `RootId::parse("@brig.id")` → Err (username vide)
- [x] `PrivateAlias::is_valid("x8Fj_29K")` → true
- [x] `PrivateAlias::is_valid("noUnderscore")` → false
- [x] `parse_identifier` : tous les cas
- [x] VSID stable : même entrées → même VSID
- [x] VSID non corrélé : client_id différent → VSID différent
- [x] VSID ≠ f(alias) : test que l'algo n'utilise jamais l'alias
- [x] 100% coverage (667 lignes workspace, 30 nouveaux tests)

---

## Vérification finale

- [x] `cargo test -p brigid-identity` passe 100% (30 tests)
- [x] `cargo llvm-cov --workspace --summary-only` → 100% lignes (667 lignes, 0 manquée)
- [x] `cargo clippy -- -D warnings` clean
- [x] `cargo fmt --all --check` clean
- [x] `cargo deny check` clean
- [x] Propriétés critiques documentées dans les tests (pas de dérivation depuis alias)
