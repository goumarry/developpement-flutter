import 'package:flutter/material.dart';

import '../data/sample_events.dart';
import '../routes/app_routes.dart';

/// Onglet « Mes réservations » (Partie D).
///
/// Contenu **codé en dur** (aucun état partagé, aucune persistance : ce sont
/// des séances ultérieures). Chaque ligne ouvre le détail de l'événement
/// correspondant *dans le Navigator de cet onglet* : la pile de l'onglet
/// « Accueil » n'en est pas affectée.
class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

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
            if (findEventById(reservation.eventId) case final event?)
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
              'Démonstration Partie D : ouvrir un détail ici puis changer '
              'd\'onglet — la pile de chaque onglet est indépendante et '
              'préservée.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Démonstration Partie C — écrans d\'erreur de route',
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
