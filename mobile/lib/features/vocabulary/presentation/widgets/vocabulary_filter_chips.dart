import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/color_tokens.dart';

/// Filter types for vocabulary list
enum VocabularyFilter {
  all,
  enriched,
  notEnriched,
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
            label: 'Enriched',
            icon: Icons.auto_awesome,
            isSelected: selectedFilter == VocabularyFilter.enriched,
            onTap: () => onFilterChanged(VocabularyFilter.enriched),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Not Enriched',
            isSelected: selectedFilter == VocabularyFilter.notEnriched,
            onTap: () => onFilterChanged(VocabularyFilter.notEnriched),
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
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? colors.primaryActionForeground
                    : colors.foreground,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isSelected
                    ? colors.primaryActionForeground
                    : colors.foreground,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
