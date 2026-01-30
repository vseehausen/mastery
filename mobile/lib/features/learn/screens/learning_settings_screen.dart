import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/database/database.dart';
import '../../../data/repositories/user_preferences_repository.dart';
import '../../../domain/models/learning_enums.dart';
import '../providers/learning_preferences_providers.dart';

/// Screen for configuring learning preferences
/// - Daily time target (5/10/15/20 min presets + custom 1-60)
/// - Intensity (Light/Normal/Intense)
/// - Target retention (85-95%)
class LearningSettingsScreen extends ConsumerStatefulWidget {
  const LearningSettingsScreen({super.key});

  @override
  ConsumerState<LearningSettingsScreen> createState() =>
      _LearningSettingsScreenState();
}

class _LearningSettingsScreenState
    extends ConsumerState<LearningSettingsScreen> {
  late int _selectedTimeTarget;
  late int _selectedIntensity;
  late double _selectedRetention;
  bool _isCustomTime = false;
  final TextEditingController _customTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTimeTarget = 10;
    _selectedIntensity = Intensity.normal;
    _selectedRetention = 0.90;
  }

  @override
  void dispose() {
    _customTimeController.dispose();
    super.dispose();
  }

  void _loadPreferences(UserLearningPreference prefs) {
    _selectedTimeTarget = prefs.dailyTimeTargetMinutes;
    _selectedIntensity = prefs.intensity;
    _selectedRetention = prefs.targetRetention;
    _isCustomTime = ![5, 10, 15, 20].contains(_selectedTimeTarget);
    if (_isCustomTime) {
      _customTimeController.text = _selectedTimeTarget.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefsAsync = ref.watch(learningPreferencesNotifierProvider);

    // Load preferences when they change
    ref.listen(learningPreferencesNotifierProvider, (_, next) {
      if (next.hasValue && next.value != null) {
        setState(() {
          _loadPreferences(next.value!);
        });
      }
    });

    // Initial load
    if (prefsAsync.hasValue && prefsAsync.value != null) {
      // Only set initial values if they haven't been modified
      final prefs = prefsAsync.value!;
      if (_selectedTimeTarget == 10 &&
          _selectedIntensity == Intensity.normal &&
          _selectedRetention == 0.90) {
        _selectedTimeTarget = prefs.dailyTimeTargetMinutes;
        _selectedIntensity = prefs.intensity;
        _selectedRetention = prefs.targetRetention;
        _isCustomTime = ![5, 10, 15, 20].contains(_selectedTimeTarget);
        if (_isCustomTime) {
          _customTimeController.text = _selectedTimeTarget.toString();
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Learning Settings',
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
        data: (prefs) => _buildSettingsContent(context, isDark, prefs),
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
    bool isDark,
    dynamic prefs,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Time Target
          _buildSectionHeader('Daily Practice Time', isDark),
          const SizedBox(height: 12),
          _buildTimeTargetSelector(isDark),

          const SizedBox(height: 32),

          // Intensity
          _buildSectionHeader('Learning Intensity', isDark),
          const SizedBox(height: 8),
          Text(
            'Controls how many new words you learn per session',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(height: 12),
          _buildIntensitySelector(isDark),

          const SizedBox(height: 32),

          // Target Retention
          _buildSectionHeader('Target Retention', isDark),
          const SizedBox(height: 8),
          Text(
            'Higher retention = more frequent reviews, better memory',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(height: 12),
          _buildRetentionSlider(isDark),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: MasteryTextStyles.bodyBold.copyWith(
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildTimeTargetSelector(bool isDark) {
    const presets = [5, 10, 15, 20];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...presets.map((minutes) => _buildTimeButton(minutes, isDark)),
            _buildCustomTimeButton(isDark),
          ],
        ),

        // Custom time input
        if (_isCustomTime) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _customTimeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '1-60',
                    filled: true,
                    fillColor: isDark
                        ? MasteryColors.cardDark
                        : MasteryColors.cardLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? MasteryColors.borderDark
                            : MasteryColors.borderLight,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: MasteryTextStyles.body.copyWith(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onChanged: (value) {
                    final minutes = int.tryParse(value);
                    if (minutes != null && minutes >= 1 && minutes <= 60) {
                      setState(() {
                        _selectedTimeTarget = minutes;
                      });
                      ref
                          .read(learningPreferencesNotifierProvider.notifier)
                          .updateDailyTimeTarget(minutes);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'minutes',
                style: MasteryTextStyles.body.copyWith(
                  color: isDark
                      ? MasteryColors.mutedForegroundDark
                      : MasteryColors.mutedForegroundLight,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTimeButton(int minutes, bool isDark) {
    final isSelected = !_isCustomTime && _selectedTimeTarget == minutes;

    return ShadButton(
      onPressed: () {
        setState(() {
          _selectedTimeTarget = minutes;
          _isCustomTime = false;
        });
        ref
            .read(learningPreferencesNotifierProvider.notifier)
            .updateDailyTimeTarget(minutes);
      },
      backgroundColor: isSelected
          ? (isDark ? MasteryColors.accentDark : MasteryColors.accentLight)
          : (isDark ? MasteryColors.cardDark : MasteryColors.cardLight),
      child: Text(
        '$minutes min',
        style: MasteryTextStyles.bodySmall.copyWith(
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildCustomTimeButton(bool isDark) {
    return ShadButton.outline(
      onPressed: () {
        setState(() {
          _isCustomTime = true;
        });
      },
      backgroundColor: _isCustomTime
          ? (isDark ? MasteryColors.accentDark : MasteryColors.accentLight)
          : (isDark ? MasteryColors.cardDark : MasteryColors.cardLight),
      child: Text(
        'Custom',
        style: MasteryTextStyles.bodySmall.copyWith(
          color: _isCustomTime
              ? Colors.white
              : (isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildIntensitySelector(bool isDark) {
    return Column(
      children: [
        _buildIntensityOption(
          intensity: IntensityEnum.light,
          label: 'Light',
          description: '2 new words per 10 min',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildIntensityOption(
          intensity: IntensityEnum.normal,
          label: 'Normal',
          description: '5 new words per 10 min',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildIntensityOption(
          intensity: IntensityEnum.intense,
          label: 'Intense',
          description: '8 new words per 10 min',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildIntensityOption({
    required IntensityEnum intensity,
    required String label,
    required String description,
    required bool isDark,
  }) {
    final isSelected = _selectedIntensity == intensity.value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIntensity = intensity.value;
        });
        ref
            .read(learningPreferencesNotifierProvider.notifier)
            .updateIntensity(intensity.value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? MasteryColors.cardDark : MasteryColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark
                      ? MasteryColors.accentDark
                      : MasteryColors.accentLight)
                : (isDark
                      ? MasteryColors.borderDark
                      : MasteryColors.borderLight),
            width: isSelected ? 2 : 1,
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
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: MasteryTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? MasteryColors.mutedForegroundDark
                          : MasteryColors.mutedForegroundLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: isDark
                    ? MasteryColors.accentDark
                    : MasteryColors.accentLight,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionSlider(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '85%',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark
                    ? MasteryColors.mutedForegroundDark
                    : MasteryColors.mutedForegroundLight,
              ),
            ),
            Text(
              '${(_selectedRetention * 100).toInt()}%',
              style: MasteryTextStyles.bodyBold.copyWith(
                color: isDark
                    ? MasteryColors.accentDark
                    : MasteryColors.accentLight,
              ),
            ),
            Text(
              '95%',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark
                    ? MasteryColors.mutedForegroundDark
                    : MasteryColors.mutedForegroundLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: isDark
                ? MasteryColors.accentDark
                : MasteryColors.accentLight,
            inactiveTrackColor: isDark
                ? MasteryColors.mutedDark
                : MasteryColors.mutedLight,
            thumbColor: isDark
                ? MasteryColors.accentDark
                : MasteryColors.accentLight,
            overlayColor:
                (isDark ? MasteryColors.accentDark : MasteryColors.accentLight)
                    .withValues(alpha: 0.2),
          ),
          child: Slider(
            value: _selectedRetention,
            min: 0.85,
            max: 0.95,
            divisions: 10,
            onChanged: (value) {
              setState(() {
                _selectedRetention = value;
              });
            },
            onChangeEnd: (value) {
              ref
                  .read(learningPreferencesNotifierProvider.notifier)
                  .updateTargetRetention(value);
            },
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? MasteryColors.mutedDark : MasteryColors.mutedLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: isDark
                    ? MasteryColors.mutedForegroundDark
                    : MasteryColors.mutedForegroundLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedRetention >= 0.92
                      ? 'High retention: Reviews are more frequent'
                      : _selectedRetention <= 0.87
                      ? 'Lower retention: Fewer reviews, risk of forgetting'
                      : 'Balanced: Good retention with moderate reviews',
                  style: MasteryTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? MasteryColors.mutedForegroundDark
                        : MasteryColors.mutedForegroundLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
