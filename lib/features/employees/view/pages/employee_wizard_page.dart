import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/employee_wizard_cubit.dart';
import '../cubit/employee_wizard_state.dart';
import '../sections/step_personal.dart';
import '../sections/step_job.dart';
import '../sections/step_compensation.dart';
import '../sections/step_employee_account.dart';
import '../widgets/employee_wizard/job/job_contract_fields.dart';
import '../widgets/employee_wizard/wizard_layout.dart';

class EmployeeWizardPage extends StatefulWidget {
  const EmployeeWizardPage({super.key});
  @override
  State<EmployeeWizardPage> createState() => _EmployeeWizardPageState();
}

class _EmployeeWizardPageState extends State<EmployeeWizardPage> {
  int currentStep = 0;
  final _visited = <int>{0};
  final _contractKey = GlobalKey<FormState>();
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _validate() => switch (currentStep) {
    0 => StepPersonal.validate(),
    1 => StepJob.formKey.currentState?.validate() ?? false,
    2 => _contractKey.currentState?.validate() ?? false,
    _ =>
      (StepCompensation.formKey.currentState?.validate() ?? false) &
          (StepEmployeeAccount.formKey.currentState?.validate() ?? false),
  };
  void _move(int step) {
    setState(() {
      currentStep = step;
      _visited.add(step);
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final titles = [
      t.stepPersonalInfo,
      ar ? 'الوظيفة' : 'Job',
      t.contract,
      ar ? 'التعويضات' : 'Compensation',
    ];
    final subtitles = ar
        ? [
            'البيانات الأساسية للموظف',
            'البيانات الوظيفية',
            'بيانات العقد الوظيفي',
            'إدخال بيانات التعويضات',
          ]
        : [
            'Employee basic information',
            'Employment information',
            'Employment contract',
            'Compensation details',
          ];
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: wizardBorder),
    );
    return BlocListener<EmployeeWizardCubit, EmployeeWizardState>(
      listenWhen: (previous, next) => !previous.success && next.success,
      listener: (context, state) {
        final login = state.loginResult!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text(
              ar
                  ? 'تم تجهيز حساب ${login.email}. ${login.accountCreated ? 'يمكنه الدخول بكلمة المرور التي حددتها.' : 'الحساب الموجود يحتفظ بكلمة مروره الحالية.'}'
                  : 'Login ready for ${login.email}. ${login.accountCreated ? 'Use the password you entered.' : 'The existing password is unchanged.'}',
            ),
          ),
        );
        context.go('/employees');
      },
      child: BlocBuilder<EmployeeWizardCubit, EmployeeWizardState>(
        builder: (context, state) {
          final locked = state.loading || state.savedEmployeeId != null;
          final sections = <Widget>[
            const StepPersonal(),
            const StepJob(includeContract: false),
            Form(
              key: _contractKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.contract,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  JobContractFields(state: state),
                  const SizedBox(height: 18),
                  TextFormField(
                    initialValue: state.contractFileUrl,
                    onChanged: context
                        .read<EmployeeWizardCubit>()
                        .setContractFileUrl,
                    decoration: InputDecoration(
                      labelText: t.contractFileUrl,
                      prefixIcon: const Icon(Icons.attach_file, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AbsorbPointer(
                  absorbing: locked,
                  child: const StepCompensation(),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(color: wizardBorder),
                ),
                const StepEmployeeAccount(),
              ],
            ),
          ];
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: wizardPurple,
                onPrimary: Colors.white,
              ),
              textTheme: Theme.of(
                context,
              ).textTheme.apply(bodyColor: wizardInk, displayColor: wizardInk),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  backgroundColor: wizardPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(130, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: wizardPurple,
                  side: const BorderSide(color: wizardBorder),
                  minimumSize: const Size(130, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: outline,
                enabledBorder: outline,
                disabledBorder: outline,
                focusedBorder: outline.copyWith(
                  borderSide: const BorderSide(color: wizardPurple, width: 1.5),
                ),
                labelStyle: const TextStyle(color: wizardInk, fontSize: 13),
                prefixIconColor: wizardPurple,
                suffixIconColor: wizardPurple,
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.white,
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final padding = constraints.maxWidth < 600 ? 12.0 : 24.0;
                  return SingleChildScrollView(
                    controller: _scroll,
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          ar ? 'إضافة موظف جديد' : 'Add a new employee',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ar
                              ? 'إدخال بيانات الموظف وإكمال خطوات الإضافة'
                              : 'Enter employee information and complete the following steps',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF777098),
                          ),
                        ),
                        const SizedBox(height: 28),
                        EmployeeWizardProgress(
                          currentStep: currentStep,
                          titles: titles,
                          subtitles: subtitles,
                          onBack: state.loading
                              ? null
                              : (index) {
                                  if (index < currentStep) _move(index);
                                },
                        ),
                        const SizedBox(height: 18),
                        if (state.loading) const LinearProgressIndicator(),
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              state.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        Container(
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            border: Border.all(color: wizardBorder),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: List.generate(
                              4,
                              (index) => Visibility(
                                visible: index == currentStep,
                                maintainState: true,
                                child: _visited.contains(index)
                                    ? AbsorbPointer(
                                        absorbing: index < 3 && locked,
                                        child: sections[index],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: OutlinedButton.icon(
                                iconAlignment: IconAlignment.end,
                                key: const ValueKey('employee-wizard-back'),
                                onPressed: state.loading || currentStep == 0
                                    ? null
                                    : () => _move(currentStep - 1),
                                icon: Icon(
                                  ar ? Icons.arrow_forward : Icons.arrow_back,
                                  size: 18,
                                  textDirection: TextDirection.ltr,
                                ),
                                label: Text(ar ? 'السابق' : 'Previous'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: FilledButton.icon(
                                iconAlignment: IconAlignment.end,
                                key: const ValueKey('employee-wizard-next'),
                                onPressed: state.loading
                                    ? null
                                    : () {
                                        if (!_validate()) return;
                                        if (currentStep < 3) {
                                          _move(currentStep + 1);
                                        } else {
                                          context
                                              .read<EmployeeWizardCubit>()
                                              .submit();
                                        }
                                      },
                                icon: Icon(
                                  currentStep == 3
                                      ? Icons.check
                                      : (ar
                                            ? Icons.arrow_back
                                            : Icons.arrow_forward),
                                  size: 18,
                                  textDirection: TextDirection.ltr,
                                ),
                                label: Text(
                                  currentStep == 3
                                      ? (state.savedEmployeeId != null
                                            ? t.retry
                                            : t.finish)
                                      : t.next,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class EmployeeWizardProgress extends StatelessWidget {
  const EmployeeWizardProgress({
    super.key,
    required this.currentStep,
    required this.titles,
    required this.subtitles,
    this.onBack,
  });
  final int currentStep;
  final List<String> titles, subtitles;
  final ValueChanged<int>? onBack;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 520;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: wizardBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(titles.length, (index) {
            final active = index == currentStep;
            final completed = index < currentStep;
            return Expanded(
              child: InkWell(
                onTap: completed && onBack != null
                    ? () => onBack!(index)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index == 0
                                ? Colors.transparent
                                : (index <= currentStep
                                      ? wizardPurple
                                      : wizardBorder),
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active
                                ? wizardPurple
                                : const Color(0xFFF8F6FC),
                            border: Border.all(
                              color: active || completed
                                  ? wizardPurple
                                  : const Color(0xFFD5CEE8),
                            ),
                          ),
                          child: completed
                              ? const Icon(
                                  Icons.check,
                                  size: 17,
                                  color: wizardPurple,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: active ? Colors.white : wizardInk,
                                  ),
                                ),
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index == titles.length - 1
                                ? Colors.transparent
                                : (index <= currentStep
                                      ? wizardPurple
                                      : wizardBorder),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      titles[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 10 : 13,
                        fontWeight: FontWeight.bold,
                        color: active ? wizardPurple : wizardInk,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitles[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF777098),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      );
    },
  );
}
