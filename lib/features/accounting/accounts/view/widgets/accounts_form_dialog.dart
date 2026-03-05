import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../l10n/app_localizations.dart';

import '../cubit/accounts_cubit.dart';

class AccountsFormDialog extends StatefulWidget {
  const AccountsFormDialog({super.key});

  @override
  State<AccountsFormDialog> createState() => _AccountsFormDialogState();
}

class _AccountsFormDialogState extends State<AccountsFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  String _type = 'expense';

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<AccountsCubit>().create(
      code: _code.text.trim(),
      name: _name.text.trim(),
      type: _type,
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.addAccount),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _code,
                decoration: InputDecoration(
                  labelText: t.code,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return t.codeRequired;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: t.name,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return t.nameRequired;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: [
                  DropdownMenuItem(value: 'asset', child: Text(t.accountTypeAsset)),
                  DropdownMenuItem(
                    value: 'liability',
                    child: Text(t.accountTypeLiability),
                  ),
                  DropdownMenuItem(value: 'equity', child: Text(t.accountTypeEquity)),
                  DropdownMenuItem(value: 'income', child: Text(t.accountTypeIncome)),
                  DropdownMenuItem(value: 'expense', child: Text(t.accountTypeExpense)),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'expense'),
                decoration: InputDecoration(
                  labelText: t.type,
                  border: const OutlineInputBorder(),
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
        ElevatedButton(onPressed: _submit, child: Text(t.save)),
      ],
    );
  }
}
