import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../domain/models/global_dictionary.dart';

/// Full-screen modal editor for meaning translations and definitions.
/// Allows editing all meaning fields including part of speech, synonyms, and alternative translations.
/// Edits are saved as vocabulary overrides (not direct edits to global dictionary).
class MeaningEditor extends StatefulWidget {
  const MeaningEditor({
    super.key,
    required this.globalDict,
    required this.onSave,
    required this.onCancel,
  });

  final GlobalDictionaryModel globalDict;
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

  String get _currentTranslation {
    final lang = widget.globalDict.translations.isNotEmpty
        ? widget.globalDict.translations.values.first
        : null;
    return lang?.primary ?? '';
  }

  String get _currentDefinition =>
      widget.globalDict.englishDefinition ?? '';

  String get _currentPartOfSpeech =>
      widget.globalDict.partOfSpeech ?? 'other';

  List<String> get _currentSynonyms => widget.globalDict.synonyms;

  List<String> get _currentAlternativeTranslations {
    final lang = widget.globalDict.translations.isNotEmpty
        ? widget.globalDict.translations.values.first
        : null;
    return lang?.alternatives ?? [];
  }

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

    return Scaffold(
      backgroundColor: colors.background,
      // Sticky header
      appBar: AppBar(
        backgroundColor: colors.background.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, size: 20, color: colors.mutedForeground),
          onPressed: _handleCancel,
        ),
        title: Text(
          'Edit Meaning',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colors.border.withValues(alpha: 0.1),
          ),
        ),
      ),
      // Scrollable content
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Translation field
                _buildField(
                  label: 'TRANSLATION',
                  child: _buildTextField(
                    controller: _translationController,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 24),

                // Definition field
                _buildField(
                  label: 'DEFINITION',
                  child: _buildTextField(
                    controller: _definitionController,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 24),

                // Part of Speech dropdown
                _buildField(
                  label: 'PART OF SPEECH',
                  child: _buildDropdown(),
                ),
                const SizedBox(height: 24),

                // Divider
                Container(
                  height: 1,
                  color: colors.border.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 24),

                // Synonyms tag editor
                _TagEditor(
                  label: 'SYNONYMS',
                  items: _synonyms,
                  placeholder: 'Add a synonym...',
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
                const SizedBox(height: 24),

                // Alternative Translations tag editor
                _TagEditor(
                  label: 'ALT TRANSLATIONS',
                  items: _alternativeTranslations,
                  placeholder: 'Add translation...',
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
              ],
            ),
          ),

          // Sticky footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: colors.background.withValues(alpha: 0.9),
                border: Border(
                  top: BorderSide(
                    color: colors.border.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: 32,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      onPressed: _handleCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadButton(
                      onPressed: _hasChanges ? _handleSave : null,
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required Widget child,
  }) {
    final colors = context.masteryColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.mutedForeground,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required int maxLines,
  }) {
    final colors = context.masteryColors;

    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 15,
        color: colors.foreground,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.mutedForeground.withValues(alpha: 0.5),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    final colors = context.masteryColors;

    return DropdownButtonFormField<String>(
      initialValue: _selectedPartOfSpeech,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedPartOfSpeech = value;
          });
        }
      },
      style: TextStyle(
        fontSize: 15,
        color: colors.foreground,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.mutedForeground.withValues(alpha: 0.5),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      dropdownColor: colors.cardBackground,
      icon: Icon(
        Icons.keyboard_arrow_down,
        size: 16,
        color: colors.mutedForeground.withValues(alpha: 0.6),
      ),
      items: _partsOfSpeech.map((pos) {
        return DropdownMenuItem<String>(
          value: pos,
          child: Text(pos[0].toUpperCase() + pos.substring(1)),
        );
      }).toList(),
    );
  }

  void _handleCancel() {
    if (_hasChanges) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Editing'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onCancel();
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      widget.onCancel();
    }
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
    required this.placeholder,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final List<String> items;
  final String placeholder;
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
        // Label with count
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: colors.mutedForeground,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.items.isNotEmpty)
                Text(
                  '${widget.items.length} added',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colors.mutedForeground.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Input with inline add button
        Stack(
          children: [
            TextField(
              controller: _controller,
              onSubmitted: (_) => _addItem(),
              style: TextStyle(
                fontSize: 15,
                color: colors.foreground,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.muted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colors.mutedForeground.withValues(alpha: 0.5),
                  ),
                ),
                hintText: widget.placeholder,
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: colors.mutedForeground.withValues(alpha: 0.5),
                ),
                contentPadding: const EdgeInsets.only(
                  left: 14,
                  right: 48,
                  top: 12,
                  bottom: 12,
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: IconButton(
                icon: Icon(
                  Icons.add,
                  size: 16,
                  color: colors.mutedForeground.withValues(alpha: 0.6),
                ),
                onPressed: _addItem,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),

        // Tag chips
        if (widget.items.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _TagChip(
                label: item,
                onDelete: () => widget.onRemove(index),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// Individual tag chip with delete button.
class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.onDelete,
  });

  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.foreground.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close,
              size: 12,
              color: colors.mutedForeground.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
