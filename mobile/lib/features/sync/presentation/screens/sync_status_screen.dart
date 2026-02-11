import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/mastery_back_button.dart';
import '../../../../providers/supabase_provider.dart';

enum _SyncStage { waitingImport, enriching, readyNoDueItems, readyToLearn }

class _SyncSnapshot {
  const _SyncSnapshot({
    required this.stage,
    required this.vocabularyCount,
    required this.enrichedCount,
    required this.dueCount,
  });

  final _SyncStage stage;
  final int vocabularyCount;
  final int enrichedCount;
  final int dueCount;
}

final syncSnapshotProvider = FutureProvider.autoDispose<_SyncSnapshot>((
  ref,
) async {
  final vocabularyCount = await ref.watch(vocabularyCountProvider.future);
  final enrichedIds = await ref.watch(enrichedVocabularyIdsProvider.future);
  final dueCards = await ref.watch(dueCardsProvider.future);
  final dueCount = dueCards.length;
  final enrichedCount = enrichedIds.length;

  if (vocabularyCount == 0) {
    return _SyncSnapshot(
      stage: _SyncStage.waitingImport,
      vocabularyCount: vocabularyCount,
      enrichedCount: enrichedCount,
      dueCount: dueCount,
    );
  }

  if (enrichedCount < vocabularyCount) {
    return _SyncSnapshot(
      stage: _SyncStage.enriching,
      vocabularyCount: vocabularyCount,
      enrichedCount: enrichedCount,
      dueCount: dueCount,
    );
  }

  if (dueCount == 0) {
    return _SyncSnapshot(
      stage: _SyncStage.readyNoDueItems,
      vocabularyCount: vocabularyCount,
      enrichedCount: enrichedCount,
      dueCount: dueCount,
    );
  }

  return _SyncSnapshot(
    stage: _SyncStage.readyToLearn,
    vocabularyCount: vocabularyCount,
    enrichedCount: enrichedCount,
    dueCount: dueCount,
  );
});

/// Shows import and enrichment readiness for the learning queue.
class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncSnapshot = ref.watch(syncSnapshotProvider);

    return Scaffold(
      appBar: AppBar(
        leading: MasteryBackButton.back(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Sync Status'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: syncSnapshot.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildError(
              context: context,
              ref: ref,
              message: error.toString(),
            ),
            data: (snapshot) =>
                _buildContent(context: context, ref: ref, snapshot: snapshot),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required WidgetRef ref,
    required _SyncSnapshot snapshot,
  }) {
    final importReady = snapshot.vocabularyCount > 0;
    final enrichmentReady =
        importReady && snapshot.enrichedCount >= snapshot.vocabularyCount;
    final queueReady = enrichmentReady && snapshot.dueCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _headline(snapshot.stage),
          style: MasteryTextStyles.displayLarge.copyWith(
            fontSize: 24,
            color: context.masteryColors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _subline(snapshot),
          style: MasteryTextStyles.bodySmall.copyWith(
            color: context.masteryColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 24),
        _TimelineRow(
          title: 'Import vocabulary',
          subtitle: '${snapshot.vocabularyCount} words available',
          isComplete: importReady,
        ),
        _TimelineRow(
          title: 'Enrich meanings',
          subtitle:
              '${snapshot.enrichedCount} of ${snapshot.vocabularyCount} enriched',
          isComplete: enrichmentReady,
        ),
        _TimelineRow(
          title: 'Build review queue',
          subtitle: '${snapshot.dueCount} due now',
          isComplete: queueReady,
          isLast: true,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ShadButton(
            onPressed: () {
              ref.invalidate(syncSnapshotProvider);
              ref.invalidate(vocabularyCountProvider);
              ref.invalidate(enrichedVocabularyIdsProvider);
              ref.invalidate(dueCardsProvider);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh),
                SizedBox(width: 8),
                Text('Refresh Status'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError({
    required BuildContext context,
    required WidgetRef ref,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 56,
            color: context.masteryColors.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            'Could not load sync status',
            style: MasteryTextStyles.bodyBold.copyWith(
              color: context.masteryColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: MasteryTextStyles.bodySmall.copyWith(
              color: context.masteryColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          ShadButton(
            onPressed: () => ref.invalidate(syncSnapshotProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _headline(_SyncStage stage) {
    switch (stage) {
      case _SyncStage.waitingImport:
        return 'Waiting for your first import';
      case _SyncStage.enriching:
        return 'Preparing your learning cards';
      case _SyncStage.readyNoDueItems:
        return 'You are synced and caught up';
      case _SyncStage.readyToLearn:
        return 'Everything is ready';
    }
  }

  String _subline(_SyncSnapshot snapshot) {
    switch (snapshot.stage) {
      case _SyncStage.waitingImport:
        return 'Connect your Kindle through the desktop app to import words.';
      case _SyncStage.enriching:
        return 'Import completed. Meanings are still being enriched.';
      case _SyncStage.readyNoDueItems:
        return 'All words are ready, but no cards are due right now.';
      case _SyncStage.readyToLearn:
        return 'You have ${snapshot.dueCount} items ready for review.';
    }
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.subtitle,
    required this.isComplete,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool isComplete;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final lineColor = context.masteryColors.border;
    final doneColor = context.masteryColors.success;
    final pendingColor = context.masteryColors.mutedForeground;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isComplete ? doneColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isComplete ? doneColor : lineColor),
                ),
                child: isComplete
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              if (!isLast) Container(width: 2, height: 44, color: lineColor),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1, bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: MasteryTextStyles.bodyBold.copyWith(
                    color: context.masteryColors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: MasteryTextStyles.bodySmall.copyWith(
                    color: pendingColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
