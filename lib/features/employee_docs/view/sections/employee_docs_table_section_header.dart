import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/employee_docs_cubit.dart';
import '../cubit/employee_docs_state.dart';
import 'employee_docs_table_section_actions.dart';

class EmployeeDocsTableSectionHeader extends StatelessWidget {
  const EmployeeDocsTableSectionHeader({
    super.key,
    required this.cubit,
    required this.state,
  });

  final EmployeeDocsCubit cubit;
  final EmployeeDocsState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.menuEmployeeDocs,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _EmployeeDocsSearchField(cubit: cubit),
            _EmployeeDocsTypeFilter(cubit: cubit, state: state),
            _EmployeeDocsExpiryFilter(cubit: cubit, state: state),
            OutlinedButton.icon(
              onPressed: () => cubit.toggleSort('created_at'),
              icon: const Icon(Icons.schedule),
              label: Text(
                state.sortBy == 'created_at'
                    ? (state.ascending ? t.createdAsc : t.createdDesc)
                    : t.sortCreated,
              ),
            ),
            EmployeeDocsCreateAction(cubit: cubit),
          ],
        ),
      ],
    );
  }
}

class _EmployeeDocsSearchField extends StatelessWidget {
  const _EmployeeDocsSearchField({required this.cubit});

  final EmployeeDocsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SizedBox(
      width: 280,
      child: TextField(
        onChanged: cubit.searchChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: t.searchEmployeeHint,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _EmployeeDocsTypeFilter extends StatelessWidget {
  const _EmployeeDocsTypeFilter({
    required this.cubit,
    required this.state,
  });

  final EmployeeDocsCubit cubit;
  final EmployeeDocsState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return DropdownButton<String?>(
      value: state.docType,
      onChanged: cubit.docTypeChanged,
      items: [
        DropdownMenuItem(value: null, child: Text(t.allTypes)),
        DropdownMenuItem(value: 'id_card', child: Text(t.idCard)),
        DropdownMenuItem(value: 'passport', child: Text(t.passport)),
        const DropdownMenuItem(value: 'cv', child: Text('CV')),
        DropdownMenuItem(
          value: 'graduation_cert',
          child: Text(t.graduationCert),
        ),
        DropdownMenuItem(
          value: 'national_address',
          child: Text(t.nationalAddress),
        ),
        DropdownMenuItem(
          value: 'bank_iban_certificate',
          child: Text(t.bankIbanCertificate),
        ),
        DropdownMenuItem(
          value: 'salary_certificate',
          child: Text(t.salaryCertificate),
        ),
        DropdownMenuItem(
          value: 'salary_definition',
          child: Text(t.salaryDefinition),
        ),
        DropdownMenuItem(
          value: 'medical_insurance',
          child: Text(t.medicalInsurance),
        ),
        DropdownMenuItem(value: 'medical_report', child: Text(t.medicalReport)),
        DropdownMenuItem(
          value: 'residency',
          child: Text(t.residencyDocument),
        ),
        DropdownMenuItem(
          value: 'driving_license',
          child: Text(t.drivingLicense),
        ),
        DropdownMenuItem(value: 'offer_letter', child: Text(t.offerLetter)),
        DropdownMenuItem(value: 'contract', child: Text(t.contract)),
        DropdownMenuItem(value: 'other', child: Text(t.other)),
      ],
    );
  }
}

class _EmployeeDocsExpiryFilter extends StatelessWidget {
  const _EmployeeDocsExpiryFilter({
    required this.cubit,
    required this.state,
  });

  final EmployeeDocsCubit cubit;
  final EmployeeDocsState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return DropdownButton<String?>(
      value: state.expiryStatus,
      onChanged: cubit.expiryStatusChanged,
      items: [
        DropdownMenuItem(value: null, child: Text(t.allStatuses)),
        DropdownMenuItem(value: 'expired', child: Text(t.expired)),
        DropdownMenuItem(value: 'expiring_soon', child: Text(t.expiringSoon)),
        DropdownMenuItem(value: 'valid', child: Text(t.valid)),
        DropdownMenuItem(value: 'no_expiry', child: Text(t.noExpiry)),
      ],
    );
  }
}
