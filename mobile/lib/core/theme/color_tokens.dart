import 'package:flutter/material.dart';

/// Mastery brand color tokens
/// Based on design system in mastery-design.pen
class MasteryColors {
  MasteryColors._();

  // ============ NEUTRAL PALETTE (Stone) ============
  // Light mode - neutral colors
  static const Color primaryLight = Color(0xFF171717);
  static const Color primaryForegroundLight = Color(0xFFFAFAFA);
  static const Color secondaryLight = Color(0xFFF5F5F5);
  static const Color secondaryForegroundLight = Color(0xFF171717);
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color foregroundLight = Color(0xFF0A0A0A);
  static const Color cardLight = Color(0xFFFAFAFA);
  static const Color cardForegroundLight = Color(0xFF0A0A0A);
  static const Color borderLight = Color(0xFFE5E5E5);
  static const Color mutedLight = Color(0xFFF5F5F5);
  static const Color mutedForegroundLight = Color(0xFF737373);

  // Dark mode - neutral colors
  static const Color primaryDark = Color(0xFFE5E5E5);
  static const Color primaryForegroundDark = Color(0xFF171717);
  static const Color secondaryDark = Color(0xFF262626);
  static const Color secondaryForegroundDark = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color foregroundDark = Color(0xFFFAFAFA);
  static const Color cardDark = Color(0xFF171717);
  static const Color cardForegroundDark = Color(0xFFFAFAFA);
  static const Color borderDark = Color(0xFF2A2A2A);
  static const Color mutedDark = Color(0xFF262626);
  static const Color mutedForegroundDark = Color(0xFF9CA3AF);

  // ============ STATUS COLORS ============
  // Light mode colors
  static const Color accentLight = Color(0xFFF59E0B);
  static const Color accentForegroundLight = Color(0xFF78350F);
  static const Color activeLight = Color(0xFF18181B);
  static const Color knownLight = Color(0xFF10B981);
  static const Color knownMutedLight = Color(0xFFDCFCE7);
  static const Color learningLight = Color(0xFFF59E0B);
  static const Color learningMutedLight = Color(0xFFFEF3C7);
  static const Color successLight = Color(0xFF10B981);
  static const Color successForegroundLight = Color(0xFFFFFFFF);
  static const Color successMutedLight = Color(0xFFDCFCE7);
  static const Color unknownLight = Color(0xFFE4E4E7);
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningMutedLight = Color(0xFFFEF3C7);

  // Dark mode colors
  static const Color accentDark = Color(0xFFFBBF24);
  static const Color accentForegroundDark = Color(0xFF451A03);
  static const Color activeDark = Color(0xFFFAFAF9);
  static const Color knownDark = Color(0xFF34D399);
  static const Color knownMutedDark = Color(0xFF052E16);
  static const Color learningDark = Color(0xFFFBBF24);
  static const Color learningMutedDark = Color(0xFF422006);
  static const Color successDark = Color(0xFF34D399);
  static const Color successForegroundDark = Color(0xFF022C22);
  static const Color successMutedDark = Color(0xFF052E16);
  static const Color unknownDark = Color(0xFF3F3F46);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color warningMutedDark = Color(0xFF422006);

  // ============ CUE PREVIEW COLORS ============
  static const Color cueTranslationLight = Color(0xFF3B82F6);
  static const Color cueTranslationDark = Color(0xFF60A5FA);
  static const Color cueDefinitionLight = Color(0xFF10B981);
  static const Color cueDefinitionDark = Color(0xFF34D399);
  static const Color cueSynonymLight = Color(0xFF8B5CF6);
  static const Color cueSynonymDark = Color(0xFFA78BFA);
  static const Color cueClozeLight = Color(0xFFF59E0B);
  static const Color cueClozeDark = Color(0xFFFBBF24);
  static const Color cueMultipleChoiceLight = Color(0xFFEC4899);
  static const Color cueMultipleChoiceDark = Color(0xFFF472B6);

  static Color getCueColor(String cueType, {bool isDark = false}) {
    switch (cueType) {
      case 'translation':
        return isDark ? cueTranslationDark : cueTranslationLight;
      case 'definition':
        return isDark ? cueDefinitionDark : cueDefinitionLight;
      case 'synonym':
        return isDark ? cueSynonymDark : cueSynonymLight;
      case 'cloze':
        return isDark ? cueClozeDark : cueClozeLight;
      case 'multiple_choice':
        return isDark ? cueMultipleChoiceDark : cueMultipleChoiceLight;
      default:
        return isDark ? mutedForegroundDark : mutedForegroundLight;
    }
  }

  // Status colors - convenience getters
  static Color getStatusColor(LearningStatus status, {bool isDark = false}) {
    switch (status) {
      case LearningStatus.known:
        return isDark ? knownDark : knownLight;
      case LearningStatus.learning:
        return isDark ? learningDark : learningLight;
      case LearningStatus.unknown:
        return isDark ? unknownDark : unknownLight;
    }
  }

  static Color getStatusMutedColor(
    LearningStatus status, {
    bool isDark = false,
  }) {
    switch (status) {
      case LearningStatus.known:
        return isDark ? knownMutedDark : knownMutedLight;
      case LearningStatus.learning:
        return isDark ? learningMutedDark : learningMutedLight;
      case LearningStatus.unknown:
        return isDark ? unknownDark : unknownLight;
    }
  }
}

enum LearningStatus { known, learning, unknown }
