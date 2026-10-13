import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
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
      // Syllabus PDFs live in the syllabus-files bucket; fetch via the
      // website file proxy using an authenticated http client is not
      // available, so download the raw file through the public API host
      // with the user's JWT.
      final jwt = await auth.downloadJwt();
      if (jwt == null) throw Exception('Could not get download token.');
      // file_url is like /api/files/syllabus/<fileId> — reuse it with JWT.
      final fileId = entry.fileUrl.split('/').last;
      final url = Uri.parse('https://www.examarchive.dev/api/app/syllabus-pdf?fileId=$fileId&jwt=$jwt');
      final res = await http.get(url, headers: {'User-Agent': 'ExamArchive-App/1.0'});
      if (res.statusCode != 200) throw Exception('Download failed (${res.statusCode})');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/syllabus-${entry.subject}.pdf');
      await file.writeAsBytes(res.bodyBytes);
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
    _api.dispose();
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
