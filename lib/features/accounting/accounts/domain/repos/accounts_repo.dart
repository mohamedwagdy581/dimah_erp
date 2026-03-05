import '../models/account.dart';

abstract class AccountsRepo {
  Future<({List<Account> items, int total})> fetchAccounts({
    required int page,
    required int pageSize,
    String? search,
    String? type,
    String sortBy,
    bool ascending,
  });

  Future<void> createAccount({
    required String code,
    required String name,
    required String type,
  });
}
