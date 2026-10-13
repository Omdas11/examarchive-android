import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/papers_provider.dart';
import 'paper_detail_screen.dart';

const _departments = [
  'Assamese', 'Bengali', 'Botany', 'Chemistry', 'Commerce', 'Economics',
  'English', 'History', 'Mathematics', 'Philosophy', 'Physics',
  'Political Science', 'Zoology',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 400) {
        context.read<PapersProvider>().loadMore();
      }
    });
    // Fetch after login gate: HomeScreen first builds once authenticated.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PapersProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PapersProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ExamArchive', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (provider.department != null || provider.year != null || provider.semester != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              tooltip: 'Clear filters',
              onPressed: provider.clearFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Search papers…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      provider.setSearch('');
                    },
                  ),
              ],
              onSubmitted: provider.setSearch,
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _FilterChip(
                  label: 'Department',
                  value: provider.department,
                  options: _departments,
                  onSelected: provider.setDepartment,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Year',
                  value: provider.year?.toString(),
                  options: const ['2025', '2024', '2023', '2022', '2021', '2020'],
                  onSelected: (v) => provider.setYear(v == null ? null : int.tryParse(v)),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Semester',
                  value: provider.semester,
                  options: const ['1st', '2nd', '3rd', '4th', '5th', '6th'],
                  onSelected: provider.setSemester,
                ),
              ],
            ),
          ),
          Expanded(child: _buildList(provider)),
        ],
      ),
    );
  }

  Widget _buildList(PapersProvider provider) {
    if (provider.loading && provider.papers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.papers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 12),
              Text(provider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: provider.refresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (provider.papers.isEmpty) {
      return const Center(child: Text('No papers found.'));
    }
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        itemCount: provider.papers.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= provider.papers.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _PaperCard(paper: provider.papers[i]);
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(value ?? label),
      selected: value != null,
      onSelected: (_) async {
        final picked = await showModalBottomSheet<String?>(
          context: context,
          builder: (ctx) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: Text('All $label'),
                  onTap: () => Navigator.pop(ctx, null),
                ),
                ...options.map((o) => ListTile(
                      title: Text(o),
                      trailing: o == value ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.pop(ctx, o),
                    )),
              ],
            ),
          ),
        );
        onSelected(picked);
      },
    );
  }
}

class _PaperCard extends StatelessWidget {
  final Paper paper;
  const _PaperCard({required this.paper});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PaperDetailScreen(paper: paper)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paper.displayTitle,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Tag(paper.courseCode),
                  if (paper.year != null) _Tag('${paper.year}'),
                  if (paper.semester != null) _Tag('${paper.semester} sem'),
                  _Tag(paper.department),
                  if (paper.programme != null) _Tag(paper.programme!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: scheme.onPrimaryContainer, fontWeight: FontWeight.w500),
      ),
    );
  }
}
