import 'package:material_ui/material_ui.dart';
import '../../../../../core/ui/app_data_state.dart';
import '../../../../../core/utils/request_id.dart';
import '../../../accounts/domain/models/account.dart';
import '../../../accounts/domain/repos/accounts_repo.dart';
import '../../domain/repos/journal_repo.dart';
import '../../domain/models/journal_line.dart';
import '../../../view/accounting_ui.dart';
import '../../../../payroll/view/widgets/payroll_format.dart';

class _DraftLine {
  String? accountId;
  final debit = TextEditingController(), credit = TextEditingController();
  void dispose() {
    debit.dispose();
    credit.dispose();
  }
}

/// Parse money as integer cents, including Arabic keyboard digits.
int? journalCents(String input) {
  var text = input.trim().replaceAll('٫', '.');
  for (var i = 0; i < 10; i++) {
    text = text
        .replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i')
        .replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i');
  }
  if (text.isEmpty) return 0;
  if (!RegExp(r'^\d{1,12}(\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  return int.parse(parts[0]) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
}

class JournalDraftWorkspace extends StatefulWidget {
  const JournalDraftWorkspace({
    super.key,
    required this.accountsRepo,
    required this.journalRepo,
    required this.onSaved,
    required this.onCancel,
  });
  final AccountsRepo accountsRepo;
  final JournalRepo journalRepo;
  final VoidCallback onSaved, onCancel;
  @override
  State<JournalDraftWorkspace> createState() => _JournalDraftWorkspaceState();
}

class _JournalDraftWorkspaceState extends State<JournalDraftWorkspace> {
  final memo = TextEditingController(), scroll = ScrollController();
  final lines = [_DraftLine(), _DraftLine()];
  final requestId = newRequestId();
  List<Account> accounts = [];
  DateTime date = DateTime.now();
  bool loading = true, busy = false;
  Object? error;
  String? message;
  String tr(String a, String e) => accountingText(context, a, e);
  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  @override
  void dispose() {
    memo.dispose();
    scroll.dispose();
    for (final l in lines) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> loadAccounts() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final all = <Account>[];
      for (var page = 0; ; page++) {
        final result = await widget.accountsRepo.fetchAccounts(
          page: page,
          pageSize: 100,
          isActive: true,
          sortBy: 'code',
          ascending: true,
        );
        all.addAll(result.items.where((a) => a.isActive));
        if (result.items.isEmpty || (page + 1) * 100 >= result.total) break;
      }
      if (mounted) {
        setState(() {
          accounts = all;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  int sum(bool debit) => lines.fold(
    0,
    (s, l) => s + (journalCents(debit ? l.debit.text : l.credit.text) ?? 0),
  );
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => date = picked);
  }

  Future<void> save() async {
    if (busy || loading || error != null) return;
    final batch = <JournalLine>[];
    for (final l in lines) {
      final debit = journalCents(l.debit.text),
          credit = journalCents(l.credit.text);
      if (l.accountId == null ||
          !accounts.any((a) => a.id == l.accountId) ||
          debit == null ||
          credit == null ||
          (debit <= 0 && credit <= 0) ||
          (debit > 0 && credit > 0)) {
        setState(
          () => message = tr(
            'اختر حسابًا نشطًا لكل سطر وأدخل مبلغًا موجبًا في المدين أو الدائن فقط، بحد أقصى خانتين عشريتين.',
            'Select an active account for every row and enter a positive debit OR credit with up to two decimal places.',
          ),
        );
        return;
      }
      batch.add(
        JournalLine(
          accountId: l.accountId!,
          accountName: accounts.firstWhere((a) => a.id == l.accountId).name,
          debit: debit / 100,
          credit: credit / 100,
        ),
      );
    }
    if (lines.length < 2 || sum(true) != sum(false)) {
      setState(
        () => message = tr(
          'القيد يحتاج سطرين على الأقل، وإجمالي المدين لازم يساوي إجمالي الدائن.',
          'Use at least two rows; total debits must equal total credits.',
        ),
      );
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await widget.journalRepo.createEntry(
        entryDate: date,
        memo: memo.text.trim(),
        lines: batch,
        requestId: requestId,
      );
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(
          () => message = tr(
            'تعذّر حفظ المسودة. تحقق من الاتصال وصلاحية الحسابات ثم أعد المحاولة؛ بياناتك محفوظة هنا.',
            'Could not save. Check your connection and account eligibility, then retry; your input is kept here.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget amount(_DraftLine l, bool debit) => TextField(
    key: ValueKey('${identityHashCode(l)}-${debit ? 'debit' : 'credit'}'),
    controller: debit ? l.debit : l.credit,
    enabled: !busy,
    textDirection: TextDirection.ltr,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: (_) => setState(() {}),
    decoration: accountingInput('', hint: '0.00').copyWith(labelText: null),
  );
  Widget totals(String label, int cents) => accountingPanel(
    Column(
      children: [
        Text(label, style: const TextStyle(color: accountingPurple)),
        const SizedBox(height: 5),
        Text(
          payrollMoney(cents / 100),
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: accountingInk,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: LayoutBuilder(
      builder: (context, box) => Scrollbar(
        controller: scroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          child: accountingPanel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                accountingHeading(
                  tr('قيد يومي جديد', 'New journal entry'),
                  tr(
                    'سجّل العملية المحاسبية واحفظها كمسودة متوازنة',
                    'Record a transaction and save a balanced draft',
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 220,
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : pickDate,
                        icon: const Icon(
                          Icons.calendar_month_outlined,
                          color: accountingPurple,
                        ),
                        label: Text(
                          '${tr('تاريخ القيد', 'Entry date')}: ${payrollDate(date)}',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: (box.maxWidth - 320).clamp(220, 900),
                      child: TextField(
                        key: const ValueKey('journal-memo'),
                        controller: memo,
                        enabled: !busy,
                        maxLength: 500,
                        decoration: accountingInput(
                          tr('ملاحظات القيد', 'Entry memo'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  tr('تفاصيل القيد', 'Entry details'),
                  style: const TextStyle(
                    color: accountingInk,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (loading)
                  const AppLoadingState(compact: true)
                else if (error != null)
                  AppFailureState(error: error, onRetry: loadAccounts)
                else if (accounts.isEmpty)
                  Text(
                    tr(
                      'لا توجد حسابات نشطة. أضف الحسابات من دليل الحسابات أولًا.',
                      'No active accounts. Add accounts in the chart of accounts first.',
                    ),
                  )
                else
                  SizedBox(
                    height: (110 + lines.length * 85)
                        .clamp(280, 520)
                        .toDouble(),
                    child: AccountingTable(
                      minimumWidth: 950,
                      headings: [
                        tr('#', '#'),
                        tr('رقم الحساب *', 'Account code *'),
                        tr('اسم الحساب', 'Account name'),
                        tr('مدين (ريال)', 'Debit (SAR)'),
                        tr('دائن (ريال)', 'Credit (SAR)'),
                        tr('الإجراءات', 'Actions'),
                      ],
                      widths: const [6, 28, 28, 18, 18, 10],
                      rows: [
                        for (var i = 0; i < lines.length; i++)
                          [
                            Text('${i + 1}', textAlign: TextAlign.center),
                            DropdownButtonFormField<String>(
                              key: ValueKey(
                                'journal-account-${identityHashCode(lines[i])}',
                              ),
                              initialValue: lines[i].accountId,
                              isExpanded: true,
                              decoration: accountingInput(
                                tr('اختر الحساب', 'Choose account'),
                              ),
                              items: [
                                for (final a in accounts)
                                  DropdownMenuItem(
                                    value: a.id,
                                    child: Tooltip(
                                      message: '${a.code} · ${a.name}',
                                      child: Text(
                                        '${a.code} · ${a.name}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                              ],
                              onChanged: busy
                                  ? null
                                  : (id) =>
                                        setState(() => lines[i].accountId = id),
                            ),
                            Text(
                              lines[i].accountId == null
                                  ? '—'
                                  : accounts
                                        .firstWhere(
                                          (a) => a.id == lines[i].accountId,
                                        )
                                        .name,
                            ),
                            amount(lines[i], true),
                            amount(lines[i], false),
                            IconButton(
                              tooltip: tr('حذف السطر', 'Remove row'),
                              onPressed: busy
                                  ? null
                                  : () {
                                      final l = lines.removeAt(i);
                                      setState(() {});
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            l.dispose();
                                          });
                                    },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: OutlinedButton.icon(
                    key: const ValueKey('journal-add-line'),
                    onPressed: busy || loading || accounts.isEmpty
                        ? null
                        : () => setState(() => lines.add(_DraftLine())),
                    icon: const Icon(Icons.add),
                    label: Text(tr('إضافة سطر جديد', 'Add new row')),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final pair in [
                      (tr('إجمالي المدين', 'Total debits'), sum(true)),
                      (tr('إجمالي الدائن', 'Total credits'), sum(false)),
                      (tr('فرق المبلغ', 'Difference'), sum(true) - sum(false)),
                    ])
                      SizedBox(
                        width: ((box.maxWidth - 100) / 3).clamp(200, 440),
                        child: totals(pair.$1, pair.$2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1E8FC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tr(
                      'الحفظ كمسودة لا يعني ترحيل القيد أو تحويل الأموال. يجب أن يتساوى إجمالي المدين والدائن.',
                      'Saving a draft does not post the entry or transfer money. Total debits and credits must balance.',
                    ),
                  ),
                ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      message!,
                      key: const ValueKey('journal-error'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('journal-save'),
                      onPressed:
                          busy || loading || error != null || accounts.isEmpty
                          ? null
                          : save,
                      style: FilledButton.styleFrom(
                        backgroundColor: accountingPurple,
                        padding: const EdgeInsets.all(16),
                      ),
                      icon: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(tr('حفظ كمسودة', 'Save draft')),
                    ),
                    OutlinedButton(
                      onPressed: busy ? null : widget.onCancel,
                      child: Text(tr('إلغاء', 'Cancel')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
