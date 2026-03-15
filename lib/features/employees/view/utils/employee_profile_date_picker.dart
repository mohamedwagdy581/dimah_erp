import 'package:flutter/material.dart';

Future<DateTime?> pickEmployeeProfileDate(
  BuildContext context, {
  required DateTime? initialDate,
}) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initialDate ?? now,
    firstDate: DateTime(now.year - 15, 1, 1),
    lastDate: DateTime(now.year + 15, 12, 31),
  );
}
