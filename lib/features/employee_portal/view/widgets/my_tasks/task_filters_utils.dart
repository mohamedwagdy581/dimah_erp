List<Map<String, dynamic>> applyTaskFilter(
  List<Map<String, dynamic>> items,
  String filter,
) {
  switch (filter) {
    case 'todo':
      return items
          .where((task) => (task['status'] ?? 'todo') == 'todo')
          .toList();
    case 'in_progress':
      return items
          .where((task) => (task['status'] ?? 'todo') == 'in_progress')
          .toList();
    case 'done':
      return items
          .where((task) => (task['status'] ?? 'todo') == 'done')
          .toList();
    case 'review_pending':
      return items
          .where(
            (task) => (task['employee_review_status'] ?? 'none') == 'pending',
          )
          .toList();
    case 'qa_pending':
      return items
          .where(
            (task) =>
                (task['status'] ?? '') == 'done' &&
                (task['qa_status'] ?? 'pending') == 'pending',
          )
          .toList();
    default:
      return items;
  }
}

int countByTaskFilter(List<Map<String, dynamic>> items, String filter) =>
    applyTaskFilter(items, filter).length;

List<Map<String, dynamic>> filterEmployeeTasks(
  List<Map<String, dynamic>> items, {
  String status = 'all',
  String search = '',
  String type = 'all',
  String sort = 'due',
}) {
  final query = search.trim().toLowerCase();
  final result = applyTaskFilter(items, status)
      .where(
        (task) =>
            (type == 'all' || (task['task_type'] ?? 'general') == type) &&
            (query.isEmpty ||
                '${task['title'] ?? ''} ${task['description'] ?? ''}'
                    .toLowerCase()
                    .contains(query)),
      )
      .toList();
  int dateCompare(Object? first, Object? second, {bool descending = false}) {
    final a = DateTime.tryParse(first?.toString() ?? '');
    final b = DateTime.tryParse(second?.toString() ?? '');
    if (a == null) return b == null ? 0 : 1;
    if (b == null) return -1;
    return descending ? b.compareTo(a) : a.compareTo(b);
  }

  const priorities = {'high': 0, 'medium': 1, 'low': 2};
  result.sort((a, b) {
    final comparison = switch (sort) {
      'priority' => (priorities[a['priority']] ?? 1).compareTo(
        priorities[b['priority']] ?? 1,
      ),
      'latest' => dateCompare(
        a['created_at'],
        b['created_at'],
        descending: true,
      ),
      _ => dateCompare(a['due_date'], b['due_date']),
    };
    return comparison != 0
        ? comparison
        : (a['id']?.toString() ?? '').compareTo(b['id']?.toString() ?? '');
  });
  return result;
}
