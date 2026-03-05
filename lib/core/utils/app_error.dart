class AppError {
  static bool isTransient(Object e) {
    final msg = e.toString();
    return msg.contains('ClientException') || msg.contains('connection closed');
  }

  static String message(Object e) => e.toString();
}
