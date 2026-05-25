# Phase 3 — `brig-id/core` : Identity & VSID

**Repo :** `brig-id/core`
**Prérequis :** Phase 2 terminée
**Crate :** `brigid-identity`

---

## Crate `brigid-identity`

### Dépendances
- [ ] `brigid-crypto` (git dep)
- [ ] `brigid-store` (workspace dep)
- [ ] `sha3` — hachage pour VSID
- [ ] `serde` — sérialisation
- [ ] `thiserror` — erreurs typées

## Formats d'identifiants

### Root public identity
- [ ] Type `RootId { username: String, server: String }`
- [ ] `RootId::parse(input: &str) -> Result<RootId>` — valide `username@server`
  - [ ] `username` : alphanumérique + `-_`, 3–64 chars, pas de `@` ni `_` seul
  - [ ] `server` : domaine valide (RFC 1123)
- [ ] `RootId::to_string()` → `username@server`
- [ ] `RootId::to_did_web()` → `did:web:server:u:username`

### Alias privés (structure, pas encore exposé en 0.0.1)
- [ ] Type `PrivateAlias(String)` — contient au moins un `_`, pas de `@`
- [ ] `PrivateAlias::is_valid(s: &str) -> bool`
- [ ] `PrivateAlias::to_did_peer()` — strip `_`, encode en DID:peer

### Détection du type d'entrée utilisateur
- [ ] `parse_identifier(input) -> IdentifierKind`
  - [ ] `@` présent → `RootPublic(RootId)`
  - [ ] `_` présent sans `@` → `PrivateAlias(PrivateAlias)`
  - [ ] sinon → `Err(InvalidIdentifier)`

## VSID (Virtual Stable ID)

- [ ] `compute_vsid(did_root: &DID, client_id: &str, salt: &[u8]) -> VSID`
  - [ ] Formule : `SHA3-256(len_u32_be(did_root) || did_root || len_u32_be(client_id) || client_id || salt)`
  - [ ] Longueurs préfixées en big-endian 4 bytes — évite les collisions (`:` est présent dans les DIDs)
  - [ ] Salt : dérivé depuis MASTER_KEY via HKDF avec info = `"brigid-vsid-salt"`
  - [ ] Résultat encodé en base64url (sans padding)
- [ ] `VSID` est stable pour même (did, client_id, salt)
- [ ] `VSID` différent si client_id change (non corrélable entre services)
- [ ] `VSID` ne dérive jamais depuis un alias (contrainte stricte)
- [ ] `VSID` ne dérive jamais depuis une identité virtuelle (contrainte stricte)

## Tests

- [ ] `RootId::parse("berenger@brig.id")` → Ok
- [ ] `RootId::parse("berenger")` → Err (pas de @)
- [ ] `RootId::parse("@brig.id")` → Err (username vide)
- [ ] `PrivateAlias::is_valid("x8Fj_29K")` → true
- [ ] `PrivateAlias::is_valid("noUnderscore")` → false
- [ ] `parse_identifier` : tous les cas
- [ ] VSID stable : même entrées → même VSID
- [ ] VSID non corrélé : client_id différent → VSID différent
- [ ] VSID ≠ f(alias) : test que l'algo n'utilise jamais l'alias
- [ ] 100% coverage

---

## Vérification finale

- [ ] `cargo test -p brigid-identity` passe 100%
- [ ] `cargo llvm-cov -p brigid-identity --summary-only` → 100%
- [ ] `cargo clippy -- -D warnings` clean
- [ ] Propriétés critiques documentées dans les tests (pas de dérivation depuis alias)
