import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/color_tokens.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supabase_provider.dart';

/// Supported native languages for enrichment.
const supportedLanguages = <String, String>{
  'de': 'German',
  'es': 'Spanish',
  'fr': 'French',
  'pt': 'Portuguese',
  'it': 'Italian',
  'nl': 'Dutch',
  'pl': 'Polish',
  'ja': 'Japanese',
  'ko': 'Korean',
  'zh': 'Chinese',
};

/// Meaning display mode options.
const displayModes = <String, String>{
  'both': 'Both (native + English)',
  'native': 'Native translation only',
  'english': 'English definition only',
};

/// Widget for selecting native language for enrichment.
class NativeLanguageSetting extends ConsumerWidget {
  const NativeLanguageSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final prefsAsync = ref.watch(userPreferencesProvider);

    return prefsAsync.when(
      loading: () => ListTile(
        title: Text(
          'Native language',
          style: MasteryTextStyles.body.copyWith(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          'Loading...',
          style: MasteryTextStyles.bodySmall.copyWith(
            color: isDark
                ? MasteryColors.mutedForegroundDark
                : MasteryColors.mutedForegroundLight,
          ),
        ),
      ),
      error: (e, s) => const SizedBox.shrink(),
      data: (prefs) {
        final currentCode = prefs.nativeLanguageCode;
        return ListTile(
          title: Text(
            'Native language',
            style: MasteryTextStyles.body.copyWith(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            supportedLanguages[currentCode] ?? currentCode,
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: isDark
                ? MasteryColors.mutedForegroundDark
                : MasteryColors.mutedForegroundLight,
          ),
          onTap: () => _showLanguagePicker(context, ref, userId, currentCode),
        );
      },
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String currentCode,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: supportedLanguages.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              trailing: entry.key == currentCode
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () async {
                final dataService = ref.read(supabaseDataServiceProvider);
                await dataService.updatePreferences(
                  userId: userId,
                  nativeLanguageCode: entry.key,
                );
                ref.invalidate(userPreferencesProvider);
                if (context.mounted) Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }
}

/// Widget for toggling meaning display mode.
class MeaningDisplayModeSetting extends ConsumerWidget {
  const MeaningDisplayModeSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final prefsAsync = ref.watch(userPreferencesProvider);

    return prefsAsync.when(
      loading: () => ListTile(
        title: Text(
          'Meaning display',
          style: MasteryTextStyles.body.copyWith(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          'Loading...',
          style: MasteryTextStyles.bodySmall.copyWith(
            color: isDark
                ? MasteryColors.mutedForegroundDark
                : MasteryColors.mutedForegroundLight,
          ),
        ),
      ),
      error: (e, s) => const SizedBox.shrink(),
      data: (prefs) {
        final currentMode = prefs.meaningDisplayMode;
        return ListTile(
          title: Text(
            'Meaning display',
            style: MasteryTextStyles.body.copyWith(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            displayModes[currentMode] ?? currentMode,
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: isDark
                ? MasteryColors.mutedForegroundDark
                : MasteryColors.mutedForegroundLight,
          ),
          onTap: () => _showDisplayModePicker(context, ref, userId, currentMode),
        );
      },
    );
  }

  void _showDisplayModePicker(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String currentMode,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: displayModes.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              trailing: entry.key == currentMode
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () async {
                final dataService = ref.read(supabaseDataServiceProvider);
                await dataService.updatePreferences(
                  userId: userId,
                  meaningDisplayMode: entry.key,
                );
                ref.invalidate(userPreferencesProvider);
                if (context.mounted) Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
