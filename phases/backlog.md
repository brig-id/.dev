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

---

## Automatiser le setup dev local (mkcert + env vars leaf)

**Repos concernés :** `web`, `server-leaf`, `.dev` (devcontainer)

**Contexte :** pour tester un vrai flux WebAuthn en dev (voir `web/README.md` "HTTPS in
dev" et `server-leaf/AGENTS.md` "Local dev without Docker"), il faut aujourd'hui, à la
main, à chaque nouvelle machine/clone :

- générer et faire confiance à un CA local (`mkcert -install`) — et si le test se fait
  depuis le navigateur de l'hôte via un port forwardé du devcontainer, l'importer
  aussi côté hôte (Firefox a son propre magasin de certs, indépendant du système —
  import manuel via `about:preferences#privacy` → Certificats → Autorités → Importer)
- générer le certificat `brigid.localhost` dans `web/.cert/` (gitignored)
- exporter `BRIGID_MASTER_KEY` (aléatoire, perdu à chaque nouveau shell) et
  `LEAF_SERVER__DOMAIN`/`LEAF_SERVER__PUBLIC_URL` pour que `leaf` matche l'origine
  `https://brigid.localhost:5173` de `web`

Rien de tout ça n'est bloquant pour avancer, mais c'est de la friction répétée à chaque
rebuild de devcontainer ou nouvelle machine.

- [ ] Script `dev.sh` (ou équivalent) à la racine de `web` et/ou `server-leaf` qui
      génère le cert mkcert s'il est absent, et lance `leaf` + `pnpm dev` avec les bons
      env vars en une seule commande.
- [ ] Persister `BRIGID_MASTER_KEY` dans un fichier `.env` local gitignored plutôt que
      de le régénérer à chaque session (avec un avertissement clair que ce n'est QUE
      pour le dev — jamais pour la prod, voir la contrainte `server-leaf/AGENTS.md`
      "Hard security constraints").
- [ ] Évaluer si `postCreateCommand`/une feature devcontainer (`.dev/.devcontainer/devcontainer.json`)
      peut automatiser `mkcert -install` + génération du cert `brigid.localhost` au
      build du conteneur, pour que ce soit prêt dès le premier `pnpm dev` — attention à
      la limite déjà documentée : le CA installé dans le conteneur n'est pas trusted
      côté hôte, donc l'étape d'import navigateur hôte restera manuelle de toute façon.
