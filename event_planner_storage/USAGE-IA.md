# USAGE-IA — TP 7 — Goumarre Yoann

Outil(s) utilisé(s) : Claude Code (Claude Sonnet 5), assistant intégré au terminal
Déclaration : [x] entrées ci-dessous

Comme pour les TP 5 et 6, j'ai collé l'énoncé complet et demandé une
implémentation des parties A, B et C, sur la base de mon projet fusionné
TP2-6 (`event_planner_forms`) copié en `event_planner_storage`.

## Entrée 1
- Partie du TP concernée : partie A (choix d'API `shared_preferences`)
- Ce que j'ai demandé : l'énoncé impose le choix entre `SharedPreferencesAsync`
  et `SharedPreferencesWithCache`, et je voulais être sûr de l'argument
  correct plutôt que de choisir au hasard.
- Ce que j'ai obtenu : l'argument décisif est que l'interface `PreferencesStore`
  imposée a des accesseurs **synchrones** (`get themeMode`, etc.) — seule
  `SharedPreferencesWithCache` le permet nativement après son `init()`
  asynchrone. `SharedPreferencesAsync` aurait forcé un `Future` partout.
- Décision : acceptée, reformulée dans le README avec la justification de
  3-5 lignes demandée par l'énoncé.

## Entrée 2 — le piège `SharedPreferences.getInstance()`
- Partie du TP concernée : partie A
- Pourquoi j'ai sollicité l'IA : l'énoncé prévient explicitement que l'API
  legacy pourrait être suggérée, et demande de documenter la sollicitation
  si c'est le cas. J'ai donc explicitement demandé à l'assistant quelle API
  il aurait utilisée s'il n'avait pas eu l'encadré imposant les deux API
  modernes.
- Ce que j'ai obtenu : confirmation que, sans cette contrainte, un réflexe
  « habituel » (connaissances antérieures à la 2.3.0 du package) aurait pu
  être `SharedPreferences.getInstance()` — l'API historique, dépréciée au
  profit de `SharedPreferencesAsync`/`SharedPreferencesWithCache` depuis
  cette version.
- Décision : refusée explicitement — `SharedPreferencesWithCache` utilisé
  partout, aucun `getInstance()` dans le code rendu (pénalité -2 points
  explicitement prévue par le barème sinon).
- Si refusée, pourquoi : API legacy désignée comme hors périmètre par
  l'énoncé lui-même.
- Correction apportée et vérification faite : `grep -r "getInstance"
  lib/` ne renvoie rien dans le projet.

## Entrée 3
- Partie du TP concernée : partie B (nommage du modèle de brouillon)
- Ce que j'ai demandé : l'énoncé attend un fichier `lib/models/event_draft.dart`,
  mais ce chemin et ce nom de classe sont déjà pris par le modèle du TP 6
  (immuable, sans persistance, champs différents). Je voulais savoir
  comment résoudre la collision sans casser le TP 6.
- Ce que j'ai obtenu : un nouveau modèle `DraftRecord` dans
  `lib/models/draft_record.dart`, conceptuellement distinct (brouillon
  partiel et persistant vs. sortie de formulaire validée en une fois),
  avec une note en tête de fichier qui explique le choix.
- Décision : acceptée — c'était la seule option qui ne touche pas au code
  du TP 6 déjà en place.

## Entrée 4
- Partie du TP concernée : transversal — vérification
- Ce que j'ai demandé : vérifier réellement l'écriture atomique, la
  migration de schéma, les quatre cas limites et la politique de purge,
  pas seulement `flutter analyze`.
- Ce que j'ai obtenu : des fichiers de test jetables avec un faux
  `path_provider` (répertoire temporaire réel) et un faux backend
  `shared_preferences` (en mémoire) — 16 tests purs (modèle + dépôt +
  préférences) qui passent tous, puis supprimés.
- Décision : acceptée. Un point intéressant découvert en cours de route :
  les tests `testWidgets` qui attendent un vrai I/O disque ou un vrai
  `compute()` (isolate) directement dans leur corps **bloquent**
  indéfiniment sans `tester.runAsync()` — tout le corps d'un `testWidgets`
  tourne dans une horloge simulée qui ne fait jamais avancer un vrai
  Future. Même avec `runAsync`, certains de ces tests continuaient à
  échouer par timeout de `pumpAndSettle` dans cet environnement précis
  (binaire `flutter_tester` sans affichage) ; plutôt que de m'acharner sur
  un problème d'outillage de test et pas du code de l'app, j'ai gardé les
  16 tests purs (qui, eux, couvrent déjà toute la logique de fond — écriture
  atomique, migration, cas limites, purge, `compute`) et relu à la main le
  câblage des écrans (`FutureBuilder` standard, rien d'exotique).
- Correction apportée et vérification faite : fichiers de test supprimés
  après exécution ; logs réels (écriture atomique, migration) collés dans
  le README.

## Bilan
- Ce que l'IA m'a fait gagner : l'argument correct pour le choix d'API
  (synchrone vs asynchrone, pas une préférence arbitraire), et la
  découverte propre de la limite `runAsync`/`compute()` sous `flutter_tester`
  plutôt que de passer un temps infini à deviner pourquoi un test semblait
  bloqué sans message d'erreur.
- Ce qui m'a coûté du temps : cette même limite d'outillage — plusieurs
  allers-retours avant de comprendre que ce n'était pas mon code qui
  bloquait, mais l'environnement de test lui-même avec du vrai I/O.
- Ce que je sais réexpliquer : la différence entre `SharedPreferencesAsync`
  et `SharedPreferencesWithCache` et pourquoi l'un des deux impose un cache
  local, le schéma écriture-temporaire-puis-renommage pour une écriture
  atomique, pourquoi un fichier vide n'est pas une erreur de parsing alors
  qu'un fichier corrompu l'est, et pourquoi `AppLifecycleState.paused` est
  le bon signal (pas `inactive`) pour une sauvegarde automatique.
