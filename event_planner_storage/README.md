# Event Planner — TP 7 : stockage local et préférences

Deux briques pour qu'Event Planner reste utilisable hors connexion : une
couche de préférences typée (partie A) et des brouillons d'événement
persistés sur disque, avec écriture atomique et migration de schéma
(parties B et C).

**Base de départ : copie d'`event_planner_forms` (fusion TP 2-6), à la
demande explicite de l'étudiant.** Même avertissement que pour les TP
précédents de cette fusion : le barème du TP 7 pénalise explicitement (-2
points par notion) `provider`, tout appel réseau, et `Form`/`TextFormField`
comme objet évalué. `provider` et `http` restent présents (hérités de la
fusion, utilisés par les onglets Accueil/Événements/Panier/Annuaire) et les
écrans `Form` du TP 6 (inscription, création d'événement) sont toujours
dans le dépôt, mais **aucun écran du TP 7 n'en dépend** : les deux
nouveaux écrans (`SettingsScreen`, `DraftListScreen`, `DraftEditScreen`)
sont en état strictement local, sans `Form` ni Provider, et ne font aucun
appel réseau. Pour une notation stricte du TP 7 isolément, la pénalité liée
à la simple présence de ces éléments dans le dépôt doit être anticipée.

Dépendances ajoutées par le TP 7 : `shared_preferences: ^2.5.5`,
`path_provider: ^2.1.6`. **Aucun usage de l'API legacy
`SharedPreferences.getInstance()`** — voir `USAGE-IA.md` pour la
sollicitation où cette API a été proposée puis refusée.

## Lancement

```bash
flutter pub get
flutter run
flutter analyze        # 0 issue
```

Nouvel onglet **Stockage** (7ᵉ onglet) → « Réglages » (partie A) et « Mes
brouillons » (partie B). Le menu 🐛 de l'écran des brouillons permet de
produire à la demande un fichier corrompu pour la démonstration (voir
partie B).

## Partie A — couche de préférences

### Choix d'API : `SharedPreferencesWithCache`

L'interface `PreferencesStore` (imposée par l'énoncé) expose des **accesseurs
synchrones** (`AppThemeMode get themeMode`, etc.), lus à **chaque
construction d'écran** concerné (réglages, et potentiellement tout écran
qui voudrait respecter le tri/la densité par défaut). `SharedPreferencesAsync`
ne peut pas satisfaire cette signature : chacun de ses accès retourne un
`Future`, ce qui aurait forcé soit un type asynchrone dans toute l'interface
métier, soit un cache applicatif maison — redondant avec celui que
`SharedPreferencesWithCache` fournit déjà nativement. Le coût d'un
rechargement explicite (`reloadCache`) n'entre pas en jeu ici : toutes les
écritures de cette application passent par nos propres setters, qui mettent
déjà le cache à jour en interne : rien d'externe ne modifie ces clés entre
deux lectures.

### `main()` : `await` avant `runApp`, pas de `FutureBuilder` racine

Choix retenu par cohérence avec l'initialisation d'`intl` déjà présente dans
ce fichier (héritée du TP 6, elle aussi un `await` avant `runApp`) : mélanger
les deux styles (`await` pour l'une, `FutureBuilder` pour l'autre) dans la
même fonction `main` aurait été plus confus à lire, pas plus correct.

### Vérification (captures requises par l'énoncé)

- **Premier lancement** : `SharedPreferencesStore` sur un backend vide
  (vérifié en test, voir `USAGE-IA.md`) renvoie bien les cinq valeurs par
  défaut (`light`, `date`, `''`, `comfortable`, `home`) sans exception —
  capture `premier_lancement.png`.
- **Survie à la fermeture complète** : modifier au moins trois préférences,
  capturer l'écran (`avant_fermeture.png`), puis **tuer complètement le
  processus** (pas seulement mettre en arrière-plan) et rouvrir — les
  valeurs modifiées doivent être identiques (`apres_reouverture.png`). Ceci
  découle directement du mécanisme de `shared_preferences`, qui persiste au
  niveau de la plateforme (`SharedPreferences`/`NSUserDefaults`/fichier XML
  selon l'OS), indépendamment du cycle de vie du processus Dart.
- Un redémarrage de l'émulateur ne réinitialise pas non plus les préférences
  (même mécanisme : la plateforme, pas le processus, possède les données).

## Partie B — brouillons sur disque

`DraftRecord` (`lib/models/draft_record.dart`) — **volontairement pas nommé
`EventDraft`** : ce nom est déjà pris par le modèle immuable produit par le
formulaire du TP 6, qui ne persiste rien. Les deux coexistent sans
collision ; voir le commentaire de tête du fichier pour le détail.

### Nommage de fichier sûr

```dart
String _safeFileName(String id) =>
    '${id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.json';
```

Tout caractère hors `[A-Za-z0-9_-]` — donc `/`, `\`, et les deux points de
`..` — est remplacé par `_`. Un identifiant `../../etc/passwd` devient
`______etc_passwd.json`, toujours strictement à l'intérieur du répertoire
des brouillons (démontré par test, voir `USAGE-IA.md`).

### Sauvegarde automatique en arrière-plan

`DraftLifecycleObserver` écoute `AppLifecycleState.paused`, pas `inactive` :
`inactive` est émis très ponctuellement (sélecteur multitâche, alerte
système, appel entrant) sans que l'application ne quitte réellement le
premier plan — écrire sur disque à chaque occurrence serait à la fois trop
fréquent et pas représentatif d'un vrai passage en arrière-plan. `paused`
signale que l'application n'est plus du tout visible : c'est le moment
pertinent.

### Cas limites (les quatre exigés)

| Cas | Comportement implémenté |
|---|---|
| Répertoire absent au premier accès | `DraftRepository._directory()` le crée silencieusement (`create(recursive: true)`) avant tout accès — aucune exception. |
| Identifiant inconnu | `load()` renvoie `null` ; l'écran d'édition s'ouvre sur `DraftRecord.empty(id)`. |
| Fichier vide (0 octet) | `load()` détecte le contenu vide avant `jsonDecode` et renvoie `DraftRecord.empty(id)` — jamais une tentative de parsing. |
| Fichier corrompu | `load()` lève `DraftCorruptedException` (capturée par `FutureBuilder.hasError`) ; l'écran affiche « Brouillon illisible. », jamais de pile Dart brute. |

**Procédure de reproduction manuelle** du fichier corrompu (telle que
demandée par l'énoncé, en plus du bouton de démo intégré au menu 🐛 de
l'écran des brouillons) :
1. Créer un brouillon normalement (titre + ville), le sauvegarder.
2. Repérer le fichier dans `<Documents de l'app>/drafts/<id>.json` (via
   l'explorateur de fichiers de l'émulateur, ou `adb shell` sur Android :
   `run-as com.esgi.eventplanner.event_planner_storage cat
   files/drafts/<id>.json`).
3. Ouvrir ce fichier dans un éditeur de texte, supprimer l'accolade
   fermante finale `}`, enregistrer.
4. Relancer l'app, ouvrir ce brouillon → message « Brouillon illisible. »
   (capture `fichier_corrompu.png`).

## Partie C — robustesse et gouvernance

### Écriture atomique

```dart
await tmpFile.writeAsString(jsonEncode(draft.toJson()), flush: true);
await tmpFile.rename(finalFile.path);
```

Démonstration du scénario d'interruption : vérifié par test qu'après un
`save()` complet, aucun fichier `*.json.tmp` ne subsiste et que le fichier
final est systématiquement un JSON valide (voir `USAGE-IA.md`). Par
construction, si le processus est tué entre l'écriture du fichier temporaire
et le `rename` (simulable en insérant un point d'arrêt entre les deux
lignes ci-dessus et en tuant le process depuis un terminal), le fichier
**final** (`<id>.json`) n'est jamais touché par l'opération en cours : il
contient encore, dans tous les cas, soit l'ancienne version complète (s'il
en existait une), soit rien du tout (nouveau brouillon jamais encore
enregistré) — jamais un contenu partiel. Seul le fichier `.tmp`, orphelin,
peut rester sur le disque dans ce cas précis ; il n'est jamais lu par
`load()` (qui ne considère que `<id>.json`) et sera écrasé sans risque à la
prochaine sauvegarde réussie.

### Migration de schéma v1 → v2

`DraftRecord.fromJson` détecte l'absence de `schemaVersion` (ou sa valeur
`1`) et relit alors le champ `city` (v1) sous le nom `location` (v2), en
appliquant `reminderEnabled: false` par défaut (champ absent en v1). Prouvé
par test à partir d'un JSON v1 de référence :

```json
{
  "id": "legacy-1",
  "title": "Ancien brouillon",
  "city": "Marseille",
  "date": null,
  "category": "Meetup",
  "lastModified": "2025-01-01T09:00:00.000"
}
```

relu sans perte (`location == 'Marseille'`, `reminderEnabled == false`), et
dont la ré-sérialisation adopte bien le nouveau schéma (`schemaVersion: 2`,
`location`, plus de `city`).

### Choix du répertoire

| Répertoire | Durabilité | Sauvegardé par le système | Effaçable par l'utilisateur |
|---|---|---|---|
| Documents (`getApplicationDocumentsDirectory`) | Survit aux mises à jour de l'app ; disparaît seulement si l'app est désinstallée ou ses données effacées | Oui en général (iCloud sur iOS par défaut ; inclus dans la sauvegarde Android standard) | Pas directement — seulement via « Effacer les données » / désinstallation |
| Support (`getApplicationSupportDirectory`) | Même durée de vie que Documents, mais pensé pour des fichiers internes non destinés à l'utilisateur | Variable selon plateforme/configuration, pas garanti | Pas directement — même mécanisme que Documents |
| Temporaire (`getTemporaryDirectory`) | Aucune garantie : le système peut le purger à tout moment (pression mémoire/espace disque) | Non, explicitement exclu des sauvegardes | Oui — « Vider le cache » dans les réglages système |

Les brouillons sont stockés dans **Documents**, pas Support ni Temporaire :
ce sont des données que l'utilisateur a lui-même saisies et doit pouvoir
retrouver après une mise à jour de l'app ou un redémarrage de l'appareil —
l'inverse du Temporaire, purgeable sans préavis. Documents est aussi le
répertoire conventionnel pour du contenu généré par l'utilisateur (par
opposition à des fichiers internes techniques, le rôle de Support).

### Politique de purge

`purgeDirectory()` (`lib/storage/draft_repository.dart`) supprime, dans un
répertoire donné, les fichiers plus vieux qu'un âge donné et/ou les plus
anciens jusqu'à respecter une taille cumulée donnée. **Déclenchement
retenu : au lancement de l'application** (`main()`, sans bloquer l'affichage),
appliqué au répertoire **temporaire** — pas aux brouillons eux-mêmes, qui
restent des données que l'utilisateur gère explicitement (liste + suppression
individuelle/globale), jamais purgées automatiquement à son insu. Un
déclenchement « au lancement » plutôt qu'« à intervalle régulier » évite
d'ajouter un planificateur de tâches en arrière-plan pour un besoin aussi
simple, et reste prévisible : un fichier temporaire trop vieux ne survit
jamais plus d'un lancement complet de l'application.

### Travail hors du fil principal

L'opération déportée via `compute()` est **le chargement de la liste
complète des brouillons** (`DraftRepository.listSummaries`), pas le
chargement d'un brouillon isolé. Un seul brouillon ne pèse que quelques
dizaines d'octets — son `jsonDecode` est de l'ordre du dixième de
milliseconde, bien sous le budget d'une frame. La liste, elle, grossit avec
le **nombre** de brouillons (pas leur taille individuelle) : décoder et
reconstruire N objets `DraftRecord` d'un coup sur le fil principal, pendant
que l'utilisateur ouvre l'écran liste, est le point qui peut réellement
provoquer un jank perceptible si N devient grand — c'est cette opération
précise qui justifie le déport, pas `load()`.

### Ce que les préférences ne doivent jamais contenir

La documentation officielle de `shared_preferences` est explicite :
l'écriture n'est pas garantie persistée au moment où l'appel `Future`
retourne, et ce mécanisme ne doit pas servir à stocker des données
critiques. Trois catégories ne doivent jamais y atterrir dans cette
application :

1. **Les données métier** (la liste des événements, les inscriptions, le
   contenu des brouillons). Ce ne sont pas des réglages d'affichage : elles
   ont une valeur propre, indépendante de toute session d'utilisation, et
   leur perte serait un incident, pas un simple retour aux valeurs par
   défaut. C'est précisément la différence de contrat avec un fichier écrit
   via l'écriture atomique de la partie C : un fichier `<id>.json`, une fois
   son `rename()` terminé, est un engagement explicite et vérifiable (on
   peut `exists()`/`readAsString()` et obtenir une garantie forte sur son
   contenu) — alors qu'une préférence est un best-effort de la plateforme,
   pensé pour des réglages dont la perte occasionnelle est sans
   conséquence grave (l'utilisateur re-choisit son thème, au pire).
2. **Les informations d'authentification** (jetons, mots de passe, identifiants
   de session). `shared_preferences` n'est pas chiffré sur la plupart des
   plateformes ; `flutter_secure_storage` existe précisément pour ce besoin
   et est explicitement hors périmètre de ce TP — mais même s'il était
   autorisé, la bonne réponse serait « jamais dans les préférences », pas
   « dans une variante chiffrée des préférences » : des identifiants ont un
   cycle de vie (expiration, révocation) que l'API clé-valeur ne modélise
   pas.
3. **Les données volumineuses.** `shared_preferences` charge l'intégralité
   de son contenu en mémoire au démarrage (ou à chaque lecture pour la
   variante `Async`) ; y stocker un gros blob (image, JSON de plusieurs
   dizaines de ko) dégraderait les temps de démarrage/lecture de **toutes**
   les autres préférences, pour un usage que `dart:io`/`path_provider`
   gèrent nativement mieux.

En résumé : les préférences sont un magasin de **réglages d'affichage**
(cinq valeurs, cf. `PreferenceKeys`), pas un magasin de données — même pour
une petite quantité, dès que la donnée a une valeur propre à préserver
plutôt qu'une simple commodité de confort à restaurer.

## Partie D — non traitée

Export/import/réinitialisation (bonus, +2 points plafonnés) n'ont pas été
implémentés dans ce rendu — périmètre déjà conséquent par ailleurs (fusion
TP 2-6 + TP 7 complet, parties A/B/C).

## Dépôt

`flutter clean` exécuté avant archivage. Les dossiers `build/` et
`.dart_tool/` ne sont pas inclus.
