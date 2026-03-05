abstract class AuthRepo {
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> changePassword(String newPassword);
  bool get isSignedIn;
}
