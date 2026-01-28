import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';

/// Filter chips for vocabulary status filtering
class VocabularyFilterChips extends StatefulWidget {
  const VocabularyFilterChips({
    super.key,
    required this.onFilterChanged,
  });

  final ValueChanged<LearningStatus?> onFilterChanged;

  @override
  State<VocabularyFilterChips> createState() => _VocabularyFilterChipsState();
}

class _VocabularyFilterChipsState extends State<VocabularyFilterChips> {
  LearningStatus? _selectedStatus;

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
            isSelected: _selectedStatus == null,
            onTap: () {
              setState(() => _selectedStatus = null);
              widget.onFilterChanged(null);
            },
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Learning',
            isSelected: _selectedStatus == LearningStatus.learning,
            onTap: () {
              setState(() => _selectedStatus = LearningStatus.learning);
              widget.onFilterChanged(LearningStatus.learning);
            },
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Known',
            isSelected: _selectedStatus == LearningStatus.known,
            onTap: () {
              setState(() => _selectedStatus = LearningStatus.known);
              widget.onFilterChanged(LearningStatus.known);
            },
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'New',
            isSelected: _selectedStatus == LearningStatus.unknown,
            onTap: () {
              setState(() => _selectedStatus = LearningStatus.unknown);
              widget.onFilterChanged(LearningStatus.unknown);
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
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: MasteryTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
