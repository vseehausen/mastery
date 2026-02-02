import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../data/database/database.dart';

/// Displays a single meaning for a vocabulary word.
/// Collapsed: primary translation + English definition.
/// Expanded: alternative translations, synonyms, edit/pin buttons.
class MeaningCard extends StatefulWidget {
  const MeaningCard({
    super.key,
    required this.meaning,
    this.onEdit,
    this.onPin,
    this.onActivate,
    this.onReTranslate,
    this.displayMode = 'both',
  });

  final Meaning meaning;
  final VoidCallback? onEdit;
  final VoidCallback? onPin;
  final VoidCallback? onActivate;
  final VoidCallback? onReTranslate;
  final String displayMode; // 'native', 'english', 'both'

  @override
  State<MeaningCard> createState() => _MeaningCardState();
}

class _MeaningCardState extends State<MeaningCard> {
  bool _isExpanded = false;

  List<String> get _alternatives {
    try {
      final decoded = jsonDecode(widget.meaning.alternativeTranslations);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  List<String> get _synonyms {
    try {
      final decoded = jsonDecode(widget.meaning.synonyms);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: widget.meaning.isPrimary
            ? Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.15),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsed content - always visible
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCollapsedContent(isDark),
            ),
          ),

          // Expanded content
          if (_isExpanded) _buildExpandedContent(isDark),
        ],
      ),
    );
  }

  Widget _buildCollapsedContent(bool isDark) {
    final showTranslation =
        widget.displayMode == 'native' || widget.displayMode == 'both';
    final showDefinition =
        widget.displayMode == 'english' || widget.displayMode == 'both';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary badge + part of speech
        Row(
          children: [
            if (widget.meaning.isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Primary',
                  style: MasteryTextStyles.caption.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            if (widget.meaning.isPrimary && widget.meaning.partOfSpeech != null)
              const SizedBox(width: 8),
            if (widget.meaning.partOfSpeech != null)
              Text(
                widget.meaning.partOfSpeech!,
                style: MasteryTextStyles.caption.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const Spacer(),
            // Low confidence indicator
            if (widget.meaning.confidence < 0.6)
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.amber.withValues(alpha: 0.7),
              ),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Primary translation
        if (showTranslation)
          Text(
            widget.meaning.primaryTranslation,
            style: MasteryTextStyles.bodyBold.copyWith(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

        if (showTranslation && showDefinition) const SizedBox(height: 4),

        // English definition
        if (showDefinition)
          Text(
            widget.meaning.englishDefinition,
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
      ],
    );
  }

  Widget _buildExpandedContent(bool isDark) {
    final alternatives = _alternatives;
    final synonyms = _synonyms;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Alternative translations
          if (alternatives.isNotEmpty) ...[
            Text(
              'Alternatives',
              style: MasteryTextStyles.caption.copyWith(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: alternatives
                  .take(3)
                  .map((alt) => Chip(
                        label: Text(alt, style: MasteryTextStyles.bodySmall),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
            if (alternatives.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${alternatives.length - 3} more',
                  style: MasteryTextStyles.caption.copyWith(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],

          // Synonyms
          if (synonyms.isNotEmpty) ...[
            Text(
              'Synonyms',
              style: MasteryTextStyles.caption.copyWith(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              synonyms.join(', '),
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Extended definition
          if (widget.meaning.extendedDefinition != null) ...[
            Text(
              widget.meaning.extendedDefinition!,
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.white60 : Colors.black45,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            children: [
              if (!widget.meaning.isActive && widget.onActivate != null)
                TextButton.icon(
                  onPressed: widget.onActivate,
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Learn this meaning too'),
                  style: TextButton.styleFrom(
                    textStyle: MasteryTextStyles.caption,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (widget.onReTranslate != null)
                TextButton.icon(
                  onPressed: widget.onReTranslate,
                  icon: const Icon(Icons.translate, size: 16),
                  label: const Text('Re-translate'),
                  style: TextButton.styleFrom(
                    textStyle: MasteryTextStyles.caption,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (!widget.meaning.isPrimary && widget.onPin != null)
                TextButton.icon(
                  onPressed: widget.onPin,
                  icon: const Icon(Icons.push_pin_outlined, size: 16),
                  label: const Text('Pin as primary'),
                  style: TextButton.styleFrom(
                    textStyle: MasteryTextStyles.caption,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (widget.onEdit != null)
                TextButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    textStyle: MasteryTextStyles.caption,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
