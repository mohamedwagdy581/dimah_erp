import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/job_titles_cubit.dart';
import '../cubit/job_titles_state.dart';
import '../widgets/job_title_form_dialog.dart';
import '../widgets/job_titles_table.dart';

class JobTitlesTableSection extends StatelessWidget {
  const JobTitlesTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<JobTitlesCubit, JobTitlesState>(
      builder: (context, state) {
        final cubit = context.read<JobTitlesCubit>();

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
                child: JobTitlesTable(
                  items: state.items,
                  onEdit: (jt) async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => JobTitleFormDialog(edit: jt),
                    );
                    if (ok == true && context.mounted) {
                      cubit.load();
                    }
                  },
                  onToggleActive: (jt) {
                    cubit.update(
                      id: jt.id,
                      name: jt.name,
                      code: jt.code,
                      description: jt.description,
                      level: jt.level,
                      isActive: !jt.isActive,
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

  final JobTitlesCubit cubit;
  final JobTitlesState state;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.menuJobTitles,
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
              onPressed: () => cubit.toggleSort('level'),
              icon: const Icon(Icons.leaderboard_outlined),
              label: Text(
                state.sortBy == 'level'
                    ? (state.ascending ? t.levelAsc : t.levelDesc)
                    : t.sortLevel,
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
                  builder: (_) => const JobTitleFormDialog(),
                );
                if (ok == true && context.mounted) {
                  cubit.load(resetPage: true);
                }
              },
              icon: const Icon(Icons.add),
              label: Text(t.addJobTitle),
            ),
          ],
        ),
      ],
    );
  }
}
