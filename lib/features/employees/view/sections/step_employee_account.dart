import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/employee_login_result.dart';
import '../cubit/employee_wizard_cubit.dart';
import '../cubit/employee_wizard_state.dart';
import '../widgets/attendance_number_field.dart';

class StepEmployeeAccount extends StatelessWidget {
  const StepEmployeeAccount({super.key});
  static final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return BlocBuilder<EmployeeWizardCubit, EmployeeWizardState>(
      builder: (context, state) {
        final cubit = context.read<EmployeeWizardCubit>();
        return Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ar ? 'حساب الدخول' : 'Login account',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${ar ? 'إيميل الدخول' : 'Login email'}: ${state.email}',
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 16),
              AttendanceNumberField(
                initialValue: state.attendanceNumber,
                enabled: !state.loading && !cubit.attendanceLinked,
                onChanged: cubit.setAttendanceNumber,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: state.loginRole,
                decoration: InputDecoration(
                  labelText: ar ? 'صلاحية الحساب' : 'Account role',
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'employee',
                    child: Text(ar ? 'موظف' : 'Employee'),
                  ),
                  DropdownMenuItem(
                    value: 'manager',
                    child: Text(ar ? 'مدير مباشر' : 'Direct manager'),
                  ),
                ],
                onChanged: state.loading
                    ? null
                    : (role) {
                        if (role != null) cubit.setLoginRole(role);
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('employee-login-password'),
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                enabled: !state.loading,
                onChanged: cubit.setInitialPassword,
                decoration: InputDecoration(
                  labelText: ar
                      ? 'كلمة مرور الحساب الجديد'
                      : 'New account password',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => isValidEmployeeLoginPassword(value ?? '')
                    ? null
                    : (ar
                          ? '12 حرفًا على الأقل، وحروف كبيرة وصغيرة ورقم ورمز'
                          : 'At least 12 characters with uppercase, lowercase, a number and a symbol'),
              ),
              const SizedBox(height: 12),
              Text(
                ar
                    ? 'الحساب الجديد سيكون جاهزًا للدخول بهذا الإيميل وكلمة المرور. إذا كان الإيميل له حساب بالفعل، يحتفظ بكلمة مروره الحالية.'
                    : 'A new account can sign in using this email and password. An existing account keeps its current password.',
              ),
              const SizedBox(height: 12),
              Text(
                ar
                    ? 'اختيار مدير مباشر يحدد صلاحياته؛ إسناد الموظفين إليه يتم من حقل المدير المباشر في بيانات الموظف.'
                    : 'The direct manager role enables manager access. Assign reports using the Direct manager field in employee details.',
              ),
            ],
          ),
        );
      },
    );
  }
}
