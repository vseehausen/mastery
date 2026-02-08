import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../domain/models/meaning.dart';

/// Inline editor for meaning translations and definitions.
/// Allows editing all meaning fields including part of speech, synonyms, and alternative translations.
class MeaningEditor extends StatefulWidget {
  const MeaningEditor({
    super.key,
    required this.meaning,
    required this.onSave,
    required this.onCancel,
  });

  final MeaningModel meaning;
  final void Function({
    required String translation,
    required String definition,
    required String partOfSpeech,
    required List<String> synonyms,
    required List<String> alternativeTranslations,
  }) onSave;
  final VoidCallback onCancel;

  @override
  State<MeaningEditor> createState() => _MeaningEditorState();
}

class _MeaningEditorState extends State<MeaningEditor> {
  late TextEditingController _translationController;
  late TextEditingController _definitionController;
  late String _selectedPartOfSpeech;
  late List<String> _synonyms;
  late List<String> _alternativeTranslations;

  String get _currentTranslation => widget.meaning.primaryTranslation;
  String get _currentDefinition => widget.meaning.englishDefinition;
  String get _currentPartOfSpeech => widget.meaning.partOfSpeech ?? 'other';
  List<String> get _currentSynonyms => widget.meaning.synonyms;
  List<String> get _currentAlternativeTranslations =>
      widget.meaning.alternativeTranslations;

  static const List<String> _partsOfSpeech = [
    'noun',
    'verb',
    'adjective',
    'adverb',
    'preposition',
    'conjunction',
    'interjection',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _translationController = TextEditingController(text: _currentTranslation);
    _definitionController = TextEditingController(text: _currentDefinition);
    _selectedPartOfSpeech = _currentPartOfSpeech;
    _synonyms = List.from(_currentSynonyms);
    _alternativeTranslations = List.from(_currentAlternativeTranslations);
  }

  @override
  void dispose() {
    _translationController.dispose();
    _definitionController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    return _translationController.text != _currentTranslation ||
        _definitionController.text != _currentDefinition ||
        _selectedPartOfSpeech != _currentPartOfSpeech ||
        !_listEquals(_synonyms, _currentSynonyms) ||
        !_listEquals(_alternativeTranslations, _currentAlternativeTranslations);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Meaning',
            style: MasteryTextStyles.bodyBold.copyWith(
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 12),

          // Translation field
          Text(
            'Translation',
            style: MasteryTextStyles.formLabel.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _translationController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: MasteryTextStyles.body,
          ),
          const SizedBox(height: 12),

          // Definition field
          Text(
            'English Definition',
            style: MasteryTextStyles.formLabel.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _definitionController,
            onChanged: (_) => setState(() {}),
            maxLines: 2,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: MasteryTextStyles.body,
          ),
          const SizedBox(height: 12),

          // Part of Speech dropdown
          Text(
            'Part of Speech',
            style: MasteryTextStyles.formLabel.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: _selectedPartOfSpeech,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPartOfSpeech = value;
                });
              }
            },
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: MasteryTextStyles.body.copyWith(
              color: colors.foreground,
            ),
            dropdownColor: colors.cardBackground,
            items: _partsOfSpeech.map((pos) {
              return DropdownMenuItem<String>(
                value: pos,
                child: Text(
                  pos[0].toUpperCase() + pos.substring(1),
                  style: MasteryTextStyles.body,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Synonyms tag editor
          _TagEditor(
            label: 'Synonyms',
            items: _synonyms,
            onAdd: (value) {
              setState(() {
                _synonyms.add(value);
              });
            },
            onRemove: (index) {
              setState(() {
                _synonyms.removeAt(index);
              });
            },
          ),
          const SizedBox(height: 12),

          // Alternative Translations tag editor
          _TagEditor(
            label: 'Alternative Translations',
            items: _alternativeTranslations,
            onAdd: (value) {
              setState(() {
                _alternativeTranslations.add(value);
              });
            },
            onRemove: (index) {
              setState(() {
                _alternativeTranslations.removeAt(index);
              });
            },
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _hasChanges ? _handleSave : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleSave() {
    final newTranslation = _translationController.text.trim();
    final newDefinition = _definitionController.text.trim();

    widget.onSave(
      translation: newTranslation,
      definition: newDefinition,
      partOfSpeech: _selectedPartOfSpeech,
      synonyms: _synonyms,
      alternativeTranslations: _alternativeTranslations,
    );
  }
}

/// Reusable tag editor widget for managing lists of strings with chips.
class _TagEditor extends StatefulWidget {
  const _TagEditor({
    required this.label,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final List<String> items;
  final void Function(String value) onAdd;
  final void Function(int index) onRemove;

  @override
  State<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<_TagEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addItem() {
    final value = _controller.text.trim();
    if (value.isNotEmpty && !widget.items.contains(value)) {
      widget.onAdd(value);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: MasteryTextStyles.formLabel.copyWith(
            color: colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          onSubmitted: (_) => _addItem(),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            hintText: 'Type and press Enter to add',
            hintStyle: MasteryTextStyles.body.copyWith(
              color: colors.mutedForeground.withValues(alpha: 0.5),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: _addItem,
            ),
          ),
          style: MasteryTextStyles.body,
        ),
        if (widget.items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Chip(
                label: Text(
                  item,
                  style: MasteryTextStyles.body.copyWith(fontSize: 13),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => widget.onRemove(index),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
