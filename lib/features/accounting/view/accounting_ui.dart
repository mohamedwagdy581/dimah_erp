import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../payroll/view/widgets/payroll_format.dart';

const accountingPurple = Color(0xFF8855BF);
const accountingInk = Color(0xFF19144F);
const accountingBorder = Color(0xFFE8DFFA);
String accountingText(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

/// Balance on the account's normal side; abnormal (negative) in parentheses.
String accountingBalance(num v) =>
    v < 0 ? '(${payrollMoney(v.abs())})' : payrollMoney(v);

/// Friendly bilingual text for errors from the accounting server functions.
String accountingErrorText(BuildContext context, Object error) {
  String tr(String ar, String en) => accountingText(context, ar, en);
  final message = error is PostgrestException ? error.message : '$error';
  if (error is PostgrestException && error.code == '42501') {
    return tr(
      'ليست لديك صلاحية لهذا الإجراء.',
      "You don't have permission for this action.",
    );
  }
  if (message.contains('Debits must equal credits')) {
    return tr('القيد غير متوازن.', 'Entry is not balanced.');
  }
  if (message.contains('inactive account')) {
    return tr(
      'القيد يستخدم حسابًا غير نشط.',
      'Entry uses an inactive account.',
    );
  }
  if (error is PostgrestException) {
    return tr(
      'رفض الخادم هذا الإجراء. حدّث الصفحة ثم أعد المحاولة.',
      'The server rejected this action. Refresh the page and try again.',
    );
  }
  return tr(
    'تعذّر إكمال العملية. تحقق من الاتصال ثم أعد المحاولة.',
    'Could not complete the action. Check your connection and retry.',
  );
}

// Material (not a decorated Container) so ListTiles inside can paint ink.
Widget accountingPanel(Widget child) => Material(
  color: Colors.white,
  shape: RoundedRectangleBorder(
    side: const BorderSide(color: accountingBorder),
    borderRadius: BorderRadius.circular(10),
  ),
  clipBehavior: Clip.antiAlias,
  child: Padding(padding: const EdgeInsets.all(18), child: child),
);

/// Full-height page body that scrolls with a fixed height on small screens,
/// so `Expanded` tables never get zero or negative height.
Widget accountingResponsivePage(Widget content, {double minHeight = 760}) =>
    LayoutBuilder(
      builder: (context, box) {
        if (box.maxHeight >= 650 && box.maxWidth >= 600) return content;
        return SingleChildScrollView(
          child: SizedBox(
            width: box.maxWidth,
            height: math.max(minHeight, box.maxHeight),
            child: content,
          ),
        );
      },
    );

InputDecoration accountingInput(String label, {String? hint}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: accountingBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    );
Widget accountingHeading(String title, String subtitle) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      title,
      style: const TextStyle(
        color: accountingInk,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    ),
    const SizedBox(height: 5),
    Text(
      subtitle,
      style: const TextStyle(color: Color(0xFF77709A), fontSize: 14),
    ),
  ],
);
Widget accountingBadge(String text, {bool active = true}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: active ? const Color(0xFFF0E5FF) : const Color(0xFFF0F0F3),
    borderRadius: BorderRadius.circular(7),
  ),
  child: Text(
    text,
    style: TextStyle(
      color: active ? accountingPurple : const Color(0xFF77709A),
      fontWeight: FontWeight.w600,
    ),
  ),
);

/// Shared fixed columns keep headers and values aligned, with visible desktop scrollbars.
class AccountingTable extends StatefulWidget {
  const AccountingTable({
    super.key,
    required this.headings,
    required this.widths,
    required this.rows,
    this.minimumWidth = 700,
  });
  final List<String> headings;
  final List<int> widths;
  final List<List<Widget>> rows;
  final double minimumWidth;
  @override
  State<AccountingTable> createState() => _AccountingTableState();
}

class _AccountingTableState extends State<AccountingTable> {
  final horizontal = ScrollController(), vertical = ScrollController();
  @override
  void dispose() {
    horizontal.dispose();
    vertical.dispose();
    super.dispose();
  }

  Widget row(List<Widget> cells, {bool header = false}) => Container(
    constraints: const BoxConstraints(minHeight: 52),
    decoration: BoxDecoration(
      color: header ? const Color(0xFFF6F2FC) : Colors.white,
      border: const Border(bottom: BorderSide(color: accountingBorder)),
    ),
    child: Row(
      children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: widget.widths[i],
            child: Padding(padding: const EdgeInsets.all(10), child: cells[i]),
          ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Container(
      decoration: BoxDecoration(
        border: Border.all(color: accountingBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: vertical,
        thumbVisibility: true,
        interactive: true,
        notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
        child: Scrollbar(
          controller: horizontal,
          thumbVisibility: true,
          interactive: true,
          notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: horizontal,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: math.max(widget.minimumWidth, box.maxWidth - 2),
              height: math.max(0, box.maxHeight - 2),
              child: Column(
                children: [
                  row([
                    for (final h in widget.headings)
                      Text(
                        h,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: accountingInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ], header: true),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: vertical,
                      child: Column(
                        children: [for (final cells in widget.rows) row(cells)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
