import 'package:flutter/material.dart';

import 'event_creation_screen.dart';
import 'registration_screen.dart';

/// Racine de l'onglet « Formulaires » (TP 6) : point d'entrée vers les deux
/// formulaires du TP, poussés dans le `Navigator` propre à cet onglet.
class FormsHubScreen extends StatelessWidget {
  const FormsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formulaires')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.how_to_reg_outlined),
              title: const Text("S'inscrire à un événement"),
              subtitle: const Text('TP 6, partie A'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegistrationScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Créer un événement'),
              subtitle: const Text('TP 6, partie B'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EventCreationScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
