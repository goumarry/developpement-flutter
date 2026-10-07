# Event Planner — TP 10 : projet final

Application Flutter `event_planner_app`, version candidate à la publication du
fil rouge : un **catalogue d'événements** alimenté par une API distante, un
**espace organisateur** authentifié, l'**inscription de participants** soumise
à des règles métier, des **préférences persistantes** et un **mode dégradé**
hors connexion.

- Flutter 3.47.2 / Dart 3.13.2 — cible testée : **Android** (émulateur).
- Dépendances : `provider`, `http`, `shared_preferences`, `path_provider`,
  `firebase_core`, `firebase_auth`, `cloud_firestore`, `flutter_localizations`
  (SDK). Aucune autre.

## 1. Périmètre fonctionnel réel

### Livré

| Fonction | Détail |
|---|---|
| Catalogue | `https://dummyjson.com/products`, réinterprété en événements. Pagination `limit`/`skip` arrêtée par `total`, recherche (`/products/search`), tri (date, titre, places restantes). Consultable **sans compte**. |
| Latence et panne | Réglages > « Démonstration réseau » : `?delay=3000` ou `/http/500` sur chaque appel du catalogue. Délai d'expiration de 8 s, une nouvelle tentative sur les erreurs transitoires. |
| Mode dégradé | Le dernier catalogue chargé est copié sur disque ; si l'appel échoue, il est affiché avec un bandeau « Catalogue non actualisé — copie locale du … ». |
| Espace organisateur | Firebase Auth (courriel / mot de passe : connexion, création de compte, mot de passe oublié). Création, modification, suppression de ses événements dans Firestore, en temps réel. |
| Isolation entre comptes | Requête filtrée sur `ownerId` **et** `firestore.rules` (preuve : `scripts/prove_rules.sh`). |
| Inscription | Formulaire validé ; refus si la capacité est atteinte, refus d'un doublon (même courriel, même événement). |
| Panier d'inscriptions | `RegistrationCartState` (`ChangeNotifier` via Provider) : consultation, retrait, puis confirmation finale (écriture Firestore). |
| Préférences | Thème clair / sombre / système et tri par défaut, via `SharedPreferencesAsync`, chargés avant `runApp`. |
| Adaptatif et accessible | Téléphone : liste + barre de navigation basse. Tablette (≥ 600 dp) : grille + rail latéral + détail en deux volets. Zones tactiles ≥ 48 dp, équivalents textuels, annonces `liveRegion`. |

### Non livré, limites assumées

- **Capacité côté serveur.** Pour un événement du catalogue, la capacité est
  vérifiée par l'application seulement : DummyJSON est en lecture seule, il
  n'existe aucun compteur partagé à protéger. Deux comptes différents peuvent
  donc chacun prendre « la dernière place ». Le **doublon**, lui, est bloqué
  aussi par le serveur (identifiant de document déterministe).
  Détail au § 11.
- **Revue de pair** : non réalisée ; aucun fichier `REVUE-PAIR.md` n'est
  remis. La revue de code du rendu est celle de la Partie C.3, dans
  `USAGE-IA.md`.
- **Compteur d'inscrits des événements d'organisateur** : non stocké ; la
  jauge compte les inscriptions de l'utilisateur connecté.
- **Tri** : appliqué aux événements déjà chargés, pas à tout le catalogue (la
  signature imposée de `fetchEvents` ne porte pas de tri).
- **Écritures hors connexion** : mises en file par le SDK Firestore et
  signalées (« enregistré hors connexion »), mais sans file d'attente
  applicative ni résolution de conflit (défi D.1 non traité).
- Défis D.1 (hors connexion complet) et D.3 (internationalisation) non
  traités. D.2 : voir § 9.
- iOS, web, bureau : non configurés.

## 2. Installation et exécution

```bash
flutter pub get
flutter run                      # émulateur ou appareil Android
flutter test                     # hors ligne, sans Firebase
flutter analyze
```

### Configuration Firebase

Le projet est déjà relié au projet Firebase `event-planner-firebase-yg`.
Pour le relier à **votre** projet :

```bash
npm install -g firebase-tools && firebase login
dart pub global activate flutterfire_cli      # puis ~/.pub-cache/bin dans le PATH
flutterfire configure --project=<votre-projet> --platforms=android \
  --out=lib/data/firebase/firebase_options.dart
firebase deploy --only firestore:rules --project <votre-projet>
```

Puis, dans la console : **Authentication > Sign-in method > Email/Password >
activer** (sinon l'inscription renvoie `operation-not-allowed`, message déjà
traduit par l'application).

**Aucune clé secrète n'est versionnée.** `firebase_options.dart` et
`android/app/google-services.json` le sont : ils ne contiennent que des
identifiants publics (`apiKey`, `projectId`, `appId`), présents de toute façon
dans chaque APK distribué. Ils servent à *adresser* le projet, pas à s'y
authentifier ; l'accès aux données est décidé par `firestore.rules`. Le
`.gitignore` exclut en revanche les clés de compte de service
(`*-adminsdk-*.json`), le magasin de clés de signature (`*.jks`,
`key.properties`) et les journaux de la CLI.

## 3. Architecture

```
lib/
├── main.dart            racine de composition : choisit les implémentations
├── presentation/        écrans, widgets, thème, routes
├── state/               ChangeNotifier exposés par Provider
├── domain/              modèles immuables, interfaces de dépôt, règles pures
└── data/                HTTP, Firestore, Auth, préférences, fichier
```

**Règle de dépendance, à sens unique vers le domaine :**

```
presentation ──> state ──> domain <── data
      └────────────────────^
```

- `domain` n'importe ni Flutter, ni `http`, ni Firebase, ni les autres couches.
- `data` implémente les interfaces de `domain` ; aucun widget, aucun état.
- `state` ne connaît que `domain` (et `foundation.dart` pour `ChangeNotifier`).
- `presentation` ne touche jamais `data` : elle reçoit des interfaces.
- `main.dart` est le seul fichier qui importe `data/` et `presentation/`.

La règle est **vérifiée automatiquement** par
`test/architecture/layer_dependencies_test.dart`, qui lit les `import` de
chaque fichier de `lib/` (contrôlé par mutation : un `import
'package:flutter/material.dart'` ajouté dans `data/` fait échouer le test).

Les erreurs suivent le même principe : `data` traduit `http.ClientException`,
`TimeoutException`, `FirebaseException`… en `AppFailure`
(`domain/failures.dart`), dont le message est déjà rédigé pour l'utilisateur.
Les états renvoient un `ActionResult` au lieu de lever : aucun écran ne
contient de `try/catch` sur une exception technique.

### Réinterprétation de DummyJSON

| Champ produit | Champ événement |
|---|---|
| `title`, `description`, `category`, `price`, `thumbnail` | titre, description, catégorie, tarif, visuel |
| `stock` | places restantes |
| `minimumOrderQuantity` | places déjà prises |
| somme des deux | capacité (un produit en rupture = un événement complet) |
| *(absent)* | date dérivée de l'identifiant : un créneau tous les deux jours |

## 4. Traçabilité des huit compétences

| Séance | Compétence | Fichier(s) attestant |
|---|---|---|
| 2 | Composition et widgets réutilisables, sans débordement | `presentation/widgets/event_card.dart` (carte à deux dispositions), `capacity_gauge.dart`, `state_views.dart`, `event_collection.dart`, `event_image.dart` ; absence de débordement testée dans `test/widgets/event_card_test.dart` (écran de 280 px, police ×2) |
| 3 | Navigation à routes nommées, arguments, valeurs de retour | `presentation/routes.dart` (table unique, arguments validés, tableau des valeurs de retour) ; retours consommés dans `event_detail_screen.dart` (`bool`), `organizer_dashboard_screen.dart` (`String`), `utils/prompts.dart` (`bool` de l'authentification) |
| 4 | État partagé par Provider, état séparé de l'interface | `presentation/app.dart` (`MultiProvider`), `state/*.dart` (aucun import de `material.dart`), usages `context.select` dans `home_shell_screen.dart` et `event_detail_screen.dart` |
| 5 | API REST, modèles typés, chargement et erreur | `data/remote/dummyjson_event_repository.dart`, `domain/repositories/event_repository.dart`, `domain/models/event.dart`, `domain/failures.dart`, `state/catalog_state.dart`, `presentation/screens/catalog_screen.dart` |
| 6 | Formulaire à validation croisée | `domain/rules/event_form_rules.dart`, `registration_form_rules.dart`, `validators.dart` ; `presentation/screens/event_editor_screen.dart`, `widgets/registration_form.dart`, `widgets/date_range_form_field.dart` |
| 7 | Préférences persistantes et données sur disque | `data/local/shared_prefs_repository.dart` (`SharedPreferencesAsync`), `state/preferences_state.dart`, `main.dart` ; `data/local/file_catalog_cache.dart` (fichier JSON, écriture atomique) |
| 8 | Authentification Firebase, Firestore protégé | `data/firebase/firebase_auth_service.dart`, `firestore_event_repository.dart`, `firestore_registration_repository.dart`, `firestore.rules`, `state/auth_state.dart`, `scripts/prove_rules.sh` |
| 9 | Adaptatif, animations implicites, accessibilité | `presentation/screens/home_shell_screen.dart` (barre / rail), `widgets/event_collection.dart` (liste / grille), `event_detail_screen.dart` (une colonne / deux volets), `utils/breakpoints.dart` ; animations : `capacity_gauge.dart` (`AnimatedFractionallySizedBox`, `AnimatedContainer`), `offline_banner.dart` (`AnimatedSize`, `AnimatedSwitcher`), `catalog_screen.dart` (`AnimatedSwitcher`), `registration_screen.dart` (`AnimatedSize`) ; accessibilité : `event_image.dart` (`semanticLabel`), `capacity_gauge.dart` (`Semantics`), `theme/app_theme.dart` (`MaterialTapTargetSize.padded`), `liveRegion` sur les messages |

## 5. Scénarios de test manuel

Compte de démonstration : en créer un depuis l'application (Réglages > « Se
connecter ou créer un compte » > « Inscription »).

### 5.1 Capacité

1. Catalogue > rechercher `Volleyball` > ouvrir l'événement.
   **Attendu :** jauge rouge « Complet » (44/44), bouton « Complet » désactivé.
2. Rechercher `Airpower` > ouvrir « Apple Airpower Wireless Charger » (7/8).
   Bouton : « S'inscrire (1 place(s) restante(s)) ».
3. S'inscrire, saisir **2** places. **Attendu :** le formulaire refuse — « Il
   ne reste que 1 place(s) : réduisez la demande. »
4. Saisir **1** place et valider. **Attendu :** retour au détail, jauge
   « Complet », mention « dont 1 place(s) pour vos inscriptions », bouton
   désactivé : l'égalité stricte ferme l'événement.

### 5.2 Doublon

1. Catalogue > ouvrir « Essence Mascara Lash Princess » > S'inscrire avec
   `ada@example.org`, 1 place. **Attendu :** inscription ajoutée.
2. Rouvrir le même événement > S'inscrire à nouveau avec ` ADA@example.org `
   (casse et espaces différents). **Attendu :** encart rouge « … est déjà
   inscrit(e) à cet événement », rien n'est ajouté.
3. Onglet Inscriptions > « Confirmer » puis refaire l'étape 2. **Attendu :**
   même refus (le doublon est aussi vérifié contre les inscriptions
   confirmées).
4. Côté serveur : `scripts/prove_rules.sh`, essais 10 et 11 (HTTP 403).

### 5.3 Pagination

1. Catalogue, recherche vide. Pied de liste : « 20 sur 194 événement(s) ·
   10 pages ».
2. Défiler : les pages se chargent seules (40, 60…). Un bouton « Afficher 20
   événement(s) de plus » permet la même chose sans défiler.
3. À 180 éléments le bouton annonce **14** (dernière page partielle). À 194 :
   « Fin du catalogue », plus aucun appel.
4. Rechercher `phone` : le total et le nombre de pages suivent la recherche.
5. Rechercher `zzzz` : vue « Aucun résultat » (ce n'est pas une erreur).

### 5.4 Mode dégradé et erreurs

1. Charger le catalogue une fois (copie locale créée).
2. Réglages > Démonstration réseau > **Erreur 500** > onglet Catalogue.
   **Attendu :** le catalogue reste affiché, avec le bandeau jaune
   « Catalogue non actualisé — copie locale du … » et « Réessayer ».
3. Repasser en **Normal** : le bandeau disparaît.
4. **Latence 3 s** puis tirer pour rafraîchir : indicateur de chargement, pas
   d'écran figé.
5. Vraie coupure : mode avion, relancer l'application. **Attendu :** même
   bandeau ; les visuels non mis en cache sont remplacés par une icône.
6. Sans copie locale (données de l'application effacées) + Erreur 500 :
   vue d'erreur plein écran avec « Réessayer ».

### 5.5 Utilisateur non connecté et session

1. Déconnecté : le catalogue et le détail restent consultables.
2. « S'inscrire » : dialogue « Connexion requise » > écran de connexion >
   une fois connecté, le formulaire d'inscription s'ouvre directement.
3. Onglets Inscriptions et Organisateur : vue « Connexion requise ».
4. Session expirée : désactiver ou supprimer le compte dans la console
   Firebase. À la révocation, ces onglets affichent « Session expirée ».

### 5.6 Isolation entre organisateurs

Compte A : créer un événement. Se déconnecter, se connecter avec un compte B :
la liste de B est vide. Preuve serveur : `scripts/prove_rules.sh` (résultat
dans `captures/preuve-regles-securite.log`).

## 6. Tests automatisés

```bash
flutter test          # 84 tests, sans réseau ni Firebase
```

| Catégorie exigée | Exigé | Livré | Fichiers |
|---|---|---|---|
| Logique métier pure | ≥ 8 | **31** | `test/domain/capacity_rule_test.dart` (8), `pagination_test.dart` (8), `event_serialization_test.dart` (6), `registration_form_validation_test.dart` (9) |
| Widgets | ≥ 3 | **17** | `test/widgets/event_card_test.dart` (4), `registration_form_test.dart` (4), `state_views_test.dart` (9) |
| `ChangeNotifier` | ≥ 1 | **21** | `test/state/registration_cart_state_test.dart` (11, dont « un doublon est refusé et ne notifie pas »), `catalog_state_test.dart` (7), `auth_state_test.dart` (3) |
| Échec réseau (double HTTP) | ≥ 1 | **11** | `test/data/dummyjson_event_repository_network_failure_test.dart` : 500, panne, délai dépassé, JSON illisible, 404, et `CatalogState` qui produit l'état d'erreur |
| *(en plus)* règle de dépendance | — | **4** | `test/architecture/layer_dependencies_test.dart` |

Les fichiers testés par `test/domain/` n'importent aucun widget. Les doubles
(`test/support/fakes.dart`) sont écrits à la main ; le client HTTP est doublé
par `MockClient`, fourni par le paquet `http`.

## 7. Qualité

- `flutter analyze` : **0 problème**. `analysis_options.yaml` ajoute à
  `flutter_lints` 13 règles (`avoid_print`, `unawaited_futures`,
  `cancel_subscriptions`, `prefer_const_constructors`, `prefer_final_locals`,
  `avoid_dynamic_calls`…) et les modes `strict-casts` / `strict-raw-types`.
- Aucun `print` / `debugPrint` dans `lib/`.
- Code mort : recherché par script (identifiant public déclaré dans `lib/` et
  référencé nulle part ailleurs) ; les deux occurrences trouvées ont été
  supprimées.

## 8. Publication

Artefact généré : `flutter build apk --release` →
`build/app/outputs/flutter-apk/app-release.apk` (remis séparément).

**Cet APK n'est pas publiable en l'état.** Étapes restantes :

| Étape | État actuel | À faire, et pourquoi |
|---|---|---|
| Identifiant d'application | `com.esgi.eventplanner.event_planner_app` | Choisir l'identifiant **définitif** avant la première mise en ligne (`applicationId`, `android/app/build.gradle.kts`) : il est immuable une fois publié, et doit correspondre à un domaine que l'on possède. Le changer impose de réenregistrer l'application dans Firebase (`flutterfire configure`). |
| Icône | Icône Flutter par défaut | Fournir une icône adaptative (avant-plan + fond) dans `android/app/src/main/res/mipmap-*` : le magasin refuse l'icône par défaut, et c'est l'identité visuelle du produit. |
| Écran de démarrage | Fond blanc + logo Flutter (`launch_background.xml`) | Le remplacer par un écran aux couleurs de l'application (clair et sombre, `values-night`), pour éviter l'éclair blanc au lancement en thème sombre. |
| Signature | Clé de **débogage** (`signingConfig = debug`) | Créer un magasin de clés de téléversement (`keytool -genkey …`), le référencer par un `key.properties` **non versionné**, déclarer un `signingConfig` de publication et activer la signature d'application Play. Une clé de débogage est refusée par le magasin ; une clé perdue empêche toute mise à jour. |
| Versionnement | `version: 1.0.0+1` | `pubspec.yaml` : `version: X.Y.Z+N`. `X.Y.Z` (`versionName`) suit le versionnement sémantique et est visible de l'utilisateur ; `N` (`versionCode`) doit **strictement augmenter** à chaque envoi, sinon le magasin le refuse. |
| Permissions | `INTERNET` uniquement | La déclarer dans le manifeste **principal** (fait) et non seulement celui de débogage. Ne rien ajouter d'autre : chaque permission doit être justifiée dans la fiche du magasin. |
| Format | APK | Le Play Store exige un `.aab` : `flutter build appbundle --release`. |
| Réduction du code | Valeurs par défaut | Vérifier R8 / l'obfuscation (`--obfuscate --split-debug-info`) et conserver les symboles pour lire les rapports de plantage. |
| Firebase | Projet de formation | Projet de production distinct, clé d'API restreinte à l'application (empreinte SHA de la clé de publication), App Check, règles relues. |
| Conformité | — | Politique de confidentialité (courriels collectés), fiche « sécurité des données », procédure de suppression de compte. |
| Nom affiché | `Event Planner` (`android:label`) | Fait. |

## 9. Intégration continue (défi D.2)

`.github/workflows/event_planner_app.yml` (à la racine du dépôt, là où GitHub
le cherche) exécute, à chaque envoi qui touche `event_planner_app/` :

1. `flutter pub get`
2. `flutter analyze` — échoue au moindre avertissement ;
3. `flutter test` — les 84 tests, sans réseau ni Firebase, donc sans aucun
   secret à configurer sur GitHub.

La version de Flutter est fixée (3.47.2) pour que l'analyse donne le même
résultat que sur le poste de développement.

**Preuve d'exécution : non fournie à ce stade.** Le fichier est versionné
mais la branche n'a pas encore été envoyée sur GitHub ; aucune exécution n'a
donc eu lieu, et le bonus n'est pas acquis tant que ce n'est pas fait :

```bash
git push -u origin tp10-event-planner-app
```

Puis, sur GitHub, onglet *Actions* > exécution « event_planner_app » : y
relever le lien (ou une capture `captures/09-integration-continue.png`) et
le reporter ici.

## 10. Choix d'architecture assumés

| Choix | Alternative écartée | Raison |
|---|---|---|
| Un seul modèle `Event` pour le catalogue et l'organisateur | Deux modèles (`Event` / `OrganizerEvent`, comme au TP 8) | Les mêmes carte, détail et inscription servent aux deux sources : c'est ce qui évite deux îlots juxtaposés. |
| Mode dégradé dans `CatalogState` | Décorateur `CachingEventRepository` dans `data/` | La question « ces données sont-elles fraîches ? » est un état d'interface ; la traiter dans l'état la rend visible et testable sans disque. |
| `AppFailure` scellée + `ActionResult` | Laisser remonter les exceptions des bibliothèques | La présentation ne dépend d'aucune bibliothèque de `data/`, et le `switch` sur les issues est exhaustif. |
| Identifiant d'inscription déterministe | Requête « existe déjà ? » avant d'écrire | Une lecture puis une écriture laissent une fenêtre de concurrence ; l'identifiant déterministe rend le doublon impossible côté serveur, sans transaction. |
| `SharedPreferencesAsync` | `SharedPreferencesWithCache` (TP 7) | Lecture unique avant `runApp`, puis `PreferencesState` : un second cache ferait doublon. |
| États dépendants du compte abonnés à `AuthState` (`addListener`) | `ChangeNotifierProxyProvider` | Le `update` d'un proxy s'exécute pendant la construction des widgets : y notifier provoque « setState during build ». L'écouteur, lui, est appelé hors construction. |
| Mode de démonstration réseau lu par le dépôt via une fonction | Paramètres `delay` / `forceError` sur `fetchEvents` | La signature de `EventRepository` est imposée, et la simulation ne concerne pas le domaine. |
| Formatage des dates à la main | Paquet `intl` | Deux fonctions pures suffisent ; une dépendance de moins, et des tests de widget sans initialisation de locale. |
| Tri côté client | Paramètres `sortBy` / `order` de l'API | Signature imposée ; limite documentée au § 1. |
| Routes nommées + `onGenerateRoute` | `go_router` | Hors des séances 1 à 9. |

## 11. Limite connue : la capacité n'est pas imposée par le serveur

**Ce qui est garanti.** Dans l'application, une inscription est refusée dès
que `places de la source + places de l'utilisateur (panier et confirmées) +
places demandées` dépasse la capacité (`domain/rules/capacity_rule.dart`,
appelée par `RegistrationCartState.add`). Le **doublon**, lui, est refusé
deux fois : par l'application, et par le serveur (`firestore.rules`).

**Ce qui ne l'est pas.** Pour un événement du catalogue, rien côté serveur
ne compte les places prises par **l'ensemble** des comptes :

- deux utilisateurs différents peuvent chacun s'inscrire à « la dernière
  place » : chacun ne voit que ses propres inscriptions ;
- un client modifié peut écrire une inscription sans passer par
  `CapacityRule` (les règles limitent seulement à 6 places par inscription).

**Pourquoi.** Le catalogue vient de DummyJSON, en lecture seule : il n'existe
aucun document partagé où tenir un compteur. Et une règle de sécurité
Firestore ne sait pas additionner les documents d'une collection : elle ne
peut lire que des documents précis (`get()`).

**Ce qu'il faudrait pour la lever** (hors des séances 1 à 9) : un document
compteur par événement, mis à jour dans la **même transaction** que
l'inscription, avec une règle qui lit ce compteur — ou une Cloud Function qui
valide l'inscription côté serveur. Dans les deux cas le compteur doit être
modifiable par d'autres comptes que le propriétaire de l'événement, ce qui
demande une collection distincte de `events` pour ne pas affaiblir
l'isolation entre organisateurs.

**Pourquoi c'est acceptable ici.** L'exigence de protection par les règles
porte sur les événements d'organisateur (prouvée, § 5.6). La limite est
écrite, visible, et son correctif identifié.

## Captures

Dossier `captures/` : jalon du parcours vertical, téléphone étroit, tablette
portrait, mode dégradé, capacité atteinte, validation croisée, journal de
preuve des règles.
