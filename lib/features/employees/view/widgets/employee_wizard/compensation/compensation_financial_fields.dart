import 'package:material_ui/material_ui.dart';
import '../wizard_layout.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../cubit/employee_wizard_cubit.dart';
import '../../../cubit/employee_wizard_state.dart';

class CompensationFinancialFields extends StatelessWidget {
  const CompensationFinancialFields({
    super.key,
    required this.state,
    required this.cubit,
  });

  final EmployeeWizardState state;
  final EmployeeWizardCubit cubit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return WizardFieldsGrid(
      children: [
        TextFormField(
          initialValue: state.bankName,
          decoration: InputDecoration(
            labelText: t.bankName,
            border: const OutlineInputBorder(),
          ),
          onChanged: cubit.setBankName,
        ),
        TextFormField(
          initialValue: state.iban,
          decoration: InputDecoration(
            labelText: t.iban,
            border: const OutlineInputBorder(),
          ),
          onChanged: cubit.setIban,
        ),
        TextFormField(
          initialValue: state.accountNumber,
          decoration: InputDecoration(
            labelText: t.accountNumber,
            border: const OutlineInputBorder(),
          ),
          onChanged: cubit.setAccountNumber,
        ),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: state.paymentMethod,
          decoration: InputDecoration(
            labelText: t.paymentMethod,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: 'bank', child: Text(t.paymentMethodBank)),
            DropdownMenuItem(value: 'cash', child: Text(t.paymentMethodCash)),
          ],
          onChanged: (v) => cubit.setPaymentMethod(v ?? 'bank'),
        ),
      ],
    );
  }
}
