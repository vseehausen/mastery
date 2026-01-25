import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../providers/database_provider.dart';

/// Screen for editing a highlight's content and note
class HighlightEditScreen extends ConsumerStatefulWidget {
  final Highlight highlight;

  const HighlightEditScreen({super.key, required this.highlight});

  @override
  ConsumerState<HighlightEditScreen> createState() => _HighlightEditScreenState();
}

class _HighlightEditScreenState extends ConsumerState<HighlightEditScreen> {
  late TextEditingController _contentController;
  late TextEditingController _noteController;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.highlight.content);
    _noteController = TextEditingController(text: widget.highlight.note ?? '');

    _contentController.addListener(_onTextChanged);
    _noteController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final contentChanged = _contentController.text != widget.highlight.content;
    final noteChanged = _noteController.text != (widget.highlight.note ?? '');

    if (_hasChanges != (contentChanged || noteChanged)) {
      setState(() {
        _hasChanges = contentChanged || noteChanged;
      });
    }
  }

  @override
  void dispose() {
    _contentController.removeListener(_onTextChanged);
    _noteController.removeListener(_onTextChanged);
    _contentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Highlight'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content section
            Text(
              'Highlight Content',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter highlight content...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),

            const SizedBox(height: 24),

            // Note section
            Text(
              'Personal Note (optional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: null,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Add your thoughts or notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.amber.shade50,
              ),
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),

            const SizedBox(height: 16),

            // Info text
            Text(
              'Changes will be synced to the cloud when you have an internet connection.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final highlightRepo = ref.read(highlightRepositoryProvider);

      // Update content if changed
      if (_contentController.text != widget.highlight.content) {
        await highlightRepo.updateContent(
          widget.highlight.id,
          _contentController.text,
        );
      }

      // Update note if changed
      final newNote = _noteController.text.isEmpty ? null : _noteController.text;
      if (newNote != widget.highlight.note) {
        await highlightRepo.updateNote(widget.highlight.id, newNote);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved')),
        );
        Navigator.of(context).pop(true); // Return true to indicate changes were made
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
