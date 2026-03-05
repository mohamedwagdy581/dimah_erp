class EmployeeLookup {
  const EmployeeLookup({required this.id, required this.fullName});

  final String id;
  final String fullName;

  factory EmployeeLookup.fromMap(Map<String, dynamic> map) {
    return EmployeeLookup(
      id: map['id'].toString(),
      fullName: (map['full_name'] ?? '').toString(),
    );
  }
}
