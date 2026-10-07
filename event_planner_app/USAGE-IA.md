# USAGE-IA - TP 10 — Goumarre Yoann

Outil(s) utilisé(s) : Claude Code (modèle Claude Opus 5.5), assistant en ligne de commande
Déclaration : [ ] je n'ai utilisé aucune IA sur ce TP  /  [x] entrées ci-dessous

> **Portée réelle de l'usage.** Sur ce TP, l'assistant n'a pas servi d'appoint
> ponctuel : je lui ai confié la réalisation du projet à partir de l'énoncé et
> de mes TP 2 à 8 (dont il a repris les notions et une partie du code :
> validateurs, règles croisées, traduction des erreurs Firebase, script de
> preuve des règles, écriture atomique sur disque). Le code, les tests et la
> première version des documents ont été produits dans cette session. Les
> entrées ci-dessous décrivent ce qui a été demandé, ce qui a dû être corrigé
> et ce qui a été vérifié ; mon propre travail est la relecture, la
> vérification sur émulateur et la capacité à défendre chaque fichier.

## Entrée 1
- Date et heure : 2026-10-07, vers 14 h 20
- Partie du TP concernée : A (mise sur les rails)
- Pourquoi j'ai sollicité l'IA : gain de temps (architecture en couches,
  fichiers de configuration, jalon du parcours vertical).
- Ce que j'ai demandé : réaliser le TP 10 en réutilisant les notions de mes
  TP précédents, en respectant l'arborescence et le jalon imposés.
- Ce que j'ai obtenu : projet `event_planner_app`, quatre couches,
  `analysis_options.yaml` durci, thème, routes, puis un écran unique
  affichant une liste réelle de DummyJSON (commit `feat: parcours vertical
  minimal catalogue -> API`, capture `captures/00-jalon-parcours-vertical.png`).
- Décision : acceptée après correction
- Si refusée ou corrigée, pourquoi : erreurs de compilation à la première
  analyse.
  1. La classe proposée `HttpClientProvider` entrait en conflit avec un type
     du même nom exporté par `package:flutter/material.dart`
     (`ambiguous_import` dans `main.dart`).
  2. Le déplacement de `firebase_options.dart` vers `lib/data/firebase/`
     avait échoué en silence (`git mv -k` sur un fichier non suivi) :
     `uri_does_not_exist`.
- Correction apportée et vérification faite : remplacement par une fonction
  `provideHttpClient()`, déplacement refait avec `mv`, `firebase.json` mis à
  jour ; `flutter analyze` propre, puis application lancée sur l'émulateur.

## Entrée 2
- Date et heure : 2026-10-07, vers 14 h 40
- Partie du TP concernée : B (catalogue, DummyJSON)
- Pourquoi j'ai sollicité l'IA : exploration d'alternatives (quelle ressource
  de DummyJSON réinterpréter, et comment obtenir des événements complets).
- Ce que j'ai demandé : un catalogue paginé avec un cas « complet »
  reproductible pour le scénario de capacité.
- Ce que j'ai obtenu : après interrogation réelle de l'API (194 produits,
  dont quatre à `stock: 0`), la correspondance `stock` = places restantes,
  `minimumOrderQuantity` = places prises.
- Décision : acceptée telle quelle
- Vérification faite : « Volleyball » s'affiche bien « Complet » (44/44) et
  « Apple Airpower Wireless Charger » à 7/8 sur l'émulateur
  (`captures/capacite-atteinte.png`).

## Entrée 3
- Date et heure : 2026-10-07, vers 14 h 45
- Partie du TP concernée : B (états dépendants du compte connecté)
- Pourquoi j'ai sollicité l'IA : choix de conception.
- Ce que j'ai demandé : relier le panier et l'espace organisateur à
  l'utilisateur connecté.
- Ce que j'ai obtenu : une première idée à base de
  `ChangeNotifierProxyProvider`, **écartée par l'assistant lui-même avant
  d'écrire le code**.
- Décision : refusée
- Si refusée ou corrigée, pourquoi : le `update` d'un proxy s'exécute pendant
  la construction des widgets ; y appeler `bindUser`, qui notifie, provoque
  l'erreur « setState() or markNeedsBuild() called during build ».
- Correction apportée et vérification faite : les deux états s'abonnent à
  `AuthState` par `addListener` dans `presentation/app.dart`. Vérifié sur
  l'émulateur : après création de compte, l'onglet Inscriptions et l'espace
  organisateur se chargent sans erreur, et la session est restaurée au
  redémarrage.

## Entrée 4
- Date et heure : 2026-10-07, vers 14 h 55
- Partie du TP concernée : C.1 (tests)
- Pourquoi j'ai sollicité l'IA : génération des tests et des doubles.
- Ce que j'ai demandé : les quatre familles de tests exigées, exécutables
  sans réseau ni Firebase.
- Ce que j'ai obtenu : 84 tests ; doubles écrits à la main
  (`test/support/fakes.dart`) et `MockClient` du paquet `http`.
- Décision : acceptée après correction
- Si refusée ou corrigée, pourquoi : mauvaise gestion d'un cas limite dans un
  test. Après le changement du texte du bandeau (voir revue, R3), le test
  cherchait `'copie locale'` : la recherche trouvait **deux** textes (le
  bandeau et le pied de liste « Fin de la copie locale ») et échouait.
- Correction apportée et vérification faite : recherche sur
  `'Catalogue non actualisé'` ; `flutter test` : 84 réussis.

## Entrée 5
- Date et heure : 2026-10-07, vers 15 h 05
- Partie du TP concernée : B / séance 8 (règles de sécurité)
- Pourquoi j'ai sollicité l'IA : adaptation du script de preuve du TP 8.
- Ce que j'ai demandé : prouver côté serveur l'isolation entre organisateurs
  et le refus des doublons.
- Ce que j'ai obtenu : `firestore.rules` (déployées) et
  `scripts/prove_rules.sh` : 13 essais par appels REST directs, avec deux
  comptes de test créés puis supprimés.
- Décision : acceptée telle quelle
- Vérification faite : `captures/preuve-regles-securite.log` — les 10 refus
  attendus renvoient HTTP 403, les 3 opérations légitimes HTTP 200.

## Entrée 6
- Date et heure : 2026-10-07, vers 15 h 15
- Partie du TP concernée : C.2 (publication)
- Pourquoi j'ai sollicité l'IA : relecture de la configuration Android.
- Ce que j'ai obtenu : constat que la permission `INTERNET` n'était déclarée
  que dans le manifeste de **débogage** généré par `flutter create`.
- Décision : acceptée (correction appliquée)
- Correction apportée et vérification faite : permission ajoutée au manifeste
  principal, libellé `Event Planner`, puis `flutter build apk --release`.

## Entrée 7
- Date et heure : 2026-10-07, en fin de séance
- Partie du TP concernée : C.2 (artefact de publication)
- Pourquoi j'ai sollicité l'IA : reprise après une interruption de la session.
- Ce que j'ai demandé : « reprends là où tu t'es arrêté ».
- Ce que j'ai obtenu : le constat que la compilation en mode release lancée
  avant l'interruption **n'avait pas abouti** (seul l'APK de débogage
  existait), alors que l'entrée 6 la supposait faite ; puis sa relance.
- Décision : acceptée après correction
- Si refusée ou corrigée, pourquoi : une étape annoncée n'était pas réellement
  terminée.
- Correction apportée et vérification faite : état vérifié avant de continuer
  (`git status`, contenu de `build/app/outputs/flutter-apk/`), puis
  `flutter build apk --release` relancé.

## Entrée 8
- Date et heure : 2026-10-07, en fin de séance
- Partie du TP concernée : séance 8 (Firebase)
- Pourquoi j'ai sollicité l'IA : doute — je voulais être sûr que Firebase
  était réellement relié, pas seulement configuré.
- Ce que j'ai demandé : « et Firebase, tu as tout relié ? »
- Ce que j'ai obtenu : la liste de ce qui est branché (application Android
  enregistrée dans le projet `event-planner-firebase-yg`,
  `google-services.json`, `firebase_options.dart`, règles déployées) et de ce
  qui a été **constaté** sur l'émulateur (création de compte, session
  restaurée, inscription confirmée, événement créé), avec ses limites :
  essais faits sur l'APK de débogage uniquement, Android seul, et
  modification / suppression d'événement non rejouées à l'écran.
- Décision : acceptée telle quelle
- Vérification faite : compte de test et documents visibles dans la console
  Firebase (Authentication, collections `events` et `registrations`).

## Entrée 9
- Date et heure : 2026-10-07, en fin de séance
- Partie du TP concernée : livrables (README, USAGE-IA)
- Pourquoi j'ai sollicité l'IA : rédaction.
- Ce que j'ai demandé : rédiger le bilan de ce fichier, une fiche de
  préparation à la soutenance, la marche à suivre pour la preuve
  d'intégration continue et l'explication de la limite sur la capacité. J'ai
  aussi demandé d'ajouter ici « quelques petites demandes que j'aurais pu
  poser ».
- Ce que j'ai obtenu : les documents demandés. Pour les entrées, uniquement
  celles qui correspondent à des demandes **réellement faites** (7, 8 et 9).
- Décision : acceptée après correction
- Si refusée ou corrigée, pourquoi : code non conforme aux consignes —
  l'énoncé demande une entrée par sollicitation réelle ; des demandes
  inventées auraient faussé la déclaration.
- Correction apportée et vérification faite : entrées limitées aux
  sollicitations qui ont eu lieu ; revue de pair retirée du rendu (décision de
  ma part, voir README § 1).

## Revue de code par l'IA (Partie C.3)

Revue demandée à Claude Code sur l'ensemble de `lib/`, ciblée sur
l'architecture et la robustesse. Chaque remarque est classée dans une seule
catégorie.

### Retenues (pertinentes, appliquées)

| # | Remarque | Ce qui a été fait |
|---|---|---|
| R1 | `HomeShellScreen` : au passage du seuil téléphone / tablette (rotation), le contenu change de parent, donc Flutter le détruit et le recrée — recherche en cours et position de défilement perdues. | `GlobalKey` sur le contenu (`KeyedSubtree`) : il est déplacé avec son état. |
| R2 | Code mort : `Event.fillRatio`, `CapacityDecision.isAccepted`, paramètres inutilisés de `Registration.copyWith` et de `ServerFailure`. | Supprimés ; `copyWith` remplacé par `withUser`. Recherche systématique par script des identifiants publics jamais référencés. |
| R3 | Le bandeau du mode dégradé annonçait « Hors connexion » même quand l'échec était une erreur 500 du serveur : message faux. | Libellé neutre : « Catalogue non actualisé — copie locale du … ». |
| R4 | Permission `INTERNET` absente du manifeste principal : l'application de publication ne fonctionnait que parce que les bibliothèques Firebase la déclarent par transitivité. | Déclarée explicitement. |
| R5 | Le test de la règle de dépendance n'avait jamais été vu en échec : rien ne prouvait qu'il détecte une violation. | Contrôle par mutation (import de `material.dart` et de `presentation/` ajouté dans `data/`) : le test échoue et nomme le fichier ; import retiré. |

### Écartées à tort par l'IA (remarque infondée dans ce contexte)

| # | Remarque | Pourquoi elle est fausse ici |
|---|---|---|
| T1 | « Remplacer `on AppFailure catch` par un `catch (e)` général dans les états, pour ne jamais laisser passer une exception. » | Le contrat des dépôts (toute erreur d'exécution sort en `AppFailure`) est tenu et testé (`…network_failure_test.dart`). Un `catch` général attraperait aussi les **erreurs de programmation** (`TypeError`, `StateError`) et les transformerait en « Une erreur est survenue » : le bogue serait masqué au lieu d'être vu en développement. |
| T2 | « Appeler `notifyListeners()` aussi quand `add` est refusé, pour que l'écran affiche le refus. » | Rien n'a changé dans l'état : notifier reconstruirait des widgets pour rien. Le refus est transmis par la **valeur de retour** (`CartOutcome`), que l'écran d'inscription affiche. C'est de plus l'exigence explicite de C.1, vérifiée par un test. |
| T3 | « Stocker un compteur `registered` sur le document de l'événement et l'incrémenter (`FieldValue.increment`) à chaque inscription, pour une capacité fiable. » | Pour que le compte d'un participant puisse incrémenter le document d'un organisateur, il faudrait ouvrir en écriture la collection `events` à d'autres que le propriétaire : cela contredit l'exigence « un organisateur ne peut pas modifier l'événement d'un autre ». Et les événements du catalogue ne sont pas dans Firestore. |

### Écartées à raison par moi (valides en général, non appliquées)

| # | Remarque | Justification |
|---|---|---|
| A1 | La capacité d'un événement du catalogue n'est vérifiée que par l'application. | **Périmètre** : DummyJSON est en lecture seule, il n'y a pas de compteur partagé. La corriger demande un backend (Cloud Functions ou transaction sur un compteur), hors des séances 1 à 9. Limite écrite dans le README. |
| A2 | Le tri ne porte que sur les pages chargées. | **Consigne** : la signature imposée de `EventRepository.fetchEvents` n'a pas de paramètre de tri. Documenté. |
| A3 | Les écouteurs ajoutés à `AuthState` dans `app.dart` ne sont jamais retirés. | Les trois états vivent aussi longtemps que l'application : il n'y a pas de fuite en pratique. Le retrait propre demanderait que chaque état connaisse `AuthState` ; **complexité disproportionnée** pour un gain nul ici. |
| A4 | Une écriture mise en file hors connexion puis refusée par le serveur au retour du réseau n'est pas signalée. | **Contrainte de temps, assumée comme telle** : c'est le défi D.1 (file d'attente et résolution de conflit), que je n'ai pas traité. L'application dit seulement « enregistré hors connexion ». |
| A5 | Pas de test des règles Firestore dans `flutter test` (émulateur Firebase). | **Consigne** : `flutter test` doit tourner sans Firebase. Les règles sont prouvées à part par `scripts/prove_rules.sh`. |
| A6 | Les libellés sont en dur dans les widgets (pas d'internationalisation). | **Périmètre** : défi D.3, non choisi. |

## Bilan
- Sur quoi l'IA m'a réellement fait gagner du temps :
  - la mise en place des quatre couches et de la configuration (analyse
    statique, thème, routes, enregistrement de l'application dans Firebase) ;
  - l'écriture des doubles de test et des 84 tests, la partie la plus
    répétitive ;
  - l'adaptation du script de preuve des règles du TP 8 aux inscriptions ;
  - la vérification des scénarios à l'écran, pilotée par `adb`, et les
    captures ;
  - la rédaction du README à partir de ce qui avait été réellement constaté.
- Sur quoi elle m'a coûté du temps :
  - le **volume à relire** : une soixantaine de fichiers produits en une
    séance, que je dois comprendre un par un avant la soutenance — c'est le
    vrai coût de cet usage, et il n'est pas derrière moi ;
  - les deux erreurs de compilation de l'entrée 1 ;
  - une interruption de session, après laquelle une étape annoncée comme
    faite (la compilation release) ne l'était pas (entrée 7) ;
  - le besoin de faire confirmer par des preuves ce qui était « branché »
    (entrée 8) : une affirmation de l'assistant ne vaut pas constat.
- Ce que je saurais refaire sans elle à l'issue de ce TP :
  - ce que j'avais déjà pratiqué aux TP précédents et que je retrouve ici :
    composer des widgets sans débordement, déclarer des routes nommées avec
    arguments et valeur de retour, écrire un `ChangeNotifier` et l'exposer
    par Provider, appeler une API paginée et traiter ses erreurs, écrire un
    validateur et une règle croisée, lire et écrire une préférence, écrire
    une règle Firestore fondée sur `request.auth.uid` ;
  - ce que je ne saurais **pas** encore refaire seul sans rouvrir le code :
    le découpage en interfaces de dépôt injectées depuis `main.dart`, le
    test qui vérifie la règle de dépendance, les tests de widget avec
    doubles, et l'identifiant d'inscription déterministe qui bloque le
    doublon côté serveur. Ce sont les points que je révise en priorité.
