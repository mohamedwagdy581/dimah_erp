import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/utils/app_error.dart';
import '../../../employees/domain/models/employee.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../../domain/models/employee_document.dart';
import '../../domain/repos/employee_docs_repo.dart';
import 'employee_docs_state.dart';

part 'employee_docs_cubit_loading_part.dart';
part 'employee_docs_cubit_filters_part.dart';
part 'employee_docs_cubit_pagination_part.dart';
part 'employee_docs_cubit_crud_part.dart';

class EmployeeDocsCubit extends Cubit<EmployeeDocsState> {
  EmployeeDocsCubit(
    this._repo, {
    String? initialDocType,
    String? initialExpiryStatus,
  }) : super(
          EmployeeDocsState.initial.copyWith(
            docType: initialDocType,
            expiryStatus: initialExpiryStatus,
          ),
        );

  final EmployeeDocsRepo _repo;
  Timer? _debounce;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> load({bool resetPage = false}) =>
      loadEmployeeDocsCubit(resetPage: resetPage);

  void toggleExpansion(String employeeId) =>
      toggleEmployeeDocsExpansion(employeeId);

  void searchChanged(String value) => onEmployeeDocsSearchChanged(value);

  Future<void> docTypeChanged(String? value) =>
      onEmployeeDocsDocTypeChanged(value);

  void expiryStatusChanged(String? value) =>
      onEmployeeDocsExpiryStatusChanged(value);

  Future<void> toggleSort(String sortBy) => onEmployeeDocsToggleSort(sortBy);

  Future<void> setPageSize(int value) => setEmployeeDocsPageSize(value);

  Future<void> nextPage() => nextEmployeeDocsPage();

  Future<void> prevPage() => prevEmployeeDocsPage();

  Future<void> create({
    required String employeeId,
    required String docType,
    required String fileUrl,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) => createEmployeeDoc(
    employeeId: employeeId,
    docType: docType,
    fileUrl: fileUrl,
    issuedAt: issuedAt,
    expiresAt: expiresAt,
  );

  Future<void> update({
    required String id,
    required String employeeId,
    required String docType,
    required String fileUrl,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) => updateEmployeeDoc(
    id: id,
    employeeId: employeeId,
    docType: docType,
    fileUrl: fileUrl,
    issuedAt: issuedAt,
    expiresAt: expiresAt,
  );

  Future<void> delete({
    required String id,
    required String employeeId,
    required String fileUrl,
  }) => deleteEmployeeDoc(
    id: id,
    employeeId: employeeId,
    fileUrl: fileUrl,
  );
}

extension on Employee {
  EmployeeLookup toLookup() => EmployeeLookup(id: id, fullName: fullName);
}
