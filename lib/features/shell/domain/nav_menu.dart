import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import 'nav_item.dart';

part 'nav_menu_items_part.dart';
part 'nav_menu_search_part.dart';

class NavMenu {
  static List<NavItem> forRole(String role) {
    return _allNavItems
        .where(
          (item) =>
              item.allowedRoles.contains(role) &&
              !(role == 'hr' &&
                  [AppRoutes.jobTitles, AppRoutes.leaves].contains(item.path)),
        )
        .map(
          (item) => role == 'hr' && item.path == AppRoutes.departments
              ? NavItem(
                  path: item.path,
                  label: 'Departments & job titles',
                  icon: item.icon,
                  allowedRoles: item.allowedRoles,
                  section: item.section,
                  keywords: [...item.keywords, 'job titles', 'المسميات'],
                )
              : item,
        )
        .toList();
  }

  static List<NavItem> searchableForRole(String role) {
    return [
      ...forRole(role),
      if (role == 'hr')
        ..._allNavItems.where((item) => item.path == AppRoutes.jobTitles),
      ..._searchOnlyNavItems.where((item) => item.allowedRoles.contains(role)),
    ];
  }
}
