import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/employees_cubit.dart';
import '../cubit/employees_state.dart';
import '../widgets/employees_pagination_bar.dart';
import '../widgets/employees_table.dart';

class EmployeesTableSection extends StatelessWidget {
  const EmployeesTableSection({
    super.key,
    this.canEdit = true,
    this.canCreate = true,
  });

  final bool canEdit;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeesCubit, EmployeesState>(
      builder: (context, state) {
        final cubit = context.read<EmployeesCubit>();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                cubit: cubit,
                state: state,
                canCreate: canCreate,
              ),
              const SizedBox(height: 12),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: EmployeesTable(
                  items: state.items,
                  canOpenProfile: true,
                ),
              ),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.cubit,
    required this.state,
    required this.canCreate,
  });

  final EmployeesCubit cubit;
  final EmployeesState state;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.menuEmployees,
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
                  hintText: t.searchEmployeesHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            DropdownButton<String?>(
              value: state.status,
              onChanged: (v) => cubit.statusFilterChanged(v),
              items: [
                DropdownMenuItem(value: null, child: Text(t.all)),
                DropdownMenuItem(value: 'active', child: Text(t.active)),
                DropdownMenuItem(value: 'inactive', child: Text(t.inactive)),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => cubit.toggleSort('full_name'),
              icon: const Icon(Icons.sort_by_alpha),
              label: Text(
                state.sortBy == 'full_name'
                    ? (state.ascending ? t.nameAsc : t.nameDesc)
                    : t.sortName,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => cubit.toggleSort('created_at'),
              icon: const Icon(Icons.schedule),
              label: Text(
                state.sortBy == 'created_at'
                    ? (state.ascending ? t.createdAsc : t.createdDesc)
                    : t.sortCreated,
              ),
            ),
            if (canCreate)
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.employeeCreate),
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(t.addEmployee),
              ),
          ],
        ),
      ],
    );
  }
}
