import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// Admin panel for moderator+ users, mirroring the website's /admin
/// dashboard. Read-only: counts and pending queues. Approving or
/// rejecting still happens on the website, which uses the server admin key.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _api = ApiService();
  ({int pendingPapers, int approvedPapers, int pendingSyllabi})? _stats;
  List<Paper> _pendingPapers = [];
  List<SyllabusEntry> _pendingSyllabi = [];
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
        _api.fetchAdminStats(),
        _api.fetchPendingPapers(),
        _api.fetchPendingSyllabi(),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0]
              as ({int pendingPapers, int approvedPapers, int pendingSyllabi});
          _pendingPapers = results[1] as List<Paper>;
          _pendingSyllabi = results[2] as List<SyllabusEntry>;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin panel',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _loading = true);
                    await _load();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _statsRow(),
                      const SizedBox(height: 16),
                      Text(
                        'Pending papers (${_pendingPapers.length})',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_pendingPapers.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No papers waiting for review.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ..._pendingPapers.map((p) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(
                                    Icons.picture_as_pdf_outlined),
                                title: Text(p.displayTitle,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  [
                                    p.courseCode,
                                    if (p.year != null) '${p.year}',
                                    p.department,
                                  ].join(' · '),
                                ),
                                trailing: const Chip(
                                  label: Text('Pending'),
                                ),
                              ),
                            )),
                      const SizedBox(height: 16),
                      Text(
                        'Pending syllabi (${_pendingSyllabi.length})',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_pendingSyllabi.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No syllabi waiting for review.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ..._pendingSyllabi.map((s) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading:
                                    const Icon(Icons.menu_book_outlined),
                                title: Text(s.displayName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  [
                                    if (s.year != null) '${s.year}',
                                    'FYUGP',
                                    'Assam University'
                                  ].join(' · '),
                                ),
                                trailing: const Chip(
                                  label: Text('Pending'),
                                ),
                              ),
                            )),
                      const SizedBox(height: 16),
                      Text(
                        'Approve or reject on the website — the app has no admin key.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _statsRow() {
    final s = _stats!;
    return Row(
      children: [
        Expanded(
            child: _statCard(
                'Pending papers', '${s.pendingPapers}', Icons.pending_outlined)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(
                'Approved', '${s.approvedPapers}', Icons.verified_outlined)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard('Pending syllabi', '${s.pendingSyllabi}',
                Icons.menu_book_outlined)),
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
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}
