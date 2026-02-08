import 'package:flutter/material.dart';

/// Mastery color tokens - Zinc palette + Indigo accent
/// Generated from design system v2.1.0
///
/// Usage with ThemeExtension (recommended):
/// ```dart
/// final colors = context.masteryColors;
/// Container(color: colors.cardBackground)
/// ```
///
/// Usage with static constants (backward compatibility):
/// ```dart
/// Container(color: MasteryColors.cardLight)
/// ```
class MasteryColors {
  MasteryColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // SURFACES
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF09090B); // zinc-950

  static const Color foregroundLight = Color(0xFF09090B); // zinc-950
  static const Color foregroundDark = Color(0xFFFAFAFA); // zinc-50

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF18181B); // zinc-900

  static const Color cardForegroundLight = Color(0xFF09090B); // zinc-950
  static const Color cardForegroundDark = Color(0xFFFAFAFA); // zinc-50

  static const Color popoverLight = Color(0xFFFFFFFF);
  static const Color popoverDark = Color(0xFF18181B); // zinc-900

  static const Color popoverForegroundLight = Color(0xFF09090B); // zinc-950
  static const Color popoverForegroundDark = Color(0xFFFAFAFA); // zinc-50

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color primaryLight = Color(0xFF09090B); // zinc-950
  static const Color primaryDark = Color(0xFFFAFAFA); // zinc-50

  static const Color primaryForegroundLight = Color(0xFFFFFFFF);
  static const Color primaryForegroundDark = Color(0xFF09090B); // zinc-950

  static const Color secondaryLight = Color(0xFFF4F4F5); // zinc-100
  static const Color secondaryDark = Color(0xFF27272A); // zinc-800

  static const Color secondaryForegroundLight = Color(0xFF09090B); // zinc-950
  static const Color secondaryForegroundDark = Color(0xFFFAFAFA); // zinc-50

  static const Color accentLight = Color(0xFF4F46E5); // indigo-600
  static const Color accentDark = Color(0xFF6366F1); // indigo-500

  static const Color accentForegroundLight = Color(0xFFFFFFFF);
  static const Color accentForegroundDark = Color(0xFFFFFFFF);

  static const Color destructiveLight = Color(0xFFDC2626); // red-600
  static const Color destructiveDark = Color(0xFFF87171); // red-400

  static const Color destructiveForegroundLight = Color(0xFFFFFFFF);
  static const Color destructiveForegroundDark = Color(0xFFFEF2F2); // red-50

  // ═══════════════════════════════════════════════════════════════════════════
  // NEUTRAL
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color mutedLight = Color(0xFFF4F4F5); // zinc-100
  static const Color mutedDark = Color(0xFF27272A); // zinc-800

  static const Color mutedForegroundLight = Color(0xFF71717A); // zinc-500
  static const Color mutedForegroundDark = Color(0xFFA1A1AA); // zinc-400

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM / INTERACTIVE
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color borderLight = Color(0xFFE4E4E7); // zinc-200
  static const Color borderDark = Color(0xFF27272A); // zinc-800

  static const Color inputLight = Color(0xFFFFFFFF);
  static const Color inputDark = Color(0xFF27272A); // zinc-800

  static const Color ringLight = Color(0xFF09090B); // zinc-950
  static const Color ringDark = Color(0xFFA1A1AA); // zinc-400

  static const Color selectionLight = Color(0xFFC7D2FE); // indigo-200
  static const Color selectionDark = Color(0xFF3730A3); // indigo-800

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC STATE EXTENSIONS
  // ═══════════════════════════════════════════════════════════════════════════

  // Success (Emerald) - "known" status, correct answers, positive states
  static const Color successLight = Color(0xFF10B981); // emerald-500
  static const Color successDark = Color(0xFF059669); // emerald-600

  static const Color successForegroundLight = Color(0xFFFFFFFF);
  static const Color successForegroundDark = Color(0xFFFFFFFF);

  static const Color successMutedLight = Color(0xFFECFDF5);
  static const Color successMutedDark = Color(0xFF064E3B);

  // Warning (Amber) - "learning" status, timer warnings, caution states
  static const Color warningLight = Color(0xFFF59E0B); // amber-500
  static const Color warningDark = Color(0xFFD97706); // amber-600

  static const Color warningForegroundLight = Color(0xFF000000);
  static const Color warningForegroundDark = Color(0xFFFFFFFF);

  static const Color warningMutedLight = Color(0xFFFFFBEB);
  static const Color warningMutedDark = Color(0xFF451A03);

  // Info (Blue) - informational states, translation cue type
  static const Color infoLight = Color(0xFF3B82F6);
  static const Color infoDark = Color(0xFF60A5FA);

  static const Color infoForegroundLight = Color(0xFFFFFFFF);
  static const Color infoForegroundDark = Color(0xFF172554);

  // ═══════════════════════════════════════════════════════════════════════════
  // VOCABULARY STAGES (8B-R4 lightness ramp: dark→bright)
  // ═══════════════════════════════════════════════════════════════════════════

  // Captured (Stone) — word captured, not yet reviewed
  static const Color stageCapturedLight = Color(0xFF57534E); // stone-600
  static const Color stageCapturedDark = Color(0xFF78716C); // stone-500
  static const Color stageCapturedBgLight = Color(0xFFF5F5F4); // stone-100
  static const Color stageCapturedBgDark = Color(0xFF1C1917); // stone-900

  // Practicing (Lime) — first review completed, in SRS rotation
  static const Color stagePracticingLight = Color(0xFF3F6212); // lime-800
  static const Color stagePracticingDark = Color(0xFF65A30D); // lime-600
  static const Color stagePracticingBgLight = Color(0xFFECFCCB); // lime-100
  static const Color stagePracticingBgDark = Color(0xFF1A2E05); // lime-950

  // Stabilizing (Emerald) — multiple successful recalls
  static const Color stageStabilizingLight = Color(0xFF047857); // emerald-700
  static const Color stageStabilizingDark = Color(0xFF10B981); // emerald-500
  static const Color stageStabilizingBgLight = Color(0xFFD1FAE5); // emerald-100
  static const Color stageStabilizingBgDark = Color(0xFF064E3B); // emerald-800

  // Active (Blue) — production recall from non-translation cues
  static const Color stageActiveLight = Color(0xFF2563EB); // blue-600
  static const Color stageActiveDark = Color(0xFF93C5FD); // blue-300
  static const Color stageActiveBgLight = Color(0xFFDBEAFE); // blue-100
  static const Color stageActiveBgDark = Color(0xFF1E3A5F); // blue-900

  // Mastered (Amber) — high stability, rare reviews
  static const Color stageMasteredLight = Color(0xFFF59E0B); // amber-500
  static const Color stageMasteredDark = Color(0xFFFBBF24); // amber-400
  static const Color stageMasteredBgLight = Color(0xFFFEF9C3); // yellow-100
  static const Color stageMasteredBgDark = Color(0xFF451A03); // amber-950

  // ═══════════════════════════════════════════════════════════════════════════
  // DOMAIN CUE COLORS (unique hues only)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color cueSynonymLight = Color(0xFFEEF2FF); // indigo-50
  static const Color cueSynonymDark = Color(0xFF4338CA); // indigo-700

  static const Color cueMultipleChoiceLight = Color(0xFFF0F9FF); // sky-50
  static const Color cueMultipleChoiceDark = Color(0xFF0369A1); // sky-700

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS (domain mapping)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maps cue type to semantic or domain color (context-aware)
  static Color getCueColor(BuildContext context, String cueType) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (cueType) {
      case 'translation':
        return isDark ? infoDark : infoLight;
      case 'definition':
        return isDark ? successDark : successLight;
      case 'synonym':
        return isDark ? cueSynonymDark : cueSynonymLight;
      case 'cloze':
        return isDark ? warningDark : warningLight;
      case 'multiple_choice':
        return isDark ? cueMultipleChoiceDark : cueMultipleChoiceLight;
      default:
        return isDark ? mutedForegroundDark : mutedForegroundLight;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// THEME EXTENSION (eliminates isDark ternaries)
// ═══════════════════════════════════════════════════════════════════════════

/// ThemeExtension for automatic theme-aware color access
///
/// Usage:
/// ```dart
/// final colors = context.masteryColors; // via extension
/// Container(color: colors.cardBackground)
/// Text('Label', style: TextStyle(color: colors.textPrimary))
/// ```
class MasteryColorScheme extends ThemeExtension<MasteryColorScheme> {
  const MasteryColorScheme({
    required this.background,
    required this.foreground,
    required this.cardBackground,
    required this.cardForeground,
    required this.popoverBackground,
    required this.popoverForeground,
    required this.primaryAction,
    required this.primaryActionForeground,
    required this.secondaryAction,
    required this.secondaryActionForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.selection,
    required this.success,
    required this.successForeground,
    required this.successMuted,
    required this.warning,
    required this.warningForeground,
    required this.warningMuted,
    required this.info,
    required this.infoForeground,
    required this.cueSynonym,
    required this.cueMultipleChoice,
    required this.stageCaptured,
    required this.stageCapturedBg,
    required this.stagePracticing,
    required this.stagePracticingBg,
    required this.stageStabilizing,
    required this.stageStabilizingBg,
    required this.stageActive,
    required this.stageActiveBg,
    required this.stageMastered,
    required this.stageMasteredBg,
  });

  // Surfaces
  final Color background;
  final Color foreground;
  final Color cardBackground;
  final Color cardForeground;
  final Color popoverBackground;
  final Color popoverForeground;

  // Actions
  final Color primaryAction;
  final Color primaryActionForeground;
  final Color secondaryAction;
  final Color secondaryActionForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;

  // Neutral
  final Color muted;
  final Color mutedForeground;

  // Form
  final Color border;
  final Color input;
  final Color ring;
  final Color selection;

  // Semantic states
  final Color success;
  final Color successForeground;
  final Color successMuted;
  final Color warning;
  final Color warningForeground;
  final Color warningMuted;
  final Color info;
  final Color infoForeground;

  // Domain cues
  final Color cueSynonym;
  final Color cueMultipleChoice;

  // Vocabulary stages
  final Color stageCaptured;
  final Color stageCapturedBg;
  final Color stagePracticing;
  final Color stagePracticingBg;
  final Color stageStabilizing;
  final Color stageStabilizingBg;
  final Color stageActive;
  final Color stageActiveBg;
  final Color stageMastered;
  final Color stageMasteredBg;

  /// Light mode color scheme
  static const light = MasteryColorScheme(
    background: MasteryColors.backgroundLight,
    foreground: MasteryColors.foregroundLight,
    cardBackground: MasteryColors.cardLight,
    cardForeground: MasteryColors.cardForegroundLight,
    popoverBackground: MasteryColors.popoverLight,
    popoverForeground: MasteryColors.popoverForegroundLight,
    primaryAction: MasteryColors.primaryLight,
    primaryActionForeground: MasteryColors.primaryForegroundLight,
    secondaryAction: MasteryColors.secondaryLight,
    secondaryActionForeground: MasteryColors.secondaryForegroundLight,
    accent: MasteryColors.accentLight,
    accentForeground: MasteryColors.accentForegroundLight,
    destructive: MasteryColors.destructiveLight,
    destructiveForeground: MasteryColors.destructiveForegroundLight,
    muted: MasteryColors.mutedLight,
    mutedForeground: MasteryColors.mutedForegroundLight,
    border: MasteryColors.borderLight,
    input: MasteryColors.inputLight,
    ring: MasteryColors.ringLight,
    selection: MasteryColors.selectionLight,
    success: MasteryColors.successLight,
    successForeground: MasteryColors.successForegroundLight,
    successMuted: MasteryColors.successMutedLight,
    warning: MasteryColors.warningLight,
    warningForeground: MasteryColors.warningForegroundLight,
    warningMuted: MasteryColors.warningMutedLight,
    info: MasteryColors.infoLight,
    infoForeground: MasteryColors.infoForegroundLight,
    cueSynonym: MasteryColors.cueSynonymLight,
    cueMultipleChoice: MasteryColors.cueMultipleChoiceLight,
    stageCaptured: MasteryColors.stageCapturedLight,
    stageCapturedBg: MasteryColors.stageCapturedBgLight,
    stagePracticing: MasteryColors.stagePracticingLight,
    stagePracticingBg: MasteryColors.stagePracticingBgLight,
    stageStabilizing: MasteryColors.stageStabilizingLight,
    stageStabilizingBg: MasteryColors.stageStabilizingBgLight,
    stageActive: MasteryColors.stageActiveLight,
    stageActiveBg: MasteryColors.stageActiveBgLight,
    stageMastered: MasteryColors.stageMasteredLight,
    stageMasteredBg: MasteryColors.stageMasteredBgLight,
  );

  /// Dark mode color scheme
  static const dark = MasteryColorScheme(
    background: MasteryColors.backgroundDark,
    foreground: MasteryColors.foregroundDark,
    cardBackground: MasteryColors.cardDark,
    cardForeground: MasteryColors.cardForegroundDark,
    popoverBackground: MasteryColors.popoverDark,
    popoverForeground: MasteryColors.popoverForegroundDark,
    primaryAction: MasteryColors.primaryDark,
    primaryActionForeground: MasteryColors.primaryForegroundDark,
    secondaryAction: MasteryColors.secondaryDark,
    secondaryActionForeground: MasteryColors.secondaryForegroundDark,
    accent: MasteryColors.accentDark,
    accentForeground: MasteryColors.accentForegroundDark,
    destructive: MasteryColors.destructiveDark,
    destructiveForeground: MasteryColors.destructiveForegroundDark,
    muted: MasteryColors.mutedDark,
    mutedForeground: MasteryColors.mutedForegroundDark,
    border: MasteryColors.borderDark,
    input: MasteryColors.inputDark,
    ring: MasteryColors.ringDark,
    selection: MasteryColors.selectionDark,
    success: MasteryColors.successDark,
    successForeground: MasteryColors.successForegroundDark,
    successMuted: MasteryColors.successMutedDark,
    warning: MasteryColors.warningDark,
    warningForeground: MasteryColors.warningForegroundDark,
    warningMuted: MasteryColors.warningMutedDark,
    info: MasteryColors.infoDark,
    infoForeground: MasteryColors.infoForegroundDark,
    cueSynonym: MasteryColors.cueSynonymDark,
    cueMultipleChoice: MasteryColors.cueMultipleChoiceDark,
    stageCaptured: MasteryColors.stageCapturedDark,
    stageCapturedBg: MasteryColors.stageCapturedBgDark,
    stagePracticing: MasteryColors.stagePracticingDark,
    stagePracticingBg: MasteryColors.stagePracticingBgDark,
    stageStabilizing: MasteryColors.stageStabilizingDark,
    stageStabilizingBg: MasteryColors.stageStabilizingBgDark,
    stageActive: MasteryColors.stageActiveDark,
    stageActiveBg: MasteryColors.stageActiveBgDark,
    stageMastered: MasteryColors.stageMasteredDark,
    stageMasteredBg: MasteryColors.stageMasteredBgDark,
  );

  @override
  ThemeExtension<MasteryColorScheme> copyWith({
    Color? background,
    Color? foreground,
    Color? cardBackground,
    Color? cardForeground,
    Color? popoverBackground,
    Color? popoverForeground,
    Color? primaryAction,
    Color? primaryActionForeground,
    Color? secondaryAction,
    Color? secondaryActionForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? muted,
    Color? mutedForeground,
    Color? border,
    Color? input,
    Color? ring,
    Color? selection,
    Color? success,
    Color? successForeground,
    Color? successMuted,
    Color? warning,
    Color? warningForeground,
    Color? warningMuted,
    Color? info,
    Color? infoForeground,
    Color? cueSynonym,
    Color? cueMultipleChoice,
    Color? stageCaptured,
    Color? stageCapturedBg,
    Color? stagePracticing,
    Color? stagePracticingBg,
    Color? stageStabilizing,
    Color? stageStabilizingBg,
    Color? stageActive,
    Color? stageActiveBg,
    Color? stageMastered,
    Color? stageMasteredBg,
  }) {
    return MasteryColorScheme(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      cardBackground: cardBackground ?? this.cardBackground,
      cardForeground: cardForeground ?? this.cardForeground,
      popoverBackground: popoverBackground ?? this.popoverBackground,
      popoverForeground: popoverForeground ?? this.popoverForeground,
      primaryAction: primaryAction ?? this.primaryAction,
      primaryActionForeground:
          primaryActionForeground ?? this.primaryActionForeground,
      secondaryAction: secondaryAction ?? this.secondaryAction,
      secondaryActionForeground:
          secondaryActionForeground ?? this.secondaryActionForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      destructive: destructive ?? this.destructive,
      destructiveForeground:
          destructiveForeground ?? this.destructiveForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      selection: selection ?? this.selection,
      success: success ?? this.success,
      successForeground: successForeground ?? this.successForeground,
      successMuted: successMuted ?? this.successMuted,
      warning: warning ?? this.warning,
      warningForeground: warningForeground ?? this.warningForeground,
      warningMuted: warningMuted ?? this.warningMuted,
      info: info ?? this.info,
      infoForeground: infoForeground ?? this.infoForeground,
      cueSynonym: cueSynonym ?? this.cueSynonym,
      cueMultipleChoice: cueMultipleChoice ?? this.cueMultipleChoice,
      stageCaptured: stageCaptured ?? this.stageCaptured,
      stageCapturedBg: stageCapturedBg ?? this.stageCapturedBg,
      stagePracticing: stagePracticing ?? this.stagePracticing,
      stagePracticingBg: stagePracticingBg ?? this.stagePracticingBg,
      stageStabilizing: stageStabilizing ?? this.stageStabilizing,
      stageStabilizingBg: stageStabilizingBg ?? this.stageStabilizingBg,
      stageActive: stageActive ?? this.stageActive,
      stageActiveBg: stageActiveBg ?? this.stageActiveBg,
      stageMastered: stageMastered ?? this.stageMastered,
      stageMasteredBg: stageMasteredBg ?? this.stageMasteredBg,
    );
  }

  @override
  ThemeExtension<MasteryColorScheme> lerp(
    covariant ThemeExtension<MasteryColorScheme>? other,
    double t,
  ) {
    if (other is! MasteryColorScheme) return this;
    return MasteryColorScheme(
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardForeground: Color.lerp(cardForeground, other.cardForeground, t)!,
      popoverBackground: Color.lerp(
        popoverBackground,
        other.popoverBackground,
        t,
      )!,
      popoverForeground: Color.lerp(
        popoverForeground,
        other.popoverForeground,
        t,
      )!,
      primaryAction: Color.lerp(primaryAction, other.primaryAction, t)!,
      primaryActionForeground: Color.lerp(
        primaryActionForeground,
        other.primaryActionForeground,
        t,
      )!,
      secondaryAction: Color.lerp(secondaryAction, other.secondaryAction, t)!,
      secondaryActionForeground: Color.lerp(
        secondaryActionForeground,
        other.secondaryActionForeground,
        t,
      )!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(
        accentForeground,
        other.accentForeground,
        t,
      )!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveForeground: Color.lerp(
        destructiveForeground,
        other.destructiveForeground,
        t,
      )!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
      selection: Color.lerp(selection, other.selection, t)!,
      success: Color.lerp(success, other.success, t)!,
      successForeground: Color.lerp(
        successForeground,
        other.successForeground,
        t,
      )!,
      successMuted: Color.lerp(successMuted, other.successMuted, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningForeground: Color.lerp(
        warningForeground,
        other.warningForeground,
        t,
      )!,
      warningMuted: Color.lerp(warningMuted, other.warningMuted, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoForeground: Color.lerp(infoForeground, other.infoForeground, t)!,
      cueSynonym: Color.lerp(cueSynonym, other.cueSynonym, t)!,
      cueMultipleChoice: Color.lerp(
        cueMultipleChoice,
        other.cueMultipleChoice,
        t,
      )!,
      stageCaptured: Color.lerp(stageCaptured, other.stageCaptured, t)!,
      stageCapturedBg: Color.lerp(stageCapturedBg, other.stageCapturedBg, t)!,
      stagePracticing: Color.lerp(stagePracticing, other.stagePracticing, t)!,
      stagePracticingBg: Color.lerp(
        stagePracticingBg,
        other.stagePracticingBg,
        t,
      )!,
      stageStabilizing: Color.lerp(
        stageStabilizing,
        other.stageStabilizing,
        t,
      )!,
      stageStabilizingBg: Color.lerp(
        stageStabilizingBg,
        other.stageStabilizingBg,
        t,
      )!,
      stageActive: Color.lerp(stageActive, other.stageActive, t)!,
      stageActiveBg: Color.lerp(stageActiveBg, other.stageActiveBg, t)!,
      stageMastered: Color.lerp(stageMastered, other.stageMastered, t)!,
      stageMasteredBg: Color.lerp(stageMasteredBg, other.stageMasteredBg, t)!,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BUILDCONTEXT EXTENSION (convenience)
// ═══════════════════════════════════════════════════════════════════════════

/// Convenience extension for accessing Mastery colors via context
extension MasteryThemeContext on BuildContext {
  /// Access Mastery color scheme: `context.masteryColors.cardBackground`
  MasteryColorScheme get masteryColors =>
      Theme.of(this).extension<MasteryColorScheme>() ??
      MasteryColorScheme.light;
}

