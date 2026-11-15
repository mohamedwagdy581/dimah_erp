import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_profile_details.dart';
import '../../utils/employee_profile_utils.dart';
import 'employee_profile_financial_sections.dart';
import 'employee_profile_work_sections.dart';
import 'profile_kv_row.dart';
import 'profile_section_card.dart';
import 'employee_profile_contracts.dart';

class EmployeeProfileSections extends StatelessWidget {
  const EmployeeProfileSections({
    super.key,
    required this.profile,
    required this.canEdit,
    required this.onAddCompensationVersion,
    required this.onAddContractVersion,
    required this.onAddSettlement,
    required this.onOpenUrl,
    this.section,
  });

  final EmployeeProfileDetails profile;
  final bool canEdit;
  final VoidCallback onAddCompensationVersion;
  final VoidCallback onAddContractVersion;
  final VoidCallback onAddSettlement;
  final ValueChanged<String> onOpenUrl;
  final int? section;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = profile;

    return Column(
      children: [
        if (section == null || section == 0)
          ProfileSectionCard(
            title: t.personal,
            children: [
              ProfileKvRow(label: t.nationalId, value: p.nationalId),
              ProfileKvRow(
                label: t.dateOfBirth,
                value: formatEmployeeDate(p.dateOfBirth),
              ),
              ProfileKvRow(label: t.gender, value: p.gender),
              ProfileKvRow(label: t.nationality, value: p.nationality),
              ProfileKvRow(label: t.maritalStatus, value: p.maritalStatus),
              ProfileKvRow(label: t.address, value: p.address),
              ProfileKvRow(label: t.city, value: p.city),
              ProfileKvRow(label: t.country, value: p.country),
              ProfileKvRow(label: t.passportNo, value: p.passportNo),
              ProfileKvRow(
                label: t.passportExpiry,
                value: formatEmployeeDate(p.passportExpiry),
              ),
              ProfileKvRow(
                label: t.residencyIssueDate,
                value: formatEmployeeDate(p.residencyIssueDate),
              ),
              ProfileKvRow(
                label: t.residencyExpiryDate,
                value: formatEmployeeDate(p.residencyExpiryDate),
              ),
              ProfileKvRow(
                label: t.insuranceStartDate,
                value: formatEmployeeDate(p.insuranceStartDate),
              ),
              ProfileKvRow(
                label: t.insuranceExpiryDate,
                value: formatEmployeeDate(p.insuranceExpiryDate),
              ),
              ProfileKvRow(
                label: t.insuranceProvider,
                value: p.insuranceProvider,
              ),
              ProfileKvRow(
                label: t.insurancePolicyNo,
                value: p.insurancePolicyNo,
              ),
              ProfileKvRow(label: t.educationLevel, value: p.educationLevel),
              ProfileKvRow(label: t.major, value: p.major),
              ProfileKvRow(label: t.university, value: p.university),
            ],
          ),
        if (section == null || section == 1)
          ProfileSectionCard(
            title: t.basicInfo,
            children: [
              ProfileKvRow(label: t.fullName, value: p.fullName),
              ProfileKvRow(
                label: Localizations.localeOf(context).languageCode == 'ar'
                    ? 'رقم الموظف'
                    : 'Employee number',
                value: p.employeeNumber,
              ),
              ProfileKvRow(label: t.email, value: p.email),
              ProfileKvRow(label: t.phone, value: p.phone),
              ProfileKvRow(label: t.status, value: p.status),
              ProfileKvRow(label: t.department, value: p.departmentName),
              ProfileKvRow(label: t.menuJobTitles, value: p.jobTitleName),
              ProfileKvRow(
                label: t.hireDate,
                value: formatEmployeeDate(p.hireDate),
              ),
              ProfileKvRow(
                label: Localizations.localeOf(context).languageCode == 'ar'
                    ? 'المدير المباشر'
                    : 'Direct manager',
                value: p.managerName,
              ),
            ],
          ),
        if (section == null || section == 3)
          EmployeeProfileFinancialSections(
            profile: p,
            canEdit: canEdit,
            onAddCompensationVersion: onAddCompensationVersion,
          ),
        if (section == 2)
          EmployeeProfileContracts(
            profile: p,
            canEdit: canEdit,
            onAdd: onAddContractVersion,
            onOpenUrl: onOpenUrl,
          ),
        if (section == null || [4, 5, 6].contains(section))
          EmployeeProfileWorkSections(
            profile: p,
            canEdit: canEdit,
            onAddContractVersion: onAddContractVersion,
            onAddSettlement: onAddSettlement,
            onOpenUrl: onOpenUrl,
            section: section,
          ),
      ],
    );
  }
}
