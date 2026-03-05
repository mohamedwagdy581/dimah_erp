import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_selector/file_selector.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/utils/safe_file_picker.dart';
import '../cubit/employee_wizard_cubit.dart';
import '../cubit/employee_wizard_state.dart';

class StepPersonal extends StatelessWidget {
  const StepPersonal({super.key});

  // هنستخدم key ده من بره (في صفحة الويزارد) عشان نعمل validate قبل Next
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
                  _PhotoPickerField(
                    photoUrl: state.photoUrl,
                    onChanged: cubit.setPhotoUrl,
                  ),
                  const SizedBox(height: 12),

                  // Full name (Required)
                  TextFormField(
                    initialValue: state.fullName,
                    onChanged: cubit.setFullName,
                    decoration: InputDecoration(
                      labelText: t.fullName,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final x = (v ?? '').trim();
                      if (x.isEmpty) return t.fullNameRequired;
                      if (x.length < 3) return t.fullNameTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Email + Phone (responsive) - Required
                  if (isSmall) ...[
                    TextFormField(
                      initialValue: state.email,
                      onChanged: cubit.setEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: t.email,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final x = (v ?? '').trim();
                        if (x.isEmpty) return t.emailRequired;
                        // Validation بسيطة
                        if (!x.contains('@') || !x.contains('.')) {
                          return t.enterValidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: state.phone,
                      onChanged: cubit.setPhone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: t.phone,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final x = (v ?? '').trim();
                        if (x.isEmpty) return t.phoneRequired;
                        if (x.length < 8) return t.phoneTooShort;
                        return null;
                      },
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: state.email,
                            onChanged: cubit.setEmail,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: t.email,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final x = (v ?? '').trim();
                              if (x.isEmpty) return t.emailRequired;
                              if (!x.contains('@') || !x.contains('.')) {
                                return t.enterValidEmail;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: state.phone,
                            onChanged: cubit.setPhone,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: t.phone,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final x = (v ?? '').trim();
                              if (x.isEmpty) return t.phoneRequired;
                              if (x.length < 8) {
                                return t.phoneTooShort;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // National ID (Required)
                  TextFormField(
                    initialValue: state.nationalId,
                    onChanged: cubit.setNationalId,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: t.nationalId,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final x = (v ?? '').trim();
                      if (x.isEmpty) return t.nationalIdRequired;
                      if (x.length < 6) return t.nationalIdTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Nationality
                  TextFormField(
                    initialValue: state.nationality ?? '',
                    onChanged: cubit.setNationality,
                    decoration: InputDecoration(
                      labelText: t.nationality,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Marital Status
                  DropdownButtonFormField<String>(
                    initialValue: state.maritalStatus,
                    decoration: InputDecoration(
                      labelText: t.maritalStatus,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'single', child: Text(t.single)),
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

                  // Address
                  TextFormField(
                    initialValue: state.address,
                    onChanged: cubit.setAddress,
                    decoration: InputDecoration(
                      labelText: t.address,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // City + Country
                  if (isSmall) ...[
                    TextFormField(
                      initialValue: state.city,
                      onChanged: cubit.setCity,
                      decoration: InputDecoration(
                        labelText: t.city,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: state.country,
                      onChanged: cubit.setCountry,
                      decoration: InputDecoration(
                        labelText: t.country,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: state.city,
                            onChanged: cubit.setCity,
                            decoration: InputDecoration(
                              labelText: t.city,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: state.country,
                            onChanged: cubit.setCountry,
                            decoration: InputDecoration(
                              labelText: t.country,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Passport
                  TextFormField(
                    initialValue: state.passportNo,
                    onChanged: cubit.setPassportNo,
                    decoration: InputDecoration(
                      labelText: t.passportNumber,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PassportExpiryField(
                    value: state.passportExpiry,
                    onPick: cubit.setPassportExpiry,
                  ),
                  const SizedBox(height: 12),

                  // Education
                  DropdownButtonFormField<String>(
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
                      DropdownMenuItem(value: 'master', child: Text(t.master)),
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

                  // Gender + DOB (Required)
                  if (isSmall) ...[
                    DropdownButtonFormField<String>(
                      initialValue: state.gender,
                      decoration: InputDecoration(
                        labelText: t.gender,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'male', child: Text(t.male)),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text(t.female),
                        ),
                      ],
                      onChanged: cubit.setGender,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return t.genderRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _DobFormField(
                      value: state.dateOfBirth,
                      onPick: cubit.setDateOfBirth,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: state.gender,
                            decoration: InputDecoration(
                              labelText: t.gender,
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text(t.male),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text(t.female),
                              ),
                            ],
                            onChanged: cubit.setGender,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return t.genderRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DobFormField(
                            value: state.dateOfBirth,
                            onPick: cubit.setDateOfBirth,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PhotoPickerField extends StatefulWidget {
  const _PhotoPickerField({
    required this.photoUrl,
    required this.onChanged,
  });

  final String photoUrl;
  final ValueChanged<String> onChanged;

  @override
  State<_PhotoPickerField> createState() => _PhotoPickerFieldState();
}

class _PhotoPickerFieldState extends State<_PhotoPickerField> {
  static const int _maxPhotoBytes = 5 * 1024 * 1024; // 5 MB
  bool _picking = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final hasPhoto = widget.photoUrl.trim().isNotEmpty;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: hasPhoto ? _resolvePhotoProvider(widget.photoUrl) : null,
          child: hasPhoto ? null : const Icon(Icons.person),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _picking ? null : _pickOnly,
            icon: const Icon(Icons.upload_outlined),
            label: Text(
              _picking ? t.picking : t.selectEmployeePhoto,
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider _resolvePhotoProvider(String rawValue) {
    final value = rawValue.trim();
    final uri = Uri.tryParse(value);
    if (uri != null) {
      final scheme = uri.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') {
        return NetworkImage(value);
      }
      if (scheme == 'file') {
        return FileImage(File(uri.toFilePath()));
      }
    }
    return FileImage(File(value));
  }

  Future<void> _pickOnly() async {
    final t = AppLocalizations.of(context)!;
    final file = await SafeFilePicker.openSingle(
      context: context,
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Images',
          extensions: ['png', 'jpg', 'jpeg', 'webp'],
        ),
      ],
    );
    if (file == null) return;
    setState(() => _picking = true);
    try {
      final length = await file.length();
      if (length > _maxPhotoBytes) {
        throw Exception(t.photoTooLargeMax5Mb);
      }
      if (file.path.isEmpty) {
        throw Exception(t.unableAccessSelectedFilePath);
      }
      widget.onChanged(file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.photoSelectedUploadAfterCreate),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(t.photoUploadFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }
}

class _DobFormField extends FormField<DateTime> {
  _DobFormField({
    required DateTime? value,
    required ValueChanged<DateTime?> onPick,
  }) : super(
         initialValue: value,
         validator: (v) {
           if (v == null) return 'Date of birth is required';
           return null;
         },
         builder: (field) {
           final t = AppLocalizations.of(field.context)!;
           final v = field.value;
           final text = v == null
               ? t.selectDate
               : '${v.year.toString().padLeft(4, '0')}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';

           return InkWell(
             onTap: () async {
               final now = DateTime.now();
               final picked = await showDatePicker(
                 context: field.context,
                 initialDate: v ?? DateTime(now.year - 25, 1, 1),
                 firstDate: DateTime(1950, 1, 1),
                 lastDate: now,
               );
               // لازم نحدث الـ FormField نفسه + نحدث الـ cubit
               field.didChange(picked);
               onPick(picked);
             },
             child: InputDecorator(
             decoration: InputDecoration(
                 labelText: t.dateOfBirth,
                 border: const OutlineInputBorder(),
                 suffixIcon: const Icon(Icons.calendar_today_outlined),
                 errorText: field.errorText,
               ),
               child: Text(text),
             ),
           );
         },
       );
}

class _PassportExpiryField extends FormField<DateTime> {
  _PassportExpiryField({
    required DateTime? value,
    required ValueChanged<DateTime?> onPick,
  }) : super(
         initialValue: value,
         builder: (field) {
           final t = AppLocalizations.of(field.context)!;
           final v = field.value;
           final text = v == null
               ? t.selectDate
               : '${v.year.toString().padLeft(4, '0')}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';

           return InkWell(
             onTap: () async {
               final now = DateTime.now();
               final picked = await showDatePicker(
                 context: field.context,
                 initialDate: v ?? now,
                 firstDate: DateTime(2000, 1, 1),
                 lastDate: DateTime(now.year + 30),
               );
               field.didChange(picked);
               onPick(picked);
             },
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: t.passportExpiry,
                 border: const OutlineInputBorder(),
                 suffixIcon: const Icon(Icons.calendar_today_outlined),
               ),
               child: Text(text),
             ),
           );
         },
       );
}
