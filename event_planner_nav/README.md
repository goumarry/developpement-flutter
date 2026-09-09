# Event Planner — TP 3 : Navigation et routes

Le mur d'événements du TP 2 devient **navigable** : consulter le détail d'un
événement, choisir une formule de participation, confirmer, puis revenir à
l'accueil avec une pile de navigation propre.

Aucune dépendance ajoutée au `pubspec.yaml` : uniquement le `Navigator` 1.0
impératif, les routes nommées, `onGenerateRoute` / `onUnknownRoute`,
`RouteSettings`, `PopScope`, `showDialog`, et (Partie D) des `Navigator`
imbriqués.

## Prérequis / lancement

- Flutter stable 3.47.2 / Dart 3.13.2 (`flutter --version`)

```bash
flutter pub get
flutter run                 # émulateur Android ou Linux desktop
flutter analyze             # 0 issue
flutter test                # 18 tests (routage + jeu de données)
```

## Arborescence

```
lib/
├── main.dart                       # MaterialApp : onGenerateRoute + onUnknownRoute
├── models/
│   ├── event.dart                  # modèle Event (TP 2) + champ id ajouté
│   └── formule.dart                # formule de participation (voyage en valeur de retour)
├── data/
│   ├── sample_events.dart          # jeu de données TP 2 + findEventById()
│   └── sample_packages.dart        # les 3 formules, codées en dur
├── routes/
│   ├── app_routes.dart             # constantes de noms de route (source unique)
│   └── route_generator.dart        # fabrique des routes + validation des arguments
├── utils/date_label.dart           # formatage de date (TP 2)
├── widgets/
│   ├── event_card.dart             # carte TP 2, contrat visuel inchangé + onTap optionnel
│   ├── capacity_gauge.dart         # jauge de places extraite du TP 2, réutilisée par le détail
│   └── … (hero_header, stats_bar, category_filters, section_header : TP 2)
└── screens/
    ├── main_shell_screen.dart      # Partie D : coquille à onglets + Navigator imbriqués
    ├── event_wall_screen.dart      # mur d'événements (ex-home_screen)
    ├── event_detail_screen.dart    # détail + « Choisir une formule »
    ├── package_selection_screen.dart  # sélection (pop avec valeur) + PopScope
    ├── confirmation_screen.dart    # récapitulatif + retour à l'accueil
    ├── reservations_screen.dart    # Partie D : 2e onglet
    └── not_found_screen.dart       # écran d'erreur unique (erreurs d'argument + 404)
```

---

## Partie A

### A.1.4 — Pourquoi la flèche de retour de l'AppBar apparaît sans être programmée

`AppBar` insère automatiquement un `BackButton` comme `leading` lorsque
`automaticallyImplyLeading` est `true` (défaut) **et** que le `Navigator` le
plus proche peut dépiler (`Navigator.canPop(context) == true`, c'est-à-dire
qu'il y a au moins une route en dessous). Ce bouton appelle
`Navigator.maybePop(context)`. Sur l'écran d'accueil (route à la racine),
`canPop` vaut `false` : aucune flèche n'est ajoutée.

### A.2 — Pourquoi la table `routes:` seule est insuffisante pour `eventDetail`

La table `routes:` associe un nom à un `WidgetBuilder` qui **ne reçoit pas**
les arguments de navigation : `builder: (context) => EventDetailScreen(...)` n'a
aucun moyen typé d'accéder à l'`Event` passé via `arguments:`. On peut le
contourner en lisant `ModalRoute.of(context)!.settings.arguments` *dans* le
widget, mais la construction de la route et la validation de son argument
restent alors éclatées dans l'écran.

**Alternative retenue : `onGenerateRoute`** (Partie C). Cette fonction reçoit
le `RouteSettings` complet — `settings.name` **et** `settings.arguments` — et
peut donc extraire, caster, valider l'argument puis construire la bonne route
(ou un écran d'erreur) de façon centralisée. Dans ce projet, `main.dart`
n'utilise **que** `onGenerateRoute` + `onUnknownRoute` ; il n'y a plus de table
`routes:`.

---

## Partie B — Parcours de réservation

Accueil → Détail → Sélection → (annulation → Détail) → Sélection → Confirmation
→ Accueil.

### Circulation des données

| Sens | Mécanisme | Type |
|---|---|---|
| Accueil → Détail | `arguments` de route | `String` (l'`id`) |
| Détail → Sélection | `arguments` de route | `String` (titre, pour affichage) |
| Sélection → Détail | valeur de retour de `pop` | `Future<Formule?>` |
| Détail → Confirmation | `arguments` de route | `ConfirmationArgs` (event + formule) |

Aucune de ces données ne transite par une variable globale, un singleton ou un
champ statique.

### Gestion du retour sans choix (étape 3)

`event_detail_screen.dart` attend `Navigator.pushNamed<Formule>(...)`, dont le
`Future<Formule?>` vaut `null` quand l'utilisateur revient sans choisir. Ce cas
est traité explicitement : un `SnackBar` « Sélection annulée », et l'écran de
détail **reste intact et utilisable** (pas de `pushReplacement`, pas de
récapitulatif partiel). Seule une valeur non nulle déclenche la navigation vers
la confirmation.

### B.4 — `pushReplacement` plutôt que `push` vers la confirmation

Le détail est **remplacé** par la confirmation. Vérification faite sur
émulateur : depuis la confirmation, le retour matériel ne repasse ni par la
sélection (déjà dépilée au `pop`) ni par le détail (remplacé), mais ramène
directement sur **le mur d'événements**, c'est-à-dire l'écran qui précédait
l'écran remplacé. Cela évite qu'un retour ne raffiche un détail dans un état
« pré-réservation » incohérent avec la confirmation qu'on vient de voir.

### B.5 — `popUntil` plutôt que `pushAndRemoveUntil` pour « Retour à l'accueil »

Le mur d'événements est resté au fond de la pile pendant tout le parcours
(jamais retiré) : `Navigator.popUntil((r) => r.isFirst)` suffit à dérouler la
pile jusqu'à lui **sans le reconstruire** (position de défilement conservée).
`pushAndRemoveUntil` aurait empilé une nouvelle instance de l'accueil puis
supprimé le reste — inutile ici, et coûteux.

---

## Partie C — Contrat d'interface d'une route

### Passage par identifiant

La route `eventDetail` reçoit un `String id`. La résolution `id → Event` se fait
dans `RouteGenerator` via `findEventById()` (jeu de données du TP 2). L'écran de
détail reçoit donc un `Event` déjà résolu et ne recalcule aucune identité.

### `onGenerateRoute` : les trois cas d'erreur d'argument de `eventDetail`

Implémentés dans `route_generator.dart`, méthode `_eventDetailRoute` :

1. **Argument absent** (`settings.arguments == null`) → écran d'erreur
   « Aucun événement demandé ».
2. **Type inattendu** (`args is! String`, ex. un `int` ou une `Map`) → écran
   d'erreur « Argument de route invalide » précisant le type reçu.
3. **Identifiant inexistant** (`findEventById` renvoie `null`) → écran d'erreur
   « Événement introuvable ».

Chaque cas rend un `NotFoundScreen` paramétré (titre + message), jamais une
exception brute ni un écran blanc. Couvert par des tests
(`test/widget_test.dart`).

### Écran d'erreur d'argument vs écran 404 : **fusion assumée**

Un seul écran, `NotFoundScreen(title, message)`, sert aux deux usages. Dans
tous ces cas l'utilisateur est dans une **impasse de navigation** et la seule
action utile est « Retour à l'accueil ». Le message affiché précise la cause
réelle (route inconnue, argument manquant, id introuvable…), ce qui rend la
distinction visible à l'écran sans dupliquer la mise en page ni le bouton de
sortie. Le bouton utilise
`Navigator.pushNamedAndRemoveUntil(AppRoutes.home, (route) => false)` sur le
`rootNavigator` (pour ressortir d'un éventuel Navigator d'onglet — Partie D).

### `onUnknownRoute`

`RouteGenerator.unknownRoute` renvoie le même `NotFoundScreen` (variante 404)
pour n'importe quel nom de route non enregistré.

### Interception du retour sur l'écran de sélection

`package_selection_screen.dart` enveloppe son `Scaffold` dans un
**`PopScope<Formule>`** (`PopScope` est disponible sur le SDK 3.47 — voir
api.flutter.dev ; `WillPopScope` n'est donc pas utilisé) :

- `canPop: false` + `onPopInvokedWithResult` : toute tentative de retour
  *matérielle ou applicative* (bouton système, flèche d'AppBar → `maybePop`)
  ouvre un `AlertDialog` « Abandonner la sélection en cours ? ». La navigation
  ne se poursuit que si l'utilisateur confirme ; **annuler le dialogue (ou le
  fermer en tapant à côté) ne produit aucune navigation** (`result ?? false`).
- Le choix explicite d'une formule appelle `Navigator.pop(context, formule)`
  (et non `maybePop`) : c'est une action volontaire, elle contourne
  légitimement le `PopScope` et renvoie la `Formule`.

Comportement vérifié par `test/navigation_flow_test.dart`.

### Table des routes

| Nom de route | Constante | Arguments attendus | Type de retour |
|---|---|---|---|
| `/` | `AppRoutes.home` | aucun | `void` |
| `/event-detail` | `AppRoutes.eventDetail` | `String id` | `void` |
| `/package-selection` | `AppRoutes.packageSelection` | `String` (titre de l'événement, optionnel) | `Formule?` |
| `/confirmation` | `AppRoutes.confirmation` | `ConfirmationArgs { Event event; Formule formule; }` | `void` |
| *(toute route inconnue)* | — | — | `void` (via `onUnknownRoute`) |

Les onglets de la Partie D réutilisent `RouteGenerator.parcoursRoute` : les
routes `/event-detail`, `/package-selection` et `/confirmation` sont donc aussi
servies à l'intérieur du `Navigator` de chaque onglet, avec la route racine
`/` de l'onglet construisant son écran d'accueil propre.

### Réflexion — identifiant plutôt qu'objet complet dans les arguments d'une route

Passer un `String id` plutôt qu'un `Event` complet fait de la route un
**contrat minimal et sérialisable**. L'argument devient une donnée primitive,
facile à valider (présence, type, existence) et à logguer, alors qu'un objet
transporte une grappe de champs dont l'écran cible n'a pas forcément besoin et
dont rien ne garantit la fraîcheur : si le jeu de données évolue, l'objet passé
en argument est une copie potentiellement périmée, tandis qu'un identifiant est
toujours re-résolu vers la version courante au moment de l'affichage. La
résolution est alors centralisée en un seul point (`findEventById` dans le
générateur), ce qui évite de disséminer la logique d'accès aux données dans les
appelants. Cela impose en contrepartie que la source de données sache répondre à
la question « qui est `evt-005` ? » — d'où le champ `id` stable ajouté au
modèle et l'écran d'erreur dédié au cas « id inconnu ».

Pour un **lien profond** (`myapp://event-detail?id=evt-005`) qui ouvrirait
directement le détail sans passer par l'accueil, l'identifiant est le seul
format viable : une URL ne peut transporter qu'une chaîne, pas un objet Dart. Le
générateur de routes reçoit alors exactement le même `String` que dans le
parcours normal, valide de la même façon, et affiche soit le détail soit
l'écran « Événement introuvable » si le lien est obsolète. Le parcours interne
et le point d'entrée externe partagent ainsi le même code de résolution et de
gestion d'erreur.

Pour la **restauration d'état** après redémarrage (kill de l'application par le
système, `RestorationMixin` / `restorationScopeId`), même logique : le framework
ne peut persister que des valeurs simples. Sauvegarder l'`id` de l'événement
affiché (et l'`id` de la formule choisie) permet de reconstruire l'écran au
relancement en re-résolvant les objets depuis la source de données ; sauvegarder
les objets eux-mêmes supposerait de les sérialiser entièrement et de gérer les
divergences de schéma entre deux versions de l'app. Ce TP n'implémente pas la
restauration, mais le choix « id dans les arguments » la rend possible sans
rien changer au contrat des routes.

---

## Partie D — Navigateurs imbriqués par onglet

`MainShellScreen` (route `/`) : un `BottomNavigationBar` à deux onglets
(« Accueil », « Mes réservations »), chacun avec **son propre `Navigator`**
(clé globale dédiée). Les deux `Navigator` sont maintenus vivants par un `IndexedStack` :
changer d'onglet ne réinitialise jamais la pile de l'onglet quitté.

Retour matériel (géré par un `PopScope` sur le `Navigator` racine) :

1. pile de l'onglet actif profonde → la 1re pression dépile son écran courant ;
2. pile de l'onglet actif à sa racine, onglet ≠ 0 → retour à l'onglet
   « Accueil » ;
3. onglet « Accueil » à sa racine → `PopScope.canPop == true`, le système fait
   sortir de l'application.

Un `NavigatorObserver` par onglet notifie la coquille à chaque push/pop pour
que `canPop` soit recalculé. Deuxième tap sur l'onglet courant = retour à sa
racine (`popUntil(isFirst)`).

## Tests

- `test/widget_test.dart` — jeu de données TP 2 intact, `id` uniques,
  `findEventById`, et les 3 cas d'erreur d'argument + 404 du générateur.
- `test/navigation_flow_test.dart` — l'écran de sélection renvoie bien une
  `Formule` au `pop`, et le `PopScope` bloque le retour tant que le dialogue
  d'abandon n'est pas confirmé.

## Captures

Dans `captures/`, dans l'ordre du parcours (émulateur Android) :

| # | Fichier | Écran |
|---|---|---|
| 01 | `01-mur-evenements.png` | Mur d'événements (onglet Accueil) |
| 02 | `02-detail.png` | Détail — arguments reçus par `id`, jauge réutilisée |
| 03 | `03-selection-formule.png` | Sélection de formule (3 formules codées en dur) |
| 04 | `04-dialogue-abandon.png` | `PopScope` — dialogue « Abandonner la sélection en cours ? » |
| 05 | `05-confirmation.png` | Confirmation (`pushReplacement`) avec récapitulatif |
| 06 | `06-retour-accueil.png` | Retour au mur via `popUntil` |
| 07 | `07-onglet-reservations.png` | Onglet « Mes réservations » (Navigator imbriqué, Partie D) |
| 08 | `08-erreur-evenement-introuvable.png` | Erreur d'argument : `id` inexistant |
| 09 | `09-erreur-404.png` | `onUnknownRoute` : route inconnue |
| 10 | `10-erreur-type-argument.png` | Erreur d'argument : type inattendu (`int` au lieu de `String`) |

L'onglet « Mes réservations » contient une petite section « Démonstration
Partie C » qui permet de déclencher les trois écrans d'erreur sans débogueur.
