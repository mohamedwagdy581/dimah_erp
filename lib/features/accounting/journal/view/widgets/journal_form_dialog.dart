import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/app_di.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../accounts/domain/models/account.dart';
import '../../domain/models/journal_line.dart';
import '../cubit/journal_cubit.dart';

part 'journal_form_dialog_build_part.dart';

class JournalFormDialog extends StatefulWidget {
  const JournalFormDialog({super.key});

  @override
  State<JournalFormDialog> createState() => _JournalFormDialogState();
}

class _JournalFormDialogState extends State<JournalFormDialog> {
  final _memo = TextEditingController();
  final _debit = TextEditingController();
  final _credit = TextEditingController();
  final List<JournalLine> _lines = [];

  DateTime? _date;
  List<Account> _accounts = const [];
  String? _accountId;
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
    if (!mounted) {
      return;
    }
    setState(() => _accounts = res.items);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _setAccountId(String? value) {
    setState(() => _accountId = value);
  }

  double _toNum(String value) => double.tryParse(value.trim()) ?? 0;

  void _addLine() {
    final t = AppLocalizations.of(context)!;
    if (_accountId == null) {
      return;
    }
    final account = _accounts.firstWhere((item) => item.id == _accountId);
    final debit = _toNum(_debit.text);
    final credit = _toNum(_credit.text);
    if (debit <= 0 && credit <= 0) {
      setState(() => _error = t.debitOrCreditRequired);
      return;
    }
    _lines.add(
      JournalLine(
        accountId: account.id,
        accountName: account.name,
        debit: debit,
        credit: credit,
      ),
    );
    _debit.clear();
    _credit.clear();
    setState(() => _error = null);
  }

  String _formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
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
    final totalDebit = _lines.fold<num>(0, (sum, line) => sum + line.debit);
    final totalCredit = _lines.fold<num>(0, (sum, line) => sum + line.credit);
    if (totalDebit != totalCredit) {
      setState(() => _error = t.debitsMustEqualCredits);
      return;
    }
    await context.read<JournalCubit>().createEntry(
      entryDate: _date!,
      memo: _memo.text.trim(),
      lines: _lines,
    );
    if (!mounted) {
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => buildJournalFormDialog(context);
}
