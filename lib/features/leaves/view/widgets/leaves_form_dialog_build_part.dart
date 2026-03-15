part of 'leaves_form_dialog.dart';

extension _LeavesFormDialogBuild on _LeavesFormDialogState {
  Widget buildLeavesFormDialog(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialLeave == null ? 'Add Leave' : 'Resubmit Leave'),
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
                  decoration: const InputDecoration(
                    labelText: 'Search employee',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
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
                  decoration: const InputDecoration(
                    labelText: 'Employee',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Employee is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: const [
                  DropdownMenuItem(value: 'annual', child: Text('Annual')),
                  DropdownMenuItem(value: 'sick', child: Text('Sick')),
                  DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'annual'),
                decoration: const InputDecoration(
                  labelText: 'Leave Type',
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
                    _uploading ? 'Uploading attachment...' : 'Saving leave request...',
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
                      label: const Text('Attach PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: _fileName,
                      builder: (context, name, _) {
                        return Text(
                          name.isEmpty ? 'No file' : name,
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
                      label: Text(_formatDate(_start, 'Start Date')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_uploading || _saving) ? null : _pickEnd,
                      icon: const Icon(Icons.event_available),
                      label: Text(_formatDate(_end, 'End Date')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_uploading || _saving) ? null : _submit,
          child: Text(_saving ? 'Saving...' : (widget.initialLeave == null ? 'Save' : 'Resubmit')),
        ),
      ],
    );
  }
}
