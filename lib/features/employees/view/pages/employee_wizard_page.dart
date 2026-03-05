import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';

import '../cubit/employee_wizard_cubit.dart';
import '../cubit/employee_wizard_state.dart';
import '../sections/step_personal.dart';
import '../sections/step_job.dart';
import '../sections/step_compensation.dart';

class EmployeeWizardPage extends StatefulWidget {
  const EmployeeWizardPage({super.key});

  @override
  State<EmployeeWizardPage> createState() => _EmployeeWizardPageState();
}

class _EmployeeWizardPageState extends State<EmployeeWizardPage> {
  int currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocListener<EmployeeWizardCubit, EmployeeWizardState>(
      listener: (context, state) {
        if (state.success) {
          context.go('/employees');
        }
      },
      child: BlocBuilder<EmployeeWizardCubit, EmployeeWizardState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: Text(t.pageCreateEmployee)),
            body: Column(
              children: [
                if (state.loading) const LinearProgressIndicator(),
                if (state.error != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
                Expanded(
                  child: Stepper(
                    currentStep: currentStep,
                    onStepContinue: () {
                      if (currentStep == 0) {
                        final ok =
                            StepPersonal.formKey.currentState?.validate() ??
                            false;
                        if (!ok) return;
                      }
                      if (currentStep == 1) {
                        final ok =
                            StepJob.formKey.currentState?.validate() ?? false;
                        if (!ok) return;
                      }
                      if (currentStep == 2) {
                        final ok =
                            StepCompensation.formKey.currentState?.validate() ??
                            false;
                        if (!ok) return;
                      }

                      if (currentStep < 2) {
                        setState(() => currentStep++);
                      } else {
                        context.read<EmployeeWizardCubit>().submit();
                      }
                    },

                    onStepCancel: state.loading
                        ? null
                        : () {
                            if (currentStep > 0) {
                              setState(() => currentStep--);
                            }
                          },
                    controlsBuilder: (context, details) {
                      return Row(
                        children: [
                          ElevatedButton(
                            onPressed: details.onStepContinue,
                            child: Text(
                              currentStep == 2 ? t.finish : t.next,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (currentStep > 0)
                            OutlinedButton(
                              onPressed: details.onStepCancel,
                              child: Text(t.back),
                            ),
                        ],
                      );
                    },
                    steps: [
                      Step(
                        title: Text(t.stepPersonalInfo),
                        content: const StepPersonal(),
                        isActive: true,
                      ),
                      Step(
                        title: Text(t.stepJobInfo),
                        content: const StepJob(),
                        isActive: true,
                      ),
                      Step(
                        title: Text(t.stepCompensation),
                        content: const StepCompensation(),
                        isActive: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
