# USAGE-IA — TP 6 — Goumarre Yoann

Outil(s) utilisé(s) : Claude Code (Claude Sonnet 5), assistant intégré au terminal
Déclaration : [x] entrées ci-dessous

J'ai surtout utilisé l'IA pour lever un doute ponctuel ; le reste du code
est de moi.

## Entrée 1
- Partie du TP concernée : partie C.1 (couche de validation pure)
- Ce que j'ai demandé : la règle de plage de dates compare deux dates, mais
  le `FormField` personnalisé manipule un `DateTimeRange` — qui vient de
  Flutter. Je voulais vérifier que ça ne contredit pas la contrainte « aucun
  import Flutter dans lib/validation/ ».
- Ce que j'ai obtenu : la fonction pure prend deux `DateTime?` nus (type
  `dart:core`, pas Flutter) ; c'est le `FormField`, qui lui est dans
  `lib/fields/` et a le droit d'importer Flutter, qui fait la conversion
  depuis le `DateTimeRange`.
- Décision : acceptée — vérifié qu'aucun fichier de `lib/validation/`
  n'importe `package:flutter/*` (`grep -r "package:flutter" lib/validation/`
  ne renvoie rien).

## Bilan
- Ce que l'IA m'a fait gagner : la confirmation que la séparation
  `lib/validation/` (types `dart:core`) / `lib/fields/` (Flutter) tient.
- Ce qui m'a coûté du temps : rien de notable.
- Ce que je sais réexpliquer : la différence entre une règle de champ isolé
  (`validator` simple) et une contrainte croisée (fonction pure qui lit
  plusieurs valeurs à la fois), pourquoi la couche de validation ne doit
  importer aucun type Flutter, le cycle `validate()`/`save()`/`reset()`
  appliqué à un `FormField` personnalisé, et pourquoi cocher une case ne doit
  jamais corriger silencieusement un autre champ.
