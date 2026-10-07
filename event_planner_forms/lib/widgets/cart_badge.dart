import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/app_shell_screen.dart';
import '../state/registration_cart.dart';

/// Badge de panier universel, affiché dans l'AppBar des écrans concernés
/// (TP 4, adapté à la coquille à navigateurs imbriqués du TP 3/Partie D).
///
/// Lit `RegistrationCart` **directement** via `context.select` : il ne dépend
/// que du total de places et ne se reconstruit donc que lorsque ce total
/// change. `Navigator.of(context)` résout vers le `Navigator` **de l'onglet
/// courant** (celui qui héberge l'écran où le badge est affiché) : le dépiler
/// jusqu'à sa racine ne touche donc pas aux autres onglets.
class CartBadge extends StatelessWidget {
  const CartBadge({super.key});

  /// Compteur de recompositions (mesure Partie A, TP 4). Voir README.
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
          Navigator.of(context).popUntil((route) => route.isFirst);
          AppShellScreen.openCart();
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
