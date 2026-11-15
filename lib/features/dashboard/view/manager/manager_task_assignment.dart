part of '../dashboard_page.dart';

class ManagerTasksPage extends StatelessWidget {
  const ManagerTasksPage({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<SessionCubit, SessionState>(
    builder: (context, state) {
      if (state is! SessionReady) {
        return const AppLoadingState();
      }
      final user = state.user;
      if (!['manager', 'direct_manager'].contains(user.role) ||
          user.employeeId == null) {
        return Center(
          child: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'يلزم حساب مدير مباشر مرتبط بموظف'
                : 'A linked manager account is required',
          ),
        );
      }
      return _ManagerDashboard(
        managerEmployeeId: user.employeeId!,
        assignmentOnly: true,
      );
    },
  );
}

class ManagerTaskAssignmentView extends StatefulWidget {
  const ManagerTaskAssignmentView({
    super.key,
    required this.members,
    required this.activeTasks,
    required this.completion,
    required this.upcoming,
    required this.taskTypes,
    required this.title,
    required this.description,
    required this.hours,
    required this.employeeId,
    required this.taskType,
    required this.priority,
    required this.dueDate,
    required this.saving,
    required this.onEmployee,
    required this.onType,
    required this.onPriority,
    required this.onDate,
    required this.onSubmit,
    required this.onCancel,
    required this.onWeight,
    this.attachmentName,
    this.attachmentBytes,
    this.pickingAttachment = false,
    this.attachmentRetry = false,
    this.onPickAttachment,
    this.onRemoveAttachment,
    this.averageProgress = const {},
    this.onRefresh,
  });
  final List<TeamMember> members;
  final Map<String, int> activeTasks;
  final Map<String, double> completion;
  final List<Map<String, dynamic>> upcoming;
  final Map<String, String> taskTypes;
  final TextEditingController title, description, hours;
  final String? employeeId;
  final String taskType, priority;
  final DateTime? dueDate;
  final bool saving;
  final ValueChanged<String?> onEmployee, onType, onPriority;
  final VoidCallback onDate, onCancel;
  final Future<void> Function() onSubmit;
  final Future<int> Function(String?, String) onWeight;
  final String? attachmentName;
  final int? attachmentBytes;
  final bool pickingAttachment, attachmentRetry;
  final VoidCallback? onPickAttachment, onRemoveAttachment;
  final Map<String, double> averageProgress;
  final VoidCallback? onRefresh;
  @override
  State<ManagerTaskAssignmentView> createState() =>
      _ManagerTaskAssignmentViewState();
}

class _ManagerTaskAssignmentViewState extends State<ManagerTaskAssignmentView> {
  final _form = GlobalKey<FormState>();
  late Future<int> _weight;
  bool _dateMissing = false;
  bool get locked =>
      widget.saving || widget.pickingAttachment || widget.attachmentRetry;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  @override
  void initState() {
    super.initState();
    _weight = widget.onWeight(widget.employeeId, widget.taskType);
  }

  @override
  void didUpdateWidget(covariant ManagerTaskAssignmentView old) {
    super.didUpdateWidget(old);
    if (old.employeeId != widget.employeeId ||
        old.taskType != widget.taskType) {
      _weight = widget.onWeight(widget.employeeId, widget.taskType);
    }
    if (widget.dueDate != null) _dateMissing = false;
    if (old.employeeId != null && widget.employeeId == null) {
      _form.currentState?.reset();
      _dateMissing = false;
    }
  }

  String number(String raw) {
    const arabic = '٠١٢٣٤٥٦٧٨٩', persian = '۰۱۲۳۴۵۶۷۸۹';
    return raw
        .trim()
        .split('')
        .map(
          (c) => arabic.contains(c)
              ? '${arabic.indexOf(c)}'
              : persian.contains(c)
              ? '${persian.indexOf(c)}'
              : c == '٫'
              ? '.'
              : c,
        )
        .join();
  }

  Future<void> _submit() async {
    if (widget.saving || widget.pickingAttachment) return;
    if (widget.attachmentRetry) {
      await widget.onSubmit();
      return;
    }
    final valid = _form.currentState!.validate();
    setState(() => _dateMissing = widget.dueDate == null);
    if (!valid || _dateMissing) return;
    widget.hours.text = number(widget.hours.text);
    await widget.onSubmit();
  }

  String date(DateTime? value) => value == null
      ? tr('اختر التاريخ', 'Choose date')
      : '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
  Widget field(String label, Widget child, {bool required = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text.rich(
        TextSpan(
          text: label,
          children: required
              ? [
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ]
              : [],
        ),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 7),
      child,
    ],
  );
  InputDecoration decoration({String? hint}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surface
        : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: EmployeeTheme.primary.withValues(alpha: .2),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: EmployeeTheme.primary.withValues(alpha: .2),
      ),
    ),
  );
  Widget line(List<Widget> children) => LayoutBuilder(
    builder: (_, box) => box.maxWidth < 500
        ? Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const SizedBox(height: 14),
              ],
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i < children.length - 1) const SizedBox(width: 14),
              ],
            ],
          ),
  );
  Widget panel(Widget child) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: EmployeeTheme.primary.withValues(alpha: .13)),
    ),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
  @override
  Widget build(BuildContext context) {
    final selected = widget.members
        .where((m) => m.id == widget.employeeId)
        .firstOrNull;
    final form = panel(
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: EmployeeTheme.primary.withValues(alpha: .12),
                  child: const Icon(
                    Icons.description_rounded,
                    color: EmployeeTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('إسناد مهمة', 'Assign task'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        tr(
                          'إسناد مهمة جديدة إلى أحد أعضاء الفريق',
                          'Assign a new task to a team member',
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onRefresh != null)
                  IconButton(
                    tooltip: tr('تحديث بيانات الموظف', 'Refresh employee data'),
                    onPressed: locked ? null : widget.onRefresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: EmployeeTheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.attachmentRetry)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  tr(
                    'المهمة اتسندت بالفعل. أعد رفع المرفق على نفس المهمة، أو أغلق النموذج لإكمال العمل بدون المرفق.',
                    'Task already assigned. Retry the attachment on the same task, or close to continue without it.',
                  ),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (widget.members.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  tr(
                    'لا يوجد موظفون نشطون مرتبطون بفريقك',
                    'No active employees are linked to your team',
                  ),
                ),
              ),
            line([
              field(
                tr('عنوان المهمة', 'Task title'),
                TextFormField(
                  controller: widget.title,
                  enabled: !locked,
                  decoration: decoration(),
                  maxLength: 150,
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? tr('اكتب عنوان المهمة', 'Enter a task title')
                      : null,
                ),
                required: true,
              ),
              field(
                tr('الموظف', 'Employee'),
                DropdownButtonFormField<String>(
                  key: ValueKey('employee-${widget.employeeId}'),
                  initialValue: widget.employeeId,
                  isExpanded: true,
                  decoration: decoration(
                    hint: tr('اختر الموظف', 'Choose employee'),
                  ),
                  items: widget.members
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: EmployeeTheme.primary
                                    .withValues(alpha: .13),
                                child: Text(
                                  m.name.characters.first,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: EmployeeTheme.dark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  m.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: locked ? null : widget.onEmployee,
                  validator: (v) =>
                      v == null || !widget.members.any((m) => m.id == v)
                      ? tr('اختر موظفًا من فريقك', 'Choose a team member')
                      : null,
                ),
                required: true,
              ),
            ]),
            const SizedBox(height: 14),
            field(
              tr('وصف المهمة (اختياري)', 'Task description (optional)'),
              TextFormField(
                controller: widget.description,
                enabled: !locked,
                maxLines: 2,
                maxLength: 500,
                decoration: decoration(),
              ),
            ),
            const SizedBox(height: 14),
            line([
              field(
                tr('نوع المهمة', 'Task type'),
                DropdownButtonFormField<String>(
                  key: ValueKey('type-${widget.taskType}'),
                  initialValue: widget.taskType,
                  isExpanded: true,
                  decoration: decoration(),
                  items: widget.taskTypes.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: locked ? null : widget.onType,
                ),
                required: true,
              ),
              field(
                tr('الأولوية', 'Priority'),
                DropdownButtonFormField<String>(
                  key: ValueKey('priority-${widget.priority}'),
                  initialValue: widget.priority,
                  decoration: decoration(),
                  items: ['high', 'medium', 'low']
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p == 'high'
                                      ? Colors.red
                                      : p == 'medium'
                                      ? Colors.orange
                                      : Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                p == 'high'
                                    ? tr('عالية', 'High')
                                    : p == 'medium'
                                    ? tr('متوسطة', 'Medium')
                                    : tr('منخفضة', 'Low'),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: locked ? null : widget.onPriority,
                ),
                required: true,
              ),
              field(
                tr('تاريخ الاستحقاق', 'Due date'),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: locked ? null : widget.onDate,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: decoration(),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                date(widget.dueDate),
                                textAlign: TextAlign.center,
                                textDirection: widget.dueDate == null
                                    ? null
                                    : TextDirection.ltr,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_dateMissing)
                      Text(
                        tr('اختر تاريخ الاستحقاق', 'Choose a due date'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
                required: true,
              ),
            ]),
            const SizedBox(height: 18),
            line([
              field(
                tr('الوقت المقدّر', 'Estimated time'),
                TextFormField(
                  controller: widget.hours,
                  enabled: !locked,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.end,
                  decoration: decoration().copyWith(
                    suffixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          tr('ساعات', 'hours'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  validator: (v) {
                    final n = double.tryParse(number(v ?? ''));
                    return n == null || !n.isFinite || n <= 0
                        ? tr(
                            'أدخل عدد ساعات صحيحًا أكبر من صفر',
                            'Enter valid hours greater than zero',
                          )
                        : null;
                  },
                ),
                required: true,
              ),
              field(
                tr('الوزن النسبي', 'Relative weight'),
                FutureBuilder<int>(
                  future: _weight,
                  builder: (context, value) => InputDecorator(
                    decoration: decoration().copyWith(
                      suffixText: tr('من ٥', 'of 5'),
                    ),
                    child: Text(
                      value.hasError
                          ? '—'
                          : value.hasData
                          ? '${value.data}'
                          : '…',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                required: false,
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              tr(
                'الوزن يُحدد تلقائيًا حسب نوع المهمة وإعدادات القسم.',
                'Weight is set automatically from task type and department settings.',
              ),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr('مرفق (اختياري)', 'Attachment (optional)'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 7),
            InkWell(
              onTap: locked ? null : widget.onPickAttachment,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: EmployeeTheme.primary.withValues(alpha: .22),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.file_upload_outlined,
                      color: EmployeeTheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pickingAttachment
                                ? tr('جارٍ قراءة الملف…', 'Reading file…')
                                : widget.attachmentName ??
                                      tr('إضافة مرفق', 'Add attachment'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.attachmentName == null
                                ? tr(
                                    'PDF، صور، Word، Excel، ZIP أو TXT — حتى 10 ميجابايت',
                                    'PDF, images, Word, Excel, ZIP or TXT — up to 10 MB',
                                  )
                                : '${((widget.attachmentBytes ?? 0) / (1024 * 1024)).toStringAsFixed(2)} MB',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.attachmentName != null)
                      IconButton(
                        tooltip: tr('إزالة المرفق', 'Remove attachment'),
                        onPressed: locked ? null : widget.onRemoveAttachment,
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            line([
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed:
                    widget.saving ||
                        widget.pickingAttachment ||
                        widget.members.isEmpty
                    ? null
                    : _submit,
                icon: widget.saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  widget.saving
                      ? tr('جارٍ الإسناد…', 'Assigning…')
                      : widget.attachmentRetry
                      ? tr('إعادة رفع المرفق', 'Retry attachment')
                      : tr('إسناد المهمة', 'Assign task'),
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: widget.saving || widget.pickingAttachment
                    ? null
                    : widget.onCancel,
                child: Text(
                  widget.attachmentRetry
                      ? tr('إغلاق', 'Close')
                      : tr('إلغاء', 'Cancel'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
    final summary = panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('ملخص عبء العمل للموظف', 'Employee workload summary'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: EmployeeTheme.primary.withValues(alpha: .12),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: selected == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      tr(
                        'اختر موظفًا لعرض المهام الموكلة إليه',
                        'Choose an employee to view assigned tasks',
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: EmployeeTheme.primary.withValues(
                              alpha: .20,
                            ),
                            child: Text(
                              selected.name
                                  .split(' ')
                                  .where((p) => p.isNotEmpty)
                                  .take(2)
                                  .map((p) => p.characters.first)
                                  .join(),
                              style: const TextStyle(
                                color: EmployeeTheme.dark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  selected.jobTitle.trim().isEmpty
                                      ? tr(
                                          'الوظيفة غير محددة',
                                          'Job title not specified',
                                        )
                                      : selected.jobTitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _summaryRow(
                        tr('المهام النشطة', 'Active tasks'),
                        Text(
                          '${widget.activeTasks[selected.id] ?? 0}',
                          textAlign: TextAlign.start,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _summaryRow(
                        tr('نسبة الإنجاز', 'Completion'),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: [
                              Text(
                                '${((widget.completion[selected.id] ?? 0) * 100).round()}%',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      minHeight: 7,
                                      value:
                                          widget.completion[selected.id] ?? 0,
                                      color: const Color(0xFF00A17C),
                                      backgroundColor: EmployeeTheme.primary
                                          .withValues(alpha: .1),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _summaryRow(
                        tr('متوسط تقدم المهام', 'Average task progress'),
                        Text(
                          '${((widget.averageProgress[selected.id] ?? 0) * 100).round()}%',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('أهم المهام القادمة', 'Upcoming tasks'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: EmployeeTheme.primary.withValues(alpha: .035),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!widget.upcoming.any(
                              (r) => r['employee_id'] == selected.id,
                            ))
                              Text(
                                tr(
                                  'لا توجد مهام مستحقة خلال ٧ أيام',
                                  'No tasks due in the next 7 days',
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                            for (final row
                                in widget.upcoming
                                    .where(
                                      (r) => r['employee_id'] == selected.id,
                                    )
                                    .take(4))
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: row['priority'] == 'high'
                                              ? Colors.red
                                              : row['priority'] == 'low'
                                              ? Colors.blue
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (row['title'] ?? '—').toString(),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${tr('التقدم', 'Progress')}: ${TeamTask.taskProgressValue(row).round()}%',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: EmployeeTheme.dark,
                                            ),
                                          ),
                                          Text(
                                            date(
                                              DateTime.tryParse(
                                                (row['due_date'] ?? '')
                                                    .toString(),
                                              ),
                                            ),
                                            textDirection: TextDirection.ltr,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.copyWith(
          titleMedium: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontSize: 14),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LayoutBuilder(
            builder: (_, box) => box.maxWidth < 950
                ? Column(children: [form, const SizedBox(height: 16), summary])
                : Table(
                    columnWidths: {
                      0: FixedColumnWidth(
                        (box.maxWidth * .26).clamp(270.0, 320.0),
                      ),
                      1: const FixedColumnWidth(16),
                      2: const FlexColumnWidth(),
                    },
                    children: [
                      TableRow(
                        children: [
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.fill,
                            child: summary,
                          ),
                          const SizedBox(width: 16),
                          form,
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, Widget value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: EmployeeTheme.primary.withValues(alpha: .035),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 94, child: value),
      ],
    ),
  );
}
