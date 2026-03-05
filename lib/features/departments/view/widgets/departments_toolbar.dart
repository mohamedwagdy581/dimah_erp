import 'package:flutter/material.dart';

class DepartmentsToolbar extends StatelessWidget {
  const DepartmentsToolbar({
    super.key,
    required this.search,
    required this.isActive,
    required this.onSearchChanged,
    required this.onSearchSubmit,
    required this.onActiveFilterChanged,
    required this.onAddPressed,
    required this.onSortByName,
    required this.onSortByCreated,
  });

  final String search;
  final bool? isActive;

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchSubmit;
  final ValueChanged<bool?> onActiveFilterChanged;

  final VoidCallback onAddPressed;

  final VoidCallback onSortByName;
  final VoidCallback onSortByCreated;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Departments',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 12),

        // Search
        SizedBox(
          width: 260,
          child: TextField(
            onChanged: onSearchChanged,
            onSubmitted: (_) => onSearchSubmit(),
            controller: TextEditingController(text: search)
              ..selection = TextSelection.collapsed(offset: search.length),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search name or code...',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Active filter
        DropdownButton<bool?>(
          value: isActive,
          onChanged: onActiveFilterChanged,
          items: const [
            DropdownMenuItem(value: null, child: Text('All')),
            DropdownMenuItem(value: true, child: Text('Active')),
            DropdownMenuItem(value: false, child: Text('Inactive')),
          ],
        ),
        const SizedBox(width: 10),

        // Sort quick actions
        OutlinedButton.icon(
          onPressed: onSortByName,
          icon: const Icon(Icons.sort_by_alpha),
          label: const Text('Sort Name'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onSortByCreated,
          icon: const Icon(Icons.schedule),
          label: const Text('Sort Created'),
        ),

        const Spacer(),

        ElevatedButton.icon(
          onPressed: onAddPressed,
          icon: const Icon(Icons.add),
          label: const Text('Add Department'),
        ),
      ],
    );
  }
}
