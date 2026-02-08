import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';

/// Card displaying user profile information
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, this.name, this.email, this.onTap});

  final String? name;
  final String? email;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.masteryColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.masteryColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.masteryColors.primaryAction,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  color: context.masteryColors.primaryActionForeground,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? 'User',
                    style: MasteryTextStyles.bodyBold.copyWith(
                      color: context.masteryColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email ?? 'user@example.com',
                    style: MasteryTextStyles.bodySmall.copyWith(
                      color: context.masteryColors.mutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Chevron
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: context.masteryColors.mutedForeground,
              ),
          ],
        ),
      ),
    );
  }
}
