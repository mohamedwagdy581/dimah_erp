import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/approval_request.dart';
import 'approval_actions_cell.dart';
import 'approval_status_chip.dart';
import 'approvals_table_utils.dart';

class ResponsiveApprovalsTable extends StatefulWidget {
  const ResponsiveApprovalsTable({
    super.key,
    required this.items,
    required this.actorRole,
    required this.showActions,
    this.onApprove,
    this.onReject,
    this.onViewDetails,
  });
  final List<ApprovalRequest> items;
  final String actorRole;
  final bool showActions;
  final ValueChanged<String>? onApprove, onReject;
  final ValueChanged<ApprovalRequest>? onViewDetails;
  @override
  State<ResponsiveApprovalsTable> createState() =>
      _ResponsiveApprovalsTableState();
}

class _ResponsiveApprovalsTableState extends State<ResponsiveApprovalsTable> {
  final horizontal = ScrollController(), vertical = ScrollController();
  @override
  void dispose() {
    horizontal.dispose();
    vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    Widget cell(Widget child, {bool heading = false, bool centered = false}) =>
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: heading ? 18 : 14,
          ),
          child: Align(
            alignment: centered
                ? Alignment.center
                : AlignmentDirectional.centerStart,
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: heading ? 13 : 14,
                height: 1.5,
                fontWeight: heading ? FontWeight.w700 : FontWeight.w400,
                color: const Color(0xFF242052),
              ),
              child: child,
            ),
          ),
        );
    final labels = [
      t.employee,
      t.type,
      t.status,
      t.pendingWith,
      t.created,
      t.details,
      if (widget.showActions) t.actions,
    ];
    final widths = [
      250.0,
      155.0,
      160.0,
      180.0,
      135.0,
      154.0,
      if (widget.showActions) 270.0,
    ];
    final minimum = widths.fold<double>(0, (a, b) => a + b);
    return LayoutBuilder(
      builder: (context, box) {
        final width = math.max(minimum, box.maxWidth - 12);
        final columns = {
          for (var i = 0; i < widths.length; i++)
            i: FixedColumnWidth(widths[i] * width / minimum),
        };
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5DDF2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Scrollbar(
            controller: vertical,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
            child: Scrollbar(
              controller: horizontal,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14, right: 12),
                child: SingleChildScrollView(
                  key: const ValueKey('approvals-horizontal-scroll'),
                  controller: horizontal,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    child: Column(
                      children: [
                        Table(
                          columnWidths: columns,
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF5F1FA),
                              ),
                              children: [
                                for (
                                  var index = 0;
                                  index < labels.length;
                                  index++
                                )
                                  cell(
                                    Text(labels[index]),
                                    heading: true,
                                    centered: index == 5,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            key: const ValueKey('approvals-vertical-scroll'),
                            controller: vertical,
                            child: Table(
                              columnWidths: columns,
                              defaultVerticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              border: const TableBorder(
                                horizontalInside: BorderSide(
                                  color: Color(0xFFECE5F4),
                                ),
                              ),
                              children: [
                                for (var i = 0; i < widget.items.length; i++)
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: i.isEven
                                          ? Colors.white
                                          : const Color(0xFFFCFAFF),
                                    ),
                                    children: [
                                      cell(
                                        SelectableText(
                                          widget.items[i].employeeName,
                                        ),
                                      ),
                                      cell(
                                        Text(
                                          approvalTypeLabel(
                                            t,
                                            widget.items[i].requestType,
                                          ),
                                        ),
                                      ),
                                      cell(
                                        ApprovalStatusChip(
                                          status: widget.items[i].status,
                                          t: t,
                                        ),
                                      ),
                                      cell(
                                        Text(
                                          approvalPendingWithLabel(
                                            t,
                                            widget.items[i],
                                          ),
                                        ),
                                      ),
                                      cell(
                                        Text(
                                          formatApprovalDate(
                                            widget.items[i].createdAt,
                                          ),
                                          textDirection: TextDirection.ltr,
                                        ),
                                      ),
                                      cell(
                                        OutlinedButton.icon(
                                          onPressed:
                                              widget.onViewDetails == null
                                              ? null
                                              : () => widget.onViewDetails!(
                                                  widget.items[i],
                                                ),
                                          icon: const Icon(
                                            Icons.visibility_outlined,
                                            size: 17,
                                          ),
                                          label: Text(
                                            t.view,
                                            maxLines: 1,
                                            softWrap: false,
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            minimumSize: const Size(96, 36),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            foregroundColor: const Color(
                                              0xFF8659BB,
                                            ),
                                          ),
                                        ),
                                        centered: true,
                                      ),
                                      if (widget.showActions)
                                        cell(
                                          ApprovalActionsCell(
                                            request: widget.items[i],
                                            actorRole: widget.actorRole,
                                            onApprove: widget.onApprove,
                                            onReject: widget.onReject,
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
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
      },
    );
  }
}
