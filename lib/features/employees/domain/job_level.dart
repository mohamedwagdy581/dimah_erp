String jobLevelLabel(String? level, {required bool isArabic}) =>
    switch (level) {
      'junior' => isArabic ? 'جونيور' : 'Junior',
      'mid' => isArabic ? 'متوسط' : 'Mid-level',
      'senior' => isArabic ? 'سينيور' : 'Senior',
      _ => isArabic ? 'غير محدد' : 'Not specified',
    };
