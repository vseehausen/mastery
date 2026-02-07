import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../domain/models/user_preferences.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/dev_mode_provider.dart';
import '../../../../providers/supabase_provider.dart';
import '../../../learn/providers/learning_preferences_providers.dart';
import '../../../sync/presentation/screens/sync_status_screen.dart';
import '../../language_setting.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_list_item.dart';

/// Unified settings screen with iOS grouped-list pattern
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefsAsync = ref.watch(learningPreferencesNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: MasteryTextStyles.bodyBold.copyWith(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: prefsAsync.when(
        data: (prefs) => _buildSettingsContent(
          context,
          ref,
          isDark,
          prefs,
          currentUser,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error loading preferences',
            style: MasteryTextStyles.body.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    UserPreferencesModel? prefs,
    AsyncValue<User?> currentUser,
  ) {
    if (prefs == null) {
      return const Center(child: Text('No preferences available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEARNING SECTION
          SettingsSection(
            title: 'LEARNING',
            children: [
              SettingsListItem(
                label: 'Session length',
                value: _getSessionLengthLabel(prefs.dailyTimeTargetMinutes),
                                onTap: () => _showSessionLengthSheet(context, ref, isDark, prefs),
              ),
              SettingsListItem(
                label: 'Intensity',
                value: _getIntensityLabel(prefs.intensity),
                                onTap: () => _showIntensitySheet(context, ref, isDark, prefs),
              ),
              SettingsListItem(
                label: 'Target retention',
                value: _getRetentionLabel(prefs.targetRetention),
                                onTap: () => _showRetentionSheet(context, ref, isDark, prefs),
              ),
              SettingsListItem(
                label: 'Native language',
                value: getLanguageEnglishName(prefs.nativeLanguageCode),
                                onTap: () => _showNativeLanguageSheet(context, ref, isDark, prefs),
              ),
              SettingsListItem(
                label: 'Meaning display',
                value: getDisplayModeLabel(prefs.meaningDisplayMode),
                                onTap: () => _showMeaningDisplaySheet(context, ref, isDark, prefs),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // DATA SECTION
          SettingsSection(
            title: 'DATA',
            children: [
              SettingsListItem(
                label: 'Sync Status',
                                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const SyncStatusScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ACCOUNT SECTION
          SettingsSection(
            title: 'ACCOUNT',
            children: [
              currentUser.when(
                data: (User? user) => _buildProfileRow(
                  context,
                  isDark,
                  (user?.userMetadata?['full_name'] as String?) ?? 'User',
                  user?.email ?? 'user@example.com',
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
              SettingsListItem(
                label: 'Sign Out',
                isDanger: true,
                onTap: () => _showSignOutDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ABOUT SECTION
          SettingsSection(
            title: 'ABOUT',
            children: [
              GestureDetector(
                onLongPress: () {
                  final currentDevMode = ref.read(devModeProvider);
                  ref.read(devModeProvider.notifier).state = !currentDevMode;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        currentDevMode
                            ? 'Dev mode disabled'
                            : 'Dev mode enabled',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const SettingsListItem(
                  label: 'Version',
                  value: '1.0.0',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // Profile Row
  // =============================================================================

  Widget _buildProfileRow(
    BuildContext context,
    bool isDark,
    String name,
    String email,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? MasteryColors.mutedDark : MasteryColors.mutedLight,
              border: Border.all(
                color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.person,
              color: isDark ? MasteryColors.mutedForegroundDark : MasteryColors.mutedForegroundLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: MasteryTextStyles.bodyBold.copyWith(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: MasteryTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: isDark ? MasteryColors.mutedForegroundDark : MasteryColors.mutedForegroundLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // Label Getters (Fibonacci: 3, 5, 8)
  // =============================================================================

  String _getSessionLengthLabel(int minutes) {
    if (minutes <= 3) return 'Quick and easy';
    if (minutes <= 5) return 'Regular';
    if (minutes <= 8) return 'Serious';
    return 'Custom ($minutes min)';
  }

  String _getIntensityLabel(int intensity) {
    switch (intensity) {
      case 0: return 'Light';
      case 1: return 'Normal';
      case 2: return 'Intense';
      default: return 'Normal';
    }
  }

  String _getRetentionLabel(double retention) {
    if (retention < 0.87) return 'Moderate';
    if (retention < 0.90) return 'Balanced';
    return 'Perfectionist';
  }

  // =============================================================================
  // Bottom Sheets (Fibonacci: 3, 5, 8)
  // =============================================================================

  void _showSessionLengthSheet(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    UserPreferencesModel prefs,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? MasteryColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Session length',
                  style: MasteryTextStyles.bodyBold.copyWith(
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Options (Fibonacci: 3, 5, 8)
              _buildSheetOption(
                context: context,
                ref: ref,
                isDark: isDark,
                label: 'Quick and easy',
                subtitle: '3 minutes per session',
                isSelected: prefs.dailyTimeTargetMinutes <= 3,
                onTap: () {
                  ref
                      .read(learningPreferencesNotifierProvider.notifier)
                      .updateDailyTimeTarget(3);
                  Navigator.pop(context);
                },
              ),
              _buildSheetOption(
                context: context,
                ref: ref,
                isDark: isDark,
                label: 'Regular',
                subtitle: '5 minutes per session',
                isSelected: prefs.dailyTimeTargetMinutes > 3 && prefs.dailyTimeTargetMinutes <= 5,
                onTap: () {
                  ref
                      .read(learningPreferencesNotifierProvider.notifier)
                      .updateDailyTimeTarget(5);
                  Navigator.pop(context);
                },
              ),
              _buildSheetOption(
                context: context,
                ref: ref,
                isDark: isDark,
                label: 'Serious',
                subtitle: '8 minutes per session',
                isSelected: prefs.dailyTimeTargetMinutes > 5,
                onTap: () {
                  ref
                      .read(learningPreferencesNotifierProvider.notifier)
                      .updateDailyTimeTarget(8);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showIntensitySheet(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    UserPreferencesModel prefs,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? MasteryColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Intensity',
                  style: MasteryTextStyles.bodyBold.copyWith(
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Options (Fibonacci: 3, 5, 8)
              _buildSheetOption(
                context: context,
                ref: ref,
                isDark: isDark,
                label: 'Light',
                subtitle: '3 new words per session',
                isSelected: prefs.intensity == 0,
                onTap: () {
                  ref
                      .read(learningPreferencesNotifierProvider.notifier)
                      .updateIntensity(0);
                  Navigator.pop(context);
                },
              ),
              _buildSheetOption(
                context: context,
                ref: ref,
                isDark: isDark,
                label: 'Normal',
                subtitle: '5 new words per session',
                isSelected: prefs.intensity == 1,
                onTap: () {
                  ref
                      .read(learningPreferencesNotifierProvider.notifier)
                      .updateIntensity(1);
                  Navigator.pop(context);
                },
              ),
              _buildSheetOption(
                context: context,
                ref: ref,
                isDark: isDark,
                label: 'Intense',
                subtitle: '8 new words per session',
                isSelected: prefs.intensity == 2,
                onTap: () {
                  ref
                      .read(learningPreferencesNotifierProvider.notifier)
                      .updateIntensity(2);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRetentionSheet(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    UserPreferencesModel prefs,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? MasteryColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Target retention',
                  style: MasteryTextStyles.bodyBold.copyWith(
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Options (85%, 90%, 95%)
              _buildSheetOption(
                context: context,
                ref: ref,
                isDark: isDark,
                label: 'Moderate',
                subtitle: '85% retention • Fewer reviews',
                isSelected: prefs.targetRetention < 0.87,
                onTap: () {
                  ref
                      .read(learningPreferencesNotifierProvider.notifier)
                      .updateTargetRetention(0.85);
                  Navigator.pop(context);
                },
              ),
              _buildSheetOption(
                context: context,
                ref: ref,
                isDark: isDark,
                label: 'Balanced',
                subtitle: '90% retention • Recommended',
                isSelected: prefs.targetRetention >= 0.87 && prefs.targetRetention < 0.92,
                onTap: () {
                  ref
                      .read(learningPreferencesNotifierProvider.notifier)
                      .updateTargetRetention(0.90);
                  Navigator.pop(context);
                },
              ),
              _buildSheetOption(
                context: context,
                ref: ref,
                isDark: isDark,
                label: 'Perfectionist',
                subtitle: '95% retention • Heavy workload',
                isSelected: prefs.targetRetention >= 0.92,
                onTap: () {
                  ref
                      .read(learningPreferencesNotifierProvider.notifier)
                      .updateTargetRetention(0.95);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNativeLanguageSheet(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    UserPreferencesModel prefs,
  ) {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? MasteryColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 20),
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Native language',
                  style: MasteryTextStyles.bodyBold.copyWith(
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Scrollable options
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: supportedLanguages.entries.map((entry) {
                final code = entry.key;
                final englishName = entry.value['english']!;
                final nativeName = entry.value['native']!;
                return _buildSheetOption(
                  context: context,
                  ref: ref,
                  isDark: isDark,
                  label: englishName,
                  subtitle: nativeName,
                  isSelected: prefs.nativeLanguageCode == code,
                  onTap: () async {
                    final dataService = ref.read(supabaseDataServiceProvider);
                    await dataService.updatePreferences(
                      userId: userId,
                      nativeLanguageCode: code,
                    );
                    ref.invalidate(learningPreferencesNotifierProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMeaningDisplaySheet(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    UserPreferencesModel prefs,
  ) {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? MasteryColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Meaning display',
                  style: MasteryTextStyles.bodyBold.copyWith(
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Options
              ...displayModes.entries.map((entry) {
                final mode = entry.key;
                final label = entry.value['label']!;
                final subtitle = entry.value['subtitle']!;
                return _buildSheetOption(
                  context: context,
                  ref: ref,
                  isDark: isDark,
                  label: label,
                  subtitle: subtitle,
                  isSelected: prefs.meaningDisplayMode == mode,
                  onTap: () async {
                    final dataService = ref.read(supabaseDataServiceProvider);
                    await dataService.updatePreferences(
                      userId: userId,
                      meaningDisplayMode: mode,
                    );
                    ref.invalidate(learningPreferencesNotifierProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
    required BuildContext context,
    required WidgetRef ref,
    required bool isDark,
    required String label,
    required String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: MasteryTextStyles.bodyBold.copyWith(
                      fontSize: 14,
                      color: isSelected
                          ? MasteryColors.accentLight
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: MasteryTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: isDark
                            ? MasteryColors.mutedForegroundDark
                            : MasteryColors.mutedForegroundLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: MasteryColors.accentLight,
                size: 24,
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.signOut();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
