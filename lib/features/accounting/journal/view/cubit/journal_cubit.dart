import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_error.dart';
import '../../domain/models/journal_line.dart';
import '../../domain/repos/journal_repo.dart';
import 'journal_state.dart';

class JournalCubit extends Cubit<JournalState> {
  JournalCubit(this._repo) : super(JournalState.initial);

  final JournalRepo _repo;

  Future<void> load({bool resetPage = false}) async {
    try {
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: true,
          clearError: true,
          page: resetPage ? 0 : state.page,
        ),
      );

      final result = await _repo.fetchEntries(
        page: resetPage ? 0 : state.page,
        pageSize: state.pageSize,
        status: state.status,
        startDate: state.startDate,
        endDate: state.endDate,
        sortBy: state.sortBy,
        ascending: state.ascending,
      );

      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          items: result.items,
          total: result.total,
        ),
      );
    } catch (e) {
      if (AppError.isTransient(e)) {
        if (isClosed) return;
        emit(state.copyWith(loading: false));
        return;
      }
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: AppError.message(e)));
    }
  }

  Future<void> statusFilterChanged(String? v) async {
    emit(state.copyWith(status: v));
    await load(resetPage: true);
  }

  Future<void> startDateChanged(DateTime? v) async {
    emit(state.copyWith(startDate: v));
    await load(resetPage: true);
  }

  Future<void> endDateChanged(DateTime? v) async {
    emit(state.copyWith(endDate: v));
    await load(resetPage: true);
  }

  Future<void> toggleSort(String sortBy) async {
    if (state.sortBy == sortBy) {
      emit(state.copyWith(ascending: !state.ascending));
    } else {
      emit(state.copyWith(sortBy: sortBy, ascending: sortBy == 'entry_date'));
    }
    await load(resetPage: true);
  }

  Future<void> setPageSize(int v) async {
    emit(state.copyWith(pageSize: v));
    await load(resetPage: true);
  }

  Future<void> nextPage() async {
    if (!state.canNext) return;
    emit(state.copyWith(page: state.page + 1));
    await load();
  }

  Future<void> prevPage() async {
    if (!state.canPrev) return;
    emit(state.copyWith(page: state.page - 1));
    await load();
  }

  Future<void> createEntry({
    required DateTime entryDate,
    required String memo,
    required List<JournalLine> lines,
  }) async {
    await _repo.createEntry(entryDate: entryDate, memo: memo, lines: lines);
    await load(resetPage: true);
  }
}
