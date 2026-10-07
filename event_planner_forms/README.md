# Event Planner — TP 6 : formulaires et validation

Deux formulaires d'Event Planner : l'inscription d'un participant (partie A)
et la création d'un événement par un organisateur (partie B), avec une
couche de validation écrite à la main, découplée de Flutter (partie C).

**Base de départ : copie d'`event_planner_api` (fusion TP 2-5), à la demande
explicite de l'étudiant.** Même avertissement qu'au TP précédent : le barème
du TP 6 pénalise explicitement (-2 points par notion) `provider`, tout appel
réseau, et toute dépendance de formulaire externe. `provider` et `http`
restent présents dans ce projet (hérités de la fusion, utilisés par les
onglets Accueil/Événements/Panier/Annuaire) mais **ne sont utilisés par
aucun écran du TP 6** : les deux formulaires de ce TP (`RegistrationScreen`,
`EventCreationScreen`) sont strictement en état local (`StatefulWidget`),
sans Provider ni requête réseau, conformément au périmètre de la séance 6.
Pour une notation strict du TP 6 isolément, la pénalité liée à la simple
présence de ces dépendances dans le projet doit être anticipée.

Seule dépendance ajoutée par le TP 6 : `intl: ^0.20.3` (formatage des dates
sélectionnées, explicitement autorisé par l'énoncé).

## Lancement

```bash
flutter pub get
flutter run            # émulateur Android ou Linux desktop
flutter analyze        # 0 issue
```

Les deux formulaires sont accessibles depuis le nouvel onglet
**Formulaires** (6ᵉ onglet de la coquille, après Annuaire) : « S'inscrire à
un événement » (partie A) et « Créer un événement » (partie B).

## Partie A — formulaire d'inscription

`lib/screens/registration_screen.dart`. Un `Form` unique, une
`GlobalKey<FormState>`, quatre `TextFormField` chacun relié à son propre
`TextEditingController` et `FocusNode` propres, tous déclarés en champ du
`State` et libérés dans `dispose()`.

- **Navigation clavier** : chaque champ sauf le dernier a
  `textInputAction: TextInputAction.next` et un `onFieldSubmitted` qui
  redonne le focus au champ suivant via `FocusScope.of(context).requestFocus(...)`.
  Le dernier (courriel) a `TextInputAction.done` et son `onFieldSubmitted`
  déclenche directement `_submit()`, exactement comme le bouton.
- **Soumission** : `_formKey.currentState!.validate()` ; si faux, rien de
  plus (messages d'erreur seuls) ; si vrai, `save()`, `SnackBar`, `reset()`,
  puis le focus revient au premier champ.
- **Clavier adapté** : `TextInputType.number` (places, avec
  `FilteringTextInputFormatter.digitsOnly`) et `TextInputType.emailAddress`
  (courriel).

## Partie B — formulaire de création d'événement

`lib/screens/event_creation_screen.dart` (10 champs) +
`lib/screens/event_summary_screen.dart` (récapitulatif) +
`lib/models/event_draft.dart` (modèle immuable produit à la confirmation).

Les quatre contraintes croisées (adresse/en-ligne, tarif/gratuit,
capacité/inscrits existants, date de fin/date de début) vivent dans
`lib/validation/cross_field_rules.dart`, appelées depuis le `validator` du
champ concerné (ou du `FormField` personnalisé pour les dates) — jamais de
logique de validation écrite directement dans un widget.

**Convention retenue pour le tarif « gratuit »** : un tarif vide **ou** égal
à `0` est accepté quand la case « gratuit » est cochée ; toute autre valeur
est refusée avec un message qui demande de corriger le tarif, pas de
décocher la case — cocher la case ne corrige jamais une saisie existante.

**Récapitulatif** : `EventSummaryScreen` est poussé par-dessus le formulaire
(`Navigator.push`, pas de remplacement) : revenir sur « Modifier » dépile
simplement cet écran, les contrôleurs du formulaire n'ont jamais été
recréés. La confirmation finale (`pop(true)`) déclenche le `SnackBar` dans
`EventCreationScreen`, construit à partir de l'instance `EventDraft` reçue
en retour — jamais des contrôleurs bruts.

## Partie C — architecture de validation et cycle de vie

### 1. Couche de validation pure

`lib/validation/validators.dart` (règles génériques : `required`,
`minLength`, `maxLength`, `matchesPattern`, `positiveInteger`, `compose`) et
`lib/validation/cross_field_rules.dart` (les 4 contraintes croisées) —
**aucun des deux fichiers n'importe `package:flutter/*`**. Le seul point
d'attention : la règle de plage de dates prend deux `DateTime?` nus (type
`dart:core`), jamais un `DateTimeRange` (type Flutter) — c'est le `FormField`
personnalisé, dans `lib/fields/`, qui fait la conversion.

### 2. Cycle de vie des contrôleurs et `FocusNode`

Chaque écran libère nommément, dans `dispose()`, tous les contrôleurs et
`FocusNode` qu'il a créés (5 de chaque dans `EventCreationScreen`, 4 de
chaque dans `RegistrationScreen`).

**Protocole d'observation de la fuite** : DevTools n'étant pas accessible
depuis cet environnement (pas d'affichage graphique), la fuite a été
démontrée par un compteur d'instances vivantes, instrumenté temporairement
sur un `TextEditingController` et un `FocusNode` (incrémenté au constructeur,
décrémenté dans `dispose()`), sur deux petits écrans de test — l'un sans
`dispose()` défini, l'autre avec — montés puis démontés via `flutter test`
(fichier de vérification jetable, supprimé ensuite). Résultat observé :

```
[démo fuite] AVANT correction — contrôleurs encore vivants après démontage : 3 (attendu : 0)
[démo fuite] AVANT correction — FocusNode encore vivants après démontage : 3 (attendu : 0)
[démo fuite] APRÈS correction — contrôleurs encore vivants après démontage : 0 (attendu : 0)
[démo fuite] APRÈS correction — FocusNode encore vivants après démontage : 0 (attendu : 0)
```

Sans `dispose()`, les 3 contrôleurs et les 3 `FocusNode` du widget de test
survivent intégralement au démontage de l'écran (fuite confirmée) ; avec
`dispose()`, le compteur retombe à zéro. C'est exactement ce schéma qui est
appliqué dans `RegistrationScreen.dispose()` et
`EventCreationScreen.dispose()` : chaque contrôleur/`FocusNode` y est listé
nommément, jamais une boucle implicite qui pourrait silencieusement en
oublier un si la liste des champs change.

### 3. Choix du mode d'auto-validation

| Champ | Mode | Justification |
|---|---|---|
| Nom complet, ville, places (partie A) | `onUserInteraction` (niveau `Form`) | Feedback dès la première modification, sans braquer l'utilisateur avant qu'il ait rien tapé. |
| Courriel (partie A) | `onUserInteraction` **+ logique conditionnelle** | Le `validator` lui-même ignore l'erreur de format jusqu'à ce que le champ perde le focus une première fois (`_emailTouched`, mis à jour par un listener de `FocusNode`) : afficher « format invalide » après chaque caractère taper serait agressif, précisément le cas que l'énoncé proscrit. |
| Titre, description, capacité, adresse, tarif (partie B) | `onUserInteraction` (par champ) | Même logique que la partie A : texte libre, feedback utile dès la première interaction. |
| Catégorie, plage de dates, heure, conditions (partie B) | `disabled` (valeur par défaut, non surchargée) | Ces champs n'ont pas d'état « presque valide » pendant la saisie (on choisit une valeur, ou on ne l'a pas encore fait) : une erreur avant toute tentative de soumission n'apporterait rien, seulement du bruit visuel sur un écran qu'on vient d'ouvrir. |

### 4. `FormField` personnalisé

`lib/fields/date_range_form_field.dart` — `DateRangeFormField extends
FormField<DateTimeRange>`, décrit plus haut (partie B). Choix de conception
assumé : sélectionner la date de début pré-remplit la date de fin à la même
valeur (plutôt que de la laisser vide), pour éviter un état transitoire où
la fin serait antérieure au début ; la validation (`fin strictement après
début`) continue de s'appliquer normalement si l'utilisateur ne modifie pas
la fin par la suite.

### 5. Formatteur deux décimales

`lib/formatters/two_decimals_formatter.dart` — `TwoDecimalsFormatter`
rejette (renvoie `oldValue` inchangé) toute frappe qui produirait une
troisième décimale, sans jamais bloquer la saisie de la partie entière.
Combiné à `FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))` pour
n'autoriser que chiffres et séparateur.

### 6. Perte de saisie non soumise

`EventCreationScreen` traque un booléen `_dirty` (mis à `true` par un
listener sur chaque contrôleur, et à chaque changement de switch/case/date/
heure). Un `PopScope` au niveau de l'écran intercepte toute tentative de
sortie :

```dart
PopScope(
  canPop: !_dirty || _submitted,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    if (await _confirmAbandon() && context.mounted) {
      Navigator.of(context).pop();
    }
  },
  ...
)
```

API vérifiée contre `flutter --version` → **Flutter 3.47.2 / Dart 3.13.2** :
`PopScope` + `onPopInvokedWithResult` (le callback moderne, succédant à
`onPopInvoked`/`WillPopScope`, déjà utilisé ailleurs dans ce projet fusionné
— TP 3, écran de sélection de formule). Une boîte de dialogue demande
confirmation (« Continuer la saisie » / « Abandonner ») ; fermer la boîte
sans choisir (tap hors cadre) équivaut à « continuer la saisie ».

### 7. Tableau des règles de validation

| Champ | Règle | Message affiché | Cas limites testés |
|---|---|---|---|
| Nom complet (A) | obligatoire, 2-80 car. | « Ce champ est obligatoire. » / « Doit contenir au moins 2 caractères. » / « Ne doit pas dépasser 80 caractères. » | vide, 1 caractère, exactement 80, 81 caractères |
| Ville (A) | obligatoire, min 2 car. | mêmes messages génériques | vide, espace seul, 1 caractère |
| Places demandées (A) | obligatoire, entier strictement positif | « Ce champ est obligatoire. » / « Saisissez un nombre entier strictement positif. » | vide, « 0 », négatif (bloqué par le clavier numérique de toute façon), non numérique |
| Courriel (A) | obligatoire, expression régulière | « Ce champ est obligatoire. » / « Saisissez une adresse au format nom@domaine.ext » | chaîne vide, absence de @, domaine sans point, espace en début de valeur |
| Titre (B) | obligatoire | « Ce champ est obligatoire. » | vide |
| Description (B) | obligatoire, 20-500 car. | + « Ne doit pas dépasser 500 caractères. » | vide, 19 caractères, exactement 20, exactement 500, 501 caractères |
| Catégorie (B) | obligatoire (dropdown) | « Choisissez une catégorie. » | aucune sélection |
| Capacité (B) | obligatoire, entier positif | identiques à « places demandées » | vide, 0, non numérique |
| Adresse (B) — **croisée** | obligatoire si hors ligne, interdite si en ligne | « Indiquez l'adresse du lieu : l'événement n'est pas en ligne. » / « Videz l'adresse : l'événement est en ligne... » | vide+hors ligne, remplie+en ligne, vide+en ligne (ok), remplie+hors ligne (ok), bascule du switch après saisie |
| Plage de dates (B) — **croisée**, `FormField` perso | fin strictement après début | « Choisissez la date de début. » / « ... la date de fin. » / « La date de fin doit être après la date de début... » | aucune date, début seul, fin == début, fin < début, fin > début (ok) |
| Heure de début (B) | obligatoire | « Choisissez une heure de début. » | non choisie |
| Tarif (B) — **croisée** | nul (0 ou vide) si gratuit | « Mettez le tarif à 0 (ou videz le champ)... » / « Saisissez un tarif valide... » / « Le tarif ne peut pas être négatif. » | gratuit+valeur non nulle, gratuit+vide (ok), gratuit+« 0 » (ok), non gratuit+négatif, 3ᵉ décimale refusée dès la frappe par le formatteur |
| Capacité vs inscrits (B) — **croisée** | capacité ≥ `inscritsExistants` (12, codé en dur) | « Augmentez la capacité à au moins 12... » | 5 (refusé), 11 (refusé), 12 (limite, ok), 20 (ok) |
| Conditions d'organisation (B) | case cochée obligatoire | « Cochez la case pour confirmer que vous acceptez les conditions. » | non cochée |

## Partie D — non traitée

Le parcours multi-étapes (`Stepper`/`PageView`) n'a pas été implémenté dans
ce rendu — bonus plafonné à 2 points, périmètre déjà conséquent par ailleurs
(fusion TP 2-5 + TP 6 complet).

## Dépôt

`flutter clean` exécuté avant archivage. Les dossiers `build/` et
`.dart_tool/` ne sont pas inclus.
