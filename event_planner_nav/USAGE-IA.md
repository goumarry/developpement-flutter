# USAGE-IA — TP 3 — Goumarre Yoann

Outil(s) utilisé(s) : ChatGPT (GPT-4) + Claude (assistant intégré à l'éditeur), ponctuellement
Déclaration : [x] entrées ci-dessous

## Entrée 1
- Date et heure : 08/09/2026, ~11h
- Partie du TP concernée : Partie A
- Pourquoi j'ai sollicité l'IA : vérifier ma compréhension de la différence entre
  la table `routes:` et `onGenerateRoute` avant de commencer, pour ne pas partir
  sur une mauvaise architecture.
- Ce que j'ai demandé : « en Flutter, pourquoi je ne peux pas passer un objet à
  une route déclarée dans la map routes: du MaterialApp ? »
- Ce que j'ai obtenu : explication correcte — le `WidgetBuilder` de la table
  `routes:` ne reçoit pas `settings.arguments`, il faut soit lire
  `ModalRoute.of(context).settings.arguments` dans le widget, soit passer par
  `onGenerateRoute`.
- Décision : acceptée telle quelle (explication, pas de code)
- Correction apportée et vérification faite : reformulé avec mes mots dans le
  README (section A.2). Vérifié dans la doc officielle « Navigate with arguments ».

## Entrée 2
- Date et heure : 08/09/2026, ~11h
- Partie du TP concernée : Partie B (écran de détail)
- Pourquoi j'ai sollicité l'IA : je n'étais pas sûr de la bonne façon de typer le
  `Future` retourné par `pushNamed` et d'éviter un warning « use_build_context_synchronously ».
- Ce que j'ai demandé : comment attendre proprement la valeur de retour d'un
  écran poussé par `Navigator.pushNamed` et réutiliser le `context` ensuite.
- Ce que j'ai obtenu : `Navigator.of(context).pushNamed<Formule>(...)` renvoie
  `Future<Formule?>` ; ajouter `if (!context.mounted) return;` après le `await`.
- Décision : acceptée après correction
- Si refusée ou corrigée, pourquoi : la première version proposée mettait le
  `pushReplacementNamed` dans le cas `null` — c'était l'inverse de la consigne
  (on ne remplace QUE si une formule a été choisie).
- Correction apportée et vérification faite : inversé la condition, `SnackBar`
  dans le cas `null`, `pushReplacementNamed` seulement si `formule != null`.
  Testé sur émulateur : annuler la sélection laisse bien le détail intact.

## Entrée 3
- Date et heure : 08/09/2026, ~11h
- Partie du TP concernée : Partie C (PopScope)
- Pourquoi j'ai sollicité l'IA : `WillPopScope` était marqué déprécié dans mon
  éditeur, je voulais confirmer l'API `PopScope` à jour et sa nouvelle signature
  de callback.
- Ce que j'ai demandé : équivalent moderne de `WillPopScope` avec un dialogue de
  confirmation avant de laisser le retour se faire.
- Ce que j'ai obtenu : `PopScope(canPop: false, onPopInvokedWithResult: ...)`
  avec appel manuel à `Navigator.pop()` après confirmation.
- Décision : acceptée après correction
- Si refusée ou corrigée, pourquoi : l'exemple utilisait encore
  `onPopInvoked` (déprécié depuis 3.22) et ne gérait pas le cas où l'utilisateur
  ferme le dialogue en tapant à côté (retour `null`).
- Correction apportée et vérification faite : utilisé
  `onPopInvokedWithResult`, et `return result ?? false` pour que la fermeture du
  dialogue n'entraîne aucune navigation. Vérifié sur api.flutter.dev et écrit un
  test widget (`navigation_flow_test.dart`) qui reproduit le scénario.

## Entrée 4
- Date et heure : 08/09/2026, ~11h
- Partie du TP concernée : Partie D (navigateurs imbriqués)
- Pourquoi j'ai sollicité l'IA : la pile d'un onglet se réinitialisait quand je
  changeais d'onglet, et le bouton retour matériel sortait de l'app au lieu de
  dépiler l'onglet actif.
- Ce que j'ai demandé : comment garder deux `Navigator` imbriqués vivants et
  router le bouton retour vers l'onglet actif.
- Ce que j'ai obtenu : idée de l'`IndexedStack` de `Navigator` + `GlobalKey`, et
  du `PopScope` sur la coquille qui délègue au `Navigator` de l'onglet courant.
- Décision : acceptée après correction
- Si refusée ou corrigée, pourquoi : la version proposée laissait `PopScope`
  avec un `canPop` fixe, donc la coquille ne se rafraîchissait jamais et le
  système ne laissait plus jamais sortir de l'app. Il manquait aussi la gestion
  « onglet ≠ 0 → revenir à l'onglet 0 ».
- Correction apportée et vérification faite : ajouté un `NavigatorObserver` par
  onglet qui `setState` la coquille pour recalculer `canPop`, et la logique à 3
  cas décrite dans le README. Testé à la main sur émulateur (accueil → détail →
  sélection, changement d'onglet, retour matériel).

## Entrée 5
- Date et heure : 08/09/2026, ~11h
- Partie du TP concernée : transversal (tests — `test/widget_test.dart`,
  `test/navigation_flow_test.dart`)
- Pourquoi j'ai sollicité l'IA : une fois l'app fonctionnelle, je voulais un
  filet de sécurité contre les régressions, surtout sur les cas d'erreur de la
  Partie C. Écrire à la main tous les `RouteSettings` (argument nul, mauvais
  type, id inconnu, route inconnue) est répétitif et je risquais d'en oublier.
- Ce que j'ai demandé : générer une suite de tests couvrant (1) l'intégrité du
  jeu de données repris du TP 2 et l'unicité des `id`, (2) les trois cas
  d'erreur d'argument + le 404 du générateur de routes, (3) le fait que l'écran
  de sélection renvoie bien une `Formule` au `pop` et que le `PopScope` bloque
  le retour tant que le dialogue d'abandon n'est pas confirmé.
- Ce que j'ai obtenu : les deux fichiers de test quasi complets (18 tests).
- Décision : acceptée après correction
- Si refusée ou corrigée, pourquoi : (a) la version initiale instanciait de
  vrais `BuildContext`, ce qui ne compile pas — j'ai remplacé par un petit
  `_FakeContext` qui implémente `BuildContext` via `noSuchMethod`, puisque les
  `builder` testés n'utilisent pas le contexte ; (b) un test se contentait de
  `expect(route, isNotNull)`, trop laxiste — je l'ai rendu explicite en
  vérifiant le **type d'écran** construit (`isA<NotFoundScreen>()` vs
  `isA<EventDetailScreen>()`) ; (c) un import inutilisé signalé par
  `flutter analyze`, supprimé.
- Correction apportée et vérification faite : `flutter analyze` → 0 issue,
  `flutter test` → 18/18. J'ai relu chaque test pour être sûr de comprendre ce
  qu'il vérifie et pourquoi il passe.

## Bilan
- Sur quoi l'IA m'a réellement fait gagner du temps : retrouver la signature à
  jour de `PopScope` / `onPopInvokedWithResult` sans fouiller le changelog,
  débloquer l'`IndexedStack` de navigateurs pour la Partie D, et surtout écrire
  la suite de tests (beaucoup de code répétitif de mise en place de
  `RouteSettings`).
- Sur quoi elle m'a coûté du temps : plusieurs exemples utilisaient des API
  dépréciées (`onPopInvoked`, `WillPopScope`) ou géraient mal le cas « retour
  sans choix » ; côté tests, la première mouture ne compilait pas (faux
  `BuildContext`) et certains `expect` étaient trop vagues.
- Ce que je saurais refaire sans elle à l'issue de ce TP : toute la Partie A et
  B (routes nommées, `onGenerateRoute`, passage d'arguments, valeur de retour de
  `pop`, `pushReplacement` vs `push`, `popUntil`), la validation d'arguments de
  route et l'écran d'erreur, et écrire un test de générateur de routes
  maintenant que j'ai vu le schéma (créer un `RouteSettings`, appeler la
  fonction, asserter sur la route obtenue). Pour la Partie D je saurais
  réexpliquer le principe mais je relirais sans doute un exemple pour la
  mécanique exacte des clés.
