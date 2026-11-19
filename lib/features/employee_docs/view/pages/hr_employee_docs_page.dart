import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/app_di.dart';
import '../../../../core/utils/safe_file_picker.dart';
import '../../../../core/widgets/page_navigation_buttons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../employees/data/repos/hr_employees_repo.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../../domain/models/employee_document.dart';
import '../../domain/repos/employee_docs_repo.dart';
import '../widgets/employee_docs_form_dialog.dart';
import '../widgets/employee_docs_table/document_type_utils.dart';
import '../widgets/employee_docs_table/document_file_utils.dart';

class HrEmployeeDocsPage extends StatefulWidget {
  const HrEmployeeDocsPage({
    super.key,
    this.repo,
    this.loadEmployees,
    this.today,
    this.initialEmployeeId,
    this.initialDocType,
    this.initialExpiryStatus,
    this.initialIssuedAt,
    this.initialExpiresAt,
    this.initialOldExpiresAt,
  });
  final EmployeeDocsRepo? repo;
  final Future<HrEmployeesData> Function()? loadEmployees;
  final DateTime? today, initialIssuedAt, initialExpiresAt, initialOldExpiresAt;
  final String? initialEmployeeId, initialDocType, initialExpiryStatus;
  @override
  State<HrEmployeeDocsPage> createState() => _HrEmployeeDocsPageState();
}

class _HrEmployeeDocsPageState extends State<HrEmployeeDocsPage> {
  EmployeeDocsRepo get repo => widget.repo ?? AppDI.employeeDocsRepo;
  HrEmployeesData _employees = const HrEmployeesData();
  List<EmployeeDocument> _docs = [];
  bool _loading = true, _busy = false;
  String? _error, _employee, _type, _expiry;
  DateTime? _from, _to;
  EmployeeDocument? _editing;
  int _page = 0, _formVersion = 0;
  static const purple = Color(0xFF8654BC),
      ink = Color(0xFF21194E),
      border = Color(0xFFECE6F4);
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  @override
  void initState() {
    super.initState();
    _employee = widget.initialEmployeeId;
    _type = widget.initialDocType;
    _expiry = switch (widget.initialExpiryStatus) {
      'expiring_soon' => 'soon',
      'no_expiry' => 'none',
      'all' => null,
      final value => value,
    };
    _load();
  }

  Future<List<EmployeeDocument>> _all() async {
    final docs = <EmployeeDocument>[];
    for (var page = 0; ; page++) {
      final batch = await repo.fetchDocs(
        page: page,
        pageSize: 500,
        sortBy: 'created_at',
      );
      docs.addAll(batch.items);
      if (batch.items.isEmpty || docs.length >= batch.total) break;
    }
    return docs;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>([
        _all(),
        (widget.loadEmployees ??
            () => SupabaseHrEmployeesRepo(Supabase.instance.client).load())(),
      ]);
      if (mounted) {
        setState(() {
          _docs = values[0] as List<EmployeeDocument>;
          _employees = values[1] as HrEmployeesData;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String date(DateTime? d) => d == null
      ? '—'
      : '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  String expiry(EmployeeDocument d) {
    if (d.expiresAt == null) return 'none';
    final now = widget.today ?? DateTime.now();
    final days = DateTime.utc(
      d.expiresAt!.year,
      d.expiresAt!.month,
      d.expiresAt!.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    return days < 0
        ? 'expired'
        : days <= 30
        ? 'soon'
        : 'valid';
  }

  Future<void> _pick(bool from) async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? widget.today ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (chosen != null && mounted) {
      setState(() {
        if (from) {
          _from = chosen;
          if (_to?.isBefore(chosen) == true) _to = chosen;
        } else {
          _to = chosen;
          if (_from?.isAfter(chosen) == true) _from = chosen;
        }
        _page = 0;
      });
    }
  }

  Future<void> _open(EmployeeDocument doc) async {
    try {
      final uri = Uri.tryParse(doc.fileUrl);
      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Cannot open document');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _download(EmployeeDocument doc) async {
    try {
      final path = storagePathFromPublicUrl(doc.fileUrl);
      if (path == null) throw StateError('Invalid document storage URL');
      final name = Uri.parse(doc.fileUrl).pathSegments.last;
      final location = await SafeFilePicker.saveLocation(
        context: context,
        suggestedName: name,
        acceptedTypeGroups: const [],
      );
      if (location == null) return;
      final bytes = await Supabase.instance.client.storage
          .from('employee_docs')
          .download(path);
      await XFile.fromData(bytes, name: name).saveTo(location.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _delete(EmployeeDocument doc) async {
    if (_busy) return;
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteDocument),
        content: Text(t.deleteDocumentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
    });
    try {
      await repo.deleteDoc(id: doc.id, fileUrl: doc.fileUrl);
      if (mounted) {
        if (_editing?.id == doc.id) _reset();
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _reset() => setState(() {
    _editing = null;
    _formVersion++;
  });
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final names = {
      for (final e in _employees.employees) e.id: e.fullName,
      for (final d in _docs)
        if (_employees.employees.every((e) => e.id != d.employeeId))
          d.employeeId: d.employeeName,
    };
    final lookups = [
      for (final entry in names.entries)
        EmployeeLookup(id: entry.key, fullName: entry.value),
    ];
    final types = {
      'id_card',
      'passport',
      'residency',
      'contract',
      'medical_insurance',
      'cv',
      'graduation_cert',
      'national_address',
      'driving_license',
      'offer_letter',
      'bank_iban_certificate',
      'salary_certificate',
      'salary_definition',
      'medical_report',
      'other',
      ..._docs.map((d) => d.docType),
      ?_type,
    };
    String typeLabel(String value) =>
        types.contains(value) &&
            !{
              'id_card',
              'passport',
              'residency',
              'contract',
              'medical_insurance',
              'cv',
              'graduation_cert',
              'national_address',
              'driving_license',
              'offer_letter',
              'bank_iban_certificate',
              'salary_certificate',
              'salary_definition',
              'medical_report',
              'other',
            }.contains(value)
        ? value
        : docTypeLabel(t, value);
    final docs = _docs
        .where(
          (d) =>
              (_employee == null || d.employeeId == _employee) &&
              (_type == null || d.docType == _type) &&
              (_expiry == null || expiry(d) == _expiry) &&
              (_from == null ||
                  d.expiresAt != null && !d.expiresAt!.isBefore(_from!)) &&
              (_to == null ||
                  d.expiresAt != null && !d.expiresAt!.isAfter(_to!)),
        )
        .toList();
    final grouped = <String, List<EmployeeDocument>>{};
    for (final d in docs) {
      grouped.putIfAbsent(d.employeeId, () => []).add(d);
    }
    final ids = grouped.keys.toList()
      ..sort((a, b) => (names[a] ?? a).compareTo(names[b] ?? b));
    final pages = (ids.length / 2).ceil().clamp(1, 1000000),
        page = _page.clamp(0, (ids.length / 2).ceil().clamp(1, 1000000) - 1);
    Widget filter(
      String key,
      String label,
      String? value,
      Map<String, String> items,
      ValueChanged<String?> change,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: ink)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          key: ValueKey('$key-$value'),
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: border),
            ),
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(t.all)),
            for (final e in items.entries)
              DropdownMenuItem(
                value: e.key,
                child: Text(e.value, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: _busy
              ? null
              : (v) => setState(() {
                  change(v);
                  _page = 0;
                }),
        ),
      ],
    );
    Widget card(String id) {
      final matches = _employees.employees.where((e) => e.id == id);
      final e = matches.isEmpty ? null : matches.first;
      Widget initials() => Container(
        color: const Color(0xFFF0E3FF),
        alignment: Alignment.center,
        child: Text(
          (names[id] ?? '?')
              .trim()
              .split(RegExp(r'\s+'))
              .where((s) => s.isNotEmpty)
              .take(2)
              .map((s) => s.characters.first)
              .join(),
          style: const TextStyle(
            fontSize: 15,
            color: purple,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAFF),
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: e?.photoUrl?.isNotEmpty == true
                        ? Image.network(
                            e!.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stack) => initials(),
                          )
                        : initials(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        names[id] ?? id,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      Text(
                        e?.jobTitleName ?? '—',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF77738C),
                        ),
                      ),
                    ],
                  ),
                ),
                if (e?.employeeNumber != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E3FF),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      e!.employeeNumber!,
                      style: const TextStyle(fontSize: 12, color: purple),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: c.maxWidth),
                  child: DataTable(
                    headingRowHeight: 38,
                    dataRowMinHeight: 42,
                    dataRowMaxHeight: 48,
                    columnSpacing: 16,
                    horizontalMargin: 10,
                    dividerThickness: 0,
                    border: const TableBorder(
                      horizontalInside: BorderSide(color: border),
                      verticalInside: BorderSide(color: Color(0xFFF4EFFA)),
                    ),
                    headingRowColor: const WidgetStatePropertyAll(
                      Color(0xFFF4F0F8),
                    ),
                    headingTextStyle: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: ink, fontSize: 13),
                    dataTextStyle: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: ink, fontSize: 13),
                    columns: [
                      for (final label in [
                        t.documentType,
                        t.issuedDate,
                        t.expiresDate,
                        t.actions,
                      ])
                        DataColumn(label: Text(label)),
                    ],
                    rows: [
                      for (final d in grouped[id]!)
                        DataRow(
                          cells: [
                            DataCell(Text(typeLabel(d.docType))),
                            DataCell(
                              Text(
                                date(d.issuedAt),
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                            DataCell(
                              Text(
                                date(d.expiresAt),
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  color: expiry(d) == 'expired'
                                      ? const Color(0xFFF04461)
                                      : null,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    key: ValueKey('open-${d.id}'),
                                    tooltip: t.open,
                                    onPressed: d.fileUrl.isEmpty || _busy
                                        ? null
                                        : () => _open(d),
                                    icon: const Icon(
                                      Icons.visibility_outlined,
                                      size: 17,
                                      color: purple,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    key: ValueKey('download-${d.id}'),
                                    tooltip: t.download,
                                    onPressed: d.fileUrl.isEmpty || _busy
                                        ? null
                                        : () => _download(d),
                                    icon: const Icon(
                                      Icons.download_outlined,
                                      size: 17,
                                      color: purple,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    key: ValueKey('edit-${d.id}'),
                                    tooltip: t.edit,
                                    onPressed: _busy
                                        ? null
                                        : () => setState(() {
                                            _editing = d;
                                            _formVersion++;
                                          }),
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 17,
                                      color: purple,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    key: ValueKey('delete-${d.id}'),
                                    tooltip: t.delete,
                                    onPressed: _busy ? null : () => _delete(d),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 17,
                                      color: Color(0xFFF04461),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final form = EmployeeDocsFormDialog(
      key: ValueKey('form-${_editing?.id}-$_formVersion'),
      embedded: true,
      employees: lookups,
      repo: repo,
      initialDocument: _editing,
      initialEmployeeId: widget.initialEmployeeId,
      initialDocType: widget.initialDocType,
      initialIssuedAt: widget.initialIssuedAt,
      initialExpiresAt: widget.initialExpiresAt,
      initialOldExpiresAt: widget.initialOldExpiresAt,
      onBusyChanged: (busy) {
        if (mounted) {
          setState(() {
            _busy = busy;
          });
        }
      },
      onClosed: (saved) {
        _reset();
        if (saved) _load();
      },
    );
    final cards = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final id in ids.skip(page * 2).take(2)) card(id),
        if (!_loading && ids.isEmpty)
          AppEmptyState(
            title:
                _employee == null &&
                    _type == null &&
                    _expiry == null &&
                    _from == null &&
                    _to == null
                ? tr('لا توجد مستندات حاليًا', 'No documents yet')
                : null,
            filtered:
                _employee != null ||
                _type != null ||
                _expiry != null ||
                _from != null ||
                _to != null,
            onClear:
                _employee != null ||
                    _type != null ||
                    _expiry != null ||
                    _from != null ||
                    _to != null
                ? () => setState(() {
                    _employee = null;
                    _type = null;
                    _expiry = null;
                    _from = null;
                    _to = null;
                    _page = 0;
                  })
                : null,
          ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              tr(
                '${docs.length} مستند • ${ids.length} موظف',
                '${docs.length} documents • ${ids.length} employees',
              ),
              style: const TextStyle(fontSize: 12, color: Color(0xFF77738C)),
            ),
            PageNavigationButtons(
              onPrevious: page > 0
                  ? () => setState(() {
                      _page = page - 1;
                    })
                  : null,
              onNext: page + 1 < pages
                  ? () => setState(() {
                      _page = page + 1;
                    })
                  : null,
              previousTooltip: tr('السابق', 'Previous'),
              nextTooltip: tr('التالي', 'Next'),
              center: Text(
                '${page + 1} / $pages',
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('مستندات الموظفين', 'Employee documents'),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(
                          'إدارة مستندات الموظفين والوثائق الرسمية',
                          'Manage employee documents and official records',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF77738C),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _busy || _loading ? null : _load,
                  tooltip: tr('تحديث', 'Refresh'),
                  icon: const Icon(Icons.refresh, color: purple),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 1000
                    ? 5
                    : c.maxWidth >= 600
                    ? 3
                    : c.maxWidth >= 420
                    ? 2
                    : 1;
                final width = (c.maxWidth - (cols - 1) * 10) / cols;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: width,
                      child: filter(
                        'employee',
                        t.employee,
                        _employee,
                        names,
                        (v) => _employee = v,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: filter('type', t.documentType, _type, {
                        for (final type in types) type: typeLabel(type),
                      }, (v) => _type = v),
                    ),
                    SizedBox(
                      width: width,
                      child: filter(
                        'expiry',
                        tr('حالة الانتهاء', 'Expiry status'),
                        _expiry,
                        {
                          'valid': tr('ساري', 'Valid'),
                          'soon': tr(
                            'ينتهي خلال ٣٠ يوم',
                            'Expires within 30 days',
                          ),
                          'expired': tr('منتهي', 'Expired'),
                          'none': tr('بدون تاريخ انتهاء', 'No expiry date'),
                        },
                        (v) => _expiry = v,
                      ),
                    ),
                    for (final from in [true, false])
                      SizedBox(
                        width: width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(
                                from
                                    ? 'من تاريخ الانتهاء'
                                    : 'إلى تاريخ الانتهاء',
                                from ? 'Expiry from' : 'Expiry to',
                              ),
                              style: const TextStyle(fontSize: 13, color: ink),
                            ),
                            const SizedBox(height: 5),
                            OutlinedButton(
                              onPressed: _busy ? null : () => _pick(from),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ink,
                                side: const BorderSide(color: border),
                                minimumSize: const Size(double.infinity, 42),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      date(from ? _from : _to),
                                      textDirection: TextDirection.ltr,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _employee = null;
                        _type = null;
                        _expiry = null;
                        _from = null;
                        _to = null;
                        _page = 0;
                      }),
                child: Text(tr('إعادة ضبط', 'Reset filters')),
              ),
            ),
            if (_loading) const AppLoadingState(),
            if (_error != null) AppFailureState(error: _error, onRetry: _load),
            const SizedBox(height: 10),
            if (!_loading && _error == null)
              LayoutBuilder(
                builder: (context, c) => c.maxWidth >= 950
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: c.maxWidth * .37, child: form),
                          const SizedBox(width: 14),
                          Expanded(child: cards),
                        ],
                      )
                    : Column(
                        children: [form, const SizedBox(height: 14), cards],
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
