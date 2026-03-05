import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../cubit/accounts_cubit.dart';
import '../cubit/accounts_state.dart';
import '../widgets/accounts_form_dialog.dart';
import '../widgets/accounts_pagination_bar.dart';
import '../widgets/accounts_table.dart';

class AccountsTableSection extends StatelessWidget {
  const AccountsTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        final cubit = context.read<AccountsCubit>();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(cubit: cubit, state: state),
              const SizedBox(height: 12),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              Expanded(child: AccountsTable(items: state.items)),
              const SizedBox(height: 12),
              AccountsPaginationBar(
                page: state.page,
                totalPages: state.totalPages,
                total: state.total,
                canPrev: state.canPrev,
                canNext: state.canNext,
                onPrev: cubit.prevPage,
                onNext: cubit.nextPage,
                pageSize: state.pageSize,
                onPageSizeChanged: cubit.setPageSize,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cubit, required this.state});

  final AccountsCubit cubit;
  final AccountsState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.menuAccounts,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                onChanged: cubit.searchChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: t.searchCodeOrName,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            DropdownButton<String?>(
              value: state.type,
              onChanged: (v) => cubit.typeFilterChanged(v),
              items: [
                DropdownMenuItem(value: null, child: Text(t.allTypes)),
                DropdownMenuItem(value: 'asset', child: Text(t.accountTypeAsset)),
                DropdownMenuItem(value: 'liability', child: Text(t.accountTypeLiability)),
                DropdownMenuItem(value: 'equity', child: Text(t.accountTypeEquity)),
                DropdownMenuItem(value: 'income', child: Text(t.accountTypeIncome)),
                DropdownMenuItem(value: 'expense', child: Text(t.accountTypeExpense)),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => cubit.toggleSort('code'),
              icon: const Icon(Icons.sort_by_alpha),
              label: Text(
                state.sortBy == 'code'
                    ? (state.ascending ? t.codeAsc : t.codeDesc)
                    : t.sortCode,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: context.read<AccountsCubit>(),
                    child: const AccountsFormDialog(),
                  ),
                );
                if (ok == true && context.mounted) {
                  cubit.load(resetPage: true);
                }
              },
              icon: const Icon(Icons.add),
              label: Text(t.addAccount),
            ),
          ],
        ),
      ],
    );
  }
}
