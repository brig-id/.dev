# brig·id — Post-Phase Backlog

Items deferred from implementation phases because they are genuinely hard,
require external infrastructure, or have diminishing returns at the time of
writing. Track them here, not in phase checklists.

---

## crypto

### FIPS 203 / 204 Known Answer Tests

**Why deferred:** `ml-kem` and `ml-dsa` (RustCrypto) already pass NIST KATs
internally. Our hybrid wrappers add X25519 / Ed25519 around the PQC core and
use `OsRng` — they have no deterministic entry point exposed in the public API.
Adding KAT coverage would require either exposing internal deterministic APIs
in tests or testing the PQC primitives in isolation, which duplicates what the
upstream crates already do.

**What to do when prioritised:**
- Add `#[cfg(test)]` helpers that call `encapsulate_deterministic` / `from_seed`
  with fixed seeds from NIST's test vector files (ACVP JSON format).
- Source vectors: <https://github.com/usnistgov/ACVP-Server/tree/master/gen-val>
- Cover only the PQC layer, not the full hybrid (the X25519 / Ed25519 parts are
  covered by ed25519-dalek and x25519-dalek's own test suites).

### Test coverage below 100%

**Current:** 92.64% lines (as of phase 1 completion).

**Uncovered paths:**
- `master_key::from_env()` — requires setting `BRIGID_MASTER_KEY` env var;
  works fine but needs `std::env::set_var` which is `unsafe` in edition 2024
  multi-threaded tests.
- `master_key::from_file()` — needs a tempfile; straightforward to add with
  the `tempfile` crate if 100% coverage becomes a hard requirement.
- Some `Io` error branches in error handling.

**What to do when prioritised:**
- Add `tempfile` as a `dev-dependency`.
- Test `from_env` with `std::env::set_var` inside a dedicated single-threaded
  integration test (or use `serial_test` crate to isolate env mutations).
- Target: `cargo llvm-cov --workspace` ≥ 98% lines.

### Fuzz target execution in CI

**Current:** Three fuzz targets written (`fuzz_decrypt`, `fuzz_hybrid_decapsulate`,
`fuzz_hybrid_verify`) but never executed — only compiled locally.

**What to do when prioritised:**
1. Verify nightly compilation: `cargo +nightly fuzz build`
2. Add `.github/workflows/fuzz.yml` — `workflow_dispatch` trigger +
   weekly scheduled run; 60–300 seconds per target.
3. Alternatively enrol in Google OSS-Fuzz for continuous background fuzzing.
4. Store crash corpora as workflow artifacts.

---

## General

### Conventional commit scopes

Phase labels (`phase-1`, `phase-2`, …) are not valid scopes. Use component
names: `crypto`, `core`, `ci`, `store`, `api`, `ui`, etc.
