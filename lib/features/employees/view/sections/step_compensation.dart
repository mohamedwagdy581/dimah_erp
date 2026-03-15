import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/employee_wizard_cubit.dart';
import '../cubit/employee_wizard_state.dart';
import '../widgets/employee_wizard/compensation/compensation_financial_fields.dart';
import '../widgets/employee_wizard/compensation/compensation_salary_fields.dart';
import '../widgets/employee_wizard/compensation/compensation_total_card.dart';

class StepCompensation extends StatefulWidget {
  const StepCompensation({super.key});

  static final formKey = GlobalKey<FormState>();

  @override
  State<StepCompensation> createState() => _StepCompensationState();
}

class _StepCompensationState extends State<StepCompensation> {
  late final TextEditingController _basic;
  late final TextEditingController _housing;
  late final TextEditingController _transport;
  late final TextEditingController _other;

  @override
  void initState() {
    super.initState();
    _basic = TextEditingController();
    _housing = TextEditingController();
    _transport = TextEditingController();
    _other = TextEditingController();
  }

  @override
  void dispose() {
    _basic.dispose();
    _housing.dispose();
    _transport.dispose();
    _other.dispose();
    super.dispose();
  }

  double _toDouble(String v) => double.tryParse(v.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cubit = context.read<EmployeeWizardCubit>();

    return BlocBuilder<EmployeeWizardCubit, EmployeeWizardState>(
      builder: (context, state) {
        final total = state.basicSalary + state.housingAllowance + state.transportAllowance + state.otherAllowance;
        return Form(
          key: StepCompensation.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.stepCompensation,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CompensationSalaryFields(
                basic: _basic,
                housing: _housing,
                transport: _transport,
                other: _other,
                cubit: cubit,
                parse: _toDouble,
              ),
              const SizedBox(height: 16),
              CompensationFinancialFields(state: state, cubit: cubit),
              const SizedBox(height: 16),
              CompensationTotalCard(total: total.toDouble()),
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        );
      },
    );
  }
}
