import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/ui/app_data_state.dart';
import '../../../../../core/utils/request_id.dart';
import '../../domain/models/account.dart';
import '../../domain/repos/accounts_repo.dart';
import '../../../view/accounting_ui.dart';

class AccountsWorkspace extends StatefulWidget {
  const AccountsWorkspace({super.key, required this.repo, this.onOpenLedger});
  final AccountsRepo repo;

  /// Receives an account id; defaults to opening the General Ledger route.
  final ValueChanged<String>? onOpenLedger;
  @override
  State<AccountsWorkspace> createState() => _AccountsWorkspaceState();
}

class _AccountsWorkspaceState extends State<AccountsWorkspace> {
  Timer? debounce;
  final code = TextEditingController(),
      name = TextEditingController(),
      search = TextEditingController();
  final pageScroll = ScrollController();
  final form = GlobalKey<FormState>();
  List<Account> items = [];
  String? typeFilter, editingId, message;
  bool? activeFilter;
  String type = 'expense';
  bool active = true,
      isCash = false,
      loading = true,
      busy = false,
      ascending = true;
  Object? error;
  int page = 0, total = 0, generation = 0;
  late String requestId;
  String tr(String a, String e) => accountingText(context, a, e);
  @override
  void initState() {
    super.initState();
    requestId = newRequestId();
    load();
  }

  @override
  void dispose() {
    debounce?.cancel();
    generation++;
    code.dispose();
    name.dispose();
    search.dispose();
    pageScroll.dispose();
    super.dispose();
  }

  Future<void> load({bool reset = false}) async {
    if (reset) page = 0;
    final version = ++generation;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await widget.repo.fetchAccounts(
        page: page,
        pageSize: 10,
        search: search.text.trim(),
        type: typeFilter,
        isActive: activeFilter,
        sortBy: 'code',
        ascending: ascending,
      );
      if (mounted && version == generation) {
        setState(() {
          items = result.items;
          total = result.total;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted && version == generation) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  void resetForm() {
    setState(() {
      editingId = null;
      requestId = newRequestId();
      code.clear();
      name.clear();
      type = 'expense';
      active = true;
      isCash = false;
      message = null;
    });
    form.currentState?.reset();
  }

  void edit(Account a) {
    if (busy) return;
    setState(() {
      editingId = a.id;
      code.text = a.code;
      name.text = a.name;
      type = a.type;
      active = a.isActive;
      isCash = a.isCash;
      message = null;
    });
    pageScroll.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void openLedger(String id) => widget.onOpenLedger != null
      ? widget.onOpenLedger!(id)
      : context.go('${AppRoutes.ledger}?account=$id');

  Future<void> save() async {
    if (busy || !(form.currentState?.validate() ?? false)) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await widget.repo.updateAccount(
        id: editingId ?? requestId,
        code: code.text.trim(),
        name: name.text.trim(),
        type: type,
        isActive: active,
        isCash: type == 'asset' && isCash,
      );
      if (!mounted) return;
      resetForm();
      setState(() => message = tr('تم حفظ الحساب.', 'Account saved.'));
      await load(reset: true);
    } catch (e) {
      if (mounted) {
        setState(
          () => message = e.toString().contains('23505')
              ? tr(
                  'الرمز مستخدم لحساب آخر. اختر رمزًا مختلفًا.',
                  'This code belongs to another account.',
                )
              : tr(
                  'تعذّر حفظ الحساب. تحقق من الاتصال ثم أعد المحاولة؛ بياناتك محفوظة هنا.',
                  'Could not save. Check your connection and retry; your input is kept here.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String typeLabel(String key) => switch (key) {
    'asset' => tr('أصل', 'Asset'),
    'liability' => tr('التزام', 'Liability'),
    'equity' => tr('حقوق ملكية', 'Equity'),
    'income' => tr('إيراد', 'Income'),
    _ => tr('مصروف', 'Expense'),
  };
  Widget accountForm() => accountingPanel(
    Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  editingId == null
                      ? tr('إضافة حساب جديد', 'Add new account')
                      : tr('تعديل الحساب', 'Edit account'),
                  style: const TextStyle(
                    color: accountingInk,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              CircleAvatar(
                backgroundColor: const Color(0xFFF0E5FF),
                child: IconButton(
                  tooltip: tr('إضافة حساب جديد', 'Add new account'),
                  onPressed: busy ? null : resetForm,
                  icon: const Icon(Icons.add, color: accountingPurple),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const ValueKey('account-code'),
            controller: code,
            enabled: !busy,
            textDirection: TextDirection.ltr,
            decoration: accountingInput(
              tr('الرمز *', 'Code *'),
              hint: tr('مثال: 5100', 'Example: 5100'),
            ),
            validator: (v) => (v ?? '').trim().isEmpty
                ? tr('أدخل رمز الحساب', 'Enter account code')
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('account-name'),
            controller: name,
            enabled: !busy,
            decoration: accountingInput(tr('اسم الحساب *', 'Account name *')),
            validator: (v) => (v ?? '').trim().isEmpty
                ? tr('أدخل اسم الحساب', 'Enter account name')
                : null,
          ),
          const SizedBox(height: 16),
          KeyedSubtree(
            key: const ValueKey('account-type'),
            child: DropdownButtonFormField<String>(
              key: ValueKey('type-${editingId ?? requestId}-$type'),
              initialValue: type,
              isExpanded: true,
              decoration: accountingInput(tr('نوع الحساب *', 'Account type *')),
              items: [
                for (final key in [
                  'asset',
                  'liability',
                  'equity',
                  'income',
                  'expense',
                ])
                  DropdownMenuItem(value: key, child: Text(typeLabel(key))),
              ],
              onChanged: busy
                  ? null
                  : (v) => setState(() {
                      type = v!;
                      if (type != 'asset') isCash = false;
                    }),
            ),
          ),
          if (type == 'asset')
            CheckboxListTile(
              key: const ValueKey('account-is-cash'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(tr('حساب نقدية / بنك', 'Cash / Bank account')),
              subtitle: Text(
                tr('يُحتسب ضمن رصيد النقدية', 'Counted in the cash balance'),
              ),
              value: isCash,
              onChanged: busy ? null : (v) => setState(() => isCash = v!),
              activeColor: accountingPurple,
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('حالة الحساب', 'Account status')),
            subtitle: Text(
              active
                  ? tr(
                      'نشط: متاح للقيود الجديدة',
                      'Active: available for new entries',
                    )
                  : tr(
                      'غير نشط: يبقى في السجلات السابقة',
                      'Inactive: retained in existing records',
                    ),
            ),
            value: active,
            onChanged: busy ? null : (v) => setState(() => active = v),
            activeThumbColor: accountingPurple,
          ),
          const SizedBox(height: 16),
          Text(
            tr(
              'الحساب هنا بند محاسبي، مثل البنك أو مصروفات الرواتب؛ ليس حساب دخول لموظف.',
              'An account is a bookkeeping category, such as Bank or Salary expenses; it is not an employee login.',
            ),
            style: const TextStyle(color: Color(0xFF77709A), fontSize: 13),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(message!, key: const ValueKey('account-message')),
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const ValueKey('account-save'),
                onPressed: busy ? null : save,
                style: FilledButton.styleFrom(
                  backgroundColor: accountingPurple,
                ),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(tr('حفظ الحساب', 'Save account')),
              ),
              OutlinedButton(
                onPressed: busy ? null : resetForm,
                child: Text(tr('إلغاء', 'Cancel')),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  Widget listing(double height) => accountingPanel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 240,
              child: TextField(
                controller: search,
                onChanged: (_) {
                  debounce?.cancel();
                  debounce = Timer(
                    const Duration(milliseconds: 350),
                    () => load(reset: true),
                  );
                },
                onSubmitted: (_) => load(reset: true),
                decoration:
                    accountingInput(
                      tr('البحث بالاسم أو الرمز', 'Search name or code'),
                    ).copyWith(
                      suffixIcon: IconButton(
                        tooltip: tr('بحث', 'Search'),
                        onPressed: () => load(reset: true),
                        icon: const Icon(Icons.search),
                      ),
                    ),
              ),
            ),
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                key: ValueKey('filter-type-$typeFilter'),
                initialValue: typeFilter,
                isExpanded: true,
                decoration: accountingInput(tr('نوع الحساب', 'Account type')),
                items: [
                  DropdownMenuItem(value: null, child: Text(tr('الكل', 'All'))),
                  for (final key in [
                    'asset',
                    'liability',
                    'equity',
                    'income',
                    'expense',
                  ])
                    DropdownMenuItem(value: key, child: Text(typeLabel(key))),
                ],
                onChanged: (v) {
                  typeFilter = v;
                  load(reset: true);
                },
              ),
            ),
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<bool>(
                key: ValueKey('filter-active-$activeFilter'),
                isExpanded: true,
                initialValue: activeFilter,
                decoration: accountingInput(tr('الحالة', 'Status')),
                items: [
                  DropdownMenuItem(value: null, child: Text(tr('الكل', 'All'))),
                  DropdownMenuItem(
                    value: true,
                    child: Text(tr('نشط', 'Active')),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text(tr('غير نشط', 'Inactive')),
                  ),
                ],
                onChanged: (v) {
                  activeFilter = v;
                  load(reset: true);
                },
              ),
            ),
            IconButton(
              tooltip: tr('عكس ترتيب الرموز', 'Reverse code order'),
              onPressed: () {
                ascending = !ascending;
                load(reset: true);
              },
              icon: const Icon(Icons.sort_by_alpha, color: accountingPurple),
            ),
            TextButton.icon(
              onPressed: loading
                  ? null
                  : () {
                      search.clear();
                      typeFilter = null;
                      activeFilter = null;
                      load(reset: true);
                    },
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: Text(tr('مسح الفلاتر', 'Clear filters')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: height,
          child: AppDataRegion(
            loading: loading,
            error: error,
            empty: items.isEmpty,
            filtered:
                search.text.isNotEmpty ||
                typeFilter != null ||
                activeFilter != null,
            onRetry: load,
            child: AccountingTable(
              minimumWidth: 650,
              headings: [
                tr('الرمز', 'Code'),
                tr('اسم الحساب', 'Account name'),
                tr('نوع الحساب', 'Type'),
                tr('الحالة', 'Status'),
                tr('الإجراءات', 'Actions'),
              ],
              widths: const [14, 32, 20, 16, 14],
              rows: [
                for (final a in items)
                  [
                    Text(a.code, textAlign: TextAlign.center),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SelectableText(a.name),
                        if (a.isCash) accountingBadge(tr('نقدية', 'Cash')),
                      ],
                    ),
                    Text(typeLabel(a.type), textAlign: TextAlign.center),
                    Center(
                      child: accountingBadge(
                        a.isActive
                            ? tr('نشط', 'Active')
                            : tr('غير نشط', 'Inactive'),
                        active: a.isActive,
                      ),
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        IconButton(
                          key: ValueKey('edit-account-${a.id}'),
                          tooltip: tr('تعديل الحساب', 'Edit account'),
                          onPressed: busy ? null : () => edit(a),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: accountingPurple,
                          ),
                        ),
                        IconButton(
                          key: ValueKey('ledger-account-${a.id}'),
                          tooltip: tr('عرض دفتر الأستاذ', 'View ledger'),
                          onPressed: () => openLedger(a.id),
                          icon: const Icon(
                            Icons.receipt_long_outlined,
                            color: accountingPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Text(
              tr(
                'عرض ${items.length} من $total حساب',
                'Showing ${items.length} of $total accounts',
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: !loading && page > 0
                      ? () {
                          page--;
                          load();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${page + 1} / ${(total / 10).ceil().clamp(1, 999999)}',
                  textDirection: TextDirection.ltr,
                ),
                IconButton(
                  onPressed: !loading && (page + 1) * 10 < total
                      ? () {
                          page++;
                          load();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Scrollbar(
      controller: pageScroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: pageScroll,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            accountingHeading(
              tr('دليل الحسابات', 'Chart of accounts'),
              tr(
                'إدارة البنود المحاسبية المستخدمة في القيود اليومية',
                'Manage the accounts used in journal entries',
              ),
            ),
            const SizedBox(height: 18),
            if (box.maxWidth >= 1000)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 350, child: accountForm()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: listing((box.maxHeight - 240).clamp(320, 650)),
                  ),
                ],
              )
            else ...[
              accountForm(),
              const SizedBox(height: 16),
              listing(420),
            ],
          ],
        ),
      ),
    ),
  );
}
