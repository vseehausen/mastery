import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/text_styles.dart';
import '../theme/color_tokens.dart';

/// Custom bottom navigation bar with 3 tabs
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark
        ? MasteryColors.foregroundDark
        : MasteryColors.activeLight;
    final inactiveColor = isDark
        ? MasteryColors.mutedForegroundDark
        : MasteryColors.mutedForegroundLight;
    final bgColor = isDark ? MasteryColors.cardDark : MasteryColors.cardLight;
    const tabs = [
      {'icon': Icons.today_outlined, 'label': 'Today'},
      {'icon': Icons.book_outlined, 'label': 'Words'},
      {'icon': Icons.insights_outlined, 'label': 'Progress'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? MasteryColors.borderDark
                : MasteryColors.borderLight,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Expanded(
            child: _NavTab(
              icon: tabs[index]['icon'] as IconData,
              label: tabs[index]['label'] as String,
              isActive: selectedIndex == index,
              onTap: () => onTabSelected(index),
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      containedInkWell: true,
      highlightShape: BoxShape.rectangle,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: isActive ? activeColor : inactiveColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: MasteryTextStyles.caption.copyWith(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
