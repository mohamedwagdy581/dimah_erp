import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';

import '../cubit/employee_wizard_cubit.dart';
import '../cubit/employee_wizard_state.dart';

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
        final total =
            state.basicSalary +
            state.housingAllowance +
            state.transportAllowance +
            state.otherAllowance;

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

              TextFormField(
                controller: _basic,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t.basicSalaryRequired,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => cubit.setBasicSalary(_toDouble(v)),
                validator: (v) {
                  final value = _toDouble(v ?? '');
                  if (value <= 0) return t.basicSalaryValidationRequired;
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _housing,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t.housingAllowance,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => cubit.setHousingAllowance(_toDouble(v)),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _transport,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t.transportAllowance,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => cubit.setTransportAllowance(_toDouble(v)),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _other,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t.otherAllowance,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => cubit.setOtherAllowance(_toDouble(v)),
              ),

              const SizedBox(height: 16),

              // Financial info
              TextFormField(
                initialValue: state.bankName,
                decoration: InputDecoration(
                  labelText: t.bankName,
                  border: const OutlineInputBorder(),
                ),
                onChanged: cubit.setBankName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: state.iban,
                decoration: InputDecoration(
                  labelText: t.iban,
                  border: const OutlineInputBorder(),
                ),
                onChanged: cubit.setIban,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: state.accountNumber,
                decoration: InputDecoration(
                  labelText: t.accountNumber,
                  border: const OutlineInputBorder(),
                ),
                onChanged: cubit.setAccountNumber,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
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

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      t.total,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      t.amountSar(total.toStringAsFixed(2)),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),

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
