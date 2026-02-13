import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/logging/decision_log.dart';
import 'core/network/connectivity.dart';
import 'core/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/color_tokens.dart';
import 'core/widgets/global_status_banner.dart';
import 'features/auth/auth_guard.dart';
import 'features/home/presentation/screens/today_screen.dart';
import 'providers/review_write_queue_provider.dart';
import 'providers/supabase_provider.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: '.env');
      try {
        await SupabaseConfig.initialize();
        await DecisionLog.init(SupabaseConfig.client);
      } catch (e) {
        debugPrint('Supabase init failed: $e');
        // App can still run, will show auth screen
      }
      final sharedPreferences = await SharedPreferences.getInstance();

      final sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';
      if (sentryDsn.isNotEmpty) {
        await SentryFlutter.init(
          (options) {
            options.dsn = sentryDsn;
            options.tracesSampleRate = 0.2;
          },
          appRunner: () => _runApp(sharedPreferences),
        );
      } else {
        _runApp(sharedPreferences);
      }
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack: $stack');
      Sentry.captureException(error, stackTrace: stack);
    },
  );
}

void _runApp(SharedPreferences sharedPreferences) {
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MasteryApp(),
    ),
  );
}

class MasteryApp extends StatefulWidget {
  const MasteryApp({super.key});

  @override
  State<MasteryApp> createState() => _MasteryAppState();
}

class _MasteryAppState extends State<MasteryApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DecisionLog.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(DecisionLog.flush());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Mastery',
      theme: MasteryTheme.light,
      darkTheme: MasteryTheme.dark,
      builder: (context, child) {
        // Add ThemeExtension support by wrapping with Theme widget
        final brightness = Theme.of(context).brightness;
        final themeData = Theme.of(context).copyWith(
          extensions: [
            brightness == Brightness.dark
                ? MasteryColorScheme.dark
                : MasteryColorScheme.light,
          ],
        );
        return Theme(
          data: themeData,
          child: ScaffoldMessenger(child: child ?? const SizedBox.shrink()),
        );
      },
      home: const AuthGuard(child: HomeScreen()),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final vocabularyCount = ref.watch(vocabularyCountProvider);
    final enrichedVocabularyIds = ref.watch(enrichedVocabularyIdsProvider);
    final statusBannerData = deriveGlobalStatusBannerData(
      connectivity: connectivity,
      vocabularyCount: vocabularyCount,
      enrichedVocabularyIds: enrichedVocabularyIds,
      showEnrichmentProgress: false,
    );

    return Scaffold(
      body: Column(
        children: [
          if (statusBannerData != null)
            GlobalStatusBanner(
              data: statusBannerData,
              actionLabel: _statusActionLabel(statusBannerData.type),
              onActionPressed: () => _handleStatusAction(ref, statusBannerData.type),
            ),
          const Expanded(child: TodayScreen()),
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

  void _handleStatusAction(WidgetRef ref, GlobalStatusType type) {
    switch (type) {
      case GlobalStatusType.offline:
        ref.read(connectivityProvider.notifier).checkNow();
        ref.invalidate(vocabularyCountProvider);
        ref.invalidate(enrichedVocabularyIdsProvider);
        return;
      case GlobalStatusType.syncError:
        ref.invalidate(vocabularyCountProvider);
        ref.invalidate(enrichedVocabularyIdsProvider);
        return;
      case GlobalStatusType.enrichmentProgress:
        return;
    }
  }
}
