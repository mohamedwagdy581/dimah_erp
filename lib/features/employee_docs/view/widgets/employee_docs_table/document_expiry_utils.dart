import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_document.dart';

enum ExpiryStatus { expired, expiringSoon, valid, noExpiry }

({int expired, int expiringSoon, int valid}) buildDocumentCounts(List<EmployeeDocument> docs) {
  var expired = 0;
  var expiringSoon = 0;
  var valid = 0;
  for (final doc in docs) {
    switch (expiryStatus(doc.expiresAt)) {
      case ExpiryStatus.expired:
        expired++;
      case ExpiryStatus.expiringSoon:
        expiringSoon++;
      case ExpiryStatus.valid:
        valid++;
      case ExpiryStatus.noExpiry:
        break;
    }
  }
  return (expired: expired, expiringSoon: expiringSoon, valid: valid);
}

ExpiryStatus expiryStatus(DateTime? expiresAt) {
  if (expiresAt == null) return ExpiryStatus.noExpiry;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expiry = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
  final days = expiry.difference(today).inDays;
  if (days < 0) return ExpiryStatus.expired;
  if (days <= 30) return ExpiryStatus.expiringSoon;
  return ExpiryStatus.valid;
}

bool matchesExpiryFilter(EmployeeDocument doc, String? expiryFilter) {
  if (expiryFilter == null) return true;
  final status = expiryStatus(doc.expiresAt);
  switch (expiryFilter) {
    case 'expired':
      return status == ExpiryStatus.expired;
    case 'expiring_soon':
      return status == ExpiryStatus.expiringSoon;
    case 'valid':
      return status == ExpiryStatus.valid;
    case 'no_expiry':
      return status == ExpiryStatus.noExpiry;
    default:
      return true;
  }
}

String statusLabel(AppLocalizations t, ExpiryStatus status) {
  switch (status) {
    case ExpiryStatus.expired:
      return t.expired;
    case ExpiryStatus.expiringSoon:
      return t.expiringSoon;
    case ExpiryStatus.valid:
      return t.valid;
    case ExpiryStatus.noExpiry:
      return t.noExpiry;
  }
}

Color statusColor(ThemeData theme, ExpiryStatus status) {
  switch (status) {
    case ExpiryStatus.expired:
      return theme.colorScheme.error;
    case ExpiryStatus.expiringSoon:
      return Colors.orange;
    case ExpiryStatus.valid:
      return Colors.green;
    case ExpiryStatus.noExpiry:
      return theme.colorScheme.primary;
  }
}
