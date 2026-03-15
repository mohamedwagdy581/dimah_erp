import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/employee_wizard_cubit.dart';
import '../cubit/employee_wizard_state.dart';
import '../widgets/employee_wizard/personal/personal_contact_fields.dart';
import '../widgets/employee_wizard/personal/personal_date_fields.dart';
import '../widgets/employee_wizard/personal/personal_identity_fields.dart';
import '../widgets/employee_wizard/personal/personal_location_fields.dart';
import '../widgets/employee_wizard/personal/personal_photo_picker_field.dart';

class StepPersonal extends StatelessWidget {
  const StepPersonal({super.key});

  static final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<EmployeeWizardCubit, EmployeeWizardState>(
      builder: (context, state) {
        final cubit = context.read<EmployeeWizardCubit>();
        return LayoutBuilder(
          builder: (context, c) {
            final isSmall = c.maxWidth < 700;
            return Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.personalInformation,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  PersonalPhotoPickerField(photoUrl: state.photoUrl, onChanged: cubit.setPhotoUrl),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: state.fullName,
                    onChanged: cubit.setFullName,
                    decoration: InputDecoration(labelText: t.fullName, border: const OutlineInputBorder()),
                    validator: (v) {
                      final x = (v ?? '').trim();
                      if (x.isEmpty) return t.fullNameRequired;
                      if (x.length < 3) return t.fullNameTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  PersonalContactFields(state: state, cubit: cubit, isSmall: isSmall),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: state.nationalId,
                    onChanged: cubit.setNationalId,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: t.nationalId, border: const OutlineInputBorder()),
                    validator: (v) {
                      final x = (v ?? '').trim();
                      if (x.isEmpty) return t.nationalIdRequired;
                      if (x.length < 6) return t.nationalIdTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: state.nationality ?? '',
                    onChanged: cubit.setNationality,
                    decoration: InputDecoration(labelText: t.nationality, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: state.maritalStatus,
                    decoration: InputDecoration(labelText: t.maritalStatus, border: const OutlineInputBorder()),
                    items: [
                      DropdownMenuItem(value: 'single', child: Text(t.single)),
                      DropdownMenuItem(value: 'married', child: Text(t.married)),
                      DropdownMenuItem(value: 'divorced', child: Text(t.divorced)),
                      DropdownMenuItem(value: 'widowed', child: Text(t.widowed)),
                    ],
                    onChanged: cubit.setMaritalStatus,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: state.address,
                    onChanged: cubit.setAddress,
                    decoration: InputDecoration(labelText: t.address, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  PersonalLocationFields(state: state, cubit: cubit, isSmall: isSmall),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: state.passportNo,
                    onChanged: cubit.setPassportNo,
                    decoration: InputDecoration(labelText: t.passportNumber, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  PassportExpiryField(value: state.passportExpiry, onPick: cubit.setPassportExpiry),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: state.educationLevel,
                    decoration: InputDecoration(labelText: t.educationLevel, border: const OutlineInputBorder()),
                    items: [
                      DropdownMenuItem(value: 'high_school', child: Text(t.highSchool)),
                      DropdownMenuItem(value: 'diploma', child: Text(t.diploma)),
                      DropdownMenuItem(value: 'bachelor', child: Text(t.bachelor)),
                      DropdownMenuItem(value: 'master', child: Text(t.master)),
                      DropdownMenuItem(value: 'phd', child: Text(t.phd)),
                    ],
                    onChanged: cubit.setEducationLevel,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: state.major,
                    onChanged: cubit.setMajor,
                    decoration: InputDecoration(labelText: t.major, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: state.university,
                    onChanged: cubit.setUniversity,
                    decoration: InputDecoration(labelText: t.university, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  PersonalIdentityFields(state: state, cubit: cubit, isSmall: isSmall),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
