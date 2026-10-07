# Captures — TP 10

Prises sur l'émulateur Android (1440 × 3120 px à 560 dpi, soit 411 dp de
large). La tablette est simulée sur le même émulateur par
`adb shell wm size 1600x2560` et `adb shell wm density 320` (800 × 1280 dp),
puis `wm size reset` / `wm density reset`.

| Fichier | Ce qu'il montre |
|---|---|
| `00-jalon-parcours-vertical.png` | Jalon de la Partie A : un seul écran, une liste réelle issue de DummyJSON. |
| `01-telephone-etroit-catalogue.png` | Téléphone étroit : liste, cartes horizontales, barre de navigation basse. |
| `02-tablette-portrait-catalogue.png` | Tablette portrait : grille de tuiles verticales, rail de navigation latéral. |
| `03-mode-degrade.png` | Mode dégradé (APK release, thème sombre) : catalogue issu de la copie locale, bandeau « non actualisé ». |
| `04-evenement-complet.png` | Événement complet à la source : jauge rouge, bouton désactivé. |
| `05-connexion-requise.png` | Utilisateur non connecté qui veut s'inscrire : la connexion est proposée. |
| `capacite-atteinte.png` | Après inscription à la dernière place : l'événement se ferme. |
| `06-panier-inscriptions.png` | Inscriptions en cours, modifiables avant confirmation. |
| `07-validation-croisee-tablette.png` | Éditeur d'événement : trois validations croisées refusées. |
| `08-espace-organisateur-tablette.png` | Espace organisateur après création d'un événement dans Firestore. |
| `preuve-regles-securite.log` | Sortie de `scripts/prove_rules.sh` : refus du serveur (HTTP 403). |
