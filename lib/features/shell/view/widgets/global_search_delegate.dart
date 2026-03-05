import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/nav_i18n.dart';
import '../../domain/nav_item.dart';

class GlobalSearchDelegate extends SearchDelegate<NavItem?> {
  GlobalSearchDelegate({required this.items});

  final List<NavItem> items;

  @override
  String? get searchFieldLabel =>
      PlatformDispatcher.instance.locale.languageCode == 'ar'
      ? 'ابحث في النظام...'
      : 'Search in system...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: AppLocalizations.of(context)!.clear,
          onPressed: () => query = '',
          icon: const Icon(Icons.close),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.back,
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _ResultsList(
      items: _filtered(items, query),
      onTap: (item) {
        close(context, item);
        context.go(item.path);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _ResultsList(
      items: _filtered(items, query),
      onTap: (item) {
        close(context, item);
        context.go(item.path);
      },
    );
  }

  List<NavItem> _filtered(List<NavItem> all, String q) {
    final needle = q.trim().toLowerCase();
    if (needle.isEmpty) return all;

    return all.where((item) {
      final label = item.label.toLowerCase();
      final path = item.path.toLowerCase();
      final section = item.section.toLowerCase();
      if (label.contains(needle) ||
          path.contains(needle) ||
          section.contains(needle)) {
        return true;
      }

      for (final k in item.keywords) {
        if (k.toLowerCase().contains(needle)) return true;
      }
      return false;
    }).toList();
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.items, required this.onTap});

  final List<NavItem> items;
  final ValueChanged<NavItem> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noResults),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = items[i];
        final label = localizedNavLabel(context, item);
        final section = localizedNavSection(context, item);

        return ListTile(
          leading: Icon(item.icon),
          title: Text(label),
          subtitle: Text('$section • ${item.path}'),
          onTap: () => onTap(item),
        );
      },
    );
  }
}
