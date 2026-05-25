# Phase 1 — `brig-id/crypto`

**Repo :** `brig-id/crypto`
**Prérequis :** Phase 0 terminée
**Parallèle avec :** Phase 2

---

## Initialisation

- [x] `cargo init --lib` dans `crypto/`
- [x] Configurer `Cargo.toml` : édition 2024, version 0.0.1, licence MIT/Apache-2.0
- [x] `.cargo/config.toml` : linker mold, flags release (LTO thin, codegen-units 1)
- [x] `deny.toml` : configurer licences (MIT/Apache-2.0) + advisories (cargo deny check)
- [x] Ajouter caller workflow `.github/workflows/ci.yml` (appelle reusable ci-rust)
- [x] Ajouter caller workflow `.github/workflows/security.yml` (appelle reusable security-audit)
- [x] Ajouter caller workflow `.github/workflows/coverage.yml`

## Dépendances Rust

- [x] `aes-gcm` — AES-256-GCM (RustCrypto)
- [x] `hkdf` + `sha3` — HKDF-SHA3-256 (RustCrypto)
- [x] `ed25519-dalek` — Ed25519 signatures (classique)
- [x] `ml-kem` — ML-KEM-768, FIPS 203 (RustCrypto, pure Rust)
- [x] `ml-dsa` — ML-DSA-65, FIPS 204 (RustCrypto, pure Rust)
- [x] `x25519-dalek` — X25519 pour le KEM hybride
- [x] `rand_core` + `getrandom` — RNG sécurisé (feature `js` si wasm, serveur uniquement pour Phase 1)
- [x] `zeroize` — zéroisation mémoire des secrets
- [x] `secrecy` — wrapper Secret<T> pour les clés
- [x] `hex` — décodage `MASTER_KEY` depuis l'environnement

## Implémentation

### MASTER_KEY loading
- [x] Charger depuis variable d'environnement (`BRIGID_MASTER_KEY`, encodage hex 64 chars)
- [x] Charger depuis fichier (path configurable, même format hex)
- [x] Valider la longueur exacte (32 bytes après décodage hex) au chargement
- [x] Vérifier que jamais hardcodé, jamais loggé
- [x] Type `MasterKey(Secret<[u8; 32]>)` avec `Zeroize`

### AES-256-GCM
- [x] Struct `EncryptedBlob { nonce: [u8; 12], ciphertext: Vec<u8> }` (évite confusion d'ordre de paramètres)
- [x] `encrypt(key, plaintext) -> EncryptedBlob` — nonce aléatoire 96 bits
- [x] `decrypt(key, blob) -> Zeroizing<Vec<u8>>` — plaintext zéroïsé automatiquement en drop (secret en mémoire)
- [x] Nonce jamais réutilisé, clé toujours zéroïsée après usage
- [x] Profile release : `panic = "abort"` (empêche les unwinds de laisser des secrets sur la stack)

### HKDF-SHA3-256
- [x] `derive_key(master, info, length) -> Secret<[u8; N]>`
- [x] `derive_user_key(master, user_id, purpose) -> Secret<[u8; 32]>` — clé par utilisateur

### Ed25519 (classique)
- [x] `generate_keypair() -> (SigningKey, VerifyingKey)`
- [x] `sign(key, message) -> Signature`
- [x] `verify(vk, message, sig) -> bool`

### ML-KEM-768 + X25519 (hybride PQC, FIPS 203)
- [x] `hybrid_kem_keygen() -> (PublicKey, SecretKey)` — ML-KEM-768 + X25519 combined
- [x] `hybrid_encapsulate(pk) -> (Ciphertext, SharedSecret)`
- [x] `hybrid_decapsulate(sk, ct) -> SharedSecret`
- [x] Combiner les deux shared secrets via HKDF : `SS = HKDF(SS_mlkem || SS_x25519, info = b"brigid-hybrid-kem-v1")` (domain separation)

### ML-DSA-65 + Ed25519 (hybride PQC, FIPS 204)
- [x] `hybrid_keygen() -> (SigningKey, VerifyingKey)`
- [x] `hybrid_sign(sk, message) -> HybridSignature`
- [x] `hybrid_verify(vk, message, sig) -> bool`
- [x] Signature = concat(ml_dsa_sig, ed25519_sig) avec préfixes longueurs

### Fuzz targets (`cargo-fuzz`, nightly)
- [x] `fuzz_decrypt` — entrée aléatoire dans decrypt (must not panic)
- [x] `fuzz_hybrid_decapsulate` — ciphertext aléatoire
- [x] `fuzz_hybrid_verify` — signature aléatoire

## Tests
- [ ] 100% unit test coverage (`cargo llvm-cov`) — atteint 92.64% lignes
- [ ] Tests de régression vecteurs FIPS 203 (ML-KEM test vectors)
- [ ] Tests de régression vecteurs FIPS 204 (ML-DSA test vectors)
- [x] Test : decrypt(encrypt(x)) == x pour AES-GCM
- [x] Test : verify(sign(m)) == true, tampered msg == false
- [x] Test : hybrid KEM round-trip
- [x] Test : deux appels successifs à `encrypt()` produisent des nonces distincts

## Sécurité
- [x] `cargo audit` — zéro advisory
- [x] `cargo deny check` — zéro violation (licences + advisories)
- [x] `clippy --deny warnings` — zéro warning
- [x] Pas de `unwrap()` sur des chemins d'erreur crypto (tout propagé proprement)
- [x] Secrets zéroïsés (`Zeroize`) en drop

---

## Vérification finale

- [x] `cargo test` passe 100% (27/27 tests)
- [ ] `cargo llvm-cov --summary-only` → 100% lines — atteint 92.64%
- [ ] `cargo +nightly fuzz run fuzz_decrypt -- -max_total_time=60` → pas de crash
- [x] `cargo audit` clean
- [x] `cargo deny check` clean
- [x] `cargo clippy -- -D warnings` clean
