import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/dev_mode_provider.dart';
import '../../../../providers/ui_preferences_provider.dart';
import '../widgets/profile_card.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_list_item.dart';

/// Settings screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _showDefinitions = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final showEnrichmentProgressOnHome = ref.watch(
      showEnrichmentProgressOnHomeProvider,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Settings',
                  style: MasteryTextStyles.displayLarge.copyWith(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                primary: false,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile section
                    currentUser.when(
                      data: (user) => ProfileCard(
                        name:
                            (user?.userMetadata?['full_name'] as String?) ??
                            'User',
                        email: user?.email ?? 'user@example.com',
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),

                    // Learning preferences section
                    SettingsSection(
                      title: 'LEARNING PREFERENCES',
                      children: [
                        SettingsListItem(
                          label: 'Daily Goal',
                          value: '15 words',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Daily goal not yet configurable',
                                ),
                              ),
                            );
                          },
                        ),
                        SettingsListItem(
                          label: 'Notifications',
                          trailing: ShadSwitch(
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() => _notificationsEnabled = value);
                            },
                          ),
                        ),
                        SettingsListItem(
                          label: 'Show Definitions',
                          trailing: ShadSwitch(
                            value: _showDefinitions,
                            onChanged: (value) {
                              setState(() => _showDefinitions = value);
                            },
                          ),
                        ),
                        SettingsListItem(
                          label: 'Show enrichment progress on Home',
                          trailing: ShadSwitch(
                            value: showEnrichmentProgressOnHome,
                            onChanged: (value) {
                              ref
                                      .read(
                                        showEnrichmentProgressOnHomeProvider
                                            .notifier,
                                      )
                                      .state =
                                  value;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Account section
                    SettingsSection(
                      title: 'ACCOUNT',
                      children: [
                        SettingsListItem(
                          label: 'Export Data',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Export not yet implemented'),
                              ),
                            );
                          },
                        ),
                        SettingsListItem(
                          label: 'Sign Out',
                          isDanger: true,
                          onTap: () => _showSignOutDialog(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // About section
                    SettingsSection(
                      title: 'ABOUT',
                      children: [
                        GestureDetector(
                          onLongPress: () {
                            final currentDevMode = ref.read(devModeProvider);
                            ref.read(devModeProvider.notifier).state =
                                !currentDevMode;
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
                        SettingsListItem(
                          label: 'Help & Feedback',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Help not yet available'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
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
