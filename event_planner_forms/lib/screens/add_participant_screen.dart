import 'package:flutter/material.dart';

import '../api/exceptions.dart';
import '../api/users_api.dart';

/// Partie D (bonus) — écriture simulée sur `/users/add`.
///
/// Champ de saisie minimal, sans `Form`/`TextFormField` ni validation : le
/// sujet autorise explicitement cette forme pour la partie D. Le bouton
/// d'envoi est simplement désactivé tant que les deux champs sont vides —
/// ce n'est pas une validation de formulaire, juste une garde d'UI.
class AddParticipantScreen extends StatefulWidget {
  const AddParticipantScreen({super.key});

  @override
  State<AddParticipantScreen> createState() => _AddParticipantScreenState();
}

class _AddParticipantScreenState extends State<AddParticipantScreen> {
  final UsersApi _api = UsersApi();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _sending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _api.close();
    super.dispose();
  }

  bool get _canSubmit =>
      !_sending &&
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    setState(() {
      _sending = true;
      _errorMessage = null;
    });
    try {
      // POST non idempotent : aucune nouvelle tentative automatique ici
      // (voir UsersApi.addParticipant et la note du README, partie D).
      final created = await _api.addParticipant(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Créé côté serveur de test : #${created.id} ${created.fullName} '
            '(non persisté par DummyJSON).',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle inscription')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Formulaire minimal — envoie un POST à /users/add. La réponse '
              "contient un identifiant simulé, non persisté côté serveur.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _firstNameController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _canSubmit ? _submit : null,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_sending ? 'Envoi…' : 'Envoyer l\'inscription'),
            ),
          ],
        ),
      ),
    );
  }
}
