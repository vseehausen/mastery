import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../data/database/database.dart';

/// Inline editor for meaning translations and definitions.
/// Allows editing primary translation, English definition, and pinning alternatives.
class MeaningEditor extends StatefulWidget {
  const MeaningEditor({
    super.key,
    required this.meaning,
    required this.onSave,
    required this.onCancel,
  });

  final Meaning meaning;
  final void Function({
    String? primaryTranslation,
    String? englishDefinition,
  }) onSave;
  final VoidCallback onCancel;

  @override
  State<MeaningEditor> createState() => _MeaningEditorState();
}

class _MeaningEditorState extends State<MeaningEditor> {
  late TextEditingController _translationController;
  late TextEditingController _definitionController;

  @override
  void initState() {
    super.initState();
    _translationController =
        TextEditingController(text: widget.meaning.primaryTranslation);
    _definitionController =
        TextEditingController(text: widget.meaning.englishDefinition);
  }

  @override
  void dispose() {
    _translationController.dispose();
    _definitionController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    return _translationController.text != widget.meaning.primaryTranslation ||
        _definitionController.text != widget.meaning.englishDefinition;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.1),
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
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Translation field
          Text(
            'Translation',
            style: MasteryTextStyles.formLabel.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
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
              color: isDark ? Colors.white60 : Colors.black54,
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
      primaryTranslation: newTranslation != widget.meaning.primaryTranslation
          ? newTranslation
          : null,
      englishDefinition: newDefinition != widget.meaning.englishDefinition
          ? newDefinition
          : null,
    );
  }
}
