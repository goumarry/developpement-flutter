# Event Planner — TP 4 : gestion d'état avec Provider

Le panier d'inscriptions d'Event Planner : un participant ajoute des
inscriptions depuis la liste ou le détail d'un événement, un **badge d'AppBar**
commun reflète le total en temps réel sur tous les écrans, et un écran de
synthèse permet d'ajuster les quantités.

Une seule dépendance ajoutée : `provider: ^6.1.5`.

## Lancement

```bash
flutter pub get
flutter run            # émulateur Android ou Linux desktop
flutter analyze        # 0 issue
```

Périmètre : ce TP couvre **les Parties A et B**. Les Parties C (Future.delayed /
état de chargement / `ChangeNotifierProxyProvider`) et D (`ValueNotifier`) ne
sont pas traitées.

## Arborescence

```
lib/
├── main.dart                       # MultiProvider au-dessus de MaterialApp
├── models/                         # Dart pur, zéro dépendance Flutter
│   ├── event.dart
│   └── session.dart
├── data/
│   └── event_repository.dart       # dépôt en mémoire, listes figées (B.1)
├── state/                          # notifiers — foundation.dart uniquement
│   ├── registration_cart.dart      # panier + règles métier (B.2)
│   └── display_preferences.dart    # tri / filtre / densité (B.3)
├── routes/                         # réemploi TP 3 (navigation non évaluée)
│   ├── app_routes.dart
│   └── route_generator.dart
├── utils/
│   ├── cart_feedback.dart          # CartOutcome -> message / SnackBar (couche UI)
│   └── date_label.dart
├── widgets/
│   ├── cart_badge.dart             # badge d'AppBar (B.5) — context.select
│   ├── event_section.dart          # niveau 2 (A) — ne dépend plus d'aucun état
│   ├── event_tile.dart             # niveau 3 (A) / ligne d'événement (B)
│   ├── event_thumb.dart            # vignette de démo (reprise du fil rouge)
│   └── capacity_gauge.dart
└── screens/
    ├── home_shell_screen.dart      # BottomNavigationBar Accueil / Panier + IndexedStack
    ├── event_list_screen.dart      # niveau 1 (A) / liste réelle (B)
    ├── event_detail_screen.dart    # sessions + ajout au panier (poussé au-dessus du shell)
    ├── cart_screen.dart            # synthèse, quantités, retrait
    ├── callback_demo_screen.dart   # PARTIE A.1 conservée (mesure reproductible)
    └── not_found_screen.dart
```

### Navigation

`home` (`/`) construit `HomeShellScreen` : une `BottomNavigationBar` à deux
destinations (**Accueil** / **Panier**, avec pastille de quantité) au-dessus
d'un `IndexedStack` qui garde les deux écrans montés. Le **détail** d'un
événement est *poussé* par-dessus le shell. L'onglet actif est un état d'UI
local porté par un `ValueNotifier` (primitive autorisée) exposé en `static` sur
`HomeShellScreen`, pour que le `CartBadge` des AppBars puisse demander
« ouvre le panier » depuis n'importe où. La navigation n'est pas évaluée dans
ce TP.

---

## Partie A — du callback au premier ChangeNotifier

### A.1 — Le montage « callback » et sa mesure

Le montage à trois niveaux exigé par l'énoncé est conservé **tel quel** dans
`lib/screens/callback_demo_screen.dart` (accessible depuis le menu ⋮ de l'écran
liste → « Démo recompositions »), pour que la mesure reste reproductible :

- `CallbackDemoScreen` (niveau 1, `StatefulWidget`) détient `_registrationCount`
  et `_increment()` (`setState`) ;
- il passe `count` + `onIncrement` à `_CallbackSection` (niveau 2) ;
- qui les repasse à `_CallbackTile` (niveau 3), lequel affiche le compteur et
  porte le bouton ;
- `_CallbackBadge` dans l'AppBar est lui aussi alimenté par paramètre.

Chaque widget incrémente un `static int builds` et fait un `debugPrint`.

**Mesure relevée sur émulateur — 5 appuis sur « + 1 »** (compteurs statiques
`builds` + `debugPrint`, panneau visible en bas de l'écran de démo) :

| Widget | Appels à `build()` (init + 5 incréments) |
|---|---|
| `_CallbackTile` (niveau 3) | 1 + 5 = **6** |
| `_CallbackSection` (niveau 2) | 1 + 5 = **6** |
| `_CallbackBadge` (AppBar) | 1 + 5 = **6** |

Un seul « + 1 » déclenche donc **3 reconstructions** (niveau 1 non compté),
alors qu'une seule d'entre elles — la tuile — affiche réellement une valeur qui
a changé du point de vue de l'utilisateur.

**Survie de l'état à la navigation :** en poussant un écran factice puis
`Navigator.pop`, `_registrationCount` **survit** (l'état du niveau 1 reste monté
sous la route poussée). Mais il est **perdu** dès que `CallbackDemoScreen` est
recréé : `pushReplacement` pour revenir, `pushNamedAndRemoveUntil` vers une
nouvelle instance, ou un simple `setState` d'un ancêtre. L'état est prisonnier
d'un `State` précis dans l'arbre.

### A.2 — Constat (les trois limites observées)

1. **Plomberie de callbacks.** `_CallbackSection` (niveau 2) reçoit `count` et
   `onIncrement` uniquement pour les transmettre : il ne s'en sert pas. Ajouter
   un niveau intermédiaire = ajouter deux paramètres partout sur le chemin.
2. **Volume de recompositions.** Un incrément reconstruit les trois widgets du
   chemin (6 appels chacun sur 5 incréments) parce que `setState` reconstruit
   tout le sous-arbre du niveau 1, qu'un widget dépende ou non de la donnée.
3. **Fragilité à la navigation.** L'état vit dans le `State` du niveau 1. Il ne
   survit qu'aux navigations qui laissent ce `State` monté ; toute recréation du
   widget le remet à zéro. Rien ne le partage avec un autre écran déjà affiché.

### A.3 — Premier `ChangeNotifier`

`RegistrationCart extends ChangeNotifier` (`lib/state/registration_cart.dart`),
exposé par un unique `ChangeNotifierProvider` **au-dessus de `MaterialApp`**
(voir `main.dart`, ici via `MultiProvider` puisque la Partie B ajoute un second
notifier).

Dans les écrans réels :
- `EventListScreen` devient un **`StatelessWidget`** — plus de `_registrationCount`,
  plus de `setState` de panier ;
- `EventSection` ne reçoit **plus** `count` ni `onIncrement` : sa signature est
  `title` / `subtitle` / `children` ;
- `EventTile` lit sa tranche d'état via `context.select` (les places réservées
  **pour son événement**) et mute le panier via
  `context.read<RegistrationCart>().addRegistration(...)` dans le `onPressed`,
  jamais dans `build` ;
- `CartBadge` lit `context.select<RegistrationCart, int>((c) => c.totalSeats)`,
  indépendamment, sans rien recevoir de `EventListScreen`.

**Mesure relevée sur émulateur — depuis l'écran liste (8 tuiles), « Ajouter
1 place » sur 5 événements différents :**

| Widget | Avant (montage callbacks, cf. A.1) | Après (Provider + `select`) |
|---|---|---|
| `EventListScreen` (niveau 1) | ~1 + 5 | **1** (0 reconstruction : n'observe pas le panier) |
| `EventSection` (niveau 2) | ~1 + 5 | **1** (0 reconstruction : ne dépend d'aucun état) |
| `EventTile` (les 8 tuiles) | 8 + 5×8 (tout le sous-arbre) | 8 + **5** (une seule reconstruction par tuile touchée ; les 3 tuiles non touchées restent à 1) |
| `CartBadge` (instance de la liste) | 1 + 5 | 1 + 5 (il affiche le total, qui change à chaque ajout) |

`EventSection` et `EventListScreen` ne sont **plus reconstruits du tout** lors
d'un ajout. Seules se reconstruisent : la tuile concernée (`select` sur *sa*
clé `seatsForEvent(id)`) et le badge (`select` sur `totalSeats`). Ajouter au
panier l'événement A ne reconstruit pas la tuile de l'événement B — vérifié
dans le journal `flutter run` (`BUILD EventTile evt-00X`).

**Survie à la navigation :** le panier vit au-dessus de `MaterialApp`. Il
survit à tout : `push`/`pop`, `pushReplacement`, `pushNamedAndRemoveUntil`,
recréation d'un écran. Vérifié.

---

## Partie B — panier complet et préférences d'affichage

### B.1 — Dépôt de données

`EventRepository` (`lib/data/event_repository.dart`) : 8 événements figés
(`static final`), chacun avec `id`, `title`, `category`, `date`, `capacity`,
`taken` (places déjà prises hors panier) et une liste de `Session`
(`id`, `label`, `schedule`). `allEvents()` renvoie une `List.unmodifiable` :
rien n'est mutable dans le dépôt.

Deux événements sont calibrés pour les démonstrations métier :
`evt-002` est **complet** (`taken == capacity`), `evt-004` n'a que **2 places**
restantes.

### B.2 — `RegistrationCart`

Collection de `CartLine` (événement + session + nombre de places). Opérations
publiques : `addRegistration`, `removeRegistration`, `updateSeats`,
`changeSession`, `clear` ; getters `totalSeats`, `distinctEventCount`,
`seatsForEvent`, `lines` (non modifiable).

**Règles métier, appliquées par le notifier lui-même :**

| Règle | Mise en œuvre | Signal en cas de refus |
|---|---|---|
| Pas deux fois le même événement | `containsEvent(id)` avant l'ajout | `CartOutcome.rejectedDuplicate` |
| Événement complet | `event.taken + places > event.capacity` | `CartOutcome.rejectedEventFull` |
| Plafond utilisateur | `totalSeats + places > maxSeatsPerUser` | `CartOutcome.rejectedUserCap` |

**Choix documentés :**
- *Doublon* → **refus** (`rejectedDuplicate`). Pour changer la quantité ou la
  session d'un événement déjà au panier, l'utilisateur passe par l'écran panier
  (`updateSeats` / `changeSession`). Contrat plus lisible qu'un ajout au
  comportement variable.
- *Plafond* → **`maxSeatsPerUser = 6`**. Un particulier réserve pour lui et
  quelques accompagnants ; 6 couvre ce cas sans permettre de bloquer des lots de
  places.

Toute opération renvoie un `CartOutcome` (énumération) — `outcome.isSuccess`
distingue succès et refus. Aucun `print`, aucune exception : la couche UI
(`cart_feedback.dart`) traduit l'énumération en `SnackBar`.

**Découplage strict :** `registration_cart.dart` n'importe que
`package:flutter/foundation.dart` et des modèles Dart purs — vérifiable par
`grep -rE 'material|widgets|cupertino' lib/state/` (aucun résultat).

### B.3 — `DisplayPreferences`

`ChangeNotifier` **indépendant** (n'importe pas `RegistrationCart`) :
- tri : `EventSort { dateAsc, titleAsc, seatsLeftDesc }` ;
- filtre catégorie : `String?` (`null` = toutes) ;
- densité : `EventDensity { comfortable, compact }`.

Une méthode **pure** `applyTo(List<Event>)` renvoie une nouvelle liste filtrée
et triée (ne mute pas la source). Même contrainte de découplage.

### B.4 — `MultiProvider`

Un unique `MultiProvider` au-dessus de `MaterialApp` (`main.dart`) assemble
`RegistrationCart` et `DisplayPreferences`.

### B.5 — Badge universel

Deux consommateurs indépendants du même `RegistrationCart`, chacun via
`context.select<RegistrationCart, int>((c) => c.totalSeats)` :
- `CartBadge` dans l'AppBar de `EventListScreen` et `EventDetailScreen` ;
- la pastille de l'onglet **Panier** de la `BottomNavigationBar` (`HomeShellScreen`).

**Scénario vérifié :** depuis le détail de `evt-001`, « Ajouter au panier
(2 places) » → `Navigator.pop` vers la liste → **le badge de l'écran liste ET
la pastille de l'onglet Panier affichent déjà 2**, sans action supplémentaire ni
callback entre écrans. Aucun
widget de `lib/screens/` ou `lib/widgets/` ne mute un champ des notifiers : la
seule voie est `context.read<...>().<méthode métier>()`.

### Démonstrations des trois refus

Reproductibles à la main (chacune produit un `SnackBar` rouge, pas de plantage) :

| Test | Manip | Résultat |
|---|---|---|
| Doublon | ajouter `evt-001`, puis « Ajouter 1 place » sur sa tuile | « déjà dans le panier » |
| Complet | ouvrir `evt-002` (déjà complet) → il n'y a pas de sélecteur ; via la tuile, « Ajouter 1 place » | « l'événement est complet » |
| Plafond | ajouter 6 places (p. ex. 4 sur un événement + 3 sur un autre) | « plafond atteint : 6 places maximum » |

## `context.watch` / `read` / `select` — choix

| Endroit | Primitive | Pourquoi |
|---|---|---|
| `CartBadge` / pastille onglet Panier | `select` → `totalSeats` | ne se reconstruit que si le total change |
| `EventTile` | `select` → `seatsForEvent(id)` + `density` | granularité par tuile ; B n'affecte pas les autres tuiles |
| `EventListScreen` / `_PreferencesBar` | `watch<DisplayPreferences>` | tri/filtre/densité changent la liste entière — reconstruction voulue |
| `CartScreen` | `watch<RegistrationCart>` | l'écran affiche tout le panier |
| tous les `onPressed` / `onTap` | `read` | mutation hors `build` |

## Captures (`captures/`)

| # | Fichier | Contenu |
|---|---|---|
| 01 | `01-liste.png` | Écran liste (vignettes, barre de préférences, `BottomNavigationBar` Accueil/Panier avec pastille) |
| 02 | `02-demo-callbacks.png` | Partie A — écran de démo, compteurs `build()` à 6/6/6 après 5 « + 1 » |
| 03 | `03-detail-sessions.png` | Détail d'un événement : vignette + sélection de session + sélecteur de places |
| 04 | `04-detail-deja-au-panier.png` | Détail d'un événement déjà au panier (ajout via `read`, SnackBar) |
| 05 | `05-liste-badge-synchro.png` | B.5 — retour du détail vers la liste : badge d'AppBar ET pastille d'onglet déjà à jour |
| 06 | `06-panier.png` | Onglet panier : quantités, sessions, total « N place(s) · M événement(s) » |
| 07 | `07-refus-doublon.png` | Refus métier — événement déjà au panier |
| 08 | `08-refus-complet.png` | Refus métier — événement complet |
| 09 | `09-refus-plafond.png` | Refus métier — plafond de 6 places atteint |
