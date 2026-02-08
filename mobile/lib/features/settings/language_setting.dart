import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/color_tokens.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supabase_provider.dart';

/// Supported native languages with English and native names.
const supportedLanguages = <String, Map<String, String>>{
  'de': {'english': 'German', 'native': 'Deutsch'},
  'es': {'english': 'Spanish', 'native': 'Español'},
  'fr': {'english': 'French', 'native': 'Français'},
  'pt': {'english': 'Portuguese', 'native': 'Português'},
  'it': {'english': 'Italian', 'native': 'Italiano'},
  'nl': {'english': 'Dutch', 'native': 'Nederlands'},
  'pl': {'english': 'Polish', 'native': 'Polski'},
  'ja': {'english': 'Japanese', 'native': '日本語'},
  'ko': {'english': 'Korean', 'native': '한국어'},
  'zh': {'english': 'Chinese', 'native': '中文'},
};

/// Get language English name for UI
String getLanguageEnglishName(String code) {
  return supportedLanguages[code]?['english'] ?? code;
}

/// Get language native name for UI
String getLanguageNativeName(String code) {
  return supportedLanguages[code]?['native'] ?? code;
}

/// Meaning display mode options with descriptions.
const displayModes = <String, Map<String, String>>{
  'both': {'label': 'Both', 'subtitle': 'Show definition and translation'},
  'english': {
    'label': 'Definition only',
    'subtitle': 'Immersive learning experience',
  },
  'native': {
    'label': 'Translation only',
    'subtitle': 'Quickest for memorization',
  },
};

/// Get display mode label for UI
String getDisplayModeLabel(String mode) {
  return displayModes[mode]?['label'] ?? mode;
}

/// Widget for selecting native language for enrichment.
class NativeLanguageSetting extends ConsumerWidget {
  const NativeLanguageSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final prefsAsync = ref.watch(userPreferencesProvider);

    return prefsAsync.when(
      loading: () => ListTile(
        title: Text(
          'Native language',
          style: MasteryTextStyles.body.copyWith(
            color: context.masteryColors.foreground,
          ),
        ),
        subtitle: Text(
          'Loading...',
          style: MasteryTextStyles.bodySmall.copyWith(
            color: context.masteryColors.mutedForeground,
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
              color: context.masteryColors.foreground,
            ),
          ),
          subtitle: Text(
            getLanguageEnglishName(currentCode),
            style: MasteryTextStyles.bodySmall.copyWith(
              color: context.masteryColors.mutedForeground,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: context.masteryColors.mutedForeground,
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
            final code = entry.key;
            final englishName = entry.value['english']!;
            return ListTile(
              title: Text(englishName),
              trailing: code == currentCode
                  ? Icon(Icons.check, color: context.masteryColors.success)
                  : null,
              onTap: () async {
                final dataService = ref.read(supabaseDataServiceProvider);
                await dataService.updatePreferences(
                  userId: userId,
                  nativeLanguageCode: code,
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
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final prefsAsync = ref.watch(userPreferencesProvider);

    return prefsAsync.when(
      loading: () => ListTile(
        title: Text(
          'Meaning display',
          style: MasteryTextStyles.body.copyWith(
            color: context.masteryColors.foreground,
          ),
        ),
        subtitle: Text(
          'Loading...',
          style: MasteryTextStyles.bodySmall.copyWith(
            color: context.masteryColors.mutedForeground,
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
              color: context.masteryColors.foreground,
            ),
          ),
          subtitle: Text(
            getDisplayModeLabel(currentMode),
            style: MasteryTextStyles.bodySmall.copyWith(
              color: context.masteryColors.mutedForeground,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: context.masteryColors.mutedForeground,
          ),
          onTap: () =>
              _showDisplayModePicker(context, ref, userId, currentMode),
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
            final mode = entry.key;
            final label = entry.value['label']!;
            return ListTile(
              title: Text(label),
              trailing: mode == currentMode
                  ? Icon(Icons.check, color: context.masteryColors.success)
                  : null,
              onTap: () async {
                final dataService = ref.read(supabaseDataServiceProvider);
                await dataService.updatePreferences(
                  userId: userId,
                  meaningDisplayMode: mode,
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
