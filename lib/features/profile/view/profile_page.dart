import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/di/app_di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/session_cubit.dart';
import 'employee_profile_cubit.dart';
import 'employee_profile_view.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<SessionCubit, SessionState>(
    builder: (context, session) {
      if (session is SessionLoading) {
        return const AppLoadingState();
      }
      if (session is SessionReady && session.user.role == 'employee') {
        return BlocProvider(
          create: (_) => EmployeeProfileCubit(AppDI.profileRepo)..load(),
          child: EmployeeProfileView(
            email: session.user.email,
            onPassword: () => context.go('/change-password'),
            onLogout: AppDI.authRepo.signOut,
          ),
        );
      }
      return const _LegacyProfilePage();
    },
  );
}

class _LegacyProfilePage extends StatefulWidget {
  const _LegacyProfilePage();

  @override
  State<_LegacyProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_LegacyProfilePage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AppDI.profileRepo.getProfile();
    _name.text = data.name;
    _phone.text = data.phone;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await AppDI.profileRepo.updateProfile(
        name: _name.text,
        phone: _phone.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 520,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'My Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: Text(_loading ? 'Saving...' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
