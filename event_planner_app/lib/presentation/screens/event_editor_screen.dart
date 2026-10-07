import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/models/event.dart';
import '../../domain/rules/event_form_rules.dart';
import '../../domain/rules/validators.dart';
import '../../state/organizer_events_state.dart';
import '../../state/registration_cart_state.dart';
import '../utils/breakpoints.dart';
import '../widgets/date_range_form_field.dart';

/// Création ([event] nul) ou modification d'un événement d'organisateur.
/// Renvoie à l'écran appelant un message de succès (`String`).
///
/// Formulaire à **validation croisée** (règles pures de
/// `domain/rules/event_form_rules.dart`) :
/// * adresse obligatoire en présentiel, interdite en ligne ;
/// * tarif nul si « Gratuit » est coché, positif sinon ;
/// * fin strictement après le début ;
/// * en modification, capacité au moins égale aux places déjà attribuées.
class EventEditorScreen extends StatefulWidget {
  const EventEditorScreen({super.key, this.event});

  final Event? event;

  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  static const List<String> _categories = [
    'Conférence',
    'Atelier',
    'Concert',
    'Sport',
    'Salon',
  ];

  final _formKey = GlobalKey<FormState>();
  late final Event? _initial = widget.event;
  late final _title = TextEditingController(text: _initial?.title ?? '');
  late final _description = TextEditingController(
    text: _initial?.description ?? '',
  );
  late final _address = TextEditingController(text: _initial?.location ?? '');
  late final _capacity = TextEditingController(
    text: _initial?.capacity.toString() ?? '',
  );
  late final _price = TextEditingController(
    text: _initial == null || _initial.isFree ? '' : '${_initial.price}',
  );
  late String _category = _categories.contains(_initial?.category)
      ? _initial!.category
      : _categories.first;
  late bool _isOnline = _initial?.isOnline ?? false;
  late bool _isFree = _initial?.isFree ?? true;
  EventPeriod _period = (start: null, end: null);

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _period = (start: _initial?.start, end: _initial?.end);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _address.dispose();
    _capacity.dispose();
    _price.dispose();
    super.dispose();
  }

  /// Une case qui change invalide ou valide **un autre** champ : après un
  /// premier envoi, on revalide tout le formulaire pour que le message du
  /// champ lié apparaisse ou disparaisse aussitôt.
  void _onLinkedFieldChanged(VoidCallback change) {
    setState(change);
    if (_autovalidate != AutovalidateMode.disabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formKey.currentState?.validate();
      });
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState!;
    if (!form.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    form.save();
    final price = _isFree
        ? 0.0
        : double.parse(_price.text.trim().replaceAll(',', '.'));
    final event = Event(
      id: _initial?.id ?? '',
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category,
      start: _period.start!,
      end: _period.end!,
      location: _isOnline ? '' : _address.text.trim(),
      isOnline: _isOnline,
      capacity: int.parse(_capacity.text.trim()),
      registered: 0,
      price: price,
    );

    setState(() {
      _saving = true;
      _saveError = null;
    });
    final result = await context.read<OrganizerEventsState>().save(event);
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() {
        _saving = false;
        _saveError = result.error;
      });
      return;
    }
    final verb = _initial == null ? 'créé' : 'modifié';
    Navigator.of(context).pop(
      result.queuedOffline
          ? 'Événement $verb hors connexion : il sera envoyé au retour du réseau.'
          : 'Événement $verb.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Places que l'utilisateur détient déjà sur cet événement : la capacité
    // ne peut pas descendre en dessous.
    final existing = _initial == null
        ? 0
        : context.read<RegistrationCartState>().heldSeats(_initial.id);
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(
        title: Text(_initial == null ? 'Nouvel événement' : 'Modifier'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Breakpoints.readableWidth,
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Titre'),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      validator: compose([
                        requiredField(),
                        minLength(3),
                        maxLength(80),
                      ]),
                    ),
                    gap,
                    TextFormField(
                      controller: _description,
                      decoration: const InputDecoration(
                        labelText: 'Description (facultative)',
                      ),
                      minLines: 2,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      validator: maxLength(500),
                    ),
                    gap,
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Catégorie'),
                      items: [
                        for (final category in _categories)
                          DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _category = value ?? _category),
                    ),
                    gap,
                    DateRangeFormField(
                      initialValue: _period,
                      onSaved: (value) => _period = value ?? _period,
                      validator: (value) =>
                          validateDateRange(value?.start, value?.end),
                    ),
                    gap,
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('En ligne'),
                      subtitle: const Text('Pas de lieu physique'),
                      value: _isOnline,
                      onChanged: (value) =>
                          _onLinkedFieldChanged(() => _isOnline = value),
                    ),
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(
                        labelText: 'Adresse du lieu',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          validateAddress(address: value, isOnline: _isOnline),
                    ),
                    gap,
                    TextFormField(
                      controller: _capacity,
                      decoration: const InputDecoration(
                        labelText: 'Capacité (nombre de places)',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.next,
                      validator: compose([
                        requiredField(),
                        positiveInteger(),
                        (value) => validateCapacityAgainstExisting(
                          capacityText: value,
                          existingRegistrations: existing,
                        ),
                      ]),
                    ),
                    gap,
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Gratuit'),
                      value: _isFree,
                      onChanged: (value) =>
                          _onLinkedFieldChanged(() => _isFree = value ?? false),
                    ),
                    TextFormField(
                      controller: _price,
                      decoration: const InputDecoration(
                        labelText: 'Tarif',
                        suffixText: '€',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                      ],
                      validator: (value) =>
                          validatePrice(priceText: value, isFree: _isFree),
                    ),
                    if (_saveError != null) ...[
                      gap,
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _saveError!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
