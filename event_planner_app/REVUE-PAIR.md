# REVUE-PAIR — TP 10 — Goumarre Yoann

> **À compléter.** Une revue de pair est faite par une autre personne : ce
> fichier ne peut pas être rempli à sa place. Il fournit le cadre attendu
> (au moins **deux observations d'architecture** et une **réponse point par
> point**) et des pistes de lecture pour le relecteur.

- Relecteur : _Nom Prénom_
- Date de la revue : _JJ/MM/AAAA_
- Version relue : commit `_______` de la branche `tp10-event-planner-app`
- Durée : _____ min

## Pour le relecteur : par où commencer

1. `README.md`, § 3 (architecture) et § 10 (choix assumés).
2. `lib/main.dart` puis `lib/presentation/app.dart` : comment les couches
   sont assemblées.
3. Un parcours complet : `catalog_screen.dart` → `catalog_state.dart` →
   `event_repository.dart` → `dummyjson_event_repository.dart`.
4. `lib/state/registration_cart_state.dart` et
   `lib/domain/rules/capacity_rule.dart` : les règles métier.
5. `firestore.rules` et `scripts/prove_rules.sh`.

Questions qui méritent un avis extérieur :

- Le mode dégradé est décidé dans `CatalogState` et non dans un dépôt de
  `data/` : est-ce le bon endroit ?
- `app.dart` relie le panier à `AuthState` par `addListener` : est-ce lisible,
  ou un `ProxyProvider` aurait-il été plus clair ?
- Un seul modèle `Event` pour le catalogue et l'organisateur : le champ
  `ownerId` nullable est-il une bonne frontière ?
- La capacité n'est pas imposée côté serveur pour le catalogue : la limite
  est-elle assez visible pour un utilisateur ?

## Observations d'architecture (au moins deux)

### Observation 1
- Fichier(s) concerné(s) :
- Constat du relecteur :
- Risque ou conséquence :
- Proposition :

**Ma réponse :** _acceptée / refusée / reportée_ —

### Observation 2
- Fichier(s) concerné(s) :
- Constat du relecteur :
- Risque ou conséquence :
- Proposition :

**Ma réponse :** _acceptée / refusée / reportée_ —

## Autres observations (robustesse, lisibilité, tests)

| # | Fichier | Observation | Ma réponse |
|---|---|---|---|
| 3 | | | |
| 4 | | | |

## Suites données

| Observation | Décision | Commit |
|---|---|---|
| 1 | | |
| 2 | | |
