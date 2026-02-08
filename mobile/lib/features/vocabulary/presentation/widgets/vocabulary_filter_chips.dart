import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/color_tokens.dart';

/// Filter types for vocabulary list
enum VocabularyFilter {
  all,
  captured,
  practicing,
  stabilizing,
  active,
  mastered,
}

/// Filter chips for vocabulary filtering
class VocabularyFilterChips extends StatelessWidget {
  const VocabularyFilterChips({
    super.key,
    required this.onFilterChanged,
    required this.selectedFilter,
  });

  final ValueChanged<VocabularyFilter> onFilterChanged;
  final VocabularyFilter selectedFilter;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: selectedFilter == VocabularyFilter.all,
            onTap: () => onFilterChanged(VocabularyFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Captured',
            isSelected: selectedFilter == VocabularyFilter.captured,
            onTap: () => onFilterChanged(VocabularyFilter.captured),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Practicing',
            isSelected: selectedFilter == VocabularyFilter.practicing,
            onTap: () => onFilterChanged(VocabularyFilter.practicing),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Stabilizing',
            isSelected: selectedFilter == VocabularyFilter.stabilizing,
            onTap: () => onFilterChanged(VocabularyFilter.stabilizing),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Active',
            isSelected: selectedFilter == VocabularyFilter.active,
            onTap: () => onFilterChanged(VocabularyFilter.active),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Mastered',
            isSelected: selectedFilter == VocabularyFilter.mastered,
            onTap: () => onFilterChanged(VocabularyFilter.mastered),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryAction : colors.muted,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: MasteryTextStyles.bodySmall.copyWith(
            color: isSelected
                ? colors.primaryActionForeground
                : colors.foreground,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
