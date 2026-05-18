import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/settlements_cubit.dart';
import '../cubit/settlements_state.dart';
import '../widgets/employees_pagination_bar.dart';
import '../widgets/settlements_table.dart';

class SettlementsTableSection extends StatelessWidget {
  const SettlementsTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettlementsCubit, SettlementsState>(
      builder: (context, state) {
        final cubit = context.read<SettlementsCubit>();
        final t = AppLocalizations.of(context)!;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.menuSettlements,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 320,
                child: TextField(
                  onChanged: cubit.searchChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: t.searchSettlementsHint,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t.settlementsTabHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              Expanded(child: SettlementsTable(items: state.items)),
              const SizedBox(height: 12),
              EmployeesPaginationBar(
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
