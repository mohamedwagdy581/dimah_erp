class Validators {
  static String? required(String? v, {String msg = 'Required'}) {
    if (v == null || v.trim().isEmpty) return msg;
    return null;
  }

  static String? minLen(String? v, int n, {String? msg}) {
    if (v == null) return msg ?? 'Too short';
    if (v.trim().length < n) return msg ?? 'Minimum $n characters';
    return null;
  }

  static String? phone(String? v, {String msg = 'Invalid phone'}) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final ok = RegExp(r'^[0-9+\-\s]{7,20}$').hasMatch(v.trim());
    return ok ? null : msg;
  }
}
