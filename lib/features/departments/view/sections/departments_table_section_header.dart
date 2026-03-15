import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/departments_cubit.dart';
import '../cubit/departments_state.dart';
import '../widgets/department_form_dialog.dart';

class DepartmentsTableSectionHeader extends StatelessWidget {
  const DepartmentsTableSectionHeader({
    super.key,
    required this.cubit,
    required this.state,
  });

  final DepartmentsCubit cubit;
  final DepartmentsState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
            _DepartmentsSearchField(cubit: cubit),
            _DepartmentsActiveFilter(cubit: cubit, state: state),
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
            _AddDepartmentButton(cubit: cubit),
            _AutoAssignManagersButton(cubit: cubit),
          ],
        ),
      ],
    );
  }
}

class _DepartmentsSearchField extends StatelessWidget {
  const _DepartmentsSearchField({required this.cubit});

  final DepartmentsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SizedBox(
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
    );
  }
}

class _DepartmentsActiveFilter extends StatelessWidget {
  const _DepartmentsActiveFilter({
    required this.cubit,
    required this.state,
  });

  final DepartmentsCubit cubit;
  final DepartmentsState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return DropdownButton<bool?>(
      value: state.isActive,
      onChanged: cubit.activeFilterChanged,
      items: [
        DropdownMenuItem(value: null, child: Text(t.all)),
        DropdownMenuItem(value: true, child: Text(t.active)),
        DropdownMenuItem(value: false, child: Text(t.inactive)),
      ],
    );
  }
}

class _AddDepartmentButton extends StatelessWidget {
  const _AddDepartmentButton({required this.cubit});

  final DepartmentsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ElevatedButton.icon(
      onPressed: () => _openCreateDialog(context),
      icon: const Icon(Icons.add),
      label: Text(t.addDepartment),
    );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
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
  }
}

class _AutoAssignManagersButton extends StatelessWidget {
  const _AutoAssignManagersButton({required this.cubit});

  final DepartmentsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: () => _run(context),
      icon: const Icon(Icons.auto_fix_high_outlined),
      label: Text(t.autoAssignManagers),
    );
  }

  Future<void> _run(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    try {
      final count = await cubit.autoAssignManagers();
      if (!context.mounted) {
        return;
      }
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
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.autoAssignFailed(e.toString()))));
    }
  }
}
