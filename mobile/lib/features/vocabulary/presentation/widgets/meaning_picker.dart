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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can learn the others later.',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
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
                  isDark: isDark,
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
    required this.isDark,
    required this.onSelect,
  });

  final MeaningOption option;
  final bool isDark;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? MasteryColors.cardDark : MasteryColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: option.isRecommended
              ? Theme.of(context).primaryColor
              : (isDark
                  ? MasteryColors.borderDark
                  : MasteryColors.borderLight),
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
                    color: isDark ? Colors.white : Colors.black,
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
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
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
