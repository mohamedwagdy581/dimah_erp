part of 'employee_repo_impl.dart';

mixin _EmployeesRepoExpirySettingsMixin on _EmployeesRepoProfileUpdateMixin {
  @override
  Future<ExpiryAlertSettings> fetchExpiryAlertSettings() async {
    final tenantId = await _tenantId();
    final row = await _client
        .from('expiry_alert_settings')
        .select(
          'contract_alert_days, residency_alert_days, insurance_alert_days, documents_alert_days',
        )
        .eq('tenant_id', tenantId)
        .maybeSingle();

    if (row == null) {
      return const ExpiryAlertSettings(
        contractAlertDays: 90,
        residencyAlertDays: 90,
        insuranceAlertDays: 90,
        documentsAlertDays: 90,
      );
    }

    int asInt(dynamic value, int fallback) =>
        value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;

    return ExpiryAlertSettings(
      contractAlertDays: asInt(row['contract_alert_days'], 90),
      residencyAlertDays: asInt(row['residency_alert_days'], 90),
      insuranceAlertDays: asInt(row['insurance_alert_days'], 90),
      documentsAlertDays: asInt(row['documents_alert_days'], 90),
    );
  }

  @override
  Future<void> upsertExpiryAlertSettings(ExpiryAlertSettings settings) async {
    final tenantId = await _tenantId();
    try {
      await _client.rpc(
        'upsert_expiry_alert_settings',
        params: {
          'p_tenant_id': tenantId,
          'p_contract_alert_days': settings.contractAlertDays,
          'p_residency_alert_days': settings.residencyAlertDays,
          'p_insurance_alert_days': settings.insuranceAlertDays,
          'p_documents_alert_days': settings.documentsAlertDays,
        },
      );
    } catch (_) {
      await _client.from('expiry_alert_settings').upsert({
        'tenant_id': tenantId,
        'contract_alert_days': settings.contractAlertDays,
        'residency_alert_days': settings.residencyAlertDays,
        'insurance_alert_days': settings.insuranceAlertDays,
        'documents_alert_days': settings.documentsAlertDays,
      });
    }
  }
}
