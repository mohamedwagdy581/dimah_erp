part of 'employee_docs_form_dialog.dart';

extension _EmployeeDocsInlineForm on _EmployeeDocsFormDialogState {
  Widget buildInlineDocumentForm(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    const purple = Color(0xFF8654BC),
        border = Color(0xFFECE6F4),
        ink = Color(0xFF21194E);
    final busy = _uploading || _saving;
    InputDecoration decoration(String hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: border),
      ),
      border: const OutlineInputBorder(),
    );
    Widget label(String text, {bool required = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Flexible(
            child: Text(text, style: const TextStyle(fontSize: 13, color: ink)),
          ),
          if (required) const Text(' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
    final types = _docTypeGroups(t).expand((g) => g.items).toList();
    final custom = types.every((i) => i.value != _docType.text);
    final employees = [..._employees];
    if (_employeeId != null && employees.every((e) => e.id != _employeeId)) {
      employees.add(
        EmployeeLookup(
          id: _employeeId!,
          fullName: widget.initialDocument?.employeeName ?? _employeeId!,
        ),
      );
    }
    Widget dateField(bool issued) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label(issued ? t.issuedDate : t.expiresDate),
          OutlinedButton(
            onPressed: busy
                ? null
                : issued
                ? _pickIssued
                : _pickExpires,
            style: OutlinedButton.styleFrom(
              foregroundColor: ink,
              side: const BorderSide(color: border),
              minimumSize: const Size(double.infinity, 42),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(
                      issued ? _issuedAt : _expiresAt,
                      '—',
                    ).replaceAll('-', '/'),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const Icon(Icons.calendar_month_outlined, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E3FF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    widget.initialDocument == null
                        ? Icons.add
                        : Icons.edit_outlined,
                    color: purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.initialDocument == null
                        ? tr('إضافة مستند جديد', 'Add new document')
                        : tr('تعديل المستند', 'Edit document'),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.initialOldExpiresAt != null) ...[
              _buildRenewHint(context),
              const SizedBox(height: 12),
            ],
            label(t.employee, required: true),
            DropdownButtonFormField<String>(
              key: const ValueKey('document-employee'),
              initialValue: _employeeId,
              isExpanded: true,
              decoration: decoration(
                tr('اختر الموظف...', 'Choose employee...'),
              ),
              items: [
                for (final e in employees)
                  DropdownMenuItem(
                    value: e.id,
                    child: Text(e.fullName, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: busy || widget.initialDocument != null
                  ? null
                  : _setEmployeeId,
              validator: (v) => v == null ? t.employeeRequired : null,
            ),
            const SizedBox(height: 14),
            label(t.documentType, required: true),
            DropdownButtonFormField<String>(
              initialValue: _docType.text,
              isExpanded: true,
              decoration: decoration(
                tr('اختر نوع المستند...', 'Choose document type...'),
              ),
              items: [
                for (final i in types)
                  DropdownMenuItem(value: i.value, child: Text(i.label)),
                if (custom)
                  DropdownMenuItem(
                    value: _docType.text,
                    child: Text(_docType.text),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (v) {
                      if (v != null) _setDocType(v);
                    },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                dateField(true),
                const SizedBox(width: 10),
                dateField(false),
              ],
            ),
            const SizedBox(height: 16),
            label(tr('المرفق', 'Attachment'), required: true),
            FormField<String>(
              validator: (_) =>
                  _uploadedFileUrl.isEmpty ? t.fileRequired : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    key: const ValueKey('document-upload'),
                    onTap: busy ? null : _pickFile,
                    borderRadius: BorderRadius.circular(6),
                    child: CustomPaint(
                      foregroundPainter: _DocumentUploadBorder(
                        field.hasError ? Colors.red : const Color(0xFFCDB4F4),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 22,
                        ),
                        color: const Color(0xFFFCFAFF),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              color: purple,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFileName.isEmpty
                                  ? tr(
                                      'اضغط لاختيار ملف',
                                      'Click to choose a file',
                                    )
                                  : _selectedFileName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: purple,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'PDF, JPG, PNG, DOC, DOCX',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF77738C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (field.hasError)
                    Text(
                      field.errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (busy) ...[const SizedBox(height: 10), _buildProgressState(t)],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('document-save'),
                    onPressed: busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      tr('حفظ المستند', 'Save document'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 85,
                  child: OutlinedButton(
                    onPressed: busy ? null : () => widget.onClosed?.call(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(t.cancel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentUploadBorder extends CustomPainter {
  const _DocumentUploadBorder(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 9) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + 5).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DocumentUploadBorder old) => color != old.color;
}
