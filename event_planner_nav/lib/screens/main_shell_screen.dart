import 'package:flutter/material.dart';

import '../routes/route_generator.dart';
import 'event_wall_screen.dart';
import 'reservations_screen.dart';

/// Coquille à onglets de l'application (Partie D).
///
/// Chaque onglet possède **son propre [Navigator] imbriqué** avec sa propre
/// pile. Les deux navigators sont maintenus vivants par un [IndexedStack] :
/// changer d'onglet ne réinitialise jamais la pile de l'onglet quitté.
///
/// Gestion du retour matériel (via [PopScope] rattaché au Navigator racine) :
/// 1. si l'onglet actif a une pile profonde -> on dépile son écran courant ;
/// 2. sinon, si on n'est pas sur le premier onglet -> on y revient ;
/// 3. sinon (premier onglet, pile à la racine) -> [PopScope.canPop] vaut
///    `true` et le système fait sortir de l'application normalement.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  NavigatorState? get _currentNavigator => _navKeys[_currentIndex].currentState;

  bool get _shellCanPop =>
      _currentIndex == 0 && !(_currentNavigator?.canPop() ?? false);

  void _handlePop() {
    final navigator = _currentNavigator;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Deuxième tap sur l'onglet courant -> retour à sa racine.
      _navKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _shellCanPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _TabNavigator(
              navigatorKey: _navKeys[0],
              onStackChanged: () {
                if (mounted) setState(() {});
              },
              rootBuilder: (_) => const EventWallScreen(),
            ),
            _TabNavigator(
              navigatorKey: _navKeys[1],
              onStackChanged: () {
                if (mounted) setState(() {});
              },
              rootBuilder: (_) => const ReservationsScreen(),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border),
              activeIcon: Icon(Icons.bookmark),
              label: 'Mes réservations',
            ),
          ],
        ),
      ),
    );
  }
}

/// [Navigator] d'un onglet. Sa route initiale `'/'` construit la racine de
/// l'onglet ; toutes les autres routes du parcours sont déléguées au
/// générateur partagé [RouteGenerator.parcoursRoute].
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
/// pour que [PopScope.canPop] soit recalculé.
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
