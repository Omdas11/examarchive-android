import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'paper_detail_screen.dart' show PdfViewerScreen;

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
  bool _downloading = false;
  String? _downloadingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _api.fetchSyllabusLibrary();
      if (mounted) {
        setState(() { _entries = items; _loading = false; });
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

  Future<void> _openPdf(SyllabusEntry entry) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in (Account tab) to open syllabus PDFs.')),
        );
      }
      return;
    }
    setState(() { _downloading = true; _downloadingId = entry.id; });
    try {
      // Direct from Appwrite Storage (syllabus-files bucket).
      // file_url is like /api/files/syllabus/<fileId>.
      final fileId = entry.fileUrl.split('/').last;
      if (fileId.isEmpty) throw Exception('No file attached to this syllabus.');
      final bytes = await _api.downloadSyllabusPdf(fileId);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/syllabus-${entry.subject}.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      setState(() { _downloading = false; _downloadingId = null; });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(path: file.path, title: '${entry.displayName} Syllabus'),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() { _downloading = false; _downloadingId = null; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Syllabus', style: TextStyle(fontWeight: FontWeight.bold))),
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
                          onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async { setState(() { _loading = true; }); await _load(); },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: _entries.length,
                    itemBuilder: (context, i) {
                      final e = _entries[i];
                      final busy = _downloading && _downloadingId == e.id;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              e.displayName.isNotEmpty ? e.displayName[0] : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(e.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            [if (e.year != null) '${e.year}', 'FYUGP', 'Assam University']
                                .join(' · '),
                          ),
                          trailing: busy
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.picture_as_pdf_outlined),
                          onTap: busy ? null : () => _openPdf(e),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
