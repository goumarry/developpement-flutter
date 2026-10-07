import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/catalog_state.dart';

/// Catalogue — jalon « parcours vertical » : une liste réelle issue de l'API,
/// qui traverse presentation -> state -> domain <- data.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue')),
      body: switch (catalog.status) {
        CatalogStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        CatalogStatus.error =>
          Center(child: Text(catalog.errorMessage ?? 'Erreur')),
        CatalogStatus.loaded => ListView.builder(
            itemCount: catalog.events.length,
            itemBuilder: (context, index) {
              final event = catalog.events[index];
              return ListTile(
                title: Text(event.title),
                subtitle: Text(
                  '${event.category} · '
                  '${event.registered}/${event.capacity} places',
                ),
              );
            },
          ),
      },
    );
  }
}
