import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/reporting/report_layout.dart';
import '../../domain/models/employee_profile_details.dart';

ImageProvider? resolveEmployeePhotoProvider(String? rawValue) {
  final value = (rawValue ?? '').trim();
  if (value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri != null) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') {
      return NetworkImage(value);
    }
    if (scheme == 'file') {
      final filePath = uri.toFilePath();
      if (filePath.trim().isEmpty) return null;
      return FileImage(File(filePath));
    }
  }

  return FileImage(File(value));
}

String formatEmployeeDate(DateTime? date) {
  if (date == null) return '-';
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String formatEmployeeMoney(double? value) {
  if (value == null) return '-';
  return value.toStringAsFixed(2);
}

double totalEmployeeCompensation(EmployeeProfileDetails profile) {
  return (profile.basicSalary ?? 0) +
      (profile.housingAllowance ?? 0) +
      (profile.transportAllowance ?? 0) +
      (profile.otherAllowance ?? 0);
}

bool isMostlyArabicText(String value) => ReportLayout.isMostlyArabic(value);
