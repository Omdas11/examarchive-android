import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// One department's syllabus: its papers, each expandable to show units.
/// Data comes from the Syllabus_Table collection (2,789 rows), grouped by
/// paper code — the same content the website's per-department syllabus page
/// shows, minus the department PDF (deleted bucket, no file to open).
class DepartmentSyllabusScreen extends StatefulWidget {
  final SyllabusEntry entry;

  const DepartmentSyllabusScreen({super.key, required this.entry});

  @override
  State<DepartmentSyllabusScreen> createState() =>
      _DepartmentSyllabusScreenState();
}

/// Paper-code prefix per department (e.g. PHY covers PHYDSC/PHYDSM/…).
const _deptPrefixes = {
  'Assamese': 'ASM',
  'Bengali': 'BEN',
  'Botany': 'BOT',
  'Chemistry': 'CHM',
  'Commerce': 'COM',
  'Economics': 'ECO',
  'English': 'ENG',
  'History': 'HIS',
  'Mathematics': 'MTM',
  'Philosophy': 'PHI',
  'Physics': 'PHY',
  'Political Science': 'POL',
  'Zoology': 'ZOO',
};

class _DepartmentSyllabusScreenState extends State<DepartmentSyllabusScreen> {
  final _api = ApiService();
  Map<String, List<SyllabusUnit>> _papers = {};
  bool _loading = true;
  String? _error;

  String get _prefix =>
      _deptPrefixes[widget.entry.displayName] ??
      widget.entry.displayName.substring(0, 3).toUpperCase();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final grouped = await _api.fetchDepartmentSyllabus(_prefix);
      if (mounted) {
        setState(() {
          _papers = grouped;
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.entry.displayName} Syllabus',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
              : _papers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No syllabus papers listed for ${widget.entry.displayName} yet.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      itemCount: _papers.keys.length,
                      itemBuilder: (context, i) {
                        final code =
                            _papers.keys.toList()..sort();
                        final paperCode = code[i];
                        final units = _papers[paperCode]!;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            title: Text(
                              paperCode,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                                '${units.length} unit${units.length == 1 ? '' : 's'}'),
                            children: units
                                .map((u) => ListTile(
                                      leading: CircleAvatar(
                                        radius: 14,
                                        child: Text(
                                          '${u.unitNumber}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      title: Text(
                                        u.content,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      subtitle: u.lectures != null
                                          ? Text('${u.lectures} lectures',
                                              style: theme
                                                  .textTheme.bodySmall)
                                          : null,
                                    ))
                                .toList(),
                          ),
                        );
                      },
                    ),
    );
  }
}
