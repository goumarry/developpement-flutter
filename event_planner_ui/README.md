# Event Planner UI — TP2 : Widgets et composition

Écran d'accueil « mur d'événements » de l'application fil rouge **Event Planner**, réalisé exclusivement avec les widgets de disposition du SDK Flutter (`Row`, `Column`, `Stack`, `Container`...), sans dépendance externe, sans navigation, sans état partagé et sans appel réseau au-delà du chargement d'images de démonstration.

## Prérequis

- Flutter stable 3.47.2 / Dart 3.13.2 (vérifier avec `flutter --version`)
- Un appareil connecté : émulateur Android ou `Linux (desktop)`

## Lancer le projet

```bash
flutter pub get
flutter run
```

## Lancer les tests

```bash
flutter analyze
flutter test
```

Les tests (`test/widget_test.dart`) ne portent pas sur le rendu visuel — `Image.network`
échoue toujours pendant `flutter test` (comportement documenté du SDK, aucune requête
réseau réelle n'est autorisée dans ce mode). Ils vérifient à la place que
`lib/data/sample_events.dart` contient bien tous les cas limites exigés par l'énoncé
(titre long, événement complet, événement en ligne, sur-réservation, lieu long), et que
`dateLabel` formate correctement une date connue.

## Arborescence

```
lib/
├── main.dart                    # MaterialApp
├── data/
│   └── sample_events.dart       # Modèle Event (immuable) + jeu de données codé en dur
├── utils/
│   └── date_label.dart          # Formatage de date sans intl
├── widgets/
│   ├── event_card.dart          # Carte d'événement (Partie A)
│   ├── hero_header.dart         # En-tête hero avec avatar en débordement
│   ├── stats_bar.dart           # Barre de 3 statistiques à largeur égale
│   ├── category_filters.dart    # Pastilles de filtre (Wrap)
│   └── section_header.dart      # Titre de section + compteur
└── screens/
    └── home_screen.dart         # Assemblage complet de l'écran (Partie B)
```

## Choix de composition notables

### Le bloc textuel de `EventCard` ne pousse jamais la vignette

La vignette est contrainte à 88×88 par un `SizedBox` ; le bloc texte est enveloppé dans un
`Expanded` à l'intérieur de la `Row`. Comme `Expanded` prend tout l'espace restant sans
jamais en réclamer plus, un titre très long est absorbé par l'`overflow: ellipsis` du
`Text` (2 lignes max) plutôt que de faire déborder la carte.

### La jauge de places ne peut pas dépasser sa piste, par construction

Le taux `registered / capacity` est d'abord borné (`clamp(0.0, 1.0)`), puis converti en
deux valeurs de `flex` entières (`filledFlex` + `remainingFlex = 1000`) réparties entre
deux `Expanded` dans une `Row`, elle-même superposée à la piste grise dans un `Stack`.
Comme la somme des `flex` est fixe et que `Expanded` ne peut par définition pas dépasser
la largeur qui lui est allouée, la barre de remplissage ne peut structurellement jamais
excéder la largeur de la piste — y compris pour les événements en liste d'attente
(`registered > capacity`).

### La barre de statistiques sans `IntrinsicHeight`

Les séparateurs verticaux de 1px doivent occuper toute la hauteur de la barre. Plutôt que
d'utiliser `IntrinsicHeight` (hors périmètre de ce TP), la `Row` est bornée par une
hauteur fixe (`SizedBox`/`Container(height: 64)`) et déclarée
`crossAxisAlignment: CrossAxisAlignment.stretch` : chaque enfant, y compris les
séparateurs, s'étire alors automatiquement sur toute la hauteur disponible.

### L'avatar de l'en-tête hero déborde sans être rogné

Le `Stack` de `HeroHeader` est déclaré `clipBehavior: Clip.none`. L'image de fond est
contrainte à une hauteur fixe (`imageHeight = 220`), mais le `SizedBox` englobant réserve
`imageHeight + 24px` : l'avatar, positionné pour chevaucher le bas de l'image, dépasse
donc visiblement le cadre de la photo (24px hors image) tout en restant contenu dans
l'espace réservé par le header — pas de collision avec la barre de statistiques qui suit.

### Un seul défilement pour tout l'écran

`HomeScreen` place l'intégralité du contenu (en-tête, stats, filtres, cartes, pied de
page) dans la `Column` d'un unique `SingleChildScrollView`. La liste des événements est
injectée avec une simple boucle `for` plutôt qu'un `ListView` imbriqué, pour respecter la
contrainte « pas de zone défilante dans une zone défilante » — et éviter par construction
toute exception de contraintes liée à un `Expanded` placé dans une zone de hauteur non
bornée.

## Jeu de données (`lib/data/sample_events.dart`)

8 événements couvrant les cas limites exigés par l'énoncé :

| Cas | Événement |
|---|---|
| Titre > 70 caractères | Conférence annuelle sur l'ingénierie des systèmes distribués... |
| Événement complet (`isSoldOut`) | Atelier Flutter : composition avancée |
| Événement en ligne, ville/lieu non renseignés | Meetup mensuel Dart & Flutter |
| Sur-réservation (`registered > capacity`) | Table ronde : éthique et intelligence artificielle |
| Nom de lieu long | Introduction au Clean Architecture |

## Hors périmètre (volontairement absent)

Conformément à l'énoncé : pas de `Navigator`, pas de gestion d'état partagé
(`provider`/`ChangeNotifier`), pas d'appel réseau logique (`http`, `FutureBuilder`), pas
de formulaire, pas de persistance, pas de `MediaQuery`/`LayoutBuilder`, pas de widget
animé, et aucune dépendance ajoutée à `pubspec.yaml`.
