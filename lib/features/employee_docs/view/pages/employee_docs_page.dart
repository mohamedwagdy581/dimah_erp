import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../cubit/employee_docs_cubit.dart';
import '../sections/employee_docs_table_section.dart';
import '../widgets/employee_docs_form_dialog.dart';

class EmployeeDocsPage extends StatelessWidget {
  const EmployeeDocsPage({
    super.key,
    this.initialDocType,
    this.initialExpiryStatus,
    this.initialEmployeeId,
    this.autoOpenCreate = false,
    this.initialIssuedAt,
    this.initialExpiresAt,
    this.initialOldExpiresAt,
  });

  final String? initialDocType;
  final String? initialExpiryStatus;
  final String? initialEmployeeId;
  final bool autoOpenCreate;
  final DateTime? initialIssuedAt;
  final DateTime? initialExpiresAt;
  final DateTime? initialOldExpiresAt;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeeDocsCubit(
        AppDI.employeeDocsRepo,
        initialDocType: initialDocType,
        initialExpiryStatus: initialExpiryStatus,
        initialEmployeeId: initialEmployeeId,
      )..load(),
      child: _EmployeeDocsPageBody(
        initialEmployeeId: initialEmployeeId,
        initialDocType: initialDocType,
        autoOpenCreate: autoOpenCreate,
        initialIssuedAt: initialIssuedAt,
        initialExpiresAt: initialExpiresAt,
        initialOldExpiresAt: initialOldExpiresAt,
      ),
    );
  }
}

class _EmployeeDocsPageBody extends StatefulWidget {
  const _EmployeeDocsPageBody({
    required this.initialEmployeeId,
    required this.initialDocType,
    required this.autoOpenCreate,
    required this.initialIssuedAt,
    required this.initialExpiresAt,
    required this.initialOldExpiresAt,
  });

  final String? initialEmployeeId;
  final String? initialDocType;
  final bool autoOpenCreate;
  final DateTime? initialIssuedAt;
  final DateTime? initialExpiresAt;
  final DateTime? initialOldExpiresAt;

  @override
  State<_EmployeeDocsPageBody> createState() => _EmployeeDocsPageBodyState();
}

class _EmployeeDocsPageBodyState extends State<_EmployeeDocsPageBody> {
  bool _didOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didOpen || !widget.autoOpenCreate) return;
    _didOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => BlocProvider.value(
          value: context.read<EmployeeDocsCubit>(),
          child: EmployeeDocsFormDialog(
            initialEmployeeId: widget.initialEmployeeId,
            initialDocType: widget.initialDocType,
            initialIssuedAt: widget.initialIssuedAt,
            initialExpiresAt: widget.initialExpiresAt,
            initialOldExpiresAt: widget.initialOldExpiresAt,
          ),
        ),
      );
      if (ok == true && mounted) {
        context.read<EmployeeDocsCubit>().load(resetPage: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const EmployeeDocsTableSection();
}
