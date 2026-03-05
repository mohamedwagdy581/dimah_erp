import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/departments_cubit.dart';
import '../cubit/departments_state.dart';
import '../widgets/department_form_dialog.dart';
import '../widgets/department_table.dart';

class DepartmentsTableSection extends StatelessWidget {
  const DepartmentsTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<DepartmentsCubit, DepartmentsState>(
      builder: (context, state) {
        final cubit = context.read<DepartmentsCubit>();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _Header(cubit: cubit, state: state, t: t),
              const SizedBox(height: 12),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: DepartmentTable(
                  items: state.items,
                  onEdit: (d) async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: context.read<DepartmentsCubit>(),
                        child: DepartmentFormDialog(edit: d),
                      ),
                    );
                    if (ok == true && context.mounted) {
                      cubit.load();
                    }
                  },
                  onToggleActive: (d) {
                    cubit.update(
                      id: d.id,
                      name: d.name,
                      code: d.code,
                      description: d.description,
                      isActive: !d.isActive,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cubit, required this.state, required this.t});

  final DepartmentsCubit cubit;
  final DepartmentsState state;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.menuDepartments,
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
                  hintText: t.searchNameOrCodeHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            DropdownButton<bool?>(
              value: state.isActive,
              onChanged: (v) => cubit.activeFilterChanged(v),
              items: [
                DropdownMenuItem(value: null, child: Text(t.all)),
                DropdownMenuItem(value: true, child: Text(t.active)),
                DropdownMenuItem(value: false, child: Text(t.inactive)),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => cubit.toggleSort('name'),
              icon: const Icon(Icons.sort_by_alpha),
              label: Text(
                state.sortBy == 'name'
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
            ElevatedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: context.read<DepartmentsCubit>(),
                    child: const DepartmentFormDialog(),
                  ),
                );
                if (ok == true && context.mounted) {
                  cubit.load(resetPage: true);
                }
              },
              icon: const Icon(Icons.add),
              label: Text(t.addDepartment),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final count = await cubit.autoAssignManagers();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        count == 0
                            ? t.noManagerChangesNeeded
                            : t.assignedUpdatedManagers(count),
                      ),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.autoAssignFailed(e.toString()))),
                  );
                }
              },
              icon: const Icon(Icons.auto_fix_high_outlined),
              label: Text(t.autoAssignManagers),
            ),
          ],
        ),
      ],
    );
  }
}
