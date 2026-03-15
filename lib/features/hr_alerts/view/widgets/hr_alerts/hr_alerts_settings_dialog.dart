import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../employees/domain/models/expiry_alert.dart';

Future<ExpiryAlertSettings?> showHrAlertsSettingsDialog(
  BuildContext context,
  ExpiryAlertSettings current,
) async {
  final t = AppLocalizations.of(context)!;
  final contractCtrl = TextEditingController(text: current.contractAlertDays.toString());
  final residencyCtrl = TextEditingController(text: current.residencyAlertDays.toString());
  final insuranceCtrl = TextEditingController(text: current.insuranceAlertDays.toString());
  final documentsCtrl = TextEditingController(text: current.documentsAlertDays.toString());
  final formKey = GlobalKey<FormState>();

  Widget daysField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (v) {
        final n = int.tryParse((v ?? '').trim());
        if (n == null || n <= 0 || n > 365) {
          return t.validationRange1To365;
        }
        return null;
      },
    );
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.hrAlertsSettingsTitle),
      content: SizedBox(
        width: 380,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              daysField(contractCtrl, t.hrAlertsContractDays),
              const SizedBox(height: 10),
              daysField(residencyCtrl, t.hrAlertsResidencyDays),
              const SizedBox(height: 10),
              daysField(insuranceCtrl, t.hrAlertsInsuranceDays),
              const SizedBox(height: 10),
              daysField(documentsCtrl, t.hrAlertsDocumentsDays),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.cancel)),
        ElevatedButton(
          onPressed: () {
            if (!(formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(dialogContext, true);
          },
          child: Text(t.save),
        ),
      ],
    ),
  );

  contractCtrl.dispose();
  residencyCtrl.dispose();
  insuranceCtrl.dispose();
  documentsCtrl.dispose();
  if (ok != true) return null;

  return ExpiryAlertSettings(
    contractAlertDays: int.parse(contractCtrl.text.trim()),
    residencyAlertDays: int.parse(residencyCtrl.text.trim()),
    insuranceAlertDays: int.parse(insuranceCtrl.text.trim()),
    documentsAlertDays: int.parse(documentsCtrl.text.trim()),
  );
}
