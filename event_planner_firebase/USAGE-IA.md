# USAGE-IA — TP 8 — Goumarre Yoann

Outil utilisé : Claude Code (Claude Sonnet 5.5), dans le terminal
Déclaration : [x] entrées ci-dessous

## Entrée 1 — identifiant de projet Firebase invalide
- Date : 2026-10-07 — partie A
- Demandé : créer le projet `event_planner_firebase` (avec underscores).
- Obtenu : échec. Le journal `firebase-debug.log` indiquait `project_id
  contains invalid characters` : seuls minuscules, chiffres et tirets sont
  acceptés, et l'identifiant doit être unique.
- Décision : acceptée après correction — projet recréé en
  `event-planner-firebase-yg`, désigné explicitement dans `flutterfire configure`
  (un autre de mes projets, `goumarry-heroes`, existait).

## Entrée 2 — API FlutterFire vérifiées contre la version installée
- Parties : toutes
- Obtenu : les signatures ont été recherchées dans le code des paquets
  installés (`firebase_auth 6.7.0`, `cloud_firestore 6.10.0`) avant d'écrire le
  code. L'ancienne `User.updateProfile(...)` (dépréciée) a été écartée au
  profit de `updateDisplayName`.
- Décision : aucune API inexistante ou obsolète retenue, donc pas d'entrée de
  refus pour ce motif.

## Entrée 3 — `orderBy` + `where` et index composite
- Partie C
- Obtenu : `where('ownerId')` combiné à `orderBy('createdAt')` exige un index
  composite. La liste principale est donc triée côté client, et la requête
  `where(ownerId) + orderBy(date)` est réservée à l'écran de diagnostic, qui
  provoque volontairement l'erreur.
- Décision : acceptée. Vérifié sur l'émulateur : erreur `failed-precondition`
  avec lien de création (`captures/diagnostic-permission-denied-et-index.png`).

## Entrée 4 — `invalid-credential` plutôt que `wrong-password`
- Partie B
- Obtenu : sur un projet récent, mauvais mot de passe et compte inexistant
  donnent tous deux `invalid-credential` ; le traducteur les traite avec le
  même message vague.
- Décision : acceptée. Vérifié avec un vrai mauvais mot de passe.

## Bilan
- Gain de temps : lecture du journal de la CLI, squelette (garde d'accès par
  `StreamBuilder`), règles Firestore et script de preuve.
- Perte de temps : changements de plateformes demandés successivement,
  attente de propagation du projet Firebase.
- À refaire seul : _à compléter après relecture du code_ (garde d'accès,
  pourquoi une règle serveur ne se remplace pas par un contrôle client,
  `isFromCache` / `hasPendingWrites`).
