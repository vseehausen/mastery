import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';

/// Option data for the meaning picker.
class MeaningOption {
  const MeaningOption({
    required this.meaningId,
    required this.primaryTranslation,
    required this.englishDefinition,
    this.isRecommended = false,
  });

  final String meaningId;
  final String primaryTranslation;
  final String englishDefinition;
  final bool isRecommended;
}

/// Screen for selecting which meaning of an ambiguous word to learn first.
class MeaningPickerScreen extends StatelessWidget {
  const MeaningPickerScreen({
    super.key,
    required this.meanings,
    required this.onSelect,
  });

  final List<MeaningOption> meanings;
  final void Function(String meaningId) onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Which meaning do you want to learn first?',
            style: MasteryTextStyles.bodyBold.copyWith(
              fontSize: 20,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can learn the others later.',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: meanings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _MeaningOptionCard(
                  option: meanings[index],
                  onSelect: () => onSelect(meanings[index].meaningId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MeaningOptionCard extends StatelessWidget {
  const _MeaningOptionCard({
    required this.option,
    required this.onSelect,
  });

  final MeaningOption option;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: option.isRecommended
              ? Theme.of(context).primaryColor
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  option.primaryTranslation,
                  style: MasteryTextStyles.bodyBold.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ),
              if (option.isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .primaryColor
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Recommended',
                    style: MasteryTextStyles.caption.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            option.englishDefinition,
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ShadButton.outline(
              onPressed: onSelect,
              size: ShadButtonSize.sm,
              child: const Text('Start with this'),
            ),
          ),
        ],
      ),
    );
  }
}
