class LeaveBalance {
  const LeaveBalance({
    required this.type,
    required this.entitlement,
    required this.used,
  });

  final String type;
  final double entitlement;
  final double used;

  double get remaining => entitlement - used;
}
