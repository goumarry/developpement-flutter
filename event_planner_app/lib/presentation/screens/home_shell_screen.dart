import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/registration_cart_state.dart';
import '../utils/breakpoints.dart';
import 'catalog_screen.dart';
import 'my_registrations_screen.dart';
import 'organizer_dashboard_screen.dart';
import 'settings_screen.dart';

/// Coquille de navigation principale, **adaptative** : la navigation change
/// de nature selon la largeur disponible, elle n'est pas seulement agrandie.
///
/// * téléphone : `NavigationBar` en bas ;
/// * tablette (>= [Breakpoints.tablet]) : `NavigationRail` latéral, le
///   contenu occupe toute la hauteur.
///
/// `IndexedStack` : chaque onglet garde son état (position de défilement,
/// recherche en cours) quand on en change.
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _index = 0;

  static const List<Widget> _pages = [
    CatalogScreen(),
    MyRegistrationsScreen(),
    OrganizerDashboardScreen(),
    SettingsScreen(),
  ];

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    // `select` : la coquille ne se reconstruit que si le nombre change, pas à
    // chaque notification du panier.
    final pending = context.select<RegistrationCartState, int>(
      (cart) => cart.lines.length,
    );
    final registrationsIcon = Badge(
      isLabelVisible: pending > 0,
      label: Text('$pending'),
      child: const Icon(Icons.confirmation_number_outlined),
    );
    final body = IndexedStack(index: _index, children: _pages);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.tablet) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      const NavigationRailDestination(
                        icon: Icon(Icons.event_outlined),
                        label: Text('Catalogue'),
                      ),
                      NavigationRailDestination(
                        icon: registrationsIcon,
                        label: const Text('Inscriptions'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.edit_calendar_outlined),
                        label: Text('Organisateur'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        label: Text('Réglages'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.event_outlined),
                label: 'Catalogue',
              ),
              NavigationDestination(
                icon: registrationsIcon,
                label: 'Inscriptions',
              ),
              const NavigationDestination(
                icon: Icon(Icons.edit_calendar_outlined),
                label: 'Organisateur',
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                label: 'Réglages',
              ),
            ],
          ),
        );
      },
    );
  }
}
