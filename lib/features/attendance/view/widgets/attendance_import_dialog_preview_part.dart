part of 'attendance_import_dialog.dart';

extension _AttendanceImportDialogPreview on _AttendanceImportDialogState {
  Widget buildInlinePreview(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    String deviceTime(DateTime? value) => _fmtTime(
      value?.isUtc == true ? value!.add(const Duration(hours: 3)) : value,
    );
    final matched = _rows.where((r) => r.isMatched).length;
    final busy = _saving || _parsing;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5D8F4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(
              color: Color(0xFFF3EAFE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF8654BC),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('معاينة البيانات المستوردة', 'Imported records preview'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF21194E),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: busy ? null : () => widget.onClosed?.call(false),
                  tooltip: tr('إغلاق المعاينة', 'Close preview'),
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF8654BC),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: busy ? null : _pickAndParse,
                      icon: const Icon(Icons.attach_file, size: 17),
                      label: Text(
                        tr(
                          _sourceName == null
                              ? 'اختيار ملف CSV'
                              : 'تغيير الملف',
                          _sourceName == null
                              ? 'Choose CSV file'
                              : 'Change file',
                        ),
                      ),
                    ),
                    if (_sourceName != null)
                      Text(
                        _sourceName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF77738C),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tr(
                    'مطابقة الأعمدة تلقائيًا وربط الموظف برقم البصمة المحفوظ؛ الأرقام غير المرتبطة لا تُستورد.',
                    'Columns are detected automatically. Employees match saved device IDs; unlinked IDs are skipped.',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF77738C),
                  ),
                ),
                if (busy) const LinearProgressIndicator(),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                if (_rows.isNotEmpty)
                  LayoutBuilder(
                    builder: (context, c) => SizedBox(
                      height: 230,
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: c.maxWidth),
                            child: DataTable(
                              headingRowHeight: 40,
                              dataRowMinHeight: 42,
                              dataRowMaxHeight: 52,
                              horizontalMargin: 12,
                              columnSpacing: 24,
                              headingRowColor: const WidgetStatePropertyAll(
                                Color(0xFFF5F2FA),
                              ),
                              columns: [
                                for (final label in [
                                  tr('رقم البصمة', 'Person ID'),
                                  tr('اسم الموظف', 'Employee'),
                                  tr('التاريخ', 'Date'),
                                  tr('وقت الحضور', 'Check in'),
                                  tr('وقت الانصراف', 'Check out'),
                                  tr('النتيجة', 'Result'),
                                ])
                                  DataColumn(label: Text(label)),
                              ],
                              rows: [
                                for (final row in _rows)
                                  DataRow(
                                    cells: [
                                      DataCell(Text(row.sourcePersonId)),
                                      DataCell(
                                        Text(
                                          row.matchedEmployeeName ??
                                              row.sourceName,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _fmtDate(row.date),
                                          textDirection: TextDirection.ltr,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          deviceTime(row.checkIn),
                                          textDirection: TextDirection.ltr,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          deviceTime(row.checkOut),
                                          textDirection: TextDirection.ltr,
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              row.isMatched
                                                  ? Icons.check_circle_outline
                                                  : Icons.error_outline,
                                              size: 16,
                                              color: row.isMatched
                                                  ? const Color(0xFF009B7E)
                                                  : Colors.red,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              row.isMatched
                                                  ? tr('مرتبط', 'Matched')
                                                  : tr('غير مرتبط', 'Unlinked'),
                                              style: TextStyle(
                                                color: row.isMatched
                                                    ? const Color(0xFF009B7E)
                                                    : Colors.red,
                                              ),
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
                    ),
                  ),
                if (_rows.isNotEmpty)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      tr(
                        'تصحيح فرق ٣ ساعات للسجلات المستوردة سابقًا',
                        'Repair previously imported 3-hour shift',
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      tr(
                        'يتطلب تثبيت إصلاح التوقيت؛ التصحيحات المعتمدة تظل محفوظة.',
                        'Requires timezone repair installation; approved corrections are preserved.',
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: _repairTimezone,
                    onChanged: busy ? null : _setRepairTimezone,
                  ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Text(
                      tr(
                        '$matched مرتبط من أصل ${_rows.length} سجل',
                        '$matched matched of ${_rows.length} records',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8654BC),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: matched == 0 || busy ? null : _import,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8654BC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: Text(tr('استيراد البيانات', 'Import records')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAttendanceImportDialog(BuildContext context) {
    final visible = _visibleRows;
    final matchedCount = _rows.where((e) => e.isMatched).length;
    final lateCount = _rows.where((e) => e.lateMinutes > 0).length;
    final overtimeCount = _rows.where((e) => e.overtimeMinutes > 0).length;
    final unmatchedCount = _rows.length - matchedCount;

    // Use MediaQuery to adapt to screen height and avoid overflow
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight * 0.8;

    return AlertDialog(
      title: const Text('Import Attendance CSV'),
      content: SizedBox(
        width: 1180,
        height: dialogHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              matchedCount,
              lateCount,
              overtimeCount,
              unmatchedCount,
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'تصحيح فرق ٣ ساعات للسجلات المستوردة سابقًا من نفس الملف'
                    : 'Repair the 3-hour shift in records previously imported from this file',
              ),
              subtitle: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'فعّلها بعد تثبيت ملف إصلاح التوقيت. التصحيحات والسجلات غير المطابقة تظل محفوظة.'
                    : 'Requires the timezone repair SQL. Corrections and nonmatching records are preserved.',
              ),
              value: _repairTimezone,
              onChanged: _parsing || _saving ? null : _setRepairTimezone,
            ),
            const Text(
              'Matches saved device Person IDs only. Unlinked IDs are skipped. Existing employee days are preserved. Normal check-in/out only; no shift lateness or overtime calculation.',
            ),
            if (_parsing || _saving) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 8),
            if (_rows.isNotEmpty) ...[
              _buildFilterBar(),
              const SizedBox(height: 10),
              Expanded(child: _buildTable(visible)),
            ] else
              const Expanded(
                child: Center(
                  child: Text('Choose a CSV file to preview and import.'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: (_parsing || _saving)
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: (_rows.isEmpty || _parsing || _saving) ? null : _import,
          icon: const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Importing...' : 'Import Matched Records'),
        ),
      ],
    );
  }

  Widget _buildHeader(
    int matchedCount,
    int lateCount,
    int overtimeCount,
    int unmatchedCount,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: (_parsing || _saving) ? null : _pickAndParse,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(_sourceName == null ? 'Choose CSV File' : 'Change File'),
        ),
        if (_sourceName != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              _sourceName!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
        if (_rows.isNotEmpty) ...[
          _smallStat('Rows', _rows.length.toString()),
          _smallStat('Matched', matchedCount.toString(), color: Colors.green),
          _smallStat('Late', lateCount.toString(), color: Colors.orange),
          _smallStat('Overtime', overtimeCount.toString(), color: Colors.blue),
          _smallStat('Unmatched', unmatchedCount.toString(), color: Colors.red),
        ],
      ],
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        DropdownButton<_ImportFilter>(
          value: _filter,
          onChanged: (_parsing || _saving)
              ? null
              : (v) {
                  if (v == null) return;
                  _setFilter(v);
                },
          items: const [
            DropdownMenuItem(value: _ImportFilter.all, child: Text('All')),
            DropdownMenuItem(value: _ImportFilter.late, child: Text('Late')),
            DropdownMenuItem(
              value: _ImportFilter.overtime,
              child: Text('Overtime'),
            ),
            DropdownMenuItem(
              value: _ImportFilter.unmatched,
              child: Text('Unmatched'),
            ),
          ],
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 260,
          child: TextField(
            enabled: !_parsing && !_saving,
            onChanged: _setSearch,
            decoration: const InputDecoration(
              hintText: 'Search name/person id...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _smallStat(String title, String value, {Color? color}) {
    return Chip(
      label: Text('$title: $value'),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color ?? Colors.grey.shade300),
      backgroundColor: color?.withValues(alpha: 0.1) ?? Colors.grey.shade100,
      labelStyle: TextStyle(
        color: color ?? Colors.black87,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}
