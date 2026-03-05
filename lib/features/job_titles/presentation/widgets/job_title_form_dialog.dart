import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';

import '../../domain/models/job_title.dart';
import '../cubit/job_titles_cubit.dart';

class JobTitleFormDialog extends StatefulWidget {
  const JobTitleFormDialog({super.key, this.edit});

  final JobTitle? edit;

  @override
  State<JobTitleFormDialog> createState() => _JobTitleFormDialogState();
}

class _JobTitleFormDialogState extends State<JobTitleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _desc;
  late final TextEditingController _level;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.edit?.name ?? '');
    _code = TextEditingController(text: widget.edit?.code ?? '');
    _desc = TextEditingController(text: widget.edit?.description ?? '');
    _level = TextEditingController(text: widget.edit?.level?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _desc.dispose();
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isEdit = widget.edit != null;

    return AlertDialog(
      title: Text(isEdit ? t.editJobTitle : t.addJobTitle),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: t.name),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? t.requiredField : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _code,
                decoration: InputDecoration(labelText: t.codeOptional),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _level,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.levelOptional,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: t.descriptionOptional,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final cubit = context.read<JobTitlesCubit>();
            final level = int.tryParse(_level.text.trim());

            if (isEdit) {
              await cubit.update(
                id: widget.edit!.id,
                name: _name.text,
                code: _code.text,
                description: _desc.text,
                level: level,
                isActive: widget.edit!.isActive,
              );
            } else {
              await cubit.create(
                name: _name.text,
                code: _code.text,
                description: _desc.text,
                level: level,
              );
            }

            if (context.mounted) Navigator.pop(context, true);
          },
          child: Text(isEdit ? t.save : t.create),
        ),
      ],
    );
  }
}
