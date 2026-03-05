import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../l10n/app_localizations.dart';

import '../../../../../core/di/app_di.dart';
import '../../../accounts/domain/models/account.dart';
import '../../domain/models/journal_line.dart';
import '../cubit/journal_cubit.dart';

class JournalFormDialog extends StatefulWidget {
  const JournalFormDialog({super.key});

  @override
  State<JournalFormDialog> createState() => _JournalFormDialogState();
}

class _JournalFormDialogState extends State<JournalFormDialog> {
  final _memo = TextEditingController();
  DateTime? _date;
  List<Account> _accounts = const [];
  String? _accountId;
  final _debit = TextEditingController();
  final _credit = TextEditingController();
  final List<JournalLine> _lines = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _memo.dispose();
    _debit.dispose();
    _credit.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final res = await AppDI.accountsRepo.fetchAccounts(
      page: 0,
      pageSize: 200,
      search: null,
      type: null,
      sortBy: 'code',
      ascending: true,
    );
    if (!mounted) return;
    setState(() => _accounts = res.items);
  }

  double _toNum(String v) => double.tryParse(v.trim()) ?? 0;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _addLine() {
    final t = AppLocalizations.of(context)!;
    if (_accountId == null) return;
    final acc = _accounts.firstWhere((a) => a.id == _accountId);
    final debit = _toNum(_debit.text);
    final credit = _toNum(_credit.text);
    if (debit <= 0 && credit <= 0) {
      setState(() => _error = t.debitOrCreditRequired);
      return;
    }
    _lines.add(
      JournalLine(
        accountId: acc.id,
        accountName: acc.name,
        debit: debit,
        credit: credit,
      ),
    );
    _debit.clear();
    _credit.clear();
    setState(() => _error = null);
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    if (_date == null) {
      setState(() => _error = t.dateRequired);
      return;
    }
    if (_lines.isEmpty) {
      setState(() => _error = t.addAtLeastOneLine);
      return;
    }
    final totalDebit = _lines.fold<num>(0, (s, l) => s + l.debit);
    final totalCredit = _lines.fold<num>(0, (s, l) => s + l.credit);
    if (totalDebit != totalCredit) {
      setState(() => _error = t.debitsMustEqualCredits);
      return;
    }
    await context.read<JournalCubit>().createEntry(
      entryDate: _date!,
      memo: _memo.text.trim(),
      lines: _lines,
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.newJournalEntry),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text(
                _date == null
                    ? t.pickDate
                    : '${_date!.year.toString().padLeft(4, '0')}-'
                          '${_date!.month.toString().padLeft(2, '0')}-'
                          '${_date!.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memo,
              decoration: InputDecoration(
                labelText: t.memo,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              items: _accounts
                  .map(
                    (a) => DropdownMenuItem(
                      value: a.id,
                      child: Text('${a.code} - ${a.name}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
              decoration: InputDecoration(
                labelText: t.account,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _debit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: t.debit,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _credit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: t.credit,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _addLine, child: Text(t.add)),
              ],
            ),
            const SizedBox(height: 8),
            ..._lines.map(
              (l) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${l.accountName}: D ${l.debit} / C ${l.credit}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
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
