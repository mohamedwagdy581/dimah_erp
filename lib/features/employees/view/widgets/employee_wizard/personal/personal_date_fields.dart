import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';

class DobFormField extends FormField<DateTime> {
  DobFormField({
    super.key,
    required DateTime? value,
    required ValueChanged<DateTime?> onPick,
    bool showLabel = true,
    String requiredMessage = 'Date of birth is required',
  }) : super(
         initialValue: value,
         validator: (v) => v == null ? requiredMessage : null,
         builder: (field) {
           final t = AppLocalizations.of(field.context)!;
           final v = field.value;
           final text = v == null
               ? t.selectDate
               : '${v.year.toString().padLeft(4, '0')}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';

           return InkWell(
             onTap: () async {
               final now = DateTime.now();
               final picked = await showDatePicker(
                 context: field.context,
                 initialDate: v ?? DateTime(now.year - 25, 1, 1),
                 firstDate: DateTime(1950, 1, 1),
                 lastDate: now,
               );
               if (picked != null) {
                 field.didChange(picked);
                 onPick(picked);
               }
             },
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: showLabel ? t.dateOfBirth : null,
                 border: const OutlineInputBorder(),
                 suffixIcon: const Icon(Icons.calendar_today_outlined),
                 errorText: field.errorText,
               ),
               child: Text(text),
             ),
           );
         },
       );
}

class PassportExpiryField extends FormField<DateTime> {
  PassportExpiryField({
    super.key,
    required DateTime? value,
    required ValueChanged<DateTime?> onPick,
  }) : super(
         initialValue: value,
         builder: (field) {
           final t = AppLocalizations.of(field.context)!;
           final v = field.value;
           final text = v == null
               ? t.selectDate
               : '${v.year.toString().padLeft(4, '0')}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';

           return InkWell(
             onTap: () async {
               final now = DateTime.now();
               final picked = await showDatePicker(
                 context: field.context,
                 initialDate: v ?? now,
                 firstDate: DateTime(2000, 1, 1),
                 lastDate: DateTime(now.year + 30),
               );
               field.didChange(picked);
               onPick(picked);
             },
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: t.passportExpiry,
                 border: const OutlineInputBorder(),
                 suffixIcon: const Icon(Icons.calendar_today_outlined),
               ),
               child: Text(text),
             ),
           );
         },
       );
}
