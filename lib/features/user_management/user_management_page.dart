import 'package:erp_sys/core/ui/app_data_state.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_management_repo.dart';

const _ink = Color(0xFF21194E), _purple = Color(0xFF8654BC);
const _border = Color(0xFFE8E2F4), _muted = Color(0xFF777098);

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key, this.repo});
  final UserManagementRepo? repo;
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late final UserManagementRepo _repo;
  ManagedUsersData? _data;
  ManagedUser? _selected;
  String _role = '', _search = '';
  final _searchController = TextEditingController();
  bool _active = true, _loading = true, _saving = false;
  Object? _error;
  int _page = 0;
  final _horizontal = ScrollController();
  final _detailsScroll = ScrollController();
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  bool get _editable =>
      _data?.canEdit == true &&
      _selected != null &&
      _selected!.id != _data!.actorId;
  bool get _changed =>
      _selected != null &&
      (_selected!.role != _role || _selected!.active != _active);
  @override
  void initState() {
    super.initState();
    _repo = widget.repo ?? SupabaseUserManagementRepo(Supabase.instance.client);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontal.dispose();
    _detailsScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final next = await _repo.load();
      if (!mounted) return;
      setState(() {
        _data = next;
        _page = 0;
        _selected = null;
        _role = '';
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _select(ManagedUser user) async {
    if (_saving) return;
    if (_changed && !await _discard()) return;
    if (!mounted) return;
    setState(() {
      _selected = user;
      _role = user.role;
      _active = user.active;
    });
  }

  Future<bool> _discard() async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('تغييرات غير محفوظة', 'Unsaved changes')),
          content: Text(
            tr(
              'هل تريد ترك التغييرات الحالية واختيار حساب آخر؟',
              'Discard the current changes and choose another account?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('استمرار التعديل', 'Keep editing')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('ترك التغييرات', 'Discard changes')),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _save() async {
    if (_saving || !_editable || !_changed) return;
    setState(() => _saving = true);
    try {
      final user = await _repo.save(_selected!, _role, _active);
      if (!mounted) return;
      setState(() {
        _data = ManagedUsersData(
          actorId: _data!.actorId,
          canEdit: _data!.canEdit,
          users: _data!.users.map((u) => u.id == user.id ? user : u).toList(),
        );
        _selected = user;
        _role = user.role;
        _active = user.active;
      });
      _message(
        tr('تم حفظ الدور وحالة الحساب', 'Role and account status saved'),
      );
    } catch (e) {
      if (mounted) {
        _message(
          e is PostgrestException && e.code == '40001'
              ? tr(
                  'تم تعديل الحساب بواسطة مسؤول آخر. حدّث القائمة قبل الحفظ.',
                  'Another administrator changed this account. Refresh before saving.',
                )
              : tr(
                  'تعذر حفظ التغييرات. تحقق من صلاحيات حسابك ثم أعد المحاولة.',
                  'Could not save changes. Check your account permissions and retry.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  String _roleName(String role) => switch (role) {
    'admin' => tr('مدير النظام', 'System administrator'),
    'hr' => tr('موارد بشرية', 'Human resources'),
    'manager' || 'direct_manager' => tr('مدير مباشر', 'Direct manager'),
    'accountant' => tr('محاسب', 'Accountant'),
    'finance_manager' => tr('مدير مالي', 'Finance manager'),
    'employee' => tr('موظف', 'Employee'),
    _ => role,
  };
  List<String> _permissions(String role) => switch (role) {
    'admin' => [
      tr(
        'إدارة حسابات الشركة وأدوار المستخدمين',
        'Manage company accounts and user roles',
      ),
      tr(
        'إدارة الموارد البشرية ومراجعة الموافقات',
        'Manage HR and review approvals',
      ),
      tr('الاعتماد النهائي لمسيرات الرواتب', 'Final payroll approval'),
    ],
    'hr' => [
      tr(
        'إدارة الموظفين والأقسام والمسميات',
        'Manage employees, departments and job titles',
      ),
      tr(
        'متابعة الحضور والإجازات والمستندات',
        'Manage attendance, leave and documents',
      ),
      tr(
        'تجهيز مسيرات الرواتب والمخالصات والنماذج',
        'Prepare payroll, settlements and HR forms',
      ),
      tr('عرض حسابات المستخدمين والصلاحيات', 'View user accounts and roles'),
    ],
    'manager' || 'direct_manager' => [
      tr('متابعة أعضاء الفريق ومهامهم', 'Follow team members and tasks'),
      tr('مراجعة طلبات الفريق', 'Review team requests'),
      tr('متابعة حضور وانصراف الفريق', 'View team attendance'),
    ],
    'accountant' => [
      tr('الحسابات والقيود المحاسبية', 'Accounts and journal entries'),
      tr('مهام الرواتب المسندة للحساب', 'Assigned payroll tasks'),
    ],
    'finance_manager' => [
      tr('المراجعة المالية لمسيرات الرواتب', 'Financial payroll review'),
      tr('متابعة مهام صرف الرواتب', 'Follow payroll disbursement tasks'),
      tr('الحسابات والقيود المحاسبية', 'Accounts and journal entries'),
    ],
    'employee' => [
      tr(
        'الاطلاع على الملف والبيانات الشخصية',
        'View own profile and personal data',
      ),
      tr('المهام والطلبات الخاصة بالموظف', 'Own tasks and requests'),
      tr('الاطلاع على الحضور والإجازات', 'View own attendance and leave'),
    ],
    _ => [
      tr(
        'دور حالي غير متاح للتعيين من هذه الشاشة',
        'Existing role is not assignable from this page',
      ),
    ],
  };
  Widget _panel(Widget child) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _border),
    ),
    padding: const EdgeInsets.all(16),
    child: child,
  );
  Widget _title(String text, IconData icon) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xFFF1E8FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 22, color: _purple),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
  Widget _field(String label, Widget child) => Padding(
    padding: const EdgeInsets.only(top: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 6),
        child,
      ],
    ),
  );
  Widget _details() => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(tr('تفاصيل المستخدم', 'User details'), Icons.person),
        const SizedBox(height: 8),
        const Divider(color: _border),
        if (_selected == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Column(
              children: [
                const Icon(
                  Icons.person_search_outlined,
                  size: 42,
                  color: _purple,
                ),
                const SizedBox(height: 12),
                Text(
                  tr(
                    'اختر مستخدمًا من القائمة لعرض بياناته وصلاحياته',
                    'Choose a user to view their details and role',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted, height: 1.6),
                ),
              ],
            ),
          )
        else ...[
          _field(
            tr('الاسم الكامل', 'Full name'),
            Text(
              _selected!.name.isEmpty ? '—' : _selected!.name,
              style: const TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _field(
            tr('حساب الدخول / البريد الإلكتروني', 'Login account / email'),
            SelectableText(
              _selected!.email,
              textDirection: TextDirection.ltr,
              textAlign: ar ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: _ink,
                fontSize: 13,
                fontFamily:
                    Theme.of(context).textTheme.bodyMedium?.fontFamily ??
                    'Roboto',
              ),
            ),
          ),
          _field(
            tr('الدور', 'Role'),
            DropdownButtonFormField<String>(
              key: ValueKey('user-role-${_selected!.id}-$_role'),
              initialValue: _role,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: _border),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              style: TextStyle(
                color: _ink,
                fontSize: 13,
                fontFamily:
                    Theme.of(context).textTheme.bodyMedium?.fontFamily ??
                    'Roboto',
              ),
              items: [...managedRoles, if (!managedRoles.contains(_role)) _role]
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      enabled:
                          !['employee', 'manager'].contains(r) ||
                          _selected!.employeeId != null,
                      child: Text(_roleName(r)),
                    ),
                  )
                  .toList(),
              onChanged: !_editable || _saving
                  ? null
                  : (r) => setState(() => _role = r!),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('حالة الحساب', 'Account status'),
                  style: const TextStyle(color: _ink, fontSize: 13),
                ),
              ),
              Text(
                _active ? tr('نشط', 'Active') : tr('موقوف', 'Inactive'),
                style: TextStyle(
                  color: _active ? const Color(0xFF008B72) : Colors.red,
                  fontSize: 12,
                ),
              ),
              Switch(
                key: const ValueKey('user-active'),
                value: _active,
                onChanged: !_editable || _saving
                    ? null
                    : (v) => setState(() => _active = v),
                activeThumbColor: _purple,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            tr('ملخص صلاحيات الدور', 'Role access summary'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7F5),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                for (final text in _permissions(_role))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF00A77B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            text,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr(
              'الصلاحيات مرتبطة بالدور ونطاق الحساب في الشركة.',
              'Access depends on the role and account scope in the company.',
            ),
            style: const TextStyle(color: _muted, fontSize: 11, height: 1.5),
          ),
          if (!_editable)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _data!.canEdit
                    ? tr(
                        'حسابك الحالي محمي من تغيير دوره أو إيقافه هنا.',
                        'Your current account role and status are protected here.',
                      )
                    : tr(
                        'العرض فقط؛ تعديل الأدوار والحالة متاح لمدير النظام.',
                        'View only; a system administrator can edit roles and status.',
                      ),
                style: const TextStyle(
                  color: _purple,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  key: const ValueKey('user-save'),
                  onPressed: _editable && _changed && !_saving ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 17),
                  label: Text(
                    tr('حفظ التغييرات', 'Save changes'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _saving || !_changed
                    ? null
                    : () => setState(() {
                        _role = _selected!.role;
                        _active = _selected!.active;
                      }),
                child: Text(tr('إلغاء', 'Cancel')),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _users() {
    final matches = _data!.users
        .where(
          (u) => '${u.name} ${u.email} ${_roleName(u.role)}'
              .toLowerCase()
              .contains(_search.trim().toLowerCase()),
        )
        .toList();
    final pages = math.max(1, (matches.length / 8).ceil());
    final page = math.min(_page, pages - 1);
    final rows = matches.skip(page * 8).take(8).toList();
    Widget cell(Widget child, {bool start = true}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Align(
        alignment: start ? AlignmentDirectional.centerStart : Alignment.center,
        child: child,
      ),
    );
    Widget row(List<Widget> cells, {bool header = false, ManagedUser? user}) =>
        Material(
          color: header
              ? const Color(0xFFF5F4F9)
              : user?.id == _selected?.id
              ? const Color(0xFFF0E6FF)
              : Colors.white,
          child: InkWell(
            onTap: user == null || _saving ? null : () => _select(user),
            child: Container(
              height: header ? 48 : 58,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: Row(
                children: List.generate(
                  4,
                  (i) => Expanded(flex: [25, 32, 28, 15][i], child: cells[i]),
                ),
              ),
            ),
          ),
        );
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(tr('قائمة المستخدمين', 'User list'), Icons.groups),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            key: const ValueKey('user-search'),
            enabled: !_saving,
            onChanged: (v) => setState(() {
              _search = v;
              _page = 0;
            }),
            style: const TextStyle(fontSize: 13, color: _ink),
            decoration: InputDecoration(
              hintText: tr(
                'ابحث بالاسم أو البريد أو الدور...',
                'Search name, email or role...',
              ),
              prefixIcon: const Icon(Icons.search, size: 19, color: _muted),
              isDense: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (_, c) => ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: Scrollbar(
                  controller: _horizontal,
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  thickness: 9,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  notificationPredicate: (n) =>
                      n.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    key: const ValueKey('user-table-scroll'),
                    controller: _horizontal,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: math.max(680, c.maxWidth),
                      height: c.maxHeight,
                      child: Column(
                        children: [
                          row([
                            for (final text in [
                              tr('الاسم', 'Name'),
                              tr('حساب الدخول', 'Login account'),
                              tr('الدور', 'Role'),
                              tr('الحالة', 'Status'),
                            ])
                              cell(
                                Text(
                                  text,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ], header: true),
                          Expanded(
                            child: rows.isEmpty
                                ? AppEmptyState(
                                    filtered: _search.trim().isNotEmpty,
                                    onClear: _search.trim().isNotEmpty
                                        ? () {
                                            _searchController.clear();
                                            setState(() {
                                              _search = '';
                                              _page = 0;
                                            });
                                          }
                                        : null,
                                  )
                                : ListView(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    children: [
                                      for (final user in rows)
                                        row([
                                          cell(
                                            Text(
                                              user.name.isEmpty
                                                  ? '—'
                                                  : user.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: _ink,
                                                fontSize: 13,
                                                fontWeight:
                                                    user.id == _selected?.id
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          cell(
                                            Text(
                                              user.email,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textDirection: TextDirection.ltr,
                                              textAlign: ar
                                                  ? TextAlign.right
                                                  : TextAlign.left,
                                              style: const TextStyle(
                                                color: _ink,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          cell(
                                            Text(
                                              _roleName(user.role),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: _ink,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          cell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: user.active
                                                    ? const Color(0xFFDFF9ED)
                                                    : const Color(0xFFFFE4E7),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                user.active
                                                    ? tr('نشط', 'Active')
                                                    : tr('موقوف', 'Inactive'),
                                                style: TextStyle(
                                                  color: user.active
                                                      ? const Color(0xFF00966A)
                                                      : const Color(0xFFED3849),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ], user: user),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  tr(
                    'عرض ${rows.length} من ${matches.length} مستخدم',
                    'Showing ${rows.length} of ${matches.length} users',
                  ),
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ),
              IconButton(
                onPressed: page == 0 || _saving
                    ? null
                    : () => setState(() => _page = page - 1),
                icon: const Icon(Icons.chevron_left, size: 20),
                tooltip: tr('الصفحة السابقة', 'Previous page'),
              ),
              Text(
                '${page + 1} / $pages',
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: _purple, fontSize: 12),
              ),
              IconButton(
                onPressed: page + 1 == pages || _saving
                    ? null
                    : () => setState(() => _page = page + 1),
                icon: const Icon(Icons.chevron_right, size: 20),
                tooltip: tr('الصفحة التالية', 'Next page'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1000;
      final height = math.max(740.0, constraints.maxHeight);
      return SingleChildScrollView(
        child: SizedBox(
          height: wide ? height : height + 650,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(
                          'إدارة المستخدمين والصلاحيات',
                          'Users and access management',
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving || _loading
                          ? null
                          : () async {
                              if (_changed && !await _discard()) return;
                              await _load();
                            },
                      tooltip: tr('تحديث', 'Refresh'),
                      icon: const Icon(Icons.refresh, color: _purple),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF4EAFE), Color(0xFFEEE3FF)],
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: _purple,
                        size: 35,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(
                                'إدارة حسابات الشركة',
                                'Company account management',
                              ),
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              tr(
                                'تحديد أدوار المستخدمين وحالة حساباتهم. تعديل الصلاحيات متاح لمدير النظام، والموارد البشرية تعرض البيانات فقط.',
                                'Manage user roles and account status. System administrators can edit access; HR can view account details.',
                              ),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const AppLoadingState()
                      : _error != null
                      ? AppFailureState(error: _error, onRetry: _load)
                      : wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 370,
                              child: Scrollbar(
                                controller: _detailsScroll,
                                thumbVisibility: true,
                                interactive: true,
                                child: SingleChildScrollView(
                                  key: const ValueKey('user-details-scroll'),
                                  controller: _detailsScroll,
                                  child: _details(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _users()),
                          ],
                        )
                      : Column(
                          children: [
                            _details(),
                            const SizedBox(height: 16),
                            Expanded(child: _users()),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
