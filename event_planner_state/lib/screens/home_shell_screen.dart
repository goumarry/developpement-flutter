import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/registration_cart.dart';
import 'cart_screen.dart';
import 'event_list_screen.dart';

/// Coquille de navigation principale : une `BottomNavigationBar` à deux
/// destinations (Accueil / Panier) au-dessus d'un [IndexedStack] qui garde les
/// deux écrans montés. L'écran de détail, lui, est *poussé* par-dessus.
///
/// L'onglet actif est un simple état d'UI local, porté par un [ValueNotifier]
/// (primitive autorisée) exposé en `static` pour que le [CartBadge] des AppBars
/// puisse demander « ouvre le panier » depuis n'importe où.
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  static final ValueNotifier<int> tab = ValueNotifier<int>(0);

  /// Bascule sur l'onglet Panier (utilisé par le badge des AppBars).
  static void openCart() => tab.value = 1;

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  @override
  Widget build(BuildContext context) {
    // Le total du panier pilote la pastille de l'onglet Panier.
    final cartCount =
        context.select<RegistrationCart, int>((cart) => cart.totalSeats);

    return ValueListenableBuilder<int>(
      valueListenable: HomeShellScreen.tab,
      builder: (context, index, _) {
        return Scaffold(
          body: IndexedStack(
            index: index,
            children: const [EventListScreen(), CartScreen()],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => HomeShellScreen.tab.value = i,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  child: const Icon(Icons.shopping_cart),
                ),
                label: 'Panier',
              ),
            ],
          ),
        );
      },
    );
  }
}
