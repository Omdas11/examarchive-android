import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../providers/auth_provider.dart';
import '../widgets/theme_icon_button.dart';
import 'dashboard_screen.dart';
import 'upload_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: const [ThemeIconButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (auth.loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else
            _buildUserCard(auth),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© 2026 ExamArchive · v${AppConfig.appVersion}',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AuthProvider auth) {
    final user = auth.user!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  child: Text(
                    (user.name.isNotEmpty ? user.name[0] : user.email[0]).toUpperCase(),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name.isNotEmpty ? user.name : 'Scholar',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: auth.logout,
                  icon: const Icon(Icons.logout_outlined, size: 18),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                ),
                icon: const Icon(Icons.dashboard_outlined),
                label: const Text('Dashboard'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadScreen()),
                ),
                icon: const Icon(Icons.upload_outlined),
                label: const Text('Upload'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
