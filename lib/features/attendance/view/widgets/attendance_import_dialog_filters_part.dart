part of 'attendance_import_dialog.dart';

extension _AttendanceImportDialogFilters on _AttendanceImportDialogState {
  List<_PreviewRow> get _visibleRows {
    Iterable<_PreviewRow> visible = _rows;
    switch (_filter) {
      case _ImportFilter.all:
        break;
      case _ImportFilter.late:
        visible = visible.where((e) => e.lateMinutes > 0);
        break;
      case _ImportFilter.overtime:
        visible = visible.where((e) => e.overtimeMinutes > 0);
        break;
      case _ImportFilter.unmatched:
        visible = visible.where((e) => !e.isMatched);
        break;
    }

    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return visible.toList();
    return visible.where((e) {
      return e.sourceName.toLowerCase().contains(query) ||
          e.sourcePersonId.toLowerCase().contains(query) ||
          (e.matchedEmployeeName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }
}
