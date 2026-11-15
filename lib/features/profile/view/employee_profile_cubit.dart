import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_error.dart';
import '../domain/repos/profile_repo.dart';

class EmployeeProfileState {
  const EmployeeProfileState({
    this.name = '',
    this.phone = '',
    this.loading = false,
    this.saving = false,
    this.loaded = false,
    this.error,
    this.saveError,
    this.saveVersion = 0,
  });
  final String name;
  final String phone;
  final bool loading;
  final bool saving;
  final bool loaded;
  final String? error;
  final String? saveError;
  final int saveVersion;
}

class EmployeeProfileCubit extends Cubit<EmployeeProfileState> {
  EmployeeProfileCubit(this.repo) : super(const EmployeeProfileState());
  final ProfileRepo repo;
  Future<void> load() async {
    if (isClosed || state.loading || state.saving) return;
    emit(
      EmployeeProfileState(
        name: state.name,
        phone: state.phone,
        loading: true,
        loaded: state.loaded,
        saveVersion: state.saveVersion,
      ),
    );
    try {
      final profile = await repo.getProfile();
      if (isClosed) return;
      emit(
        EmployeeProfileState(
          name: profile.name,
          phone: profile.phone,
          loaded: true,
          saveVersion: state.saveVersion,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        EmployeeProfileState(
          name: state.name,
          phone: state.phone,
          loaded: state.loaded,
          error: AppError.message(error),
          saveVersion: state.saveVersion,
        ),
      );
    }
  }

  Future<void> save({required String name, required String phone}) async {
    if (isClosed || state.loading || state.saving || !state.loaded) return;
    emit(
      EmployeeProfileState(
        name: state.name,
        phone: state.phone,
        loaded: true,
        saving: true,
        saveVersion: state.saveVersion,
      ),
    );
    try {
      await repo.updateProfile(name: name.trim(), phone: phone.trim());
      if (isClosed) return;
      emit(
        EmployeeProfileState(
          name: name.trim(),
          phone: phone.trim(),
          loaded: true,
          saveVersion: state.saveVersion + 1,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        EmployeeProfileState(
          name: state.name,
          phone: state.phone,
          loaded: true,
          saveError: AppError.message(error),
          saveVersion: state.saveVersion,
        ),
      );
    }
  }
}
