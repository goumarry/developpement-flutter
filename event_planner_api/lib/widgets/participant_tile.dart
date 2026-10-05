import 'package:flutter/material.dart';

import '../models/participant.dart';

class ParticipantTile extends StatelessWidget {
  const ParticipantTile({
    super.key,
    required this.participant,
    required this.onTap,
  });

  final Participant participant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        backgroundImage: participant.imageUrl.isNotEmpty
            ? NetworkImage(participant.imageUrl)
            : null,
        onBackgroundImageError: participant.imageUrl.isNotEmpty
            ? (exception, stackTrace) {}
            : null,
        child: participant.imageUrl.isEmpty
            ? Text(participant.firstName.isNotEmpty
                ? participant.firstName[0].toUpperCase()
                : '?')
            : null,
      ),
      title: Text(participant.fullName),
      subtitle: Text(
        '${participant.companyName} · ${participant.email}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
