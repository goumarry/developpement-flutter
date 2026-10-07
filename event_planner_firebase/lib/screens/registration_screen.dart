import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../validation/validators.dart' as v;

/// TP 6, partie A — formulaire d'inscription d'un participant à un
/// événement. Périmètre volontairement restreint : aucun appel réseau
/// (séance 5), aucun état global (séance 4) — tout vit en état local dans ce
/// `State`.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _seatsController = TextEditingController();
  final _emailController = TextEditingController();

  final _nameFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _seatsFocus = FocusNode();
  final _emailFocus = FocusNode();

  /// L'erreur de format n'est affichée qu'une fois le champ courriel quitté
  /// une première fois — valider à chaque frappe avant que l'utilisateur
  /// ait fini de taper son adresse serait agressif (cf. README, partie C.3).
  bool _emailTouched = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus && !_emailTouched) {
        setState(() => _emailTouched = true);
      }
    });
  }

  @override
  void dispose() {
    // Chaque contrôleur et chaque FocusNode créé dans ce State est libéré
    // ici — voir README, partie C.2, pour la démonstration de la fuite
    // obtenue quand on omet cette étape.
    _nameController.dispose();
    _cityController.dispose();
    _seatsController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _cityFocus.dispose();
    _seatsFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (!_emailTouched) return null;
    return v.compose([v.required(), v.email()])(value);
  }

  void _submit() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      setState(() => _emailTouched = true); // révèle l'erreur si on force la soumission
      return;
    }
    _formKey.currentState!.save();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          'Inscription enregistrée pour ${_nameController.text.trim()}.',
        ),
      ));
    _formKey.currentState!.reset();
    setState(() => _emailTouched = false);
    FocusScope.of(context).requestFocus(_nameFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inscription à l'événement")),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocus,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: v.compose([
                v.required(),
                v.minLength(2),
                v.maxLength(80),
              ]),
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_cityFocus),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              focusNode: _cityFocus,
              decoration: const InputDecoration(
                labelText: 'Lieu de résidence (ville)',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: v.compose([v.required(), v.minLength(2)]),
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_seatsFocus),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _seatsController,
              focusNode: _seatsFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nombre de places demandées',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: v.compose([v.required(), v.positiveInteger()]),
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_emailFocus),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Courriel de contact',
                border: OutlineInputBorder(),
                hintText: 'nom@domaine.ext',
              ),
              textInputAction: TextInputAction.done,
              validator: _validateEmail,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("S'inscrire"),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
