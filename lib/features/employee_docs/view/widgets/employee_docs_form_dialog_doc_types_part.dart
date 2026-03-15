part of 'employee_docs_form_dialog.dart';

extension _EmployeeDocsFormDialogDocTypes on _EmployeeDocsFormDialogState {
  List<({String title, List<({String value, String label})> items})>
      _docTypeGroups(AppLocalizations t) {
    return [
      (
        title: t.identityDocuments,
        items: [
          (value: 'id_card', label: t.idCard),
          (value: 'passport', label: t.passport),
          (value: 'national_address', label: t.nationalAddress),
          (value: 'residency', label: t.residencyDocument),
          (value: 'driving_license', label: t.drivingLicense),
        ],
      ),
      (
        title: t.educationAndCareerDocuments,
        items: [
          (value: 'cv', label: 'CV'),
          (value: 'graduation_cert', label: t.graduationCert),
          (value: 'offer_letter', label: t.offerLetter),
          (value: 'contract', label: t.contract),
        ],
      ),
      (
        title: t.financialDocuments,
        items: [
          (value: 'bank_iban_certificate', label: t.bankIbanCertificate),
          (value: 'salary_certificate', label: t.salaryCertificate),
          (value: 'salary_definition', label: t.salaryDefinition),
        ],
      ),
      (
        title: t.medicalAndInsuranceDocuments,
        items: [
          (value: 'medical_insurance', label: t.medicalInsurance),
          (value: 'medical_report', label: t.medicalReport),
        ],
      ),
      (title: t.otherDocuments, items: [(value: 'other', label: t.other)]),
    ];
  }

  List<DropdownMenuItem<String>> _docTypeItems(AppLocalizations t) {
    return [
      for (final group in _docTypeGroups(t)) ...[
        DropdownMenuItem<String>(
          enabled: false,
          child: Text(
            group.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...group.items.map(
          (item) => DropdownMenuItem<String>(
            value: item.value,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 12),
              child: Text(item.label),
            ),
          ),
        ),
      ],
    ];
  }

  String _formatDate(DateTime? value, String fallback) {
    if (value == null) return fallback;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _pickIssued() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _issuedAt ?? now,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null) setState(() => _issuedAt = picked);
  }

  Future<void> _pickExpires() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? _issuedAt ?? now,
      firstDate: _issuedAt ?? DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 10, 12, 31),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }
}
