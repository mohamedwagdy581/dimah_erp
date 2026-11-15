import 'package:flutter/material.dart';

/// Keeps the controls, table and pager together like the other HR pages.
class PayrollListDesign extends StatelessWidget {
  const PayrollListDesign({
    super.key,
    required this.header,
    required this.table,
    required this.pagination,
    required this.status,
  });
  final Widget header;
  final Widget table;
  final Widget pagination;
  final Widget status;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAE3F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 18),
          status,
          table,
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFEFEAF5)),
          Padding(padding: const EdgeInsets.only(top: 14), child: pagination),
        ],
      ),
    ),
  );
}
