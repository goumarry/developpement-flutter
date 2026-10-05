import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/route_generator.dart';
import '../state/registration_cart.dart';
import 'cart_screen.dart';
import 'directory_screen.dart';
import 'event_list_screen.dart';
import 'event_wall_screen.dart';
import 'reservations_screen.dart';

/// Coquille de navigation principale — fusion fil-rouge.
///
/// Généralise à 5 onglets le motif à navigateurs imbriqués du TP 3 (Partie D) :
/// chaque onglet possède **son propre [Navigator]**, maintenu vivant par un
/// [IndexedStack] — changer d'onglet ne réinitialise jamais la pile de
/// l'onglet quitté.
///
/// Gestion du retour matériel (via [PopScope] rattaché au Navigator racine) :
/// 1. si l'onglet actif a une pile profonde -> on dépile son écran courant ;
/// 2. sinon, si on n'est pas sur le premier onglet -> on y revient ;
/// 3. sinon (premier onglet, pile à la racine) -> on laisse le système sortir
///    de l'application normalement.
///
/// Onglets : Accueil (TP 2/3, mur décoratif), Événements (TP 4, Provider),
/// Panier (TP 4), Réservations (TP 3, démo navigateurs imbriqués + erreurs de
/// route), Annuaire (TP 5, REST).
class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  /// Onglet actif, exposé en `static` pour que [CartBadge] puisse basculer
  /// sur le panier depuis n'importe quel onglet.
  static final ValueNotifier<int> activeTab = ValueNotifier<int>(0);

  static const int tabHome = 0;
  static const int tabEvents = 1;
  static const int tabCart = 2;
  static const int tabReservations = 3;
  static const int tabDirectory = 4;

  static void openCart() => activeTab.value = tabCart;

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  final List<GlobalKey<NavigatorState>> _navKeys =
      List.generate(5, (_) => GlobalKey<NavigatorState>());

  NavigatorState? _navigatorAt(int index) => _navKeys[index].currentState;

  void _handlePop(int activeIndex) {
    final navigator = _navigatorAt(activeIndex);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }
    if (activeIndex != AppShellScreen.tabHome) {
      AppShellScreen.activeTab.value = AppShellScreen.tabHome;
    }
  }

  void _onTabTapped(int index) {
    if (index == AppShellScreen.activeTab.value) {
      // Deuxième tap sur l'onglet courant -> retour à sa racine.
      _navKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    AppShellScreen.activeTab.value = index;
  }

  @override
  Widget build(BuildContext context) {
    final cartCount =
        context.select<RegistrationCart, int>((cart) => cart.totalSeats);

    return ValueListenableBuilder<int>(
      valueListenable: AppShellScreen.activeTab,
      builder: (context, activeIndex, _) {
        final canPopShell = activeIndex == AppShellScreen.tabHome &&
            !(_navigatorAt(AppShellScreen.tabHome)?.canPop() ?? false);

        return PopScope(
          canPop: canPopShell,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handlePop(activeIndex);
          },
          child: Scaffold(
            body: IndexedStack(
              index: activeIndex,
              children: [
                _TabNavigator(
                  navigatorKey: _navKeys[AppShellScreen.tabHome],
                  onStackChanged: () => setState(() {}),
                  rootBuilder: (_) => const EventWallScreen(),
                ),
                _TabNavigator(
                  navigatorKey: _navKeys[AppShellScreen.tabEvents],
                  onStackChanged: () => setState(() {}),
                  rootBuilder: (_) => const EventListScreen(),
                ),
                _TabNavigator(
                  navigatorKey: _navKeys[AppShellScreen.tabCart],
                  onStackChanged: () => setState(() {}),
                  rootBuilder: (_) => const CartScreen(),
                ),
                _TabNavigator(
                  navigatorKey: _navKeys[AppShellScreen.tabReservations],
                  onStackChanged: () => setState(() {}),
                  rootBuilder: (_) => const ReservationsScreen(),
                ),
                _TabNavigator(
                  navigatorKey: _navKeys[AppShellScreen.tabDirectory],
                  onStackChanged: () => setState(() {}),
                  rootBuilder: (_) => const DirectoryScreen(),
                ),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: activeIndex,
              onTap: _onTabTapped,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Accueil',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.event_outlined),
                  activeIcon: Icon(Icons.event),
                  label: 'Événements',
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
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark_border),
                  activeIcon: Icon(Icons.bookmark),
                  label: 'Réservations',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.badge_outlined),
                  activeIcon: Icon(Icons.badge),
                  label: 'Annuaire',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// [Navigator] d'un onglet (TP 3, Partie D). Sa route initiale `'/'` construit
/// la racine de l'onglet ; toutes les autres routes du parcours sont
/// déléguées au générateur partagé [RouteGenerator.parcoursRoute].
class _TabNavigator extends StatelessWidget {
  const _TabNavigator({
    required this.navigatorKey,
    required this.onStackChanged,
    required this.rootBuilder,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback onStackChanged;
  final WidgetBuilder rootBuilder;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      observers: [_StackChangeObserver(onStackChanged)],
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute<void>(settings: settings, builder: rootBuilder);
        }
        return RouteGenerator.parcoursRoute(settings);
      },
      onUnknownRoute: RouteGenerator.unknownRoute,
    );
  }
}

/// Prévient la coquille dès qu'une route est empilée/dépilée dans un onglet,
/// pour que `PopScope.canPop` soit recalculé.
class _StackChangeObserver extends NavigatorObserver {
  _StackChangeObserver(this.onChanged);

  final VoidCallback onChanged;

  void _notify() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => onChanged());

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _notify();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _notify();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _notify();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _notify();
}
