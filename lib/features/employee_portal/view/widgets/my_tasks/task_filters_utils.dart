List<Map<String, dynamic>> applyTaskFilter(List<Map<String, dynamic>> items, String filter) {
  switch (filter) {
    case 'todo':
      return items.where((task) => (task['status'] ?? 'todo') == 'todo').toList();
    case 'in_progress':
      return items.where((task) => (task['status'] ?? 'todo') == 'in_progress').toList();
    case 'done':
      return items.where((task) => (task['status'] ?? 'todo') == 'done').toList();
    case 'review_pending':
      return items.where((task) => (task['employee_review_status'] ?? 'none') == 'pending').toList();
    case 'qa_pending':
      return items.where((task) => (task['status'] ?? '') == 'done' && (task['qa_status'] ?? 'pending') == 'pending').toList();
    default:
      return items;
  }
}

int countByTaskFilter(List<Map<String, dynamic>> items, String filter) => applyTaskFilter(items, filter).length;
