import '../models/formule.dart';

/// Les trois formules de participation, **codées en dur** (aucune saisie
/// libre, aucun appel réseau). Repris du TP 3.
const List<Formule> samplePackages = [
  Formule(
    id: 'essentiel',
    label: 'Essentiel',
    priceEur: 0,
    description: "Accès à la session principale. Placement libre, sans extra.",
  ),
  Formule(
    id: 'standard',
    label: 'Standard',
    priceEur: 39,
    description:
        "Accès complet, pauses café incluses et support de présentation envoyé après l'événement.",
  ),
  Formule(
    id: 'vip',
    label: 'VIP',
    priceEur: 89,
    description:
        "Placement prioritaire, déjeuner networking et rencontre avec les intervenants.",
  ),
];
