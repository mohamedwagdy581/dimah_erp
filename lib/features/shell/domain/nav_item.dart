import 'package:flutter/material.dart';

class NavItem {
  const NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.allowedRoles,
    required this.section,
    required this.keywords,
  });

  final String path;
  final String label;
  final IconData icon;
  final List<String> allowedRoles;
  final String section;
  final List<String> keywords;
}
