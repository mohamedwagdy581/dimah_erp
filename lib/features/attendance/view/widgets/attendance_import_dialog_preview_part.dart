part of 'attendance_import_dialog.dart';

extension _AttendanceImportDialogPreview on _AttendanceImportDialogState {
  Widget buildAttendanceImportDialog(BuildContext context) {
    final visible = _visibleRows;
    final matchedCount = _rows.where((e) => e.isMatched).length;
    final lateCount = _rows.where((e) => e.lateMinutes > 0).length;
    final overtimeCount = _rows.where((e) => e.overtimeMinutes > 0).length;
    final unmatchedCount = _rows.length - matchedCount;

    return AlertDialog(
      title: const Text('Import Attendance CSV'),
      content: SizedBox(
        width: 1180,
        height: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(matchedCount, lateCount, overtimeCount, unmatchedCount),
            const SizedBox(height: 10),
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
                child: Center(child: Text('Choose a CSV file to preview and import.')),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: (_parsing || _saving) ? null : () => Navigator.pop(context, false),
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
          Text(_sourceName!, style: TextStyle(color: Colors.grey.shade600)),
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
                  setState(() => _filter = v);
                },
          items: const [
            DropdownMenuItem(value: _ImportFilter.all, child: Text('All')),
            DropdownMenuItem(value: _ImportFilter.late, child: Text('Late')),
            DropdownMenuItem(value: _ImportFilter.overtime, child: Text('Overtime')),
            DropdownMenuItem(value: _ImportFilter.unmatched, child: Text('Unmatched')),
          ],
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 260,
          child: TextField(
            enabled: !_parsing && !_saving,
            onChanged: (v) => setState(() => _search = v),
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
      side: BorderSide(color: color ?? Colors.transparent),
      labelStyle: TextStyle(
        color: color ?? Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
