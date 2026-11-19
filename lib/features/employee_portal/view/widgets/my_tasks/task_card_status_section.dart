import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/app_localizations.dart';

class TaskCardStatusSection extends StatelessWidget {
  const TaskCardStatusSection({
    super.key,
    required this.status,
    required this.progress,
    required this.onStatusChanged,
    required this.onProgressChanged,
    this.responsive = false,
  });

  final String status;
  final int progress;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<int> onProgressChanged;
  final bool responsive;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = responsive && constraints.maxWidth < 420;
        final dropdown = DropdownButtonFormField<String>(
          initialValue: status,
          isExpanded: responsive,
          decoration: InputDecoration(
            labelText: t.status,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            DropdownMenuItem(value: 'todo', child: Text(t.statusTodo)),
            DropdownMenuItem(
              value: 'in_progress',
              child: Text(t.statusInProgress),
            ),
            DropdownMenuItem(value: 'done', child: Text(t.statusDone)),
          ],
          onChanged: (value) => onStatusChanged(value ?? status),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (narrow) ...[
              dropdown,
              const SizedBox(height: 12),
              Text(t.progressLabel(progress)),
            ] else
              Row(
                children: [
                  Expanded(child: dropdown),
                  const SizedBox(width: 10),
                  SizedBox(width: 160, child: Text(t.progressLabel(progress))),
                ],
              ),
            Slider(
              value: progress.toDouble().clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 20,
              label: '$progress%',
              onChanged: (_) {},
              onChangeEnd: (value) => onProgressChanged(value.round()),
            ),
          ],
        );
      },
    );
  }
}
