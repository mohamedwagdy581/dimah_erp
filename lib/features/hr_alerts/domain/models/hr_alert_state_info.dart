class HrAlertStateInfo {
  const HrAlertStateInfo({
    this.snoozeUntil,
    this.resolvedAt,
  });

  final DateTime? snoozeUntil;
  final DateTime? resolvedAt;

  bool get isHandled => resolvedAt != null;
  bool get isSnoozed {
    final until = snoozeUntil;
    return until != null && until.isAfter(DateTime.now());
  }
}
