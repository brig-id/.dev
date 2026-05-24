# Phase 1 — `brig-id/crypto`

**Repo :** `brig-id/crypto`
**Prérequis :** Phase 0 terminée
**Parallèle avec :** Phase 2

---

## Initialisation

- [ ] `cargo init --lib` dans `crypto/`
- [ ] Configurer `Cargo.toml` : édition 2024, version 0.0.1, licence MIT/Apache-2.0
- [ ] `.cargo/config.toml` : linker mold, flags release (LTO thin, codegen-units 1)
- [ ] Ajouter caller workflow `.github/workflows/ci.yml` (appelle reusable ci-rust)
- [ ] Ajouter caller workflow `.github/workflows/security.yml` (appelle reusable security-audit)
- [ ] Ajouter caller workflow `.github/workflows/coverage.yml`

## Dépendances Rust

- [ ] `aes-gcm` — AES-256-GCM (RustCrypto)
- [ ] `hkdf` + `sha3` — HKDF-SHA3-256 (RustCrypto)
- [ ] `ed25519-dalek` — Ed25519 signatures (classique)
- [ ] `ml-kem` — ML-KEM-768, FIPS 203 (RustCrypto, pure Rust)
- [ ] `ml-dsa` — ML-DSA-65, FIPS 204 (RustCrypto, pure Rust)
- [ ] `x25519-dalek` — X25519 pour le KEM hybride
- [ ] `rand_core` + `getrandom` — RNG sécurisé
- [ ] `zeroize` — zéroisation mémoire des secrets
- [ ] `secrecy` — wrapper Secret<T> pour les clés

## Implémentation

### MASTER_KEY loading
- [ ] Charger depuis variable d'environnement (`BRIGID_MASTER_KEY`)
- [ ] Charger depuis fichier (path configurable)
- [ ] Vérifier que jamais hardcodé, jamais loggé
- [ ] Type `MasterKey(Secret<[u8; 32]>)` avec `Zeroize`

### AES-256-GCM
- [ ] `encrypt(key, plaintext) -> (nonce, ciphertext)` — nonce aléatoire 96 bits
- [ ] `decrypt(key, nonce, ciphertext) -> plaintext`
- [ ] Nonce jamais réutilisé, clé toujours zéroïsée après usage

### HKDF-SHA3-256
- [ ] `derive_key(master, info, length) -> Secret<[u8; N]>`
- [ ] `derive_user_key(master, user_id, purpose) -> Secret<[u8; 32]>` — clé par utilisateur

### Ed25519 (classique)
- [ ] `generate_keypair() -> (SigningKey, VerifyingKey)`
- [ ] `sign(key, message) -> Signature`
- [ ] `verify(vk, message, sig) -> bool`

### ML-KEM-768 + X25519 (hybride PQC, FIPS 203)
- [ ] `hybrid_kem_keygen() -> (PublicKey, SecretKey)` — ML-KEM-768 + X25519 combined
- [ ] `hybrid_encapsulate(pk) -> (Ciphertext, SharedSecret)`
- [ ] `hybrid_decapsulate(sk, ct) -> SharedSecret`
- [ ] Combiner les deux shared secrets via HKDF : `SS = HKDF(SS_mlkem || SS_x25519)`

### ML-DSA-65 + Ed25519 (hybride PQC, FIPS 204)
- [ ] `hybrid_keygen() -> (SigningKey, VerifyingKey)`
- [ ] `hybrid_sign(sk, message) -> HybridSignature`
- [ ] `hybrid_verify(vk, message, sig) -> bool`
- [ ] Signature = concat(ml_dsa_sig, ed25519_sig) avec préfixes longueurs

### Fuzz targets (`cargo-fuzz`, nightly)
- [ ] `fuzz_decrypt` — entrée aléatoire dans decrypt (must not panic)
- [ ] `fuzz_hybrid_decapsulate` — ciphertext aléatoire
- [ ] `fuzz_hybrid_verify` — signature aléatoire

## Tests
- [ ] 100% unit test coverage (`cargo llvm-cov`)
- [ ] Tests de régression vecteurs FIPS 203 (ML-KEM test vectors)
- [ ] Tests de régression vecteurs FIPS 204 (ML-DSA test vectors)
- [ ] Test : decrypt(encrypt(x)) == x pour AES-GCM
- [ ] Test : verify(sign(m)) == true, tampered msg == false
- [ ] Test : hybrid KEM round-trip
- [ ] Test : nonce collision improbable (statistical)

## Sécurité
- [ ] `cargo audit` — zéro advisory
- [ ] `cargo deny check` — zéro violation (licences + advisories)
- [ ] `clippy --deny warnings` — zéro warning
- [ ] Pas de `unwrap()` sur des chemins d'erreur crypto (tout propagé proprement)
- [ ] Secrets zéroïsés (`Zeroize`) en drop

---

## Vérification finale

- [ ] `cargo test` passe 100%
- [ ] `cargo llvm-cov --summary-only` → 100% lines
- [ ] `cargo +nightly fuzz run fuzz_decrypt -- -max_total_time=60` → pas de crash
- [ ] `cargo audit` clean
- [ ] `cargo deny check` clean
- [ ] `cargo clippy -- -D warnings` clean
