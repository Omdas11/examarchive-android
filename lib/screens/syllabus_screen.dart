import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'department_syllabus_screen.dart';

/// Syllabus library: 13 HGC departments.
///
/// Tapping a department opens its papers with their units (from the
/// Syllabus_Table collection). The old department PDFs lived in the
/// `syllabus-files` Appwrite bucket, which was deleted in the Free
/// downgrade — so there is no PDF to open any more, and the app no
/// longer tries (that was the "Storage bucket could not be found" error).
class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  final _api = ApiService();
  List<SyllabusEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _api.fetchSyllabusLibrary();
      if (mounted) {
        setState(() {
          _entries = items;
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
          title: const Text('Syllabus',
              style: TextStyle(fontWeight: FontWeight.bold))),
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
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: _entries.length,
                    itemBuilder: (context, i) {
                      final e = _entries[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              e.displayName.isNotEmpty
                                  ? e.displayName[0]
                                  : '?',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(e.displayName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            [
                              if (e.year != null) '${e.year}',
                              'FYUGP',
                              'Assam University'
                            ].join(' · '),
                          ),
                          trailing:
                              const Icon(Icons.chevron_right_outlined),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DepartmentSyllabusScreen(
                                entry: e,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
