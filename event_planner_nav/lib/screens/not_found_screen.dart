import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

/// Écran d'erreur **unique**, utilisé à la fois pour :
/// - la route inconnue (`onUnknownRoute`, erreur 404 générique) ;
/// - les trois cas d'erreur d'argument de la route de détail (argument absent,
///   type inattendu, identifiant inexistant).
///
/// Choix de fusion assumé (voir README) : dans tous ces cas l'utilisateur est
/// dans une impasse de navigation et la seule action utile est « revenir à
/// l'accueil ». Un seul écran, paramétré par [title] et [message], évite la
/// duplication tout en restant explicite : le message précise la cause réelle.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Erreur de navigation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.home_outlined),
                label: const Text('Retour à l\'accueil'),
                // pushAndRemoveUntil : on ne sait pas dans quel état est la
                // pile (route inconnue, erreur d'argument…). On reconstruit
                // donc l'accueil et on vide tout le reste. `rootNavigator` pour
                // sortir d'un éventuel Navigator imbriqué d'onglet (Partie D).
                onPressed: () => Navigator.of(context, rootNavigator: true)
                    .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
