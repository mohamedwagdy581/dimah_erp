import 'package:flutter/material.dart';

import '../../../utils/employee_profile_utils.dart';

class ProfileDateButton extends StatelessWidget {
  const ProfileDateButton({
    super.key,
    required this.label,
    required this.value,
    required this.onPressed,
    this.icon = Icons.event_note,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(value == null ? label : formatEmployeeDate(value)),
    );
  }
}
