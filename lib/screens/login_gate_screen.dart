import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../providers/auth_provider.dart';
import '../theme/app_themes.dart';

/// Full-screen login gate: blurred app UI behind, one centered login card.
class LoginGateScreen extends StatefulWidget {
  const LoginGateScreen({super.key});

  @override
  State<LoginGateScreen> createState() => _LoginGateScreenState();
}

class _LoginGateScreenState extends State<LoginGateScreen> {
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
      _snack('Enter email and password.');
      return;
    }
    if (_signupMode && pass.length < 8) {
      _snack('Password needs at least 8 characters.');
      return;
    }
    setState(() => _busy = true);
    final ok = _signupMode
        ? await auth.signup(email, pass,
            _nameCtrl.text.trim().isEmpty ? email.split('@').first : _nameCtrl.text.trim())
        : await auth.login(email, pass);
    if (mounted) {
      setState(() => _busy = false);
      if (!ok && auth.error != null) _snack(auth.error!);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Blurred app UI backdrop.
          Positioned.fill(child: _BlurredBackdrop()),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
          ),
          // Centered login card.
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppThemes.emerald,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'E',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('ExamArchive',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    _signupMode ? 'Create your free account' : 'Welcome back',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_signupMode) ...[
                            TextField(
                              controller: _nameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: _busy
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(_signupMode ? 'Sign up' : 'Log in',
                                      style: const TextStyle(fontSize: 16)),
                            ),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() => _signupMode = !_signupMode),
                            child: Text(_signupMode
                                ? 'Have an account? Log in'
                                : 'New here? Create an account'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '© 2026 ExamArchive · v${AppConfig.appVersion}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative blurred backdrop evoking the app's papers UI.
class _BlurredBackdrop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF030712), const Color(0xFF064E3B)]
              : [const Color(0xFFF8FAFC), const Color(0xFFD1FAE5)],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (_, i) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppThemes.emerald.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(7),
                    )),
                const SizedBox(height: 8),
                Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(5),
                    )),
                const SizedBox(height: 6),
                Container(
                    height: 10,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(5),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
