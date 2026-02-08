import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../network/connectivity.dart';
import '../theme/color_tokens.dart';
import '../theme/text_styles.dart';

enum GlobalStatusType { offline, enrichmentProgress, syncError }

class GlobalStatusBannerData {
  const GlobalStatusBannerData({
    required this.type,
    required this.message,
    this.progress,
  });

  final GlobalStatusType type;
  final String message;
  final double? progress;
}

GlobalStatusBannerData? deriveGlobalStatusBannerData({
  required ConnectivityStatus connectivity,
  required AsyncValue<int> vocabularyCount,
  required AsyncValue<Set<String>> enrichedVocabularyIds,
  bool showEnrichmentProgress = false,
}) {
  if (connectivity == ConnectivityStatus.disconnected) {
    return const GlobalStatusBannerData(
      type: GlobalStatusType.offline,
      message: 'You are offline. Some actions may fail until reconnecting.',
    );
  }

  if (vocabularyCount.hasError || enrichedVocabularyIds.hasError) {
    return const GlobalStatusBannerData(
      type: GlobalStatusType.syncError,
      message: 'Could not determine sync state. Retry to refresh status.',
    );
  }

  if (!showEnrichmentProgress) {
    return null;
  }

  final total = vocabularyCount.valueOrNull;
  final enriched = enrichedVocabularyIds.valueOrNull?.length;
  if (total == null || enriched == null || total <= 0 || enriched >= total) {
    return null;
  }

  final progress = (enriched / total).clamp(0.0, 1.0);
  return GlobalStatusBannerData(
    type: GlobalStatusType.enrichmentProgress,
    message: 'Preparing enrichments: $enriched of $total words ready',
    progress: progress,
  );
}

class GlobalStatusBanner extends StatelessWidget {
  const GlobalStatusBanner({
    super.key,
    required this.data,
    required this.actionLabel,
    required this.onActionPressed,
    this.onDismissPressed,
  });

  final GlobalStatusBannerData data;
  final String actionLabel;
  final VoidCallback onActionPressed;
  final VoidCallback? onDismissPressed;

  @override
  Widget build(BuildContext context) {
    final bgColor = _backgroundColor(context);
    final borderColor = _borderColor(context);
    final fgColor = _foregroundColor(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: context.masteryColors.border,
          ),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon(), size: 16, color: fgColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.message,
                  style: MasteryTextStyles.bodySmall.copyWith(color: fgColor),
                ),
              ),
              const SizedBox(width: 8),
              ShadButton.outline(
                onPressed: onActionPressed,
                child: Text(actionLabel),
              ),
              if (onDismissPressed != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Dismiss',
                  onPressed: onDismissPressed,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: context.masteryColors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
          if (data.type == GlobalStatusType.enrichmentProgress &&
              data.progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: data.progress,
                minHeight: 6,
                backgroundColor: context.masteryColors.muted,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.masteryColors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _icon() {
    switch (data.type) {
      case GlobalStatusType.offline:
        return Icons.wifi_off_rounded;
      case GlobalStatusType.enrichmentProgress:
        return Icons.auto_awesome_rounded;
      case GlobalStatusType.syncError:
        return Icons.error_outline_rounded;
    }
  }

  Color _backgroundColor(BuildContext context) {
    switch (data.type) {
      case GlobalStatusType.offline:
        return context.masteryColors.warningMuted;
      case GlobalStatusType.enrichmentProgress:
        return context.masteryColors.cardBackground;
      case GlobalStatusType.syncError:
        return context.masteryColors.destructive.withValues(alpha: 0.1);
    }
  }

  Color _borderColor(BuildContext context) {
    switch (data.type) {
      case GlobalStatusType.offline:
        return context.masteryColors.warning;
      case GlobalStatusType.enrichmentProgress:
        return context.masteryColors.border;
      case GlobalStatusType.syncError:
        return context.masteryColors.destructive.withValues(alpha: 0.3);
    }
  }

  Color _foregroundColor(BuildContext context) {
    switch (data.type) {
      case GlobalStatusType.offline:
        return context.masteryColors.warning;
      case GlobalStatusType.enrichmentProgress:
        return context.masteryColors.foreground;
      case GlobalStatusType.syncError:
        return context.masteryColors.destructive;
    }
  }
}
