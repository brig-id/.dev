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

---

## CSP : `'unsafe-inline'` temporaire (script-src / style-src)

**Repos concernés :** `server-leaf` (fix appliqué), `core` (même angle mort, pas
encore corrigé)

**Contexte :** en corrigeant le bug où le header CSP de `server-leaf` ne
touchait jamais les pages UI (voir commit `fix(leaf): 🔒️ CSP/security headers
never reached the UI fallback` sur `dev/forge`), on a découvert — en ouvrant
vraiment l'app dans un navigateur avec ce CSP réellement appliqué — que le
commentaire existant (« Qwik ne génère pas de scripts inline en mode SSG »,
présent aussi bien dans `server-leaf` que dans `brigid-api::build_router` du
repo `core`) est **faux** : le build statique de Qwik (adapter `static`)
émet plusieurs `<script>`/`<style>` inline (son bootstrap de résumabilité),
et `web` charge une police externe (`fonts.bunny.net`). Avec `script-src
'self'`/`style-src 'self'` strictement appliqués (ce qui n'était jamais
arrivé jusqu'ici, silencieusement), un navigateur bloque tout ça — plus
aucun web component (`wa-input`, `wa-button`, …) ne s'active, l'app entière
devient non-interactive.

**État actuel (stopgap) :** `server-leaf/src/lib.rs` ajoute `'unsafe-inline'`
à `script-src`/`style-src`, plus `https://fonts.bunny.net` en source
autorisée. Ça débloque l'app mais annule une bonne partie de la protection
XSS que CSP est censé apporter — à traiter comme dette technique explicite,
pas comme une solution acceptée.

**Vraie solution (pas encore faite) :** allowlist par hash SHA-256,
calculée au build :

- [ ] `web` : script de build (à greffer après `build.server`/SSG) qui scanne
      `dist/**/*.html`, extrait le contenu exact de chaque `<script>`/`<style>`
      inline, calcule son hash `sha256-...`, et écrit un manifeste
      (ex. `dist/csp-hashes.json`) dédupliqué.
- [ ] `server-leaf` : au démarrage, lire ce manifeste (si présent) et
      construire dynamiquement la valeur du header CSP en y ajoutant les
      hashes trouvés, au lieu de la chaîne statique actuelle — garde
      `script-src`/`style-src` réellement stricts (bloque tout script tiers
      non prévu) tout en autorisant précisément ce que le build de Qwik émet.
- [ ] Vérifier si les hashes sont stables d'un build à l'autre (même version
      Qwik, même structure de page) ou s'ils varient à chaque build — impacte
      si le manifeste doit être régénéré/commité ou seulement généré à la
      volée juste avant que `leaf` démarre.
- [ ] `core/brigid-api` a le même commentaire erroné et la même CSP
      statique — n'affecte pas `server-leaf` en pratique (ses routes
      renvoient du JSON, pas du HTML exécuté), mais vaut le coup d'être
      corrigé pour rester cohérent le jour où un autre repo (`server-grove`,
      `server-forest`) sert aussi de l'UI Qwik derrière `build_router`.

---

## Bug SSG statique : l'hydratation Qwik ne démarre jamais (chunk vide)

**Repos concernés :** `web`

**Contexte :** en construisant la suite Playwright (voir
`web/e2e/`), la suite a dû être pointée vers `pnpm dev` (SSR) plutôt que vers
le build statique (`pnpm build` + adapter `static`, ajouté ce même jour) —
parce que ce dernier ne fonctionne pas du tout dans un vrai navigateur.

**Diagnostic fait :** reproduit en servant `dist/` avec un simple serveur
statique Python (`server-leaf` et son CSP complètement hors jeu) :

- `window.qwikevents` existe (le petit script inline qui l'initialise
  s'exécute bien).
- Mais **aucun** web component (`wa-input`, `wa-button`, `wa-card`, …) ne
  devient interactif, et aucune requête n'est jamais faite vers les chunks
  `@web.awesome.me/webawesome-pro` (`wa.input()`, `wa.card()`, etc. dans
  `web/src/lib/wa.ts` ne sont jamais appelés).
- Cause trouvée : le premier `<script type="module" async src="/build/q-XXXXXXXX.js">`
  de chaque page HTML générée — censé être le vrai bootstrap qwikloader —
  pointe vers un fichier de **0 octet**. Il ne se passe donc littéralement
  rien à l'exécution.
- Suspect principal : ce projet utilise `rolldown-vite` (alias npm de
  `vite` dans `package.json`) plutôt que Vite/Rollup standard — un
  bundler encore jeune/expérimental. Pas confirmé, mais cohérent avec un
  bug de découpage de chunks propre à Rolldown plutôt qu'à Qwik lui-même.

- [ ] Confirmer si le chunk vide est déterministe (même fichier vide à
      chaque `pnpm build`) ou aléatoire.
- [ ] Tester avec le vrai package `vite` (sans l'alias `rolldown-vite`) pour
      isoler si le bug vient de Rolldown spécifiquement.
- [ ] Si confirmé côté Rolldown : ouvrir un ticket amont (rolldown-vite ou
      Qwik) et/ou revenir temporairement à `vite` standard pour `build.client`
      (au moins pour le build de prod, `pnpm dev` peut rester sur rolldown-vite
      si le problème ne s'y manifeste pas).
- [ ] Une fois corrigé : réaligner `web/playwright.config.ts` pour tester
      contre `pnpm build` + un seul `leaf` (topologie de prod réelle) plutôt
      que contre `pnpm dev` + proxy — voir le commentaire "KNOWN ISSUE" en
      tête de ce fichier.
- [ ] Ce bug remet aussi en question la validation faite plus tôt de
      "Docker Compose dev" (phase-3) : les checks `curl` passaient parce
      qu'ils ne vérifient que le HTML brut, jamais l'interactivité réelle
      dans un navigateur.

---

## `/passkeys` : "Add a passkey" enregistre une identité, pas un 2e credential

**Repos concernés :** `web`

**Contexte :** trouvé en écrivant `web/e2e/auth.spec.ts` (test "deleting a
passkey updates the list") — remplir le champ "Add a passkey" avec le
username du compte **déjà connecté** échoue avec `user X already exists`.
En regardant `passkeys/index.tsx::handleAdd`, c'est normal : il appelle la
même fonction `register()` que la page `/register/`, qui crée une toute
nouvelle identité — ça n'ajoute pas un second credential/passkey à
l'identité actuellement connectée. Le libellé "Add a passkey" laisse
pourtant penser le contraire (pattern UX classique : "ajouter une clé de
secours à mon compte").

Pas sûr si c'est un bug ou une fonctionnalité différente mal nommée (ex. :
permettre d'enregistrer une identité pour quelqu'un d'autre depuis une
session admin ?). Le test a été adapté pour utiliser un second username
distinct, qui correspond au comportement réel actuel.

- [ ] Clarifier l'intention produit : "Add a passkey" doit-il (a) ajouter un
      credential supplémentaire à l'identité connectée (nécessiterait un
      nouvel endpoint côté `core`/`brigid-api`, pas besoin de re-saisir un
      username), ou (b) rester tel quel (enregistrer une autre identité
      depuis cette page) mais avec un libellé qui le dise clairement ?
- [ ] Ajuster le code (`web`) et/ou les tests en fonction de la réponse.
