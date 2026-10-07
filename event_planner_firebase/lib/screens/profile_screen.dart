import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../utils/auth_error_translator.dart';

/// Profil de l'organisateur (TP 8, partie B) : identité, vérification du
/// courriel, mise à jour du nom affiché, déconnexion.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _name.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _say(String text, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _message = text;
      _isError = error;
    });
  }

  Future<void> _saveName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await user.updateDisplayName(_name.text.trim());
      // Relit le profil : `userChanges()` émet alors le nouveau nom et
      // l'interface (StreamBuilder ci-dessous) se met à jour.
      await user.reload();
      _say('Nom mis à jour.');
    } catch (e) {
      _say(translateAuthError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendVerification() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      _say('Courriel de vérification envoyé.');
    } catch (e) {
      _say(translateAuthError(e), error: true);
    }
  }

  Future<void> _signOut() async {
    // Ferme d'abord les routes empilées sur le Navigator racine (dialogues…),
    // puis déconnecte : AuthGate remplace alors toute la branche privée.
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          final firebaseUser = snapshot.data;
          if (firebaseUser == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = AppUser.fromFirebase(firebaseUser);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(user.label, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Courriel : ${user.email}'),
              Text('UID : ${user.uid}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    user.emailVerified ? Icons.verified : Icons.warning_amber,
                    color: user.emailVerified ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(user.emailVerified ? 'Courriel vérifié' : 'Courriel non vérifié'),
                  if (!user.emailVerified) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: _resendVerification,
                      child: const Text('Renvoyer'),
                    ),
                    TextButton(
                      onPressed: () => firebaseUser.reload(),
                      child: const Text('Actualiser'),
                    ),
                  ],
                ],
              ),
              const Divider(height: 32),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nom affiché',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _saveName,
                child: const Text('Mettre à jour le nom'),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  style: TextStyle(color: _isError ? scheme.error : null),
                ),
              ],
              const Divider(height: 32),
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ],
          );
        },
      ),
    );
  }
}
