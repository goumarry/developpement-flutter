# Note d'ingénierie — pourquoi une règle serveur ne se remplace jamais par un contrôle côté client

## Le principe

Tout code qui s'exécute sur l'appareil de l'utilisateur est **entre ses
mains** : il peut être décompilé, modifié, remplacé ou simplement ignoré. Un
contrôle côté client (masquer un bouton, filtrer la liste affichée, refuser
de construire un écran) améliore l'**ergonomie** : il évite à un utilisateur
honnête de tenter une action qui échouera. Il n'apporte **aucune sécurité**,
parce que l'attaquant n'a pas besoin de passer par notre application. La
seule frontière de confiance est le serveur : c'est là, et seulement là,
qu'une règle est réellement appliquée.

## Scénario concret 1 — le client modifié

Dans Event Planner, `OrganizerHomeScreen` n'affiche que les événements où
`ownerId == uid` (`where('ownerId', isEqualTo: uid)`) et n'expose un bouton de
suppression que sur ces lignes. Supposons que ces seules protections
existent, et que `firestore.rules` soit `allow read, write: if true`.
Un organisateur malveillant recompile l'application en retirant le
`where(...)` — une ligne — et obtient la liste de **tous** les événements de
**tous** les organisateurs, puis appelle `.doc(id).update(...)` ou `.delete()`
sur ceux qui lui plaisent. Notre « filtre » n'a rien filtré : il s'est
contenté de ne pas demander.

## Scénario concret 2 — l'appel direct à l'API REST

Plus simple encore : aucun besoin de modifier l'application. Les
identifiants de `firebase_options.dart` (`apiKey`, `projectId`) sont publics
par conception — ils sont dans chaque APK distribué. N'importe qui peut donc
écrire :

```bash
# lire un document d'un autre organisateur
curl "https://firestore.googleapis.com/v1/projects/<projectId>/databases/(default)/documents/events/<id>" \
     -H "Authorization: Bearer <son propre jeton d'authentification>"

# ou le modifier
curl -X PATCH ".../documents/events/<id>?updateMask.fieldPaths=title" \
     -H "Authorization: Bearer <jeton>" -H "Content-Type: application/json" \
     -d '{"fields":{"title":{"stringValue":"piraté"}}}'
```

Un compte de plus (gratuit, créé en une requête) suffit à obtenir un jeton.
Aucune des vérifications écrites en Dart n'est exécutée : la requête ne
traverse jamais notre application.
`scripts/prove_rules.sh` rejoue exactement ces appels contre le projet
déployé ; son journal est dans `captures/refus-regles-securite.log`.

## Ce que fait la règle serveur

Avec les règles de `firestore.rules`, la décision est prise **par Firestore,
pour chaque requête, avec l'identité vérifiée par le serveur**
(`request.auth.uid`, extrait d'un jeton signé que le client ne peut pas
falsifier) comparée à la donnée stockée (`resource.data.ownerId`) :
- un client sans jeton a `request.auth == null` → tout est refusé ;
- un organisateur B qui tente de lire ou modifier un document dont
  `ownerId` est A reçoit `PERMISSION_DENIED`, quelle que soit la manière dont
  il envoie la requête ;
- à la création, `request.resource.data.ownerId == request.auth.uid`
  empêche de fabriquer un document « au nom » d'un autre.

Une requête de liste est elle aussi évaluée dans sa totalité : lire toute la
collection sans filtre `ownerId` est refusé *en bloc*, même si certains
documents appartiennent à l'appelant — Firestore ne « filtre » pas pour nous
(écran de diagnostic de l'application).

## Conséquence pour la conception

1. Le contrôle côté client reste utile (UX, moins d'erreurs affichées) mais
   se conçoit comme **un confort, jamais comme une défense** ; l'application
   doit d'ailleurs traiter proprement `permission-denied` quand la règle
   serveur dit non.
2. Toute règle métier qui protège une donnée doit exister **côté serveur**
   (règles Firestore, Cloud Functions…), car le client est un environnement
   hostile par hypothèse.
3. Les identifiants de configuration ne sont pas des secrets : c'est
   justement pour cela que les règles ne peuvent pas se contenter d'être
   « discrètes ».
