import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/theme_icon_button.dart';
import 'admin_screen.dart';
import 'dashboard_screen.dart';
import 'upload_screen.dart';

/// Full profile, mirroring the website's /profile page:
/// avatar + name + role badge, XP tier progress, streak, stats grid,
/// achievements, account info — plus an Admin entry for moderator+.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  UserProfile? _profile;
  List<Paper> _uploads = [];
  int _verifications = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.fetchMyProfile(),
        _api.fetchMyUploads(),
        _api.fetchVerificationCount(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as UserProfile?;
          _uploads = results[1] as List<Paper>;
          _verifications = results[2] as int;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: const [ThemeIconButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _loading = true);
                    await _load();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _headerCard(auth),
                      const SizedBox(height: 12),
                      _xpCard(),
                      const SizedBox(height: 12),
                      _streakCard(),
                      const SizedBox(height: 12),
                      _statsGrid(),
                      const SizedBox(height: 12),
                      _achievementsCard(),
                      const SizedBox(height: 12),
                      _accountInfoCard(auth),
                      const SizedBox(height: 12),
                      _actionsRow(),
                      if (_profile?.isAdmin == true) ...[
                        const SizedBox(height: 12),
                        _adminCard(),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          '© 2026 ExamArchive · v${AppConfig.appVersion}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _load();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(AuthProvider auth) {
    final user = auth.user!;
    final profile = _profile;
    final name = user.name.isNotEmpty
        ? user.name
        : (profile?.displayName.isNotEmpty == true ? profile!.displayName : 'Scholar');
    final username = profile?.username ?? '';
    final roleLabel = _roleLabel(profile?.role ?? 'student');
    final avatarUrl = profile?.avatarUrl ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? Text(
                      (name.isNotEmpty ? name[0] : user.email[0]).toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17)),
                  if (username.isNotEmpty)
                    Text('@$username',
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(user.email,
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 6),
                  _rolePill(roleLabel),
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

  Widget _rolePill(String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// XP tier progress — the website's single ladder:
  /// Bronze 0, Silver 100, Gold 300, Platinum 800, Diamond 1500+.
  Widget _xpCard() {
    final xp = _profile?.xp ?? 0;
    const tiers = [
      (0, 'Bronze'),
      (100, 'Silver'),
      (300, 'Gold'),
      (800, 'Platinum'),
      (1500, 'Diamond'),
    ];
    var idx = 0;
    for (var i = 0; i < tiers.length; i++) {
      if (xp >= tiers[i].$1) idx = i;
    }
    final current = tiers[idx];
    final next = idx + 1 < tiers.length ? tiers[idx + 1] : null;
    final progress = next == null
        ? 1.0
        : ((xp - current.$1) / (next.$1 - current.$1)).clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.military_tech_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text('${current.$2} tier',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text('$xp XP',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                        fontSize: 15)),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              borderRadius: BorderRadius.circular(8),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              next == null
                  ? 'Top tier reached'
                  : '${next.$1 - xp} XP to ${next.$2}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _streakCard() {
    final days = _profile?.streakDays ?? 0;
    final live = _streakLive();
    final activeCount = live ? days.clamp(0, 7) : 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department_outlined,
                    color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Daily streak',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text('$days day${days == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final active = i >= 7 - activeCount;
                return CircleAvatar(
                  radius: 16,
                  backgroundColor: active
                      ? Colors.orange
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                  child: Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: active
                        ? Colors.white
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Streak is live when last activity was today or yesterday.
  bool _streakLive() {
    final last = _profile?.lastActivity ?? '';
    if (last.isEmpty || (_profile?.streakDays ?? 0) == 0) return false;
    final lastDate = DateTime.tryParse(last);
    if (lastDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final then = DateTime(lastDate.year, lastDate.month, lastDate.day);
    return today.difference(then).inDays <= 1;
  }

  Widget _statsGrid() {
    final approved = _uploads.where((p) => p.approved).length;
    final total = _uploads.length;
    final pct = total > 0 ? ((approved / total) * 100).round() : 0;
    return Row(
      children: [
        Expanded(
            child: _statCard('Uploads', '$total', Icons.upload_file_outlined)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(
                'Approved', '$approved', Icons.verified_outlined)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(
                'Approval', '$pct%', Icons.percent_outlined)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(
                'XP', '${_profile?.xp ?? 0}', Icons.star_outlined)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }

  Widget _achievementsCard() {
    final total = _uploads.length;
    final approved = _uploads.where((p) => p.approved).length;
    final pct = total > 0 ? ((approved / total) * 100).round() : 0;
    final days = _profile?.streakDays ?? 0;
    final xp = _profile?.xp ?? 0;
    final earned = <String>[];
    if (total >= 1) earned.add('First Upload');
    if (total >= 10) earned.add('10 Uploads');
    if (total >= 100) earned.add('100 Uploads');
    if (days >= 7) earned.add('7-Day Streak');
    if (days >= 30) earned.add('30-Day Streak');
    if (pct >= 90 && total >= 10) earned.add('90% Approval');
    if (xp >= 800) earned.add('Top Contributor');
    if (earned.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No achievements yet — upload a paper or keep your streak going.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Achievements',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: earned
                  .map((e) => Chip(
                        avatar: const Icon(Icons.emoji_events_outlined,
                            size: 16),
                        label: Text(e),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountInfoCard(AuthProvider auth) {
    final user = auth.user!;
    final joined = _memberSince(user.$createdAt);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account info',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _infoRow('Verifications', '$_verifications'),
            _infoRow('User ID', user.$id),
            _infoRow('Member since', joined),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _actionsRow() {
    return Row(
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
    );
  }

  Widget _adminCard() {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined,
                  color: scheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin panel',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: scheme.onPrimaryContainer)),
                    Text('Pending papers and syllabi',
                        style: TextStyle(
                            fontSize: 13,
                            color: scheme.onPrimaryContainer
                                .withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    return switch (role) {
      'contributor' => 'Contributor',
      'specialist' => 'Specialist',
      'subject_admin' => 'Subject Admin',
      'moderator' => 'Moderator',
      'founder' => 'Founder',
      _ => 'Student',
    };
  }

  String _memberSince(String createdAt) {
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}
