# Captures à réaliser avant le rendu (TP 6)

Pas d'accès à l'émulateur depuis cet environnement : à réaliser toi-même
(`flutter run`, onglet **Formulaires**).

## Partie A — Inscription

1. **`01_formulaire_vide.png`** — Taper « S'inscrire » sur le formulaire
   vide → les 4 messages d'erreur affichés, pas de crash.
2. **`02_email_invalide.png`** — Quitter le champ courriel avec une valeur
   invalide (ex. `test@sansdomaine`) → message d'erreur affiché seulement
   après avoir quitté le champ (pas pendant la frappe).
3. **`03_inscription_ok.png`** — Formulaire rempli correctement → `SnackBar`
   de confirmation, puis champs vidés (après `reset()`).

## Partie B — Création d'événement

4. **`04_adresse_en_ligne.png`** — Adresse saisie + interrupteur « en ligne »
   activé → message d'erreur sous l'adresse.
5. **`05_tarif_gratuit.png`** — Tarif non nul + case « gratuit » cochée →
   message d'erreur sous le tarif.
6. **`06_dates_invalides.png`** — Date de fin antérieure ou égale à la date
   de début → message d'erreur sous le sélecteur de plage.
7. **`07_capacite_insuffisante.png`** — Capacité inférieure à 12 → message
   d'erreur mentionnant les inscrits déjà enregistrés.
8. **`08_compteur_description.png`** — Taper dans la description → le
   compteur de caractères sous le champ se met à jour en direct.
9. **`09_recapitulatif.png`** — Récapitulatif en lecture seule après un
   remplissage valide, avant confirmation.
10. **`10_confirmation.png`** — `SnackBar` de confirmation finale (titre +
    date) après avoir tapé « Confirmer » sur le récapitulatif.
11. **`11_abandon.png`** — Modifier un champ puis tenter de quitter l'écran
    (bouton retour) → boîte de dialogue « Abandonner la création ? ».

Supprimer ce fichier `NOTES.md` une fois les captures ajoutées, ou le laisser
tel quel — il ne fait pas partie du code.
