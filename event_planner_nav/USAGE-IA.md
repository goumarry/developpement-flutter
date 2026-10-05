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

## Bilan
- Sur quoi l'IA m'a réellement fait gagner du temps : retrouver la signature à
  jour de `PopScope` / `onPopInvokedWithResult` sans fouiller le changelog, et
  confirmer ma compréhension de `routes:` vs `onGenerateRoute`.
- Sur quoi elle m'a coûté du temps : plusieurs exemples utilisaient des API
  dépréciées (`onPopInvoked`, `WillPopScope`) ou géraient mal le cas « retour
  sans choix ».
- Ce que je saurais refaire sans elle à l'issue de ce TP : routes nommées,
  `onGenerateRoute`, passage d'arguments, valeur de retour de `pop`,
  `pushReplacement` vs `push`, `popUntil`, validation d'arguments de route et
  écran d'erreur.
