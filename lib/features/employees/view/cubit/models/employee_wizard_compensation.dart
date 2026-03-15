import 'package:equatable/equatable.dart';

class EmployeeWizardCompensation extends Equatable {
  const EmployeeWizardCompensation({
    this.basicSalary = 0,
    this.housingAllowance = 0,
    this.transportAllowance = 0,
    this.otherAllowance = 0,
    this.bankName = '',
    this.iban = '',
    this.accountNumber = '',
    this.paymentMethod = 'bank',
  });

  final num basicSalary;
  final num housingAllowance;
  final num transportAllowance;
  final num otherAllowance;
  final String bankName;
  final String iban;
  final String accountNumber;
  final String paymentMethod;

  EmployeeWizardCompensation copyWith({
    num? basicSalary,
    num? housingAllowance,
    num? transportAllowance,
    num? otherAllowance,
    String? bankName,
    String? iban,
    String? accountNumber,
    String? paymentMethod,
  }) {
    return EmployeeWizardCompensation(
      basicSalary: basicSalary ?? this.basicSalary,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      transportAllowance: transportAllowance ?? this.transportAllowance,
      otherAllowance: otherAllowance ?? this.otherAllowance,
      bankName: bankName ?? this.bankName,
      iban: iban ?? this.iban,
      accountNumber: accountNumber ?? this.accountNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  @override
  List<Object?> get props => [
    basicSalary,
    housingAllowance,
    transportAllowance,
    otherAllowance,
    bankName,
    iban,
    accountNumber,
    paymentMethod,
  ];
}
