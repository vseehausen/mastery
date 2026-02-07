import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'core/network/connectivity.dart';
import 'core/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/bottom_nav_bar.dart';
import 'core/widgets/global_status_banner.dart';
import 'features/auth/auth_guard.dart';
import 'features/home/presentation/screens/today_screen.dart';
import 'features/progress/presentation/screens/progress_screen.dart';
import 'features/sync/presentation/screens/sync_status_screen.dart';
import 'features/vocabulary/presentation/screens/vocabulary_screen.dart';
import 'providers/supabase_provider.dart';
import 'providers/ui_preferences_provider.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: '.env');
      try {
        await SupabaseConfig.initialize();
      } catch (e) {
        debugPrint('Supabase init failed: $e');
        // App can still run, will show auth screen
      }
      runApp(const ProviderScope(child: MasteryApp()));
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack: $stack');
    },
  );
}

class MasteryApp extends StatelessWidget {
  const MasteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Mastery',
      theme: MasteryTheme.light,
      darkTheme: MasteryTheme.dark,
      builder: (context, child) {
        return ScaffoldMessenger(child: child ?? const SizedBox.shrink());
      },
      home: const AuthGuard(child: HomeScreen()),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  bool _dismissedEnrichmentBannerForSession = false;

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider);
    final vocabularyCount = ref.watch(vocabularyCountProvider);
    final enrichedVocabularyIds = ref.watch(enrichedVocabularyIdsProvider);
    final showEnrichmentProgressOnHome = ref.watch(
      showEnrichmentProgressOnHomeProvider,
    );
    final statusBannerData = deriveGlobalStatusBannerData(
      connectivity: connectivity,
      vocabularyCount: vocabularyCount,
      enrichedVocabularyIds: enrichedVocabularyIds,
      showEnrichmentProgress: showEnrichmentProgressOnHome,
    );
    final shouldHideBanner =
        statusBannerData?.type == GlobalStatusType.enrichmentProgress &&
        _dismissedEnrichmentBannerForSession;
    final visibleBannerData = shouldHideBanner ? null : statusBannerData;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Today
          const TodayScreen(),
          // Words
          const VocabularyScreenNew(),
          // Progress
          const ProgressScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (visibleBannerData != null)
            GlobalStatusBanner(
              data: visibleBannerData,
              actionLabel: _statusActionLabel(visibleBannerData.type),
              onActionPressed: () =>
                  _handleStatusAction(visibleBannerData.type),
              onDismissPressed:
                  visibleBannerData.type == GlobalStatusType.enrichmentProgress
                  ? () {
                      setState(
                        () => _dismissedEnrichmentBannerForSession = true,
                      );
                    }
                  : null,
            ),
          BottomNavBar(
            selectedIndex: _selectedIndex,
            onTabSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
        ],
      ),
    );
  }

  String _statusActionLabel(GlobalStatusType type) {
    switch (type) {
      case GlobalStatusType.offline:
        return 'Retry';
      case GlobalStatusType.enrichmentProgress:
        return 'Details';
      case GlobalStatusType.syncError:
        return 'Refresh';
    }
  }

  void _handleStatusAction(GlobalStatusType type) {
    switch (type) {
      case GlobalStatusType.offline:
        ref.read(connectivityProvider.notifier).checkNow();
        ref.invalidate(vocabularyCountProvider);
        ref.invalidate(enrichedVocabularyIdsProvider);
        return;
      case GlobalStatusType.enrichmentProgress:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const SyncStatusScreen(),
          ),
        );
        return;
      case GlobalStatusType.syncError:
        ref.invalidate(vocabularyCountProvider);
        ref.invalidate(enrichedVocabularyIdsProvider);
        return;
    }
  }
}
