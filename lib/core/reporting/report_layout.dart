class ReportLayout {
  const ReportLayout._();

  static bool isMostlyArabic(String value) {
    if (value.trim().isEmpty) return false;
    final arabic = RegExp(r'[\u0600-\u06FF]');
    final latin = RegExp(r'[A-Za-z]');
    final a = arabic.allMatches(value).length;
    final l = latin.allMatches(value).length;
    return a > 0 && a >= l;
  }

  static List<T> orderedByLocale<T>(List<T> values, {required bool isArabic}) {
    return isArabic ? values.reversed.toList() : values;
  }

  static String htmlDirectionFor(bool isArabicText) {
    return isArabicText ? 'rtl' : 'ltr';
  }

  static String htmlAlignFor({
    required bool pageIsArabic,
    required String value,
  }) {
    if (!pageIsArabic) return 'left';
    return isMostlyArabic(value) ? 'right' : 'left';
  }
}
