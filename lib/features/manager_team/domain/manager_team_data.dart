class TeamMember {
  const TeamMember({required this.id, required this.name, this.jobTitle = '', this.photoUrl});
  final String id, name, jobTitle;
  final String? photoUrl;
}

class TeamTask {
  TeamTask(Map<String, dynamic> row)
    : id = row['id'].toString(),
      employeeId = row['employee_id'].toString(),
      title = (row['title'] ?? '').toString(),
      status = (row['status'] ?? '').toString(),
      priority = (row['priority'] ?? 'medium').toString(),
      reviewPending = row['employee_review_status'] == 'pending',
      qaPending =
          row['status'] == 'done' &&
          (row['qa_status'] ?? 'pending') == 'pending',
      progress = taskProgressValue(row),
      due = DateTime.tryParse((row['due_date'] ?? '').toString());
  final String id, employeeId, title, status, priority;
  final bool reviewPending;
  final bool qaPending;
  final double progress;
  final DateTime? due;
  bool get done => status == 'done';
  static double taskProgressValue(Map<String, dynamic> row) {
    if (row['status'] == 'done') return 100;
    final value = double.tryParse('${row['progress'] ?? 0}') ?? 0;
    return value.isFinite ? value.clamp(0.0, 100.0) : 0;
  }
}

class ManagerTeamData {
  const ManagerTeamData({
    this.members = const [],
    this.tasks = const [],
    this.pendingRequests = 0,
    this.managerName = '',
    this.departmentNames = const [],
  });
  final List<TeamMember> members;
  final List<TeamTask> tasks;
  final int pendingRequests;
  final String managerName;
  final List<String> departmentNames;
  List<TeamTask> tasksFor(String id) =>
      tasks.where((t) => t.employeeId == id).toList();
  double completion(String id) {
    final rows = tasksFor(id);
    return rows.isEmpty ? 0 : rows.where((t) => t.done).length / rows.length;
  }

  double averageProgress(String id) {
    final rows = tasksFor(id);
    return rows.isEmpty
        ? 0
        : rows.fold<double>(0, (sum, task) => sum + task.progress) /
              rows.length /
              100;
  }

  List<TeamTask> get reviews => tasks.where((t) => t.reviewPending).toList();
  List<TeamTask> overdue(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return tasks
        .where((t) => !t.done && t.due != null && t.due!.isBefore(today))
        .toList();
  }

  List<TeamTask> upcoming(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: 7));
    return tasks
        .where(
          (t) =>
              !t.done &&
              t.due != null &&
              !t.due!.isBefore(today) &&
              t.due!.isBefore(end),
        )
        .toList()
      ..sort((a, b) => a.due!.compareTo(b.due!));
  }

  String nameFor(String id) =>
      members.where((m) => m.id == id).firstOrNull?.name ?? '—';
}
