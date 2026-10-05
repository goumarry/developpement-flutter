# USAGE-IA — TP 4 — Goumarre Yoann

Outil(s) utilisé(s) : ChatGPT (GPT-4) + Claude (assistant intégré à l'éditeur), ponctuellement
Déclaration : [x] entrées ci-dessous

## Entrée 1
- Date et heure : 09/09/2026, ~10h
- Partie du TP concernée : Partie A
- Pourquoi j'ai sollicité l'IA : je voulais être sûr de bien comprendre pourquoi
  `setState` au niveau 1 reconstruit `EventSection` (niveau 2) même quand ce
  widget ne se sert pas de la donnée, avant de rédiger le constat A.2.
- Ce que j'ai demandé : « en Flutter, si un StatefulWidget parent fait setState,
  est-ce que tous ses enfants Stateless sont reconstruits même s'ils ne
  reçoivent pas de nouveau paramètre ? »
- Ce que j'ai obtenu : oui, `setState` reconstruit toute la méthode `build` du
  widget, donc tout le sous-arbre créé dans ce `build` ; seuls les sous-arbres
  `const` sont épargnés.
- Décision : acceptée telle quelle (explication)
- Correction apportée et vérification faite : vérifié moi-même avec les
  compteurs `builds` de l'écran de démo (6/6/6 pour 5 incréments) avant de
  l'écrire dans le README.

## Entrée 2
- Date et heure : 09/09/2026, ~12h
- Partie du TP concernée : Partie B.5 / choix watch·read·select
- Pourquoi j'ai sollicité l'IA : je voulais que le badge et une tuile ne se
  reconstruisent pas inutilement quand j'ajoute au panier un *autre* événement.
- Ce que j'ai demandé : comment ne reconstruire une tuile que lorsque le nombre
  de places réservées pour *son* événement change.
- Ce que j'ai obtenu : `context.select<RegistrationCart, int>((c) =>
  c.seatsForEvent(event.id))` — la tuile ne se reconstruit que si cette valeur
  précise change.
- Décision : acceptée telle quelle
- Correction apportée et vérification faite : ajouté un `debugPrint` par
  `build` de tuile. Mesure : 5 ajouts sur 5 événements → `EventSection` et
  `EventListScreen` = 0 reconstruction, `EventTile` = +1 pour la seule tuile
  touchée (les autres restent à 1). Consigné dans le README.

## Bilan
- Sur quoi l'IA m'a réellement fait gagner du temps : confirmer le
  comportement de `setState` sur le sous-arbre, et le réflexe `context.select`
  sur une clé fine plutôt que `watch` global.
- Sur quoi elle m'a coûté du temps : rien de notable sur ces deux questions.
- Ce que je saurais refaire sans elle à l'issue de ce TP : modéliser un
  `ChangeNotifier` avec des règles métier internes et un résultat typé, l'exposer
  via `ChangeNotifierProvider` / `MultiProvider`, et choisir entre `watch`,
  `select` et `read`. La différence état local / état global est claire pour moi.
