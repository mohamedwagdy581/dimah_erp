import '../models/account.dart';

abstract class AccountsRepo {
  Future<({List<Account> items, int total})> fetchAccounts({
    required int page,
    required int pageSize,
    String? search,
    String? type,
    bool? isActive,
    String sortBy,
    bool ascending,
  });

  Future<void> createAccount({
    required String code,
    required String name,
    required String type,
    bool isActive = true,
    bool isCash = false,
  });
  Future<void> updateAccount({
    required String id,
    required String code,
    required String name,
    required String type,
    required bool isActive,
    bool isCash = false,
  });
}
