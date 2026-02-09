import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/app_defaults.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../domain/models/user_preferences.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/dev_mode_provider.dart';
import '../../../learn/providers/learning_preferences_providers.dart';
import '../../../sync/presentation/screens/sync_status_screen.dart';
import '../../language_setting.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_list_item.dart';

String retentionLabelFor(double retention) {
  if (retention <= AppDefaults.retentionEfficient) {
    return 'Efficient';
  }
  if (retention <= AppDefaults.retentionBalanced) {
    return 'Balanced';
  }
  return 'Reinforced';
}

String newWordsPerSessionLabelFor(int newWordsPerSession) {
  switch (newWordsPerSession) {
    case AppDefaults.newWordsFew:
      return 'Few';
    case AppDefaults.newWordsNormal:
      return 'Normal';
    case AppDefaults.newWordsMany:
      return 'Many';
    default:
      return 'Normal';
  }
}

/// Unified settings screen with iOS grouped-list pattern
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(learningPreferencesNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: MasteryTextStyles.bodyBold.copyWith(
            color: context.masteryColors.foreground,
          ),
        ),
        backgroundColor: context.masteryColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.masteryColors.foreground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: prefsAsync.when(
        data: (prefs) =>
            _buildSettingsContent(context, ref, prefs, currentUser),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error loading preferences',
            style: MasteryTextStyles.body.copyWith(
              color: context.masteryColors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
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
                onTap: () => _showSessionLengthSheet(context, ref, prefs),
              ),
              SettingsListItem(
                label: 'New words per session',
                value: newWordsPerSessionLabelFor(prefs.newWordsPerSession),
                onTap: () => _showNewWordsPerSessionSheet(context, ref, prefs),
              ),
              SettingsListItem(
                label: 'Review intensity',
                value: retentionLabelFor(prefs.targetRetention),
                onTap: () => _showRetentionSheet(context, ref, prefs),
              ),
              SettingsListItem(
                label: 'Native language',
                value: getLanguageEnglishName(prefs.nativeLanguageCode),
                onTap: () => _showNativeLanguageSheet(context, ref, prefs),
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
                child: const SettingsListItem(label: 'Version', value: '1.0.0'),
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

  Widget _buildProfileRow(BuildContext context, String name, String email) {
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
              color: context.masteryColors.muted,
              border: Border.all(color: context.masteryColors.border, width: 1),
            ),
            child: Icon(
              Icons.person,
              color: context.masteryColors.mutedForeground,
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
                    color: context.masteryColors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: MasteryTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: context.masteryColors.mutedForeground,
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
    if (minutes <= AppDefaults.sessionQuick) return 'Quick and easy';
    if (minutes <= AppDefaults.sessionRegular) return 'Regular';
    if (minutes <= AppDefaults.sessionSerious) return 'Serious';
    return 'Custom ($minutes min)';
  }

  // =============================================================================
  // Bottom Sheet Helper
  // =============================================================================

  /// Shared bottom sheet scaffold with drag handle and title
  void _showBottomSheet({
    required BuildContext context,
    required String title,
    required List<Widget> options,
    BoxConstraints? constraints,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.masteryColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 20),
          constraints: constraints,
          child: Column(
            mainAxisSize: constraints != null ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: context.masteryColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  title,
                  style: MasteryTextStyles.bodyBold.copyWith(
                    fontSize: 18,
                    color: context.masteryColors.foreground,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Options
              if (constraints != null)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(children: options),
                  ),
                )
              else
                ...options,
            ],
          ),
        );
      },
    );
  }

  // =============================================================================
  // Bottom Sheets (Fibonacci: 3, 5, 8)
  // =============================================================================

  void _showSessionLengthSheet(
    BuildContext context,
    WidgetRef ref,
    UserPreferencesModel prefs,
  ) {
    _showBottomSheet(
      context: context,
      title: 'Session length',
      options: [
        _buildSheetOption(
          context: context,
          ref: ref,
          label: 'Quick and easy',
          subtitle: '${AppDefaults.sessionQuick} minutes per session',
          isSelected: prefs.dailyTimeTargetMinutes <= AppDefaults.sessionQuick,
          onTap: () {
            ref
                .read(learningPreferencesNotifierProvider.notifier)
                .updateDailyTimeTarget(AppDefaults.sessionQuick);
            Navigator.pop(context);
          },
        ),
        _buildSheetOption(
          context: context,
          ref: ref,
          label: 'Regular',
          subtitle: '${AppDefaults.sessionRegular} minutes per session',
          isSelected:
              prefs.dailyTimeTargetMinutes > AppDefaults.sessionQuick &&
              prefs.dailyTimeTargetMinutes <= AppDefaults.sessionRegular,
          onTap: () {
            ref
                .read(learningPreferencesNotifierProvider.notifier)
                .updateDailyTimeTarget(AppDefaults.sessionRegular);
            Navigator.pop(context);
          },
        ),
        _buildSheetOption(
          context: context,
          ref: ref,
          label: 'Serious',
          subtitle: '${AppDefaults.sessionSerious} minutes per session',
          isSelected: prefs.dailyTimeTargetMinutes > AppDefaults.sessionRegular,
          onTap: () {
            ref
                .read(learningPreferencesNotifierProvider.notifier)
                .updateDailyTimeTarget(AppDefaults.sessionSerious);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showNewWordsPerSessionSheet(
    BuildContext context,
    WidgetRef ref,
    UserPreferencesModel prefs,
  ) {
    _showBottomSheet(
      context: context,
      title: 'New words per session',
      options: [
        _buildSheetOption(
          context: context,
          ref: ref,
          label: 'Few',
          subtitle:
              '${AppDefaults.newWordsFew} new words • More time for reviews',
          isSelected:
              prefs.newWordsPerSession ==
              AppDefaults.newWordsFew,
          onTap: () {
            ref
                .read(learningPreferencesNotifierProvider.notifier)
                .updateNewWordsPerSession(
                  AppDefaults.newWordsFew,
                );
            Navigator.pop(context);
          },
        ),
        _buildSheetOption(
          context: context,
          ref: ref,
          label: 'Normal',
          subtitle:
              '${AppDefaults.newWordsNormal} new words • Best for most learners',
          isSelected:
              prefs.newWordsPerSession ==
              AppDefaults.newWordsNormal,
          onTap: () {
            ref
                .read(learningPreferencesNotifierProvider.notifier)
                .updateNewWordsPerSession(
                  AppDefaults.newWordsNormal,
                );
            Navigator.pop(context);
          },
        ),
        _buildSheetOption(
          context: context,
          ref: ref,
          label: 'Many',
          subtitle:
              '${AppDefaults.newWordsMany} new words • Faster vocabulary growth',
          isSelected:
              prefs.newWordsPerSession ==
              AppDefaults.newWordsMany,
          onTap: () {
            ref
                .read(learningPreferencesNotifierProvider.notifier)
                .updateNewWordsPerSession(
                  AppDefaults.newWordsMany,
                );
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showRetentionSheet(
    BuildContext context,
    WidgetRef ref,
    UserPreferencesModel prefs,
  ) {
    _showBottomSheet(
      context: context,
      title: 'Review intensity',
      options: [
        _buildSheetOption(
          context: context,
          ref: ref,
          label: 'Efficient',
          subtitle:
              '${(AppDefaults.retentionEfficient * 100).toInt()}% retention • Fewer reviews, each one is harder',
          isSelected:
              prefs.targetRetention <=
              AppDefaults.retentionEfficient,
          onTap: () {
            ref
                .read(learningPreferencesNotifierProvider.notifier)
                .updateTargetRetention(
                  AppDefaults.retentionEfficient,
                );
            Navigator.pop(context);
          },
        ),
        _buildSheetOption(
          context: context,
          ref: ref,
          label: 'Balanced',
          subtitle:
              '${(AppDefaults.retentionBalanced * 100).toInt()}% retention • Best for most learners',
          isSelected:
              prefs.targetRetention >
                  AppDefaults.retentionEfficient &&
              prefs.targetRetention <=
                  AppDefaults.retentionBalanced,
          onTap: () {
            ref
                .read(learningPreferencesNotifierProvider.notifier)
                .updateTargetRetention(
                  AppDefaults.retentionBalanced,
                );
            Navigator.pop(context);
          },
        ),
        _buildSheetOption(
          context: context,
          ref: ref,
          label: 'Reinforced',
          subtitle:
              '${(AppDefaults.retentionReinforced * 100).toInt()}% retention • More reviews, each one is easier',
          isSelected:
              prefs.targetRetention >
              AppDefaults.retentionBalanced,
          onTap: () {
            ref
                .read(learningPreferencesNotifierProvider.notifier)
                .updateTargetRetention(
                  AppDefaults.retentionReinforced,
                );
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showNativeLanguageSheet(
    BuildContext context,
    WidgetRef ref,
    UserPreferencesModel prefs,
  ) {
    _showBottomSheet(
      context: context,
      title: 'Native language',
      constraints: const BoxConstraints(maxHeight: 500),
      options: supportedLanguages.entries.map((entry) {
        final code = entry.key;
        final englishName = entry.value['english']!;
        final nativeName = entry.value['native']!;
        return _buildSheetOption(
          context: context,
          ref: ref,
          label: englishName,
          subtitle: nativeName,
          isSelected: prefs.nativeLanguageCode == code,
          onTap: () async {
            await ref
                .read(learningPreferencesNotifierProvider.notifier)
                .updateNativeLanguage(code);
            if (context.mounted) Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  Widget _buildSheetOption({
    required BuildContext context,
    required WidgetRef ref,
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
            bottom: BorderSide(color: context.masteryColors.border, width: 1),
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
                          ? context.masteryColors.accent
                          : context.masteryColors.foreground,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: MasteryTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: context.masteryColors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: context.masteryColors.accent, size: 24)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.masteryColors.border,
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
            child: Text(
              'Sign Out',
              style: TextStyle(color: context.masteryColors.destructive),
            ),
          ),
        ],
      ),
    );
  }
}
