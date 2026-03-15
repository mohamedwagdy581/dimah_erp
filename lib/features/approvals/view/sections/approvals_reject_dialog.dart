import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/approvals_cubit.dart';

Future<void> openApprovalRejectDialog(
  BuildContext context,
  String id,
  ApprovalsCubit cubit,
) async {
  final t = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.rejectRequest),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: t.reasonOptional,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(t.reject),
        ),
      ],
    ),
  );
  if (ok == true) {
    await cubit.reject(id, reason: controller.text.trim());
  }
}
