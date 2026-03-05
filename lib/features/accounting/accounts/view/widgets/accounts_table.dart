import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/models/account.dart';

class AccountsTable extends StatelessWidget {
  const AccountsTable({super.key, required this.items});

  final List<Account> items;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text(t.noAccountsFound)),
        ),
      );
    }

    return Card(
      child: LayoutBuilder(
        builder: (context, c) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: c.maxWidth),
              child: DataTable(
                columns: [
                  DataColumn(label: Text(t.code)),
                  DataColumn(label: Text(t.name)),
                  DataColumn(label: Text(t.type)),
                  DataColumn(label: Text(t.status)),
                ],
                rows: items.map((a) {
                  return DataRow(
                    cells: [
                      DataCell(Text(a.code)),
                      DataCell(Text(a.name)),
                      DataCell(Text(_accountTypeLabel(t, a.type))),
                      DataCell(Text(a.isActive ? t.active : t.inactive)),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  String _accountTypeLabel(AppLocalizations t, String raw) {
    switch (raw) {
      case 'asset':
        return t.accountTypeAsset;
      case 'liability':
        return t.accountTypeLiability;
      case 'equity':
        return t.accountTypeEquity;
      case 'income':
        return t.accountTypeIncome;
      case 'expense':
        return t.accountTypeExpense;
      default:
        return raw;
    }
  }
}
