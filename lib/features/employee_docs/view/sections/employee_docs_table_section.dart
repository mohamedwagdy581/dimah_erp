import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/employee_docs_cubit.dart';
import '../cubit/employee_docs_state.dart';
import '../widgets/employee_docs_form_dialog.dart';
import '../widgets/employee_docs_pagination_bar.dart';
import '../widgets/employee_docs_table.dart';

class EmployeeDocsTableSection extends StatelessWidget {
  const EmployeeDocsTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<EmployeeDocsCubit, EmployeeDocsState>(
      builder: (context, state) {
        final cubit = context.read<EmployeeDocsCubit>();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(cubit: cubit, state: state, t: t),
              const SizedBox(height: 12),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              const Expanded(child: EmployeeDocsTable()),
              const SizedBox(height: 12),
              EmployeeDocsPaginationBar(
                page: state.page,
                totalPages: state.totalPages,
                total: state.total,
                canPrev: state.canPrev,
                canNext: state.canNext,
                onPrev: cubit.prevPage,
                onNext: cubit.nextPage,
                pageSize: state.pageSize,
                onPageSizeChanged: cubit.setPageSize,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cubit, required this.state, required this.t});

  final EmployeeDocsCubit cubit;
  final EmployeeDocsState state;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
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
            SizedBox(
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
            ),
            DropdownButton<String?>(
              value: state.docType,
              onChanged: (v) => cubit.docTypeChanged(v),
              items: [
                DropdownMenuItem(value: null, child: Text(t.allTypes)),
                DropdownMenuItem(value: 'id_card', child: Text(t.idCard)),
                DropdownMenuItem(value: 'passport', child: Text(t.passport)),
                DropdownMenuItem(value: 'cv', child: const Text('CV')),
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
                DropdownMenuItem(
                  value: 'medical_report',
                  child: Text(t.medicalReport),
                ),
                DropdownMenuItem(
                  value: 'residency',
                  child: Text(t.residencyDocument),
                ),
                DropdownMenuItem(
                  value: 'driving_license',
                  child: Text(t.drivingLicense),
                ),
                DropdownMenuItem(
                  value: 'offer_letter',
                  child: Text(t.offerLetter),
                ),
                DropdownMenuItem(value: 'contract', child: Text(t.contract)),
                DropdownMenuItem(value: 'other', child: Text(t.other)),
              ],
            ),
            DropdownButton<String?>(
              value: state.expiryStatus,
              onChanged: cubit.expiryStatusChanged,
              items: [
                DropdownMenuItem(value: null, child: Text(t.allStatuses)),
                DropdownMenuItem(value: 'expired', child: Text(t.expired)),
                DropdownMenuItem(
                  value: 'expiring_soon',
                  child: Text(t.expiringSoon),
                ),
                DropdownMenuItem(value: 'valid', child: Text(t.valid)),
                DropdownMenuItem(value: 'no_expiry', child: Text(t.noExpiry)),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => cubit.toggleSort('created_at'),
              icon: const Icon(Icons.schedule),
              label: Text(
                state.sortBy == 'created_at'
                    ? (state.ascending ? t.createdAsc : t.createdDesc)
                    : t.sortCreated,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: context.read<EmployeeDocsCubit>(),
                    child: const EmployeeDocsFormDialog(),
                  ),
                );
                if (ok == true && context.mounted) {
                  cubit.load(resetPage: true);
                }
              },
              icon: const Icon(Icons.add),
              label: Text(t.addDocument),
            ),
          ],
        ),
      ],
    );
  }
}
