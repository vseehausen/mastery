import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';

/// Filter types for vocabulary list
enum VocabularyFilter {
  all,
  enriched,
  notEnriched,
}

/// Filter chips for vocabulary filtering
class VocabularyFilterChips extends StatefulWidget {
  const VocabularyFilterChips({super.key, required this.onFilterChanged});

  final ValueChanged<VocabularyFilter> onFilterChanged;

  @override
  State<VocabularyFilterChips> createState() => _VocabularyFilterChipsState();
}

class _VocabularyFilterChipsState extends State<VocabularyFilterChips> {
  VocabularyFilter _selectedFilter = VocabularyFilter.all;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: _selectedFilter == VocabularyFilter.all,
            onTap: () {
              setState(() => _selectedFilter = VocabularyFilter.all);
              widget.onFilterChanged(VocabularyFilter.all);
            },
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Enriched',
            icon: Icons.auto_awesome,
            isSelected: _selectedFilter == VocabularyFilter.enriched,
            onTap: () {
              setState(() => _selectedFilter = VocabularyFilter.enriched);
              widget.onFilterChanged(VocabularyFilter.enriched);
            },
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Not Enriched',
            isSelected: _selectedFilter == VocabularyFilter.notEnriched,
            onTap: () {
              setState(() => _selectedFilter = VocabularyFilter.notEnriched);
              widget.onFilterChanged(VocabularyFilter.notEnriched);
            },
            isDark: isDark,
            primaryColor: primaryColor,
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
    required this.isDark,
    required this.primaryColor,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color primaryColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey[200]),
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
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
