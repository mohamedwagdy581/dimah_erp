import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeBodySection extends StatelessWidget {
  const HomeBodySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          await Supabase.instance.client.auth.signOut();
        },
        child: const Text('Logout'),
      ),
    );
  }
}
