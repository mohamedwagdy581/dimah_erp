import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';

class EmployeeProfileDialogActions extends StatelessWidget {
  const EmployeeProfileDialogActions({
    super.key,
    required this.saving,
    required this.onSave,
  });

  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: saving ? null : onSave,
          child: Text(saving ? t.saving : t.save),
        ),
      ],
    );
  }
}
