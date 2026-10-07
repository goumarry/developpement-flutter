import 'package:flutter/material.dart';

import '../api/users_api.dart';
import '../models/participant.dart';
import '../widgets/status_views.dart';

class ParticipantDetailScreen extends StatefulWidget {
  const ParticipantDetailScreen({super.key, required this.userId});

  final int userId;

  @override
  State<ParticipantDetailScreen> createState() =>
      _ParticipantDetailScreenState();
}

class _ParticipantDetailScreenState extends State<ParticipantDetailScreen> {
  final UsersApi _api = UsersApi();
  late Future<Participant> _future; // mémorisé une fois (voir directory_screen)

  @override
  void initState() {
    super.initState();
    _future = _api.fetchUserDetail(widget.userId);
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  void _retry() {
    setState(() => _future = _api.fetchUserDetail(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fiche participant')),
      body: FutureBuilder<Participant>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const FullScreenLoader(label: 'Chargement de la fiche…');
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: ErrorView.messageFor(snapshot.error),
              onRetry: _retry,
            );
          }
          return _DetailBody(participant: snapshot.data!);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.participant});

  final Participant participant;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            backgroundImage: participant.imageUrl.isNotEmpty
                ? NetworkImage(participant.imageUrl)
                : null,
            onBackgroundImageError:
                participant.imageUrl.isNotEmpty ? (exception, stackTrace) {} : null,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            participant.fullName,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        _InfoRow(icon: Icons.email_outlined, label: 'Email', value: participant.email),
        _InfoRow(
          icon: Icons.business_outlined,
          label: 'Entreprise',
          value: participant.companyName,
        ),
        // Champs disponibles seulement sur l'endpoint de détail — absents de
        // la liste paginée (consigne : "au moins un champ supplémentaire").
        _InfoRow(
          icon: Icons.home_outlined,
          label: 'Adresse',
          value: participant.address ?? 'Non renseigné',
        ),
        _InfoRow(
          icon: Icons.phone_outlined,
          label: 'Téléphone',
          value: participant.phone ?? 'Non renseigné',
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
