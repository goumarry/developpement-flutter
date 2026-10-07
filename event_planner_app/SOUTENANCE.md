# Préparation de la soutenance — TP 10

Document de travail personnel (il n'est pas exigé par l'énoncé). L'énoncé
sanctionne toute portion de code que je ne sais pas expliquer, qu'elle
fonctionne ou non : l'objectif est de pouvoir ouvrir n'importe quel fichier
et dire **ce qu'il fait, pourquoi il est dans cette couche, et ce qui casse
si on l'enlève**.

## 1. Ordre de relecture (environ 3 h)

Cocher un fichier seulement quand je sais l'expliquer sans le lire.

### Étape 1 — l'assemblage (20 min)

- [ ] `lib/main.dart` — pourquoi Firebase et les préférences sont attendus
      **avant** `runApp` ; pourquoi c'est le seul fichier qui importe `data/`.
- [ ] `lib/presentation/app.dart` — le `MultiProvider`, `lazy: false`, et les
      deux `addListener` sur `AuthState`.
- [ ] `lib/presentation/routes.dart` — arguments validés, valeurs de retour.

### Étape 2 — un parcours vertical complet (30 min)

Suivre un appel de bout en bout, c'est le jalon de la Partie A :

- [ ] `presentation/screens/catalog_screen.dart`
- [ ] `state/catalog_state.dart` — `_requestId`, `loadMore`, mode dégradé.
- [ ] `domain/repositories/event_repository.dart` + `domain/models/event.dart`
- [ ] `data/remote/dummyjson_event_repository.dart` — `eventFromProduct`,
      `_getJsonOnce`, nouvelle tentative.
- [ ] `domain/failures.dart`

### Étape 3 — les règles métier (30 min)

- [ ] `domain/rules/capacity_rule.dart`
- [ ] `domain/rules/pagination.dart`
- [ ] `domain/rules/validators.dart`, `event_form_rules.dart`,
      `registration_form_rules.dart`
- [ ] `state/registration_cart_state.dart` — où sont vérifiés capacité et
      doublon, pourquoi un refus ne notifie pas.

### Étape 4 — Firebase (30 min)

- [ ] `data/firebase/firebase_auth_service.dart`
- [ ] `data/firebase/firestore_event_repository.dart`
- [ ] `data/firebase/firestore_registration_repository.dart` — l'identifiant
      déterministe.
- [ ] `data/firebase/firebase_failure_mapper.dart` — `awaitWrite` et le délai.
- [ ] `firestore.rules` — lire chaque `allow` à voix haute.
- [ ] `state/auth_state.dart` — `_signingOut` et `sessionExpired`.

### Étape 5 — le reste de l'interface (40 min)

- [ ] `presentation/screens/home_shell_screen.dart` — barre / rail, `GlobalKey`.
- [ ] `presentation/widgets/event_collection.dart`, `event_card.dart`,
      `capacity_gauge.dart`, `state_views.dart`, `offline_banner.dart`
- [ ] `presentation/screens/event_detail_screen.dart`,
      `registration_screen.dart`, `widgets/registration_form.dart`
- [ ] `presentation/screens/event_editor_screen.dart`,
      `widgets/date_range_form_field.dart`
- [ ] `presentation/screens/auth_screen.dart`, `settings_screen.dart`,
      `my_registrations_screen.dart`, `organizer_dashboard_screen.dart`
- [ ] `presentation/theme/app_theme.dart`
- [ ] `data/local/shared_prefs_repository.dart`, `file_catalog_cache.dart`

### Étape 6 — les tests (30 min)

- [ ] `test/support/fakes.dart` — ce qu'est un double écrit à la main.
- [ ] Un test de chaque famille, lu ligne à ligne :
      `capacity_rule_test.dart`, `registration_form_test.dart`,
      `registration_cart_state_test.dart`,
      `dummyjson_event_repository_network_failure_test.dart`.
- [ ] `test/architecture/layer_dependencies_test.dart`

**Exercice qui vaut toutes les relectures :** casser volontairement une
chose, prédire quel test échoue, lancer `flutter test`, puis annuler
(`git checkout -- <fichier>`). Par exemple : remplacer `taken >= capacity`
par `taken > capacity` dans `capacity_rule.dart` ; ajouter un
`notifyListeners()` avant un `return CartOutcome.rejectedDuplicate` ;
importer `material.dart` dans un fichier de `data/`.

## 2. Démonstration en 10 minutes

Préparer avant : application installée, compte de démonstration créé, mode
réseau sur « Normal », un terminal ouvert dans `event_planner_app/`.

| Min | Geste | Phrase à dire |
|---|---|---|
| 0 – 1 | Lancer l'application, non connecté. Montrer le catalogue. | « Le catalogue vient de DummyJSON, consultable sans compte. » |
| 1 – 2 | Défiler jusqu'au pied de liste ; rechercher `zzzz`. | « La pagination s'arrête grâce au `total` du serveur. Une recherche vide n'est pas une erreur. » |
| 2 – 3 | Rechercher `Volleyball`, ouvrir. | « Complet : la capacité est atteinte, le bouton est désactivé. » |
| 3 – 5 | Rechercher `Airpower`, « S'inscrire » → dialogue → connexion → formulaire. Saisir 2 places, puis 1. | « L'action qui exige une identité propose la connexion, puis reprend. Deux places : refusé, il n'en reste qu'une. » |
| 5 – 6 | Ouvrir un autre événement, s'y inscrire, puis recommencer avec le même courriel. Onglet Inscriptions : retirer une ligne, confirmer. | « Doublon refusé. Le panier est un `ChangeNotifier` ; la confirmation écrit dans Firestore. » |
| 6 – 7 | Onglet Organisateur : créer un événement « en ligne » avec une adresse. | « Validation croisée : l'adresse est interdite pour un événement en ligne. » |
| 7 – 8 | Réglages : thème sombre ; « Erreur 500 » ; retour au catalogue. | « Le thème est persistant. L'API échoue : la copie locale s'affiche, avec un bandeau qui dit que ce n'est pas frais. » |
| 8 – 9 | Terminal : `flutter test` puis `flutter analyze`. | « 84 tests, sans réseau ni Firebase. » |
| 9 – 10 | Ouvrir `captures/preuve-regles-securite.log`. | « L'isolation entre organisateurs est imposée par le serveur : 403 pour un autre compte. » |

Si le réseau de la salle est mauvais : c'est précisément le mode dégradé, le
montrer plutôt que le subir.

## 3. Questions probables

### Architecture

**Pourquoi quatre couches ? Quelle est la règle ?**
`presentation → state → domain ← data`. Le domaine ne connaît personne. La
règle n'est pas une convention : `test/architecture/layer_dependencies_test.dart`
lit les `import` et échoue à la première violation.

**Comment la présentation obtient-elle les données sans importer `data/` ?**
`main.dart` crée les implémentations et les passe à `EventPlannerApp` sous
forme d'**interfaces** du domaine (`EventRepository`, `AuthRepository`…).
C'est de l'injection par constructeur.

**À quoi sert une interface si elle n'a qu'une implémentation ?**
Elle en a deux : la vraie, et le double des tests (`FakeEventRepository`).
C'est ce qui permet de tester `CatalogState` sans réseau.

**Pourquoi le domaine n'importe-t-il pas Flutter ?**
Pour que les règles métier soient testables en Dart pur, et parce qu'une
règle de capacité n'a aucune raison de dépendre d'une bibliothèque
d'interface. Exemple : `ThemePreference` est un enum du domaine, converti en
`ThemeMode` seulement dans `app.dart`.

**Pourquoi `AppFailure` plutôt que les exceptions d'origine ?**
Sinon l'état ou l'écran devraient connaître `http.ClientException` ou
`FirebaseException`, donc importer ces bibliothèques. La classe est
`sealed` : les sous-types sont connus et fermés.

**Pourquoi le mode dégradé est-il dans `CatalogState` et pas dans `data/` ?**
« Ces données sont-elles fraîches ? » est une information à afficher : c'est
un état d'interface. Alternative écartée : un dépôt décorateur avec cache.

### État

**Pourquoi un refus ne déclenche-t-il pas `notifyListeners` ?**
Rien n'a changé : notifier reconstruirait des widgets pour rien. Le refus
passe par la valeur de retour `CartOutcome`. Test : « un doublon est refusé
et ne notifie pas ».

**`watch`, `read`, `select` : quelle différence ?**
`watch` reconstruit à chaque notification ; `read` lit sans s'abonner (dans
un rappel) ; `select` ne reconstruit que si la valeur sélectionnée change
(pastille du panier dans `home_shell_screen.dart`).

**Pourquoi `addListener` et pas `ChangeNotifierProxyProvider` ?**
Le `update` d'un proxy s'exécute pendant la construction des widgets ; y
notifier provoque « setState() called during build ».

**À quoi sert `_requestId` dans `CatalogState` ?**
Si je lance deux recherches de suite, la réponse de la première peut arriver
après celle de la seconde et l'écraser. Chaque réponse vérifie qu'elle
correspond encore à la dernière demande.

### Réseau et données locales

**Comment sait-on quand arrêter de paginer ?**
`Pagination.hasMore(loaded, total)` : tant que le nombre chargé est
inférieur au `total` renvoyé par l'API.

**Quelles erreurs sont rejouées ?**
Les erreurs transitoires seulement : réseau, délai dépassé, 5xx. Jamais un
404 ni un JSON illisible : les rejouer ne changerait rien.

**Pourquoi le répertoire de support et pas le cache ?**
Le système peut vider le cache à tout moment ; ce fichier est justement ce
qui doit survivre pour le mode hors connexion.

**Pourquoi écrire dans un fichier temporaire puis renommer ?**
Le renommage est atomique : si l'application est tuée au milieu, l'ancien
fichier reste intact.

**`SharedPreferencesAsync` ou `WithCache` ?**
`Async` : lecture unique avant `runApp`, puis les valeurs vivent dans
`PreferencesState`. Un second cache ferait doublon.

### Firebase

**Comment un organisateur est-il empêché de voir les événements d'un autre ?**
Deux fois : la requête filtre sur `ownerId`, et la règle exige
`resource.data.ownerId == request.auth.uid`. Seule la seconde protège
vraiment : un client modifié contourne la première.

**`resource` et `request.resource` ?**
`resource` : le document tel qu'il existe. `request.resource` : le document
tel qu'il serait après l'écriture. La règle `update` vérifie les deux, pour
qu'on ne puisse pas céder son événement à un autre compte.

**Comment le doublon est-il bloqué côté serveur ?**
L'identifiant du document est `<uid>_<eventId>_<courriel>`. La même personne
au même événement vise le même document ; ce serait une mise à jour, et il
n'y a aucune règle `update` : refus.

**Vos identifiants Firebase sont dans le dépôt ?**
Oui, ce sont des identifiants publics, présents dans tout APK. Ils adressent
le projet, ils n'authentifient pas. Ce qui ne doit jamais être versionné :
une clé de compte de service, le magasin de clés de signature.

**Que se passe-t-il hors connexion à l'écriture ?**
Le SDK écrit dans son cache et met en file ; le `Future` ne se résout pas.
`awaitWrite` cesse d'attendre après 4 s et l'écran dit « enregistré hors
connexion ».

### Interface

**En quoi est-ce adaptatif et pas seulement redimensionné ?**
Au-delà de 600 dp : la barre du bas devient un rail latéral, la liste
devient une grille, la carte passe d'horizontale à verticale, le détail
passe d'une colonne à deux volets. Le seuil est comparé à la largeur
**disponible** (`LayoutBuilder`), pas à la taille de l'écran.

**Implicite ou explicite ?**
Implicite : je donne la valeur cible, le widget anime seul (`AnimatedSize`,
`AnimatedSwitcher`, `AnimatedFractionallySizedBox`). Aucun
`AnimationController` dans le projet.

**Qu'avez-vous fait pour l'accessibilité ?**
Zones tactiles de 48 dp (`MaterialTapTargetSize.padded`), `semanticLabel`
sur les visuels, `Semantics` sur la jauge, jamais la couleur comme seul
signal (« Complet » est écrit), `liveRegion` sur les messages d'erreur,
mise en page qui tient avec une police ×2 (testé).

### Tests

**Comment testez-vous sans réseau ?**
`MockClient` (fourni par `http`) remplace le client : il renvoie un 500,
lève une `ClientException` ou tarde volontairement.

**Pourquoi pas de taux de couverture ?**
L'énoncé demande un nombre et une nature de tests, pas un pourcentage. Les
règles métier et les chemins d'erreur sont couverts ; les écrans Firebase ne
le sont que manuellement.

## 4. Limites à annoncer moi-même

Les dire avant qu'on me les trouve :

1. La capacité d'un événement du catalogue n'est pas imposée par le serveur
   (README § 11).
2. Le tri ne porte que sur les pages chargées.
3. Une écriture mise en file hors connexion puis refusée par le serveur
   n'est pas signalée.
4. Pas de revue de pair.
5. L'APK release est signé avec la clé de débogage : non publiable en l'état
   (README § 8).
6. Le projet a été réalisé avec un assistant d'IA (`USAGE-IA.md`).
