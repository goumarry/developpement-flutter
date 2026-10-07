# Event Planner — TP 8 : intégration Firebase (espace organisateur)

Projet Flutter `event_planner_firebase`, **copie du TP 7**
(`event_planner_storage`, lui-même fusion TP 2-7) à laquelle s'ajoute un
**espace organisateur** adossé à Firebase : authentification par courriel et
mot de passe, liste d'événements Firestore en temps réel, règles de
sécurité serveur.

- Projet Firebase : `event-planner-firebase-yg` (plan Spark, gratuit).
- Plateforme de test : **Android** (émulateur). Windows et Web sont
  configurés via FlutterFire mais non testés.
- Dépendances ajoutées par ce TP : `firebase_core`, `firebase_auth`,
  `cloud_firestore` (versions exactes : `pubspec.lock`).
- **Écart avec l'énoncé** : le projet porte le nom `event_planner_firebase`
  (et non `event_planner_auth`), et les fichiers demandés sont greffés sur
  l'application existante plutôt que sur un projet vierge. `provider` et
  `http` (TP 4/5) sont toujours présents mais **ne servent pas à l'état
  d'authentification** : celui-ci ne s'observe que par `StreamBuilder` sur
  `authStateChanges()` / `userChanges()`. Le modèle Firestore
  `OrganizerEvent` (`lib/models/organizer_event.dart`) est distinct du
  `Event` du fil rouge (`lib/models/event.dart`), pour ne rien casser des
  écrans hérités.

## Mise en route

```bash
npm install -g firebase-tools && firebase login
dart pub global activate flutterfire_cli     # puis ~/.pub-cache/bin dans le PATH
flutterfire configure --project=event-planner-firebase-yg --platforms=android,windows,web
flutter pub get
flutter run
```

À faire une fois dans la console Firebase (non automatisable proprement par
la CLI) : **Authentication > Get started > Sign-in method > Email/Password >
activer**. Sans cela, l'inscription renvoie `operation-not-allowed` (message
déjà traduit par l'application) / `CONFIGURATION_NOT_FOUND` en REST.

Règles : `firebase deploy --only firestore:rules --project event-planner-firebase-yg`.

## Structure ajoutée

```
lib/main.dart                         init Firebase + écran d'erreur si échec
lib/firebase_options.dart             généré par FlutterFire
lib/config/firebase_config.dart       drapeau USE_EMULATORS (partie D)
lib/models/app_user.dart              vue immuable de l'utilisateur
lib/models/organizer_event.dart       document Firestore `events`
lib/services/auth_gate.dart           garde d'accès (StreamBuilder)
lib/services/events_service.dart      requêtes Firestore
lib/screens/login_screen.dart
lib/screens/register_screen.dart
lib/screens/reset_password_screen.dart
lib/screens/organizer_home_screen.dart   liste temps réel (onglet « Orga. »)
lib/screens/profile_screen.dart
lib/screens/diagnostics_screen.dart   (en plus) provoque refus / index manquant
lib/utils/auth_error_translator.dart
lib/utils/firestore_error_translator.dart
firestore.rules  firestore.indexes.json  firebase.json
scripts/prove_rules.sh                preuve des refus par appels REST directs
```

## Partie A — configuration

### Gestion de version des fichiers de configuration

Décision : **`lib/firebase_options.dart` et `android/app/google-services.json`
sont versionnés** (rien à ce sujet dans `.gitignore`, qui n'exclut que
journaux, caches de la CLI et clés de compte de service).

Raisonnement : ces fichiers contiennent l'`apiKey`, le `projectId`, l'`appId`.
Ce sont des **identifiants publics**, qui se retrouvent de toute façon dans
chaque APK ou page web distribué ; ils servent à *adresser* le projet, pas à
*s'y authentifier*. Les connaître ne donne accès à aucune donnée : l'accès est
décidé par `firestore.rules` côté serveur (voir `NOTE-SECURITE.md`). Les
versionner rend le dépôt compilable tel quel par un relecteur ou un
coéquipier. Une **vraie clé secrète** suit une logique inverse : clé de
compte de service / SDK Admin (`*-adminsdk-*.json`), clé serveur, jeton d'une
API tierce donnent un pouvoir direct et illimité sur le projet ou le service ;
elles ne doivent jamais être committées (et, si c'est arrivé, doivent être
révoquées, pas seulement supprimées de l'historique). Le `.gitignore` exclut
d'ailleurs préventivement les motifs `*-adminsdk-*.json` et
`serviceAccount*.json`. Seule précaution complémentaire utile : restreindre la
clé d'API (application Android, quotas) dans la console Google Cloud.

### Échec d'initialisation

`main()` entoure `Firebase.initializeApp` d'un `try/catch` : en cas d'échec,
`FirebaseInitErrorApp` s'affiche (message explicite + bouton « Réessayer »)
au lieu d'une exception non interceptée.

### Avertissement Gradle « Kotlin Gradle Plugin »

`flutter run` affiche : *« Your app uses the following plugins that apply
Kotlin Gradle Plugin (KGP): firebase_core »*. C'est un **avertissement
annoncé pour de futures versions de Flutter**, pas une erreur : le plugin
n'a pas encore migré vers « Built-in Kotlin ». Rien à corriger dans le projet ;
la solution durable est une mise à jour future du plugin.

## Partie B — authentification

- **Garde d'accès** (`AuthGate`) : un unique `StreamBuilder` sur
  `authStateChanges()`, monté par la route racine `/`. Pas de session → le
  flux « déconnecté » ; session → toute l'application. L'espace organisateur
  n'existe donc **pas dans l'arbre de widgets** sans session : il est
  inatteignable, pas seulement masqué.
- **Restauration de session** : tant que le flux n'a pas émis, un écran
  d'attente est affiché (jamais l'écran de connexion). Un utilisateur déjà
  connecté ne voit pas l'écran de connexion au lancement.
- **Déconnexion sans retour possible** : à `signOut()`, `AuthGate` remplace
  toute la branche connectée ; les `Navigator` imbriqués des onglets (et leur
  pile) sont détruits avec elle. Le bouton retour ne peut pas y revenir. Le
  flux déconnecté a lui aussi son propre `Navigator` : l'écran
  d'inscription ne reste pas empilé par-dessus l'application après une
  connexion réussie.
- **Inscription** : `createUserWithEmailAndPassword` puis
  `sendEmailVerification` (un échec d'envoi n'annule pas l'inscription).
- **Réinitialisation** : `sendPasswordResetEmail`, avec carte de
  confirmation. Firebase n'indique pas si l'adresse existe (protection contre
  l'énumération de comptes) ; la formulation du message en tient compte.
- **Vérification du courriel** : bandeau dans l'espace organisateur, basé sur
  `userChanges()`, boutons « Renvoyer » et « Actualiser » (`reload()`). Ne
  bloque pas l'accès.
- **Profil** : `updateDisplayName` puis `reload()`, le nom se met à jour
  dans l'interface via `userChanges()`. (L'ancienne `updateProfile(...)` est
  dépréciée et n'est pas utilisée.)

### Traduction des erreurs

`lib/utils/auth_error_translator.dart`, fonction centralisée : aucun écran
n'affiche `e.message` ni `e.toString()`. Tout code inconnu retombe sur un
message générique.

| Code | Message affiché |
|---|---|
| `email-already-in-use` | Un compte existe déjà avec cette adresse courriel… |
| `invalid-email` | Cette adresse courriel n'est pas valide… |
| `weak-password` | Mot de passe trop faible : au moins 6 caractères. |
| `invalid-credential` / `wrong-password` (/ `user-not-found`) | Adresse courriel ou mot de passe incorrect. |
| `too-many-requests` | Trop de tentatives. Patientez quelques minutes… |
| `operation-not-allowed` | La connexion par courriel/mot de passe n'est pas activée… |
| `network-request-failed` (en plus) | Connexion réseau indisponible… |
| autre | Une erreur est survenue. Veuillez réessayer… |

Remarque : sur un projet récent, une mauvaise saisie de mot de passe **et** un
compte inexistant produisent tous deux `invalid-credential` ; `wrong-password`
n'apparaît plus que sur d'anciens projets. Les deux sont donc traités
ensemble, et volontairement avec le même message (ne pas révéler si un compte
existe).

**Vérification sur l'émulateur, essais réels** (énoncé : « en provoquant réellement chaque erreur ») :

| Code | Manipulation | Message observé |
|---|---|---|
| `email-already-in-use` | s'inscrire avec un courriel existant | « Un compte existe déjà avec cette adresse courriel. Connectez-vous ou réinitialisez votre mot de passe. » (constaté sur l'émulateur) |
| `invalid-email` | courriel `abc` | « Cette adresse courriel n'est pas valide. Vérifiez-la (exemple : prenom@domaine.fr). » (constaté) |
| `weak-password` | mot de passe `123` | « Mot de passe trop faible : choisissez au moins 6 caractères. » (constaté) |
| `invalid-credential` | mauvais mot de passe | « Adresse courriel ou mot de passe incorrect. » (constaté) |
| `too-many-requests` | échecs répétés (courriel factice) | « Trop de tentatives. Patientez quelques minutes avant de réessayer. » (constaté au 7e essai) |
| `operation-not-allowed` | désactiver Email/Password dans la console, réessayer | _non provoqué_ : désactiver le fournisseur sur le projet en ligne n'a pas été fait ; le message n'est vérifié que par lecture du code (`translateAuthCode`). |

## Partie C — Firestore et sécurité

### Modèle

Collection `events` ; un document par événement, identifiant généré par
Firestore (`add`) — jamais l'UID. Champs : `title`, `ownerId` (UID du
créateur), `location`, `date`, `createdAt` (`FieldValue.serverTimestamp()`).

### Temps réel

`OrganizerHomeScreen` : `StreamBuilder` sur
`where('ownerId', isEqualTo: uid).snapshots(includeMetadataChanges: true)`.
Modifier un champ dans la console doit se refléter à l'écran sans action
(capture `captures/propagation-temps-reel.png`).

Le tri sur `createdAt` est fait **côté client**, volontairement : l'ajouter à
la requête exigerait l'index composite décrit plus bas. Pendant l'écriture
locale, `createdAt` vaut `null` (le serveur n'a pas encore résolu
`serverTimestamp()`) : l'événement est placé en tête de liste.

### Règles de sécurité (`firestore.rules`)

- non authentifié : tout refusé (`request.auth != null` est requis partout) ;
- `read`, `update`, `delete` : uniquement si `resource.data.ownerId ==
  request.auth.uid` ;
- `create` : uniquement si `request.resource.data.ownerId == request.auth.uid`
  (on ne peut pas créer un événement au nom d'un autre) ;
- tout le reste : refusé par défaut.

Déployées avec `firebase deploy --only firestore:rules`.

**Preuve du refus.** Le refus d'une lecture non authentifiée a été
constaté par appel REST direct :
`GET .../databases/(default)/documents/events` sans jeton → **HTTP 403**.
Le scénario « B modifie l'événement de A » est rejoué par
`scripts/prove_rules.sh` (deux comptes de test créés puis supprimés par le
script), qui écrit `captures/refus-regles-securite.log`. L'écran
« Diagnostic règles / index » de l'application provoque les mêmes refus
depuis le client et affiche le code `permission-denied` ; la liste elle-même
affiche un message explicite et reste stable (bouton « Réessayer »).

### Écriture locale vs confirmation serveur

Lors d'un `add`/`update`, le SDK applique l'écriture à son cache local et
**notifie immédiatement le flux** : l'élément apparaît à l'écran avant que le
serveur ait répondu. Les métadonnées permettent de distinguer :
- `doc.metadata.hasPendingWrites == true` : écriture locale non encore
  confirmée (icône ☁↑) ;
- `isFromCache == true` : donnée issue du cache local, sans confirmation du
  serveur (icône ☁ barré) ;
- les deux à `false` : confirmé par le serveur (icône ☁✓).

Avec `includeMetadataChanges: true`, la liste se redessine quand l'état passe
de « en attente » à « confirmé ». Le `Future` renvoyé par `add` ne se résout
**qu'à la confirmation serveur** (jamais hors ligne) : l'application ne
bloque donc rien dessus.

### Index manquant

Le bouton « Requête sans index composite » de l'écran de diagnostic exécute
`where('ownerId', isEqualTo: uid).orderBy('date', descending: true)`. Sans
index composite `(ownerId, date)`, Firestore répond `failed-precondition`
avec un message contenant un **lien de création directe** de l'index
(capture : `captures/diagnostic-permission-denied-et-index.png`).

Pourquoi cette contrainte : Firestore garantit que le coût d'une requête
dépend de la taille du **résultat**, pas de celle de la collection. Il y
parvient en ne répondant qu'à partir d'index triés, qu'il parcourt de façon
contiguë ; un filtre d'égalité sur un champ combiné à un tri sur un autre
champ exige un index trié sur cette paire de champs. Plutôt que de scanner
toute la collection (lent et coûteux, imprévisible à grande échelle), il
refuse la requête et demande de créer l'index.

### Comportement hors connexion

La persistance locale est activée par défaut sur Android. Comportement
attendu, observé sur l'émulateur Android (réseau coupé via `adb shell svc wifi/data disable`) :

| Action hors ligne | Attendu | Constaté |
|---|---|---|
| Relire la liste déjà chargée | fonctionne (cache), bandeau « cache local » | Liste toujours affichée, 2 événements visibles (`captures/hors-ligne.png`) |
| Créer / renommer un événement | visible tout de suite, icône « en attente » | « Hors_ligne » apparaît immédiatement, bandeau « Modifications locales en attente de confirmation serveur » |
| Lire un document jamais chargé | rien dans le cache : attente / vide | _non testé_ |
| Retour du réseau | écritures envoyées, icônes passent à « confirmé » | Après réactivation du Wi-Fi, bandeau repassé à « Données confirmées par le serveur », l'événement est conservé |
| Auth (connexion, réinitialisation) | échoue : `network-request-failed` traduit | Connexion refusée : « Connexion réseau indisponible. Vérifiez votre connexion et réessayez. » |

### Abonnements

Aucun `StreamSubscription` manuel dans l'application : tous les flux
(`authStateChanges`, `userChanges`, `snapshots`) sont consommés par des
`StreamBuilder`, qui annulent leur abonnement à la destruction du widget.
Les `TextEditingController` sont libérés dans `dispose()`.

## Partie D — émulateurs (optionnel, fait)

`firebase.json` configure les émulateurs Auth (9099) et Firestore (8080).

```bash
firebase emulators:start --project demo-event-planner
flutter run --dart-define=USE_EMULATORS=true
```

Le drapeau `USE_EMULATORS` (`lib/config/firebase_config.dart`) bascule Auth
et Firestore vers les émulateurs avant tout autre appel, sans dupliquer le
code. Depuis l'émulateur Android, l'hôte est `10.0.2.2` (et non
`localhost`, qui désignerait l'émulateur lui-même). *Non testé de bout en
bout dans cette livraison.*

**Intérêt des émulateurs.** Pour la reproductibilité d'une formation :
chaque apprenant repart d'un état propre, sans dépendre d'un compte Google,
d'un projet en ligne partagé, ni du réseau ; les erreurs de configuration de
console (fournisseur non activé, règles non déployées) disparaissent du
chemin critique. Pour les tests automatisés : exécution rapide, aucun effet
de bord sur de vraies données, état réinitialisable entre deux exécutions
(les règles de sécurité peuvent même être testées en isolation).

## Vérifications

```bash
flutter analyze        # 0 issue
flutter build apk --debug
```
