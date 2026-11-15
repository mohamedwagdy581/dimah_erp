import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/employee_wizard_cubit.dart';
import '../cubit/employee_wizard_state.dart';
import '../widgets/employee_wizard/personal/personal_date_fields.dart';
import '../widgets/employee_wizard/personal/personal_location_fields.dart';
import '../widgets/employee_wizard/personal/personal_photo_picker_field.dart';
import '../widgets/employee_wizard/wizard_layout.dart';

class StepPersonal extends StatefulWidget {
  const StepPersonal({super.key});
  static final formKey = GlobalKey<FormState>();
  static bool validate() {
    final form = formKey.currentState;
    if (form == null) return false;
    if (form.context.read<EmployeeWizardCubit>().state.gender == null) {
      form.context
          .findAncestorStateOfType<_StepPersonalState>()
          ?._openAdditional();
    }
    return form.validate();
  }

  @override
  State<StepPersonal> createState() => _StepPersonalState();
}

class _StepPersonalState extends State<StepPersonal> {
  final _extra = ExpansibleController();
  void _openAdditional() => _extra.expand();
  @override
  void dispose() {
    _extra.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return BlocBuilder<EmployeeWizardCubit, EmployeeWizardState>(
      builder: (context, state) {
        final cubit = context.read<EmployeeWizardCubit>();
        Widget textField(
          String label,
          String value,
          ValueChanged<String> change, {
          bool required = false,
          IconData? icon,
          TextInputType? type,
          String? Function(String?)? validator,
        }) => WizardLabeledField(
          label: label,
          required: required,
          child: TextFormField(
            initialValue: value,
            onChanged: change,
            keyboardType: type,
            validator: validator,
            decoration: InputDecoration(
              suffixIcon: icon == null ? null : Icon(icon, size: 18),
            ),
          ),
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            final small = constraints.maxWidth < 720;
            final mainFields = WizardFieldsGrid(
              children: [
                textField(
                  t.fullName,
                  state.fullName,
                  cubit.setFullName,
                  required: true,
                  validator: (v) {
                    final x = (v ?? '').trim();
                    if (x.isEmpty) return t.fullNameRequired;
                    if (x.length < 3) return t.fullNameTooShort;
                    return null;
                  },
                ),
                textField(
                  t.email,
                  state.email,
                  cubit.setEmail,
                  required: true,
                  icon: Icons.mail_outline,
                  type: TextInputType.emailAddress,
                  validator: (v) {
                    final x = (v ?? '').trim();
                    if (x.isEmpty) return t.emailRequired;
                    if (!x.contains('@') || !x.contains('.')) {
                      return t.enterValidEmail;
                    }
                    return null;
                  },
                ),
                textField(
                  t.phone,
                  state.phone,
                  cubit.setPhone,
                  required: true,
                  icon: Icons.phone_outlined,
                  type: TextInputType.phone,
                  validator: (v) {
                    final x = (v ?? '').trim();
                    if (x.isEmpty) return t.phoneRequired;
                    if (x.length < 8) return t.phoneTooShort;
                    return null;
                  },
                ),
                textField(
                  t.nationalId,
                  state.nationalId,
                  cubit.setNationalId,
                  required: true,
                  icon: Icons.badge_outlined,
                  type: TextInputType.number,
                  validator: (v) {
                    final x = (v ?? '').trim();
                    if (x.isEmpty) return t.nationalIdRequired;
                    if (x.length < 6) return t.nationalIdTooShort;
                    return null;
                  },
                ),
                textField(
                  t.nationality,
                  state.nationality ?? '',
                  cubit.setNationality,
                  required: true,
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? (ar ? 'الجنسية مطلوبة' : 'Nationality is required')
                      : null,
                ),
                WizardLabeledField(
                  label: t.dateOfBirth,
                  required: true,
                  child: DobFormField(
                    value: state.dateOfBirth,
                    onPick: cubit.setDateOfBirth,
                    showLabel: false,
                    requiredMessage: ar
                        ? 'تاريخ الميلاد مطلوب'
                        : 'Date of birth is required',
                  ),
                ),
              ],
            );
            final photo = PersonalPhotoPickerField(
              photoUrl: state.photoUrl,
              onChanged: cubit.setPhotoUrl,
            );
            return Form(
              key: StepPersonal.formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ar ? 'البيانات الشخصية' : 'Personal information',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (small) ...[
                    mainFields,
                    const SizedBox(height: 20),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(width: 180, child: photo),
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: mainFields),
                        const SizedBox(width: 24),
                        SizedBox(width: 180, child: photo),
                      ],
                    ),
                  const SizedBox(height: 22),
                  ExpansionTile(
                    controller: _extra,
                    maintainState: true,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 16),
                    title: Text(
                      ar
                          ? 'بيانات شخصية إضافية'
                          : 'Additional personal information',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: state.gender,
                        decoration: InputDecoration(labelText: t.gender),
                        items: [
                          DropdownMenuItem(value: 'male', child: Text(t.male)),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text(t.female),
                          ),
                        ],
                        onChanged: cubit.setGender,
                        validator: (v) => v == null ? t.genderRequired : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: state.maritalStatus,
                        decoration: InputDecoration(
                          labelText: t.maritalStatus,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'single',
                            child: Text(t.single),
                          ),
                          DropdownMenuItem(
                            value: 'married',
                            child: Text(t.married),
                          ),
                          DropdownMenuItem(
                            value: 'divorced',
                            child: Text(t.divorced),
                          ),
                          DropdownMenuItem(
                            value: 'widowed',
                            child: Text(t.widowed),
                          ),
                        ],
                        onChanged: cubit.setMaritalStatus,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: state.address,
                        onChanged: cubit.setAddress,
                        decoration: InputDecoration(
                          labelText: t.address,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PersonalLocationFields(
                        state: state,
                        cubit: cubit,
                        isSmall: small,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: state.passportNo,
                        onChanged: cubit.setPassportNo,
                        decoration: InputDecoration(
                          labelText: t.passportNumber,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PassportExpiryField(
                        value: state.passportExpiry,
                        onPick: cubit.setPassportExpiry,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: state.educationLevel,
                        decoration: InputDecoration(
                          labelText: t.educationLevel,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'high_school',
                            child: Text(t.highSchool),
                          ),
                          DropdownMenuItem(
                            value: 'diploma',
                            child: Text(t.diploma),
                          ),
                          DropdownMenuItem(
                            value: 'bachelor',
                            child: Text(t.bachelor),
                          ),
                          DropdownMenuItem(
                            value: 'master',
                            child: Text(t.master),
                          ),
                          DropdownMenuItem(value: 'phd', child: Text(t.phd)),
                        ],
                        onChanged: cubit.setEducationLevel,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: state.major,
                        onChanged: cubit.setMajor,
                        decoration: InputDecoration(
                          labelText: t.major,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: state.university,
                        onChanged: cubit.setUniversity,
                        decoration: InputDecoration(
                          labelText: t.university,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
