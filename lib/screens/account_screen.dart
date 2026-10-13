import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _signupMode = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password.')),
      );
      return;
    }
    setState(() => _busy = true);
    final ok = _signupMode
        ? await auth.signup(email, pass, _nameCtrl.text.trim().isEmpty ? email.split('@').first : _nameCtrl.text.trim())
        : await auth.login(email, pass);
    if (mounted) {
      setState(() => _busy = false);
      if (!ok && auth.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Account', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (auth.loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (!auth.isLoggedIn)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Log in with your ExamArchive account to browse papers and syllabi. New here? Switch to Sign up below — it is free.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildLoginCard(),
              ],
            )
          else
            _buildUserCard(auth),
          const SizedBox(height: 20),
          Text('Theme', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: RadioGroup<AppThemeName>(
              groupValue: themeProvider.theme,
              onChanged: (v) { if (v != null) themeProvider.setTheme(v); },
              child: Column(
                children: AppThemeName.values.map((t) {
                  return RadioListTile<AppThemeName>(
                    title: Text(t.label),
                    value: t,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'ExamArchive — free past exam papers & syllabi for Haflong Government College (Assam University) FYUGP students.\n\nThis app talks directly to the ExamArchive Appwrite backend — everything is live, nothing is bundled.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _signupMode ? 'Create account' : 'Welcome back',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Log in to download papers and sync your library.'),
            const SizedBox(height: 16),
            if (_signupMode)
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
            if (_signupMode) const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_signupMode ? 'Sign up' : 'Log in'),
            ),
            TextButton(
              onPressed: () => setState(() => _signupMode = !_signupMode),
              child: Text(_signupMode ? 'Already have an account? Log in' : 'New here? Create an account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(AuthProvider auth) {
    final user = auth.user!;
    return Card(
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
    );
  }
}
