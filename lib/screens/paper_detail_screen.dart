import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class PaperDetailScreen extends StatefulWidget {
  final Paper paper;
  const PaperDetailScreen({super.key, required this.paper});

  @override
  State<PaperDetailScreen> createState() => _PaperDetailScreenState();
}

class _PaperDetailScreenState extends State<PaperDetailScreen> {
  final _api = ApiService();
  List<SyllabusUnit> _units = [];
  bool _loadingUnits = true;
  bool _downloading = false;
  String? _downloadError;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final units = await _api.fetchSyllabusTable(widget.paper);
    if (mounted) {
      setState(() { _units = units; _loadingUnits = false; });
    }
  }

  Future<void> _downloadAndOpen() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      _promptLogin();
      return;
    }
    setState(() { _downloading = true; _downloadError = null; });
    try {
      // Direct from Appwrite Storage — no website in the middle.
      final bytes = await _api.downloadPaperPdf(widget.paper.fileId);
      final dir = await getTemporaryDirectory();
      final safeName = widget.paper.courseCode.replaceAll(RegExp(r'[^\w\-]'), '_');
      final file = File('${dir.path}/$safeName-${widget.paper.year ?? ''}.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      setState(() => _downloading = false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfViewerScreen(path: file.path, title: widget.paper.displayTitle)),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _promptLogin() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login required'),
        content: const Text('Please log in to download papers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.paper;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(p.courseCode)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(p.displayTitle, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _Row('Course code', p.courseCode),
                  _Row('Department', p.department),
                  if (p.year != null) _Row('Year', '${p.year}'),
                  if (p.semester != null) _Row('Semester', p.semester!),
                  if (p.examType != null && p.examType!.isNotEmpty) _Row('Exam type', p.examType!),
                  if (p.programme != null) _Row('Programme', p.programme!),
                  if (p.institute != null) _Row('Institute', p.institute!),
                  if (p.downloadCount > 0) _Row('Downloads', '${p.downloadCount}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _downloading ? null : _downloadAndOpen,
              icon: _downloading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(_downloading ? 'Downloading…' : 'View / Download PDF'),
            ),
          ),
          if (_downloadError != null) ...[
            const SizedBox(height: 8),
            Text(_downloadError!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 20),
          Text('Syllabus', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_loadingUnits)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_units.isEmpty)
            const Text('No syllabus table available for this paper yet.')
          else
            ..._units.map((u) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ExpansionTile(
                    title: Text('Unit ${u.unitNumber}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: u.lectures != null ? Text('${u.lectures} lectures') : null,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(u.content),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String path;
  final String title;
  const PdfViewerScreen({super.key, required this.path, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int _pages = 0;
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (_pages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('${_current + 1} / $_pages'),
              ),
            ),
        ],
      ),
      body: PDFView(
        filePath: widget.path,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onRender: (pages) => setState(() => _pages = pages ?? 0),
        onPageChanged: (page, _) => setState(() => _current = page ?? 0),
        onError: (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF')),
        ),
      ),
    );
  }
}
