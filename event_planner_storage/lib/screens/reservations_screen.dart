import 'package:flutter/material.dart';

import '../data/event_repository.dart';
import '../routes/app_routes.dart';

/// Onglet « Mes réservations » (TP 3, Partie D).
///
/// Contenu **codé en dur** (indépendant du panier Provider du TP 4 : ce sont
/// des réservations fictives, pas le panier réel — volontairement, pour
/// garder la démonstration de navigateurs imbriqués indépendante de l'état
/// applicatif). Chaque ligne ouvre le détail de l'événement correspondant
/// *dans le Navigator de cet onglet* : la pile des autres onglets n'en est
/// pas affectée.
class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  static const EventRepository _repository = EventRepository();

  static const List<({String eventId, String formule})> _fakeReservations = [
    (eventId: 'evt-005', formule: 'VIP'),
    (eventId: 'evt-006', formule: 'Standard'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes réservations')),
      body: ListView(
        children: [
          for (final reservation in _fakeReservations)
            if (_repository.findById(reservation.eventId) case final event?)
              ListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('Formule ${reservation.formule}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.eventDetail,
                  arguments: event.id,
                ),
              ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Démonstration Partie D (TP 3) : ouvrir un détail ici puis '
              'changer d\'onglet — la pile de chaque onglet est indépendante '
              'et préservée.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Démonstration Partie C (TP 3) — écrans d\'erreur de route',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.link_off, color: Colors.redAccent),
            title: const Text('Lien vers un événement inexistant'),
            subtitle: const Text('eventDetail avec id « evt-999 »'),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.eventDetail,
              arguments: 'evt-999',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.redAccent),
            title: const Text('Argument de route du mauvais type'),
            subtitle: const Text('eventDetail avec un entier au lieu d\'un id'),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.eventDetail,
              arguments: 42,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.report_gmailerrorred, color: Colors.redAccent),
            title: const Text('Route totalement inconnue (404)'),
            subtitle: const Text('nom de route non enregistré -> onUnknownRoute'),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.demoUnknownRoute),
          ),
        ],
      ),
    );
  }
}
