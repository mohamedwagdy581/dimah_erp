import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import 'nav_item.dart';

part 'nav_menu_items_part.dart';
part 'nav_menu_search_part.dart';

class NavMenu {
  static List<NavItem> forRole(String role) {
    return _allNavItems.where((item) => item.allowedRoles.contains(role)).toList();
  }

  static List<NavItem> searchableForRole(String role) {
    return [
      ...forRole(role),
      ..._searchOnlyNavItems.where((item) => item.allowedRoles.contains(role)),
    ];
  }
}
