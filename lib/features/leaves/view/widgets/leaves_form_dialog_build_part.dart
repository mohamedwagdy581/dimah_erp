part of 'leaves_form_dialog.dart';

extension _LeavesFormDialogBuild on _LeavesFormDialogState {
  Widget buildLeavesFormDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(widget.initialLeave == null ? t.addLeave : t.resubmitLeave),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.employeeId == null) ...[
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    labelText: t.searchEmployeeHint,
                    border: OutlineInputBorder(),
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
                  onChanged: _setEmployeeId,
                  decoration: InputDecoration(
                    labelText: t.employee,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return t.employeeRequired;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: [
                  DropdownMenuItem(value: 'annual', child: Text(t.leaveTypeAnnual)),
                  DropdownMenuItem(value: 'sick', child: Text(t.leaveTypeSick)),
                  DropdownMenuItem(value: 'unpaid', child: Text(t.leaveTypeUnpaid)),
                  DropdownMenuItem(value: 'other', child: Text(t.leaveTypeOther)),
                ],
                onChanged: _setLeaveType,
                decoration: InputDecoration(
                  labelText: t.type,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_uploading || _saving) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _uploading ? t.uploadingAttachment : t.savingLeaveRequest,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_uploading || _saving) ? null : _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(t.uploadPdf),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: _fileName,
                      builder: (context, name, _) {
                        return Text(
                          name.isEmpty ? t.noFileSelected : name,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_uploading || _saving) ? null : _pickStart,
                      icon: const Icon(Icons.event),
                      label: Text(_formatDate(_start, t.startDate)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_uploading || _saving) ? null : _pickEnd,
                      icon: const Icon(Icons.event_available),
                      label: Text(_formatDate(_end, t.endDate)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: t.notes,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: (_uploading || _saving) ? null : () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: (_uploading || _saving) ? null : _submit,
          child: Text(
            _saving
                ? t.saving
                : (widget.initialLeave == null ? t.save : t.resubmit),
          ),
        ),
      ],
    );
  }
}
