import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Début et fin d'un événement ; chacun peut ne pas encore être choisi.
typedef EventPeriod = ({DateTime? start, DateTime? end});

/// `FormField` personnalisé : début **et** fin (date + heure) en un seul
/// champ, intégré au cycle `validate()` / `save()` du `Form` parent.
///
/// La règle « fin après début » n'est pas ici : l'appelant fournit un
/// [validator] qui délègue à `validateDateRange` (domaine).
class DateRangeFormField extends FormField<EventPeriod> {
  DateRangeFormField({
    super.key,
    required FormFieldSetter<EventPeriod> super.onSaved,
    required FormFieldValidator<EventPeriod> super.validator,
    EventPeriod super.initialValue = (start: null, end: null),
    super.autovalidateMode,
  }) : super(
         builder: (field) {
           final theme = Theme.of(field.context);
           final value = field.value ?? (start: null, end: null);

           Future<void> pick({required bool isStart}) async {
             final context = field.context;
             final now = DateTime.now();
             final current = isStart ? value.start : value.end;
             final base = current ?? value.start ?? now;
             final date = await showDatePicker(
               context: context,
               initialDate: base,
               firstDate: DateTime(now.year - 1),
               lastDate: DateTime(now.year + 5),
             );
             if (date == null || !context.mounted) return;
             final time = await showTimePicker(
               context: context,
               initialTime: TimeOfDay.fromDateTime(base),
             );
             if (time == null) return;
             final picked = DateTime(
               date.year,
               date.month,
               date.day,
               time.hour,
               time.minute,
             );
             field.didChange(
               isStart
                   ? (start: picked, end: value.end)
                   : (start: value.start, end: picked),
             );
           }

           Widget tile(String label, DateTime? date, bool isStart) {
             return InkWell(
               onTap: () => pick(isStart: isStart),
               borderRadius: BorderRadius.circular(4),
               child: InputDecorator(
                 decoration: InputDecoration(
                   labelText: label,
                   suffixIcon: const Icon(Icons.calendar_today_outlined),
                 ),
                 child: Text(date == null ? 'Choisir…' : dateLabel(date)),
               ),
             );
           }

           return Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             mainAxisSize: MainAxisSize.min,
             children: [
               tile('Début', value.start, true),
               const SizedBox(height: 16),
               tile('Fin', value.end, false),
               if (field.hasError)
                 Padding(
                   padding: const EdgeInsets.only(top: 6, left: 12),
                   child: Text(
                     field.errorText!,
                     style: theme.textTheme.bodySmall?.copyWith(
                       color: theme.colorScheme.error,
                     ),
                   ),
                 ),
             ],
           );
         },
       );
}
