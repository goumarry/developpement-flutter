import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/home_shell_screen.dart';
import '../state/registration_cart.dart';

/// Badge de panier universel, affiché dans l'AppBar de tous les écrans.
///
/// Lit `RegistrationCart` **directement** via `context.select` : il ne dépend
/// que du total de places et ne se reconstruit donc que lorsque ce total
/// change — pas quand une session est modifiée, par exemple. Aucun écran ne lui
/// transmet quoi que ce soit par paramètre.
class CartBadge extends StatelessWidget {
  const CartBadge({super.key});

  /// Compteur de recompositions (mesure Partie A). Voir README.
  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    final int totalSeats =
        context.select<RegistrationCart, int>((cart) => cart.totalSeats);
    if (kDebugMode) debugPrint('BUILD CartBadge (#$builds) total=$totalSeats');

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        tooltip: 'Voir le panier',
        onPressed: () {
          // Revenir à la coquille puis basculer sur l'onglet Panier — depuis
          // l'écran liste comme depuis le détail (poussé au-dessus).
          Navigator.of(context).popUntil((route) => route.isFirst);
          HomeShellScreen.openCart();
        },
        icon: Badge(
          isLabelVisible: totalSeats > 0,
          label: Text('$totalSeats'),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
      ),
    );
  }
}
