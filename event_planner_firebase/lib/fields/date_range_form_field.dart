import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// `FormField` personnalisé et réutilisable (TP 6, partie C.4) : un
/// sélecteur de plage de dates (début **et** fin) en un seul contrôle,
/// intégré au cycle `validate()`/`save()`/`reset()` du `Form` parent.
///
/// La valeur portée est un [DateTimeRange] (type Flutter) ; la règle de
/// cohérence « fin après début » vit elle dans
/// `lib/validation/cross_field_rules.dart`, sous forme de deux `DateTime?`
/// nus — ce champ ne fait que les en extraire avant d'appeler cette règle
/// pure depuis son propre [validator].
class DateRangeFormField extends FormField<DateTimeRange> {
  DateRangeFormField({
    super.key,
    required super.onSaved,
    required super.validator,
    super.initialValue,
    DateTime? firstSelectableDate,
    DateTime? lastSelectableDate,
  }) : super(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          builder: (FormFieldState<DateTimeRange> state) {
            final theme = Theme.of(state.context);
            final dateFormat = DateFormat.yMMMEd('fr_FR');
            final now = DateTime.now();
            final first = firstSelectableDate ?? DateTime(now.year - 1);
            final last = lastSelectableDate ?? DateTime(now.year + 5);

            Future<void> pickStart() async {
              final picked = await showDatePicker(
                context: state.context,
                initialDate: state.value?.start ?? now,
                firstDate: first,
                lastDate: last,
              );
              if (picked == null) return;
              final currentEnd = state.value?.end;
              state.didChange(DateTimeRange(
                start: picked,
                end: currentEnd != null && currentEnd.isAfter(picked)
                    ? currentEnd
                    : picked,
              ));
            }

            Future<void> pickEnd() async {
              final start = state.value?.start;
              final picked = await showDatePicker(
                context: state.context,
                initialDate: state.value?.end ?? start ?? now,
                firstDate: start ?? first,
                lastDate: last,
              );
              if (picked == null) return;
              state.didChange(DateTimeRange(
                start: start ?? picked,
                end: picked,
              ));
            }

            Widget dateTile({
              required String label,
              required DateTime? value,
              required VoidCallback onTap,
            }) {
              return Expanded(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    child: Text(
                      value == null ? 'Choisir…' : dateFormat.format(value),
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      dateTile(
                        label: 'Date de début',
                        value: state.value?.start,
                        onTap: pickStart,
                      ),
                      const SizedBox(width: 12),
                      dateTile(
                        label: 'Date de fin',
                        value: state.value?.end,
                        onTap: pickEnd,
                      ),
                    ],
                  ),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        state.errorText!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            );
          },
        );
}
