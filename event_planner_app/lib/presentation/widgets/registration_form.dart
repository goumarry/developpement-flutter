import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/rules/registration_form_rules.dart';
import '../../domain/rules/validators.dart';

/// Données validées d'une demande d'inscription.
typedef RegistrationRequest = ({String name, String email, int seats});

/// Formulaire d'inscription à un événement.
///
/// Le widget ne contient **aucune** règle : chaque `validator` branche une
/// fonction pure du domaine. Deux validations sont croisées — la confirmation
/// du courriel (dépend du champ courriel) et le nombre de places (dépend de
/// [remainingSeats], extérieur au formulaire).
///
/// [onSubmit] n'est appelé que si tout le formulaire est valide.
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({
    super.key,
    required this.remainingSeats,
    required this.onSubmit,
    this.initialEmail = '',
    this.initialName = '',
  });

  final int remainingSeats;
  final ValueChanged<RegistrationRequest> onSubmit;
  final String initialEmail;
  final String initialName;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late final _email = TextEditingController(text: widget.initialEmail);
  final _confirmation = TextEditingController();
  final _seats = TextEditingController(text: '1');

  /// Après un premier envoi refusé, chaque correction est revalidée à la
  /// frappe ; avant, on ne signale pas d'erreur sur un champ pas encore saisi.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _confirmation.dispose();
    _seats.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    widget.onSubmit((
      name: _name.text.trim(),
      email: _email.text.trim(),
      seats: int.parse(_seats.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nom du participant'),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            validator: compose([requiredField(), minLength(2), maxLength(60)]),
          ),
          gap,
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Courriel'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: compose([requiredField(), email()]),
          ),
          gap,
          TextFormField(
            controller: _confirmation,
            decoration: const InputDecoration(
              labelText: 'Confirmation du courriel',
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) => validateEmailConfirmation(
              email: _email.text,
              confirmation: value,
            ),
          ),
          gap,
          TextFormField(
            controller: _seats,
            decoration: InputDecoration(
              labelText: 'Nombre de places',
              helperText:
                  '${widget.remainingSeats} place(s) disponible(s), '
                  '$maxSeatsPerRegistration au plus par inscription',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (value) => validateSeats(
              seatsText: value,
              remainingSeats: widget.remainingSeats,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.playlist_add),
            label: const Text('Ajouter à mes inscriptions'),
          ),
        ],
      ),
    );
  }
}
