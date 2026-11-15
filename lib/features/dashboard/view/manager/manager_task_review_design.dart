part of '../dashboard_page.dart';

class _ManagerReviewDesign extends StatelessWidget {
  const _ManagerReviewDesign({
    required this.task,
    required this.tasks,
    required this.members,
    required this.note,
    required this.busy,
    required this.error,
    required this.select,
    required this.refresh,
    required this.open,
    required this.decide,
  });
  final Map<String, dynamic> task;
  final List<Map<String, dynamic>> tasks;
  final List<TeamMember> members;
  final TextEditingController note;
  final bool busy;
  final String? error;
  final ValueChanged<String> select, open;
  final VoidCallback refresh;
  final ValueChanged<bool> decide;
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final member = members
        .where((m) => m.id == '${task['employee_id']}')
        .firstOrNull;
    final qa =
        task['status'] == 'done' &&
        (task['qa_status'] ?? 'pending') == 'pending';
    final progress = TeamTask.taskProgressValue(task);
    final files = ((task['attachments'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final rawHours = double.tryParse('${task['logged_hours'] ?? 0}') ?? 0;
    final minutes = (rawHours.isFinite ? rawHours.clamp(0, 999999) * 60 : 0)
        .round();
    String number(dynamic v) =>
        v is num ? v.toStringAsFixed(v % 1 == 0 ? 0 : 1) : '${v ?? '—'}';
    String date(dynamic raw, {bool time = false}) {
      final d = DateTime.tryParse('$raw')?.toLocal();
      if (d == null) return '—';
      final result =
          '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
      return time
          ? '$result · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'
          : result;
    }

    Widget panel(String title, Widget child, {double minHeight = 0}) =>
        Container(
          constraints: BoxConstraints(minHeight: wide ? minHeight : 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.brightness == Brightness.light
                ? Colors.white
                : scheme.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: EmployeeTheme.primary.withValues(alpha: .13),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        );
    Widget metric(String label, Widget value) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        value,
      ],
    );
    Widget value(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
    final avatar = CircleAvatar(
      radius: 21,
      backgroundColor: EmployeeTheme.primary.withValues(alpha: .20),
      child: Text(
        (member?.name ?? '—')
            .split(' ')
            .where((v) => v.isNotEmpty)
            .take(2)
            .map((v) => v.characters.first)
            .join(),
        style: const TextStyle(
          fontSize: 13,
          color: EmployeeTheme.dark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final employee = Row(
      children: [
        avatar,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member?.name ?? '${task['employee_name'] ?? '—'}',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                member?.jobTitle.isNotEmpty == true
                    ? member!.jobTitle
                    : tr('الوظيفة غير محددة', 'Job title not specified'),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final priority = task['priority'] == 'high'
        ? Colors.red
        : task['priority'] == 'low'
        ? Colors.blue
        : Colors.orange;
    final metrics = [
      metric(
        tr('الأولوية', 'Priority'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: priority.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: priority,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                task['priority'] == 'high'
                    ? tr('عالية', 'High')
                    : task['priority'] == 'low'
                    ? tr('منخفضة', 'Low')
                    : tr('متوسطة', 'Medium'),
                style: TextStyle(fontSize: 12, color: priority),
              ),
            ],
          ),
        ),
      ),
      metric(
        tr('تاريخ الاستحقاق', 'Due date'),
        Directionality(
          textDirection: TextDirection.ltr,
          child: value(date(task['due_date'])),
        ),
      ),
      metric(
        tr('الوقت المقدّر', 'Estimated time'),
        value('${number(task['estimate_hours'])} ${tr('ساعات', 'hours')}'),
      ),
      metric(
        tr('الوزن النسبي', 'Relative weight'),
        value('${number(task['weight'])} ${tr('من 5', 'of 5')}'),
      ),
    ];
    final metadata = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: EmployeeTheme.primary.withValues(alpha: .13)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: LayoutBuilder(
        builder: (_, box) => box.maxWidth >= 760
            ? Row(
                children: [
                  for (final item in metrics) ...[
                    Expanded(child: item),
                    Container(
                      height: 42,
                      width: 1,
                      color: EmployeeTheme.primary.withValues(alpha: .12),
                    ),
                  ],
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: employee),
                ],
              )
            : Column(
                children: [
                  employee,
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final item in metrics)
                        SizedBox(width: (box.maxWidth - 12) / 2, child: item),
                    ],
                  ),
                ],
              ),
      ),
    );
    final attachmentPanel = panel(
      '${tr('مرفقات المهمة', 'Task attachments')} (${files.length})',
      Column(
        children: [
          if (files.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(tr('لا توجد مرفقات', 'No attachments')),
            ),
          for (final file in files)
            _ReviewAttachmentRow(
              key: ValueKey(file['file_url']),
              file: file,
              onOpen: open,
            ),
        ],
      ),
      minHeight: 164,
    );
    final execution = panel(
      tr('تقدم التنفيذ', 'Execution progress'),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Text(
                  '${progress.round()}%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF00A17C),
                    backgroundColor: const Color(0xFFE8F3EF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            qa ? tr('مكتمل', 'Completed') : tr('قيد التنفيذ', 'In progress'),
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            qa
                ? tr(
                    'تم إنجاز المهمة وتسليمها من قبل الموظف.',
                    'The employee completed and submitted this task.',
                  )
                : tr(
                    'طلب مراجعة أثناء التنفيذ؛ الاعتماد لا يُكمل المهمة.',
                    'Review requested during execution; approval does not complete the task.',
                  ),
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      minHeight: 164,
    );
    final timing = panel(
      tr('الوقت', 'Time'),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: EmployeeTheme.primary.withValues(alpha: .035),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: metric(
                tr('الوقت المقدّر', 'Estimated time'),
                value(
                  '${number(task['estimate_hours'])} ${tr('ساعات', 'hours')}',
                ),
              ),
            ),
            Container(
              width: 1,
              height: 42,
              color: EmployeeTheme.primary.withValues(alpha: .12),
            ),
            Expanded(
              child: metric(
                tr('الوقت الفعلي المسجل', 'Actual logged time'),
                value(
                  '${minutes ~/ 60} ${tr('ساعات', 'h')} ${minutes % 60} ${tr('دقيقة', 'm')}',
                ),
              ),
            ),
          ],
        ),
      ),
      minHeight: 136,
    );
    final employeeNote = panel(
      tr('ملاحظات الموظف على التسليم', 'Employee review notes'),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: EmployeeTheme.primary.withValues(alpha: .025),
          border: Border.all(
            color: EmployeeTheme.primary.withValues(alpha: .10),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${task['employee_review_note'] ?? tr('لا توجد ملاحظات', 'No notes')}',
          style: const TextStyle(fontSize: 14, height: 1.7),
        ),
      ),
      minHeight: 136,
    );
    Widget stage(
      String label,
      IconData icon, {
      bool active = false,
      String? detail,
      bool last = false,
    }) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Column(
            children: [
              Icon(
                icon,
                size: 21,
                color: active
                    ? EmployeeTheme.primary
                    : scheme.outline.withValues(alpha: .55),
              ),
              if (!last)
                Container(
                  width: 1,
                  height: detail == null ? 25 : 39,
                  color: EmployeeTheme.primary.withValues(alpha: .20),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
    final timeline = panel(
      tr('حالة المراجعة', 'Review status'),
      Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: EmployeeTheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tr('بانتظار قرارك', 'Awaiting your decision'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: EmployeeTheme.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          stage(
            qa
                ? tr('تم التسليم', 'Submitted')
                : tr('طُلبت المراجعة', 'Review requested'),
            Icons.check_circle,
            active: true,
            detail: date(
              qa ? task['completed_at'] : task['employee_review_requested_at'],
              time: true,
            ),
          ),
          stage(
            tr('قيد المراجعة', 'Under review'),
            Icons.play_circle_fill,
            active: true,
          ),
          stage(tr('تم الاعتماد', 'Approved'), Icons.radio_button_unchecked),
          stage(
            tr('أعيد للتعديل', 'Returned for changes'),
            Icons.radio_button_unchecked,
            last: true,
          ),
        ],
      ),
    );
    final notesPanel = panel(
      tr('ملاحظات المراجعة', 'Review notes'),
      Column(
        children: [
          TextField(
            controller: note,
            enabled: !busy,
            maxLines: 1,
            maxLength: 500,
            style: const TextStyle(fontSize: 15, height: 1.5),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              hintText: tr(
                'أضف ملاحظاتك هنا (اختياري للاعتماد)…',
                'Add notes here (optional for delivery approval)…',
              ),
              errorText: error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: EmployeeTheme.primary.withValues(alpha: .18),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: EmployeeTheme.primary.withValues(alpha: .18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (_, box) {
              final buttons = [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  onPressed: busy ? null : () => decide(true),
                  icon: const Icon(Icons.check, size: 19),
                  label: Text(
                    busy
                        ? tr('جارٍ الحفظ…', 'Saving…')
                        : qa
                        ? tr('اعتماد التسليم', 'Approve delivery')
                        : tr('اعتماد المراجعة', 'Approve review'),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: EmployeeTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  onPressed: busy ? null : () => decide(false),
                  icon: const Icon(Icons.undo, size: 19),
                  label: Text(tr('إعادة التعديل', 'Return for changes')),
                ),
              ];
              return box.maxWidth < 420
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buttons[0],
                        const SizedBox(height: 10),
                        buttons[1],
                      ],
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: box.maxWidth * .08,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: buttons[0]),
                          const SizedBox(width: 12),
                          Expanded(child: buttons[1]),
                        ],
                      ),
                    );
            },
          ),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.brightness == Brightness.light
                ? Colors.white
                : scheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: EmployeeTheme.primary.withValues(alpha: .12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: EmployeeTheme.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: EmployeeTheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${task['title'] ?? '—'}',
                          style: const TextStyle(
                            fontSize: 24,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              tr('مهمة مسندة إلى', 'Assigned to'),
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              member?.name ?? '${task['employee_name'] ?? '—'}',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2F5EE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                qa
                                    ? tr(
                                        'مكتمل بانتظار المراجعة',
                                        'Completed, awaiting review',
                                      )
                                    : tr(
                                        'قيد التنفيذ بانتظار المراجعة',
                                        'In progress, awaiting review',
                                      ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: Color(0xFF008D70),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (tasks.length > 1)
                    PopupMenuButton<String>(
                      tooltip: tr(
                        'اختيار مهمة للمراجعة',
                        'Choose a task to review',
                      ),
                      enabled: !busy,
                      onSelected: select,
                      itemBuilder: (_) => tasks
                          .map(
                            (t) => PopupMenuItem(
                              value: '${t['id']}',
                              child: Text(
                                '${t['title']} • ${t['employee_name'] ?? ''}',
                              ),
                            ),
                          )
                          .toList(),
                      icon: const Icon(
                        Icons.list_alt,
                        color: EmployeeTheme.primary,
                      ),
                    ),
                  IconButton(
                    tooltip: tr('تحديث', 'Refresh'),
                    onPressed: busy ? null : refresh,
                    icon: const Icon(Icons.refresh, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              metadata,
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (_, box) => box.maxWidth < 920
                    ? Column(
                        children: [
                          attachmentPanel,
                          const SizedBox(height: 12),
                          execution,
                          const SizedBox(height: 12),
                          timing,
                          const SizedBox(height: 12),
                          employeeNote,
                          const SizedBox(height: 12),
                          timeline,
                        ],
                      )
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 41,
                              child: Column(
                                children: [
                                  attachmentPanel,
                                  const SizedBox(height: 12),
                                  Expanded(child: employeeNote),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 33,
                              child: Column(
                                children: [
                                  execution,
                                  const SizedBox(height: 12),
                                  Expanded(child: timing),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(flex: 26, child: timeline),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              notesPanel,
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewAttachmentRow extends StatefulWidget {
  const _ReviewAttachmentRow({
    super.key,
    required this.file,
    required this.onOpen,
  });
  final Map<String, dynamic> file;
  final ValueChanged<String> onOpen;
  @override
  State<_ReviewAttachmentRow> createState() => _ReviewAttachmentRowState();
}

class _ReviewAttachmentRowState extends State<_ReviewAttachmentRow> {
  bool downloading = false;

  Future<void> download(String url, String name) async {
    final segments = Uri.tryParse(url)?.pathSegments ?? <String>[];
    final bucketIndex = segments.indexOf('task_attachments');
    if (kIsWeb || bucketIndex < 0) {
      widget.onOpen(url);
      return;
    }
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => downloading = true);
    try {
      final location = await SafeFilePicker.saveLocation(
        context: context,
        suggestedName: name,
        acceptedTypeGroups: const [],
      );
      if (location == null || !mounted) return;
      final bytes = await Supabase.instance.client.storage
          .from('task_attachments')
          .download(segments.skip(bucketIndex + 1).join('/'));
      await XFile.fromData(bytes, name: name).saveTo(location.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar
                  ? 'تعذر تنزيل المرفق. حاول مرة أخرى.'
                  : 'Unable to download attachment. Try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = '${widget.file['file_name'] ?? '—'}',
        url = '${widget.file['file_url'] ?? ''}';
    final ext = name.split('.').last.toLowerCase();
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final pdf = ext == 'pdf';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      constraints: const BoxConstraints(minHeight: 58),
      decoration: BoxDecoration(
        border: Border.all(color: EmployeeTheme.primary.withValues(alpha: .13)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                width: 30,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F1F3),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Icon(
                  ['png', 'jpg', 'jpeg'].contains(ext)
                      ? Icons.image_outlined
                      : Icons.description_outlined,
                  size: 20,
                  color: Colors.blueGrey,
                ),
              ),
            ),
            Expanded(
              child: Text(
                name,
                textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 29,
              height: 34,
              decoration: BoxDecoration(
                color: pdf ? const Color(0xFFFF4545) : const Color(0xFF7B8491),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                ext.length > 4 ? 'FILE' : ext.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 38,
              color: EmployeeTheme.primary.withValues(alpha: .13),
            ),
            IconButton(
              tooltip: ar ? 'فتح المرفق' : 'Open attachment',
              onPressed: url.isEmpty ? null : () => widget.onOpen(url),
              icon: const Icon(Icons.visibility_outlined, size: 20),
            ),
            Container(
              width: 1,
              height: 38,
              color: EmployeeTheme.primary.withValues(alpha: .13),
            ),
            IconButton(
              tooltip: ar ? 'تنزيل المرفق' : 'Download attachment',
              onPressed: url.isEmpty || downloading
                  ? null
                  : () => download(url, name),
              icon: downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download_outlined, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
