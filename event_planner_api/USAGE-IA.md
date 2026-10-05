# USAGE-IA — TP 5 — Goumarre Yoann

Outil(s) utilisé(s) : Claude Code (Claude Sonnet 5), assistant intégré au terminal
Déclaration : [x] entrées ci-dessous

J'ai surtout utilisé l'IA pour lever deux doutes ponctuels ; le reste du code
est de moi.

## Entrée 1
- Partie du TP concernée : partie C (exceptions + nouvelle tentative)
- Ce que j'ai demandé : l'énoncé dit « plafonnée à trois essais » mais donne
  trois délais d'exemple (1s, 2s, 4s) — j'ai demandé de trancher l'ambiguïté
  (3 essais au total, ou 3 nouvelles tentatives après l'essai initial ?), et
  comment nommer l'exception de timeout sans conflit avec celle de
  `dart:async`.
- Ce que j'ai obtenu : 4 essais au total (cohérent avec les 3 délais donnés),
  documenté comme un choix dans le README ; classe renommée
  `RequestTimeoutException`.
- Décision : acceptée, logique et assumée comme une interprétation.

## Entrée 2
- Partie du TP concernée : partie D (idempotence du POST)
- Ce que j'ai demandé : pourquoi exactement rejouer un `POST /users/add`
  automatiquement serait dangereux (j'avais l'intuition du double-clic, je
  voulais l'argument correct).
- Ce que j'ai obtenu : l'argument de la réponse perdue — le serveur traite la
  requête mais le client ne le sait pas à temps, il rejoue l'appel.
- Décision : acceptée, reformulée dans le README.

## Bilan
- Ce que l'IA m'a fait gagner : la résolution argumentée d'une ambiguïté de
  l'énoncé et le bon argument sur l'idempotence du `POST`.
- Ce qui m'a coûté du temps : rien de notable.
- Ce que je sais réexpliquer : `Uri.https` + vérification du statut avant
  décodage, un `fromJson` défensif, les trois branches d'un `FutureBuilder`,
  le mémo du `Future` dans `initState`, et pourquoi un `POST` ne se rejoue pas
  comme un `GET`. Je relirais la syntaxe exacte de `compute` avant de la
  réécrire sans modèle.
