part of 'attendance_form_dialog.dart';

extension _AttendanceFormDialogBuild on _AttendanceFormDialogState {
  Widget buildAttendanceFormDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Attendance'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loadingEmployees) const LinearProgressIndicator(),
              if (_loadError != null) ...[
                const SizedBox(height: 8),
                Text(_loadError!, style: const TextStyle(color: Colors.red)),
              ],
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
              if (_filtered.isEmpty) ...[
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('No employees found', style: TextStyle(fontSize: 12)),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(_formatDate(_date)),
              ),
              if (_dateError != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_dateError!, style: const TextStyle(color: Colors.red)),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                items: const [
                  DropdownMenuItem(value: 'present', child: Text('Present')),
                  DropdownMenuItem(value: 'late', child: Text('Late')),
                  DropdownMenuItem(value: 'absent', child: Text('Absent')),
                  DropdownMenuItem(value: 'on_leave', child: Text('On Leave')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'present'),
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(true),
                      child: Text(_checkIn == null ? 'Check In' : _checkIn!.format(context)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(false),
                      child: Text(_checkOut == null ? 'Check Out' : _checkOut!.format(context)),
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
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
