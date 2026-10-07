# Captures à réaliser avant le rendu (TP 7)

Pas d'accès à l'émulateur depuis cet environnement : à réaliser toi-même
(`flutter run`, onglet **Stockage**). Noms exacts attendus par l'énoncé en
gras.

## Partie A — Préférences

1. **`premier_lancement.png`** — Désinstaller l'app (ou effacer ses données
   depuis les réglages Android), relancer, ouvrir Stockage → Réglages : les
   cinq préférences doivent afficher leurs valeurs par défaut (Clair / Date
   / filtre vide / Confortable / home).
2. **`avant_fermeture.png`** — Modifier au moins trois préférences (ex :
   thème Sombre, tri Titre, densité Compacte), capturer l'écran de réglages
   dans cet état.
3. **`apres_reouverture.png`** — Tuer complètement l'application (pas juste
   la mettre en arrière-plan — depuis le gestionnaire de tâches, ou
   `adb shell am force-stop com.esgi.eventplanner.event_planner_storage`),
   la rouvrir, retourner sur Réglages : les mêmes valeurs doivent être
   affichées.
4. Redémarrer l'émulateur entièrement, rouvrir l'app, vérifier que les
   préférences sont toujours là (pas de capture obligatoire pour celle-ci,
   juste à vérifier).

## Partie B — Brouillons

5. **`fichier_corrompu.png`** — Deux façons d'y arriver :
   - rapide : onglet Stockage → Mes brouillons → menu 🐛 → « Démo : produire
     un brouillon corrompu », puis ouvrir ce brouillon dans la liste (il
     apparaîtra une fois, la liste ne l'affichera plus après rechargement
     car il est filtré — rouvre-le directement si besoin) ;
   - manuelle (telle que documentée dans le README) : créer un brouillon,
     le sauvegarder, éditer son fichier `.json` sur le disque pour retirer
     l'accolade fermante finale, rouvrir le brouillon.
   Dans les deux cas, capturer l'écran « Brouillon illisible. ».
6. **`liste_brouillons.png`** *(non listé par l'énoncé mais utile)* — Au
   moins deux brouillons dans la liste, avec titre, date et taille visibles.
7. **`brouillon_restaure.png`** *(optionnel)* — Rouvrir un brouillon existant
   et montrer que ses champs sont bien pré-remplis.

Supprimer ce fichier `NOTES.md` une fois les captures ajoutées, ou le
laisser tel quel — il ne fait pas partie du code.
