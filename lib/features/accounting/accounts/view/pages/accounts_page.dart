import 'package:flutter/material.dart';

import '../../../../../core/di/app_di.dart';
import '../widgets/accounts_workspace.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountsWorkspace(repo: AppDI.accountsRepo);
  }
}
