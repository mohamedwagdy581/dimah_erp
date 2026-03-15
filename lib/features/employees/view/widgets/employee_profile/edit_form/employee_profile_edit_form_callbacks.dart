class EmployeeProfileEditFormCallbacks {
  const EmployeeProfileEditFormCallbacks({
    required this.onPickPhoto,
    required this.onStatusChanged,
    required this.onPaymentMethodChanged,
    required this.onPickPassportExpiry,
    required this.onPickResidencyIssueDate,
    required this.onPickResidencyExpiryDate,
    required this.onPickInsuranceStartDate,
    required this.onPickInsuranceExpiryDate,
    required this.onPickContractStart,
    required this.onPickContractEnd,
  });

  final void Function() onPickPhoto;
  final void Function(String?) onStatusChanged;
  final void Function(String?) onPaymentMethodChanged;
  final void Function() onPickPassportExpiry;
  final void Function() onPickResidencyIssueDate;
  final void Function() onPickResidencyExpiryDate;
  final void Function() onPickInsuranceStartDate;
  final void Function() onPickInsuranceExpiryDate;
  final void Function() onPickContractStart;
  final void Function() onPickContractEnd;
}
