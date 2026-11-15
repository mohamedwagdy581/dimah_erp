import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/session/session_cubit.dart';
import '../cubit/payroll_cubit.dart';
import '../sections/payroll_table_section.dart';
import '../widgets/payroll_preparation_view.dart';
import '../widgets/finance_payroll_workspace.dart';

class PayrollPage extends StatelessWidget {
  const PayrollPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PayrollCubit(AppDI.payrollRepo)..load(),
      child: _PayrollPageBody(
        history:
            GoRouterState.of(context).uri.queryParameters['history'] == '1',
      ),
    );
  }
}

class _PayrollPageBody extends StatefulWidget {
  const _PayrollPageBody({this.history = false});
  final bool history;
  @override
  State<_PayrollPageBody> createState() => _PayrollPageBodyState();
}

class _PayrollPageBodyState extends State<_PayrollPageBody> {
  bool _history = false;
  @override
  void initState() {
    super.initState();
    _history = widget.history;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    if (session is! SessionReady) return const SizedBox.shrink();
    if (session.user.role == 'finance_manager') {
      return IndexedStack(
        index: _history ? 1 : 0,
        children: [
          FinancePayrollWorkspace(
            repo: AppDI.payrollRepo,
            onDisbursement: (id) => context.go('/payroll/$id?disbursement=1'),
            onHistory: () {
              setState(() {
                _history = true;
              });
              context.read<PayrollCubit>().load();
            },
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  _history = false;
                }),
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'العودة لمراجعة الرواتب'
                      : 'Back to payroll review',
                ),
              ),
              const Expanded(child: PayrollTableSection()),
            ],
          ),
        ],
      );
    }
    if (session.user.role != 'hr') return const PayrollTableSection();
    // Keep the editor mounted when browsing history so an already saved ID
    // cannot be lost and accidentally recreated on returning.
    return IndexedStack(
      index: _history ? 1 : 0,
      children: [
        PayrollPreparationView(
          repo: AppDI.payrollRepo,
          onHistory: () {
            setState(() {
              _history = true;
            });
            context.read<PayrollCubit>().load();
          },
          onSubmitted: (id) => context.go('/payroll/$id'),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => setState(() {
                _history = false;
              }),
              icon: const Icon(Icons.edit_note),
              label: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'العودة لتجهيز المسير'
                    : 'Back to payroll preparation',
              ),
            ),
            const Expanded(child: PayrollTableSection()),
          ],
        ),
      ],
    );
  }
}
