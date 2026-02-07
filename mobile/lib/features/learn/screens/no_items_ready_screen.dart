import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/supabase_provider.dart';
import '../../sync/presentation/screens/sync_status_screen.dart';

/// Screen shown when there are no cards available to practice right now.
class NoItemsReadyScreen extends ConsumerWidget {
  const NoItemsReadyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('No Items Ready'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 72,
                color: isDark
                    ? MasteryColors.mutedForegroundDark
                    : MasteryColors.mutedForegroundLight,
              ),
              const SizedBox(height: 20),
              Text(
                'You are caught up for now',
                textAlign: TextAlign.center,
                style: MasteryTextStyles.bodyBold.copyWith(
                  fontSize: 20,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'New cards appear after import and enrichment, or when existing cards become due.',
                textAlign: TextAlign.center,
                style: MasteryTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? MasteryColors.mutedForegroundDark
                      : MasteryColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ShadButton(
                  onPressed: () {
                    ref.invalidate(dueCardsProvider);
                    ref.invalidate(newCardsProvider);
                    ref.invalidate(vocabularyCountProvider);
                    ref.invalidate(enrichedVocabularyIdsProvider);
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Refresh Availability'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ShadButton.outline(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const SyncStatusScreen(),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync),
                      SizedBox(width: 8),
                      Text('Check Sync Status'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
