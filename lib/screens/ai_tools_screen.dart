import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AiToolsScreen extends StatefulWidget {
  const AiToolsScreen({super.key});

  @override
  State<AiToolsScreen> createState() => _AiToolsScreenState();
}

class _AiToolsScreenState extends State<AiToolsScreen> {
  final _api = ApiService();
  final _subjectCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();

  static const _counts = [5, 10, 15];
  int _count = 10;
  bool _generating = false;
  List<Map<String, String>> _cards = [];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final subject = _subjectCtrl.text.trim();
    final topic = _topicCtrl.text.trim();
    if (subject.isEmpty || topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a subject and a topic.')),
      );
      return;
    }
    setState(() { _generating = true; _cards = []; });
    try {
      final cards = await _api.generateFlashcards(
        subject: subject,
        topic: topic,
        count: _count,
      );
      if (!mounted) return;
      setState(() { _cards = cards; _generating = false; });
      if (cards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No flashcards came back. Try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Tools', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(
              labelText: 'Subject',
              hintText: 'e.g. Physics',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _topicCtrl,
            decoration: const InputDecoration(
              labelText: 'Topic',
              hintText: 'e.g. Laws of Thermodynamics',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.topic_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _count,
            decoration: const InputDecoration(
              labelText: 'Number of cards',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.style_outlined),
            ),
            items: _counts
                .map((c) => DropdownMenuItem(value: c, child: Text('$c')))
                .toList(),
            onChanged: (v) { if (v != null) setState(() => _count = v); },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(_generating ? 'Generating…' : 'Generate flashcards'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 20),
          if (_cards.isNotEmpty) ...[
            Text(
              '${_cards.length} flashcards — tap a card to flip it',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ..._cards.asMap().entries.map(
                  (e) => _FlashcardCard(
                    index: e.key + 1,
                    total: _cards.length,
                    front: e.value['front'] ?? '',
                    back: e.value['back'] ?? '',
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

/// A flashcard that flips between question and answer on tap.
class _FlashcardCard extends StatefulWidget {
  final int index;
  final int total;
  final String front;
  final String back;

  const _FlashcardCard({
    required this.index,
    required this.total,
    required this.front,
    required this.back,
  });

  @override
  State<_FlashcardCard> createState() => _FlashcardCardState();
}

class _FlashcardCardState extends State<_FlashcardCard> {
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _flipped = !_flipped),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: _flipped
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${widget.index} / ${widget.total}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _flipped ? Icons.visibility_outlined : Icons.flip_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _flipped ? widget.back : widget.front,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _flipped
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _flipped ? 'Tap to see the question' : 'Tap to see the answer',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
