part of 'employee_docs_form_dialog.dart';

extension _EmployeeDocsFormDialogFields on _EmployeeDocsFormDialogState {
  Widget _buildEmployeeSelector(AppLocalizations t) {
    if (widget.initialEmployeeId == null && widget.initialDocument == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: t.searchEmployeeHint,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _filter,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _employeeId,
            items: _filtered
                .map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName)))
                .toList(),
            onChanged: (v) => setState(() => _employeeId = v),
            decoration: InputDecoration(
              labelText: t.employee,
              border: const OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return t.employeeRequired;
              return null;
            },
          ),
        ],
      );
    }

    final employeeName = _employees
        .firstWhere(
          (e) => e.id == _employeeId,
          orElse: () => EmployeeLookup(id: '', fullName: ''),
        )
        .fullName;
    return ListTile(
      title: Text(t.employee),
      subtitle: Text(employeeName),
      tileColor: Colors.grey[100],
    );
  }

  Widget _buildFileField(AppLocalizations t) {
    return FormField<String>(
      initialValue: _uploadedFileUrl,
      validator: (_) => _uploadedFileUrl.trim().isEmpty ? t.fileRequired : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: field.hasError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFileName.isEmpty ? t.noFileSelected : _selectedFileName,
                      style: TextStyle(
                        color: _selectedFileName.isEmpty
                            ? Theme.of(context).hintColor
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (field.errorText != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDateButtons(AppLocalizations t) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: (_uploading || _saving) ? null : _pickIssued,
            icon: const Icon(Icons.event),
            label: Text(_formatDate(_issuedAt, t.issuedDate)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: (_uploading || _saving) ? null : _pickExpires,
            icon: const Icon(Icons.event_available),
            label: Text(_formatDate(_expiresAt, t.expiresDate)),
          ),
        ),
      ],
    );
  }
}
