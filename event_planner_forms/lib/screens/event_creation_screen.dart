import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../fields/date_range_form_field.dart';
import '../formatters/two_decimals_formatter.dart';
import '../models/event_draft.dart';
import '../validation/cross_field_rules.dart' as cross;
import '../validation/validators.dart' as v;
import 'event_summary_screen.dart';

const _categories = ['Conférence', 'Atelier', 'Meetup', 'Table ronde'];

/// Nombre d'inscrits déjà enregistrés pour l'événement (TP 6, partie B —
/// codé en dur comme demandé : "utile pour la modification d'un événement
/// déjà partiellement rempli").
const inscritsExistants = 12;

/// TP 6, partie B — formulaire complet de création d'événement : dix champs
/// de natures différentes et quatre contraintes de validation croisée,
/// vérifiées avant tout `save()`.
class EventCreationScreen extends StatefulWidget {
  const EventCreationScreen({super.key});

  @override
  State<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends State<EventCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();

  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _capacityFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _priceFocus = FocusNode();

  String? _category;
  bool _isOnline = false;
  bool _isFree = false;
  DateTimeRange? _dateRange;
  TimeOfDay? _startTime;

  /// Vrai dès la première modification, pour l'interception de sortie sans
  /// soumission (TP 6, partie C.6).
  bool _dirty = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _titleController,
      _capacityController,
      _addressController,
      _priceController,
    ]) {
      controller.addListener(_markDirty);
    }
    // Écouteur séparé : la description doit aussi rafraîchir son compteur
    // de caractères à chaque frappe.
    _descriptionController.addListener(() {
      _markDirty();
      setState(() {});
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    // Chaque contrôleur et chaque FocusNode créé dans ce State est libéré
    // ici — voir README, partie C.2 (protocole de détection de fuite).
    for (final controller in [
      _titleController,
      _descriptionController,
      _capacityController,
      _addressController,
      _priceController,
    ]) {
      controller.dispose();
    }
    for (final focusNode in [
      _titleFocus,
      _descriptionFocus,
      _capacityFocus,
      _addressFocus,
      _priceFocus,
    ]) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<bool> _confirmAbandon() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Abandonner la création de l'événement ?"),
        content: const Text(
          'Les informations saisies dans ce formulaire seront perdues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continuer la saisie'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;
    _formKey.currentState!.save();

    final normalizedPrice = _isFree
        ? 0.0
        : double.tryParse(_priceController.text.trim().replaceAll(',', '.')) ??
            0.0;

    final draft = EventDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category!,
      capacity: int.parse(_capacityController.text.trim()),
      isOnline: _isOnline,
      address: _isOnline ? null : _addressController.text.trim(),
      startDate: _dateRange!.start,
      endDate: _dateRange!.end,
      startTime: _startTime!,
      price: normalizedPrice,
      isFree: _isFree,
    );

    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EventSummaryScreen(draft: draft)),
    );

    if (confirmed == true && mounted) {
      _submitted = true;
      final dateLabel = DateFormat.yMMMEd('fr_FR').format(draft.startDate);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Événement « ${draft.title} » créé pour le $dateLabel.'),
        ));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty || _submitted,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmAbandon() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Nouvel événement')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _titleController,
                focusNode: _titleFocus,
                decoration: const InputDecoration(
                  labelText: "Titre de l'événement",
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: v.compose([v.required()]),
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_descriptionFocus),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                focusNode: _descriptionFocus,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: const OutlineInputBorder(),
                  helperText:
                      '${_descriptionController.text.length} / 500 caractères',
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: v.compose([
                  v.required(),
                  v.minLength(20),
                  v.maxLength(500),
                ]),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final category in _categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                validator: (value) =>
                    value == null ? 'Choisissez une catégorie.' : null,
                onChanged: (value) => setState(() {
                  _category = value;
                  _dirty = true;
                }),
                onSaved: (value) => _category = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                focusNode: _capacityFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Capacité maximale',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: v.compose([
                  v.required(),
                  v.positiveInteger(),
                  (value) => cross.validateCapacityAgainstExisting(
                        capacityText: value,
                        existingRegistrations: inscritsExistants,
                      ),
                ]),
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_addressFocus),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Événement en ligne'),
                value: _isOnline,
                onChanged: (value) => setState(() {
                  _isOnline = value;
                  _dirty = true;
                }),
              ),
              TextFormField(
                controller: _addressController,
                focusNode: _addressFocus,
                enabled: !_isOnline,
                decoration: const InputDecoration(
                  labelText: 'Adresse du lieu',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) => cross.validateAddress(
                  address: value,
                  isOnline: _isOnline,
                ),
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_priceFocus),
              ),
              const SizedBox(height: 16),
              DateRangeFormField(
                onSaved: (range) => _dateRange = range,
                validator: (range) {
                  if (range == null) {
                    return 'Choisissez les dates de début et de fin.';
                  }
                  return cross.validateDateRange(range.start, range.end);
                },
              ),
              const SizedBox(height: 8),
              FormField<TimeOfDay>(
                onSaved: (value) => _startTime = value,
                validator: (value) =>
                    value == null ? 'Choisissez une heure de début.' : null,
                builder: (state) {
                  return InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: state.value ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        state.didChange(picked);
                        _markDirty();
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Heure de début',
                        border: const OutlineInputBorder(),
                        errorText: state.errorText,
                      ),
                      child: Text(
                        state.value == null
                            ? 'Choisir…'
                            : state.value!.format(context),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                focusNode: _priceFocus,
                enabled: !_isFree,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  TwoDecimalsFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Tarif (€)',
                  border: OutlineInputBorder(),
                  hintText: '0.00',
                ),
                textInputAction: TextInputAction.done,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) => cross.validatePrice(
                  priceText: value,
                  isFree: _isFree,
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Événement gratuit'),
                value: _isFree,
                onChanged: (value) => setState(() {
                  _isFree = value ?? false;
                  _dirty = true;
                }),
              ),
              const SizedBox(height: 8),
              FormField<bool>(
                initialValue: false,
                onSaved: (value) {}, // lu via state.value au moment du check
                validator: (value) => (value ?? false)
                    ? null
                    : "Cochez la case pour confirmer que vous acceptez les "
                        'conditions.',
                builder: (state) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: state.value ?? false,
                    onChanged: (value) {
                      state.didChange(value);
                      _markDirty();
                    },
                    title: const Text("J'accepte les conditions d'organisation"),
                    subtitle: state.hasError
                        ? Text(
                            state.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Voir le récapitulatif'),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
