# Backlog — non planifié dans une phase v0.1.0

Idées et améliorations identifiées en cours de route, pas bloquantes pour la
release v0.1.0 et pas encore rattachées à une phase précise. Ne pas
supprimer d'entrée : cocher `[x]` une fois faite, ou déplacer vers la phase
qui la prend en charge le jour où elle est planifiée.

---

## Login sans username (discoverable credentials)

**Repos concernés :** `core` (`brigid-webauthn`, `brigid-api`), `web`

**Contexte :** `web/src/lib/validation.ts::parseLoginInput` gère déjà le cas
« username seul → serveur courant » et « `username@server` différent →
lien vers l'autre serveur » (voir `login/index.tsx`). Reste l'étape
suivante : proposer une connexion passkey sans même taper le username,
en s'appuyant sur les credentials discoverable/résidentes déjà créées par
`start_passkey_registration` (`brigid-webauthn/src/service.rs:40`).

- [ ] `core/brigid-webauthn` : exposer un flux d'authentification
      « discoverable » (pendant de `start_passkey_authentication`, sans
      liste de credentials en entrée — cf. l'API `webauthn-rs` dédiée) et
      résoudre l'utilisateur via `userHandle` au moment du finish.
- [ ] `core/brigid-api` : `username` devient optionnel dans
      `BeginLoginRequest` ; si absent, démarrer le flux discoverable.
- [ ] `web` : au chargement de `/login/`, si le navigateur supporte la
      conditional UI (`PublicKeyCredential.isConditionalMediationAvailable()`),
      lancer `navigator.credentials.get({ mediation: "conditional", ... })`
      en arrière-plan sur l'input username (autofill natif du navigateur).
- [ ] `web` : le formulaire username actuel (`parseLoginInput`) reste le
      fallback — automatique si la conditional UI n'est pas supportée, ou
      si la tentative discoverable échoue/est annulée.
- [ ] Tests : `core` (nouveau flux discoverable, `userHandle` inconnu →
      erreur propre) ; `web` (fallback vers le formulaire si
      `isConditionalMediationAvailable()` est absent ou renvoie `false`).
