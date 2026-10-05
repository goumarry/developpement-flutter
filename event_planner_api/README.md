# Event Planner — fusion fil-rouge (TP 2 à TP 5)

Ce rendu est le TP 5 (consommation d'API REST — annuaire distant) **étendu,
à la demande explicite de l'étudiant**, pour regrouper dans un seul projet
les notions des quatre séances précédentes : mise en page pure (TP 2),
navigation par routes nommées + navigateurs imbriqués (TP 3), gestion d'état
Provider (TP 4), et consommation d'API REST (TP 5). Rien n'est inventé : le
code de chaque TP précédent (`event_planner_ui`, `event_planner_nav`,
`event_planner_state`) a été repris et adapté pour cohabiter dans la même
application, avec une coquille à 5 onglets.

**Avertissement de périmètre, assumé en connaissance de cause.** Le barème
du TP 5 pénalise explicitement (-2 points par notion) l'usage de `provider`
et de la navigation par routes nommées/navigateurs imbriqués, ces notions
étant hors périmètre de la séance 5. Ce projet les réintègre délibérément
pour servir de synthèse du fil rouge — ce choix a été discuté et confirmé
avant implémentation (voir `USAGE-IA.md`). **Si ce fichier doit être rendu
tel quel pour la notation du TP 5 seul, la pénalité correspondante doit être
anticipée** ; pour une notation stricte du TP 5, se référer à l'historique
Git d'avant la fusion ou retirer `provider`/`routes/` du dépôt.

Annuaire des participants (TP 5) alimenté par l'API publique
[DummyJSON](https://dummyjson.com) : liste paginée, recherche, fiche
détaillée, tirage pour rafraîchir, client réseau robuste (délais, erreurs,
coupures). Dépendances ajoutées : `http: ^1.6.0` (TP 5), `provider: ^6.1.5`
(TP 4, réintroduit pour la fusion).

## La fusion : qui vient d'où

La coquille principale (`lib/screens/app_shell_screen.dart`) a 5 onglets,
chacun avec son **propre `Navigator` imbriqué** (généralisation à 5 onglets
du motif TP 3 Partie D — la pile de chaque onglet est indépendante et
préservée au changement d'onglet) :

| Onglet | Origine | Contenu |
|---|---|---|
| **Accueil** | TP 2 / TP 3 | Mur d'événements décoratif (`EventWallScreen`, `EventCard`, `HeroHeader`, `StatsBar`, `CategoryFilters`) — mise en page pure, aucun état applicatif. |
| **Événements** | TP 4 | Liste pilotée par Provider (`EventListScreen`, tri/filtre/densité via `DisplayPreferences`, `EventTile` avec ajout rapide au panier). |
| **Panier** | TP 4 | `CartScreen` — synthèse du panier (`RegistrationCart`), règles métier (doublon, événement complet, plafond de places). |
| **Réservations** | TP 3 | `ReservationsScreen` — démonstration des navigateurs imbriqués (Partie D) et des 3 écrans d'erreur de route (Partie C : argument absent/mauvais type/id inconnu, + 404). |
| **Annuaire** | TP 5 | `DirectoryScreen` — tout le contenu décrit plus bas dans ce README. |

L'écran de détail d'un événement (`EventDetailScreen`, ouvert depuis
Accueil, Événements ou Réservations) combine volontairement **deux
mécanismes indépendants, côte à côte** : le panier Provider (TP 4,
sélection de session + places) et, en bas d'écran, un bouton séparé
« Choisir une formule (démo TP 3) » qui rejoue le parcours nommé complet du
TP 3 (`pushNamed` typé `Future<Formule?>`, `PopScope` avec dialogue
d'abandon sur l'écran de sélection, `pushReplacementNamed` vers la
confirmation). Les deux ne se mélangent pas : le panier n'est pas affecté
par le choix d'une formule, et inversement.

`CapacityGauge` a été **unifiée** entre TP 2/3 (qui prenait un `Event`
entier) et TP 4 (qui prenait un ratio) : une seule version, à base de ratio,
réutilisée partout. Le modèle `Event` fusionne les champs du TP 4
(`capacity`/`taken`/`sessions`, pour le panier) et du TP 2/3
(`city`/`venue`/`isOnline`, pour le mur) ; `registered` et `isSoldOut` sont
des alias de lecture qui laissent les widgets du TP 2/3 inchangés.

## Lancement

```bash
flutter pub get
flutter run            # émulateur Android ou Linux desktop
flutter analyze        # 0 issue
```

Un petit menu "scénarios de démonstration" (icône bug, en haut à droite de
l'annuaire) permet de rejouer à la demande les deux mécanismes imposés par le
sujet sans éditer le code :
- **Simuler un chargement lent (+1,5 s)** → ajoute `&delay=1500` à la requête
  de première page.
- **Simuler une erreur serveur (500)** → pointe vers `GET /http/500`.

C'est avec ces deux entrées de menu qu'il faut réaliser les captures d'écran
de la partie A (chargement visible, erreur visible) : relancer l'app,
ouvrir le menu, choisir l'entrée, capturer l'écran pendant/après.

## Périmètre

Côté **TP 5** (annuaire, partie de ce rendu qui reste strictement dans les
clous) : parties **A, B, C et D** couvertes ; aucune dépendance réseau autre
que `package:http` ; pas de `Form`/`TextFormField` avec validation (la
recherche utilise un `TextField` simple, explicitement autorisé par le
sujet) ; pas de génération de code ; pas de test automatisé livré.

Côté **fusion fil-rouge** (TP 2/3/4, ajoutée à la demande) : `provider` et
la navigation par routes nommées/navigateurs imbriqués sont présents — voir
l'avertissement en tête de ce fichier.

## Arborescence

```
lib/
├── main.dart                        # MultiProvider (TP4) + MaterialApp.onGenerateRoute (TP3)
├── api/                              # TP 5 — seul point d'appel réseau de l'app
│   ├── users_api.dart
│   └── exceptions.dart
├── models/
│   ├── event.dart                    # fusion TP2/3 (city/venue/isOnline) + TP4 (capacity/taken/sessions)
│   ├── session.dart                  # TP 4
│   ├── formule.dart                  # TP 3
│   ├── participant.dart              # TP 5, fromJson/toJson défensifs
│   └── users_page.dart               # TP 5, { users, total, skip, limit }
├── data/
│   ├── event_repository.dart         # TP 4 (+ données TP 2/3 fusionnées)
│   └── sample_packages.dart          # TP 3
├── state/                            # TP 4 — Provider, foundation.dart only
│   ├── registration_cart.dart
│   └── display_preferences.dart
├── routes/                           # TP 3 — onGenerateRoute / onUnknownRoute
│   ├── app_routes.dart
│   └── route_generator.dart
├── utils/
│   ├── date_label.dart               # TP 2/3/4
│   └── cart_feedback.dart            # TP 4
├── widgets/
│   ├── capacity_gauge.dart           # unifiée TP2/3 + TP4 (ratio)
│   ├── cart_badge.dart               # TP 4, adapté à la coquille à 5 onglets
│   ├── event_card.dart               # TP 2/3 (mur)
│   ├── event_tile.dart               # TP 4 (liste Provider)
│   ├── event_section.dart            # TP 4
│   ├── event_thumb.dart              # TP 2/3/4
│   ├── category_filters.dart         # TP 2/3 (décoratif)
│   ├── hero_header.dart              # TP 2/3
│   ├── section_header.dart           # TP 2/3
│   ├── stats_bar.dart                # TP 2/3
│   ├── participant_tile.dart         # TP 5
│   └── status_views.dart             # TP 5 — chargement / erreur / vide / pied de liste
└── screens/
    ├── app_shell_screen.dart         # coquille à 5 onglets, navigateurs imbriqués (TP3 Partie D)
    ├── event_wall_screen.dart        # TP 2/3, onglet Accueil
    ├── event_list_screen.dart        # TP 4, onglet Événements
    ├── event_detail_screen.dart      # fusion : panier Provider (TP4) + flux formule (TP3)
    ├── package_selection_screen.dart # TP 3, PopScope
    ├── confirmation_screen.dart      # TP 3
    ├── cart_screen.dart              # TP 4, onglet Panier
    ├── reservations_screen.dart      # TP 3, onglet Réservations (démo Parties C/D)
    ├── callback_demo_screen.dart     # TP 4, démo recompositions
    ├── not_found_screen.dart         # TP 3, écran d'erreur de route unique
    ├── directory_screen.dart         # TP 5, onglet Annuaire
    ├── participant_detail_screen.dart# TP 5
    └── add_participant_screen.dart   # TP 5, partie D (bonus)
```

## Partie A — premier appel et premier affichage

`UsersApi.fetchUsers` construit l'URI avec `Uri.https` (jamais de
concaténation), exécute `http.get`, et vérifie `response.statusCode` dans
`_checkStatus` **avant** tout `jsonDecode` : un code hors 200/201 lève une
`ApiException` typée, le corps n'est décodé que si le code est valide.

`Participant.fromJson` reste correct sur les quatre cas limites, sans jamais
lever d'exception (testé manuellement avec des JSON de test construits à la
main dans une vérification jetable, supprimée avant le rendu — voir le
journal ci-dessous obtenu lors de cette vérification) :

| Cas | Entrée | Résultat |
|---|---|---|
| champ absent | `{}` | `id: 0`, `firstName: ''`, `companyName: 'Non renseigné'` |
| champ `null` | `{'firstName': null, 'company': null, ...}` | mêmes valeurs de repli |
| type inattendu | `{'id': '42'}` | `id: 42` (parsé) |
| sous-objet incomplet | `{'company': {'department': 'Sales'}}` | `companyName: 'Non renseigné'` |

Les trois branches du `FutureBuilder` (`directory_screen.dart`,
`participant_detail_screen.dart`) sont visuellement distinctes : chargement
plein écran (`FullScreenLoader`), erreur en français avec bouton Réessayer
(`ErrorView`), liste réelle. Les deux comportements démontrables à la demande
(`&delay=1500`, `/http/500`) sont câblés dans le menu "scénarios de
démonstration" décrit plus haut — **les captures d'écran correspondantes
sont à réaliser en exécutant l'app** (voir `captures/NOTES.md`).

## Partie B — écran d'annuaire complet

- **Pagination** : `_loadNextPage` utilise `skip: _items.length` et le
  `total` renvoyé par le serveur ; elle s'arrête dès que
  `_items.length >= _total` (`reachedEnd` dans `directory_screen.dart`), sans
  jamais redemander de page au-delà.
- **Indicateur de pied de liste** (`ListFooterStatus`) : distinct du
  chargement initial plein écran, affiché en bas de la `ListView` sans
  masquer les éléments déjà chargés.
- **Recherche** : boutons de mots-clés prédéfinis (`ChoiceChip`), pas de champ
  de saisie avec validation — explicitement autorisé par le sujet pour rester
  hors du périmètre de la séance 6. Elle interrompt la pagination en cours et
  reconstruit une liste neuve (`_selectKeyword` réassigne `_firstPage`).
- **État vide vs erreur** : une recherche sans résultat (`200` + liste vide)
  affiche `EmptyView` (« Aucun résultat pour... »), visuellement différent
  (icône loupe barrée, pas de rouge, pas de bouton Réessayer) de `ErrorView`
  (icône wifi barré, texte en rouge, bouton Réessayer).
- **Détail** : `ParticipantDetailScreen` appelle `GET /users/{id}` et affiche
  deux champs absents de la liste (adresse, téléphone).
- **Rafraîchissement** : `RefreshIndicator.onRefresh` → `_onRefresh` vide
  `_items`, réassigne `_firstPage` à un nouvel appel `skip: 0` — jamais de
  mélange entre anciennes et nouvelles pages.
- **Messages d'erreur** : toujours `ErrorView.messageFor`, qui ne lit que
  `ApiException.message` (jamais `error.toString()` sur une exception Dart
  brute).

## Partie C — robustesse du client réseau

### Client réutilisé

`UsersApi` encapsule une unique instance de `http.Client`, créée une fois
dans son constructeur et fermée explicitement par `close()` (appelé dans
`dispose()` de chaque écran qui possède son `UsersApi`). Un appel statique
(`http.get(...)`) ouvrirait/fermerait une connexion TCP (et sa négociation
TLS) à chaque requête ; une instance de `Client` réutilisée garde la
connexion HTTP/1.1 keep-alive (ou la session HTTP/2) ouverte entre deux
requêtes vers le même hôte, ce qui évite de rejouer la poignée de main TCP/TLS
à chaque appel.

### Délai d'expiration

Chaque requête est bornée par `.timeout(_requestTimeout)` (8 s). Le
dépassement est intercepté (`on TimeoutException`, catégorie `dart:async` —
distincte de notre propre hiérarchie, voir ci-dessous) et traduit en
`RequestTimeoutException('Délai dépassé, veuillez réessayer.')`, un message
différent de celui d'une panne réseau ou d'un 5xx.

### Hiérarchie d'exceptions

`lib/api/exceptions.dart` définit `NetworkException`, `RequestTimeoutException`
(nommée ainsi — et non `TimeoutException` — pour ne pas entrer en conflit
avec la classe du même nom de `dart:async`), `ServerException` (porte le
`statusCode`), `NotFoundException`, `DecodingException`. Chacune porte un
message dédié, jamais une trace Dart brute.

### Nouvelle tentative à délai croissant

Le sujet donne l'exemple « 1 s, puis 2 s, puis 4 s » — trois délais, ce qui
correspond à **trois nouvelles tentatives après l'essai initial** (4 essais
au total), pas à trois essais au total : avec seulement 3 essais il n'y
aurait que 2 délais à placer entre eux. C'est l'interprétation retenue ici
(`UsersApi._maxAttempts = 4`), documentée pour éviter toute ambiguïté.

Seules les erreurs transitoires déclenchent une nouvelle tentative :
`NetworkException`, `RequestTimeoutException` (elle aussi transitoire par
nature — une coupure momentanée peut se résorber), et `ServerException`
**uniquement si `statusCode >= 500`**. Jamais sur un 404 (`NotFoundException`)
ni sur un corps illisible (`DecodingException`) : rejouer une requête
identique ne changera rien à ces deux cas.

Journal réel obtenu en appelant `UsersApi.triggerForcedServerError()` contre
`GET /http/500` (vérification jetable, supprimée avant le rendu — reproductible
via le menu "Simuler une erreur serveur (500)") :

```
[UsersApi] 2026-10-05T08:45:12.253285 GET https://dummyjson.com/http/500
[UsersApi] 2026-10-05T08:45:12.355985 tentative 1 échouée (Le service est
  momentanément indisponible, veuillez réessayer.) — nouvelle tentative dans 1s
[UsersApi] 2026-10-05T08:45:13.360531 GET https://dummyjson.com/http/500
[UsersApi] 2026-10-05T08:45:13.401258 tentative 2 échouée (...) — nouvelle
  tentative dans 2s
[UsersApi] 2026-10-05T08:45:15.402864 GET https://dummyjson.com/http/500
[UsersApi] 2026-10-05T08:45:15.444550 tentative 3 échouée (...) — nouvelle
  tentative dans 4s
[UsersApi] 2026-10-05T08:45:19.446135 GET https://dummyjson.com/http/500
```
Quatre requêtes, espacées de 1 s / 2 s / 4 s, puis l'exception
`ServerException` remonte jusqu'à l'écran (durée totale : ~7,2 s, conforme à
1+2+4 = 7 s de backoff minimum).

### Décodage JSON déporté avec `compute`

`UsersApi._requestUsersPage` déporte `jsonDecode` + construction de la liste
de `Participant` dans un isolate via `compute(_decodeUsersPageInBackground,
response.body)`. Ce déport n'a d'intérêt mesurable qu'à partir d'un certain
volume : décoder 20 objets JSON (une page) prend de l'ordre du dixième de
milliseconde sur le fil principal — largement sous le budget d'une frame
(16 ms à 60 Hz) — donc invisible à l'écran. L'intérêt apparaît quand le corps
de réponse grossit sensiblement (des centaines/milliers d'objets, ou des
champs volumineux), où le `jsonDecode` + la construction d'objets peuvent
dépasser plusieurs millisecondes et provoquer un jank perceptible si exécutés
sur le fil principal pendant un scroll ou une animation. Sur l'endpoint de
liste de ce TP (page de 20), le gain est donc surtout démonstratif : il montre
le bon réflexe (isoler le décodage) plutôt qu'un gain mesurable ici. On paie
en retour le coût fixe de la création d'un isolate (quelques millisecondes) —
c'est ce compromis qui rend le déport pertinent seulement au-delà d'un certain
volume.

### Le piège du `FutureBuilder` recréé à chaque build

Passer un appel de méthode directement à `future:` (`future:
_api.fetchUsers()` écrit dans `build()`) recrée une nouvelle requête à chaque
recomposition du widget — y compris pour un `setState()` d'un widget frère
sans aucun rapport. Démonstration obtenue avec une reproduction minimale
(deux petits widgets de test, un bouton "clic sans rapport" + un
`FutureBuilder`, vérification jetable supprimée avant le rendu) :

**Avant correction** — `future: _fakeFetch()` appelé en ligne dans `build()`,
1 affichage initial + 5 clics sans rapport :
```
[démo] requête réseau n°1 déclenchée
[démo] requête réseau n°2 déclenchée
[démo] requête réseau n°3 déclenchée
[démo] requête réseau n°4 déclenchée
[démo] requête réseau n°5 déclenchée
[démo] requête réseau n°6 déclenchée
[démo] AVANT correction — total requêtes émises: 6 pour 1 affichage initial + 5 clics sans rapport
```

**Après correction** — `Future` créé une seule fois dans `initState()` et
mémorisé dans un champ (`late Future<...> _future`), même séquence
d'interactions :
```
[démo] requête réseau n°1 déclenchée
[démo] APRÈS correction — total requêtes émises: 1 pour 1 affichage initial + 5 clics sans rapport
```

C'est exactement le schéma appliqué dans `DirectoryScreen`
(`_firstPage` mémorisé, réassigné volontairement seulement lors d'une action
utilisateur explicite — recherche, tirage, scénario de démo) et dans
`ParticipantDetailScreen` (`_future` assigné une seule fois dans
`initState`).

## Partie D (bonus) — inscription par écriture

`AddParticipantScreen` envoie `POST /users/add` via `UsersApi.addParticipant`,
qui décode l'objet renvoyé (identifiant simulé, non persisté côté serveur) et
réutilise la même hiérarchie d'exceptions que la partie C pour l'échec.

**Note sur l'idempotence et la nouvelle tentative automatique.** Un `GET` est
idempotent par convention HTTP : le rejouer n'a pas d'effet de bord
observable au-delà de la première exécution (il relit la même ressource), et
c'est précisément ce qui rend sûre la nouvelle tentative automatique de la
partie C. Un `POST /users/add`, en revanche, crée une ressource à chaque
appel réussi : si le mécanisme de nouvelle tentative de la partie C lui était
appliqué sans discernement, un cas réaliste et fréquent casserait
silencieusement — la requête part, le serveur traite l'inscription et renvoie
sa réponse, mais cette réponse se perd ou arrive après l'expiration du délai
côté client (coupure, latence, serveur lent) ; le client, ignorant que
l'inscription a bien eu lieu, interprète cela comme un échec transitoire et
rejoue le `POST`, ce qui crée une seconde inscription pour la même personne.
Avec trois nouvelles tentatives possibles, on risquerait jusqu'à quatre
inscriptions dupliquées pour une seule intention utilisateur. C'est pour
cette raison qu'`UsersApi.addParticipant` n'est **jamais** passé par
`_withRetry` : une seule tentative, et c'est à l'utilisateur de décider
explicitement (en retapant sur Envoyer) s'il veut réessayer — une nouvelle
tentative *manuelle* reste son choix informé, une nouvelle tentative
*automatique et silencieuse* sur une écriture non idempotente ne l'est pas.
(DummyJSON ne persistant pas réellement les écritures, ce risque est ici sans
conséquence réelle, mais le code est écrit comme si le serveur persistait
vraiment, ce qui est la seule posture défendable en production.)

## Dépôt

`flutter clean` exécuté avant archivage. Les dossiers `build/` et
`.dart_tool/` ne sont pas inclus.
