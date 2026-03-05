abstract class ProfileRepo {
  Future<({String name, String phone})> getProfile();
  Future<void> updateProfile({required String name, required String phone});
}
