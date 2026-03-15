import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/leaves_cubit.dart';
import '../cubit/leaves_state.dart';

class LeavesSearchField extends StatelessWidget {
  const LeavesSearchField({super.key, required this.cubit});

  final LeavesCubit cubit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SizedBox(
      width: 280,
      child: TextField(
        onChanged: cubit.searchChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: t.searchEmployeeHint,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class LeavesStatusFilter extends StatelessWidget {
  const LeavesStatusFilter({
    super.key,
    required this.cubit,
    required this.state,
  });

  final LeavesCubit cubit;
  final LeavesState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return DropdownButton<String?>(
      value: state.status,
      onChanged: cubit.statusFilterChanged,
      items: [
        DropdownMenuItem(value: null, child: Text(t.all)),
        DropdownMenuItem(value: 'pending', child: Text(t.statusPending)),
        DropdownMenuItem(value: 'approved', child: Text(t.statusApproved)),
        DropdownMenuItem(value: 'rejected', child: Text(t.statusRejected)),
      ],
    );
  }
}

class LeavesTypeFilter extends StatelessWidget {
  const LeavesTypeFilter({
    super.key,
    required this.cubit,
    required this.state,
  });

  final LeavesCubit cubit;
  final LeavesState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return DropdownButton<String?>(
      value: state.type,
      onChanged: cubit.typeFilterChanged,
      items: [
        DropdownMenuItem(value: null, child: Text(t.allTypes)),
        DropdownMenuItem(value: 'annual', child: Text(t.leaveTypeAnnual)),
        DropdownMenuItem(value: 'sick', child: Text(t.leaveTypeSick)),
        DropdownMenuItem(value: 'unpaid', child: Text(t.leaveTypeUnpaid)),
        DropdownMenuItem(value: 'other', child: Text(t.leaveTypeOther)),
      ],
    );
  }
}

class LeavesDateFilterButton extends StatelessWidget {
  const LeavesDateFilterButton({
    super.key,
    required this.value,
    required this.emptyLabel,
    required this.icon,
    required this.onPicked,
  });

  final DateTime? value;
  final String emptyLabel;
  final IconData icon;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _pickDate(context),
      icon: Icon(icon),
      label: Text(value == null ? emptyLabel : _formatDate(value!)),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  String _formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
