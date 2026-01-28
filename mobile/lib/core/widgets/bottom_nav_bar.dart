import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/text_styles.dart';

/// Custom bottom navigation bar with 4 tabs
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
    final primaryColor = Theme.of(context).primaryColor;
    final bgColor = isDark ? const Color(0xFF18181B) : Colors.white;
    const tabs = [
      {'icon': Icons.home_outlined, 'label': 'Home'},
      {'icon': Icons.lightbulb_outline, 'label': 'Learn'},
      {'icon': Icons.book_outlined, 'label': 'Words'},
      {'icon': Icons.settings_outlined, 'label': 'Settings'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300]!,
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
              primaryColor: primaryColor,
              isDark: isDark,
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
    required this.primaryColor,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;

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
            Icon(
              icon,
              size: 24,
              color: isActive
                  ? primaryColor
                  : (isDark ? Colors.grey[600] : Colors.grey[400]),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: MasteryTextStyles.caption.copyWith(
                color: isActive
                    ? primaryColor
                    : (isDark ? Colors.grey[600] : Colors.grey[500]),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
