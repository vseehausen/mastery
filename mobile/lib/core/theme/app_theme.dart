import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'color_tokens.dart';
import 'text_styles.dart';

/// Mastery app theme configuration using shadcn_ui
/// Stone palette + Amber accent design system v1.0.0
class MasteryTheme {
  MasteryTheme._();

  static ShadThemeData get light {
    return ShadThemeData(
      brightness: Brightness.light,
      colorScheme: const ShadColorScheme(
        // Primary - Stone 900 for primary actions
        primary: MasteryColors.primaryLight,
        primaryForeground: MasteryColors.primaryForegroundLight,

        // Secondary - Stone 100
        secondary: MasteryColors.secondaryLight,
        secondaryForeground: MasteryColors.secondaryForegroundLight,

        // Destructive - Red
        destructive: MasteryColors.destructiveLight,
        destructiveForeground: MasteryColors.destructiveForegroundLight,

        // Muted - Stone 100
        muted: MasteryColors.mutedLight,
        mutedForeground: MasteryColors.mutedForegroundLight,

        // Accent - Amber 500 (brand color)
        accent: MasteryColors.accentLight,
        accentForeground: MasteryColors.accentForegroundLight,

        // Foreground - Stone 900
        foreground: MasteryColors.foregroundLight,

        // Card - White
        card: MasteryColors.cardLight,
        cardForeground: MasteryColors.cardForegroundLight,

        // Popover - White
        popover: MasteryColors.popoverLight,
        popoverForeground: MasteryColors.popoverForegroundLight,

        // Border - Stone 200
        border: MasteryColors.borderLight,

        // Input - Stone 200
        input: MasteryColors.inputLight,

        // Ring - Amber 500 (focus indicator)
        ring: MasteryColors.ringLight,

        // Background - White
        background: MasteryColors.backgroundLight,

        // Selection - Amber 100
        selection: MasteryColors.selectionLight,
      ),
      textTheme: _buildTextTheme(),
    );
  }

  static ShadThemeData get dark {
    return ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: const ShadColorScheme(
        // Primary - Stone 50 for primary actions
        primary: MasteryColors.primaryDark,
        primaryForeground: MasteryColors.primaryForegroundDark,

        // Secondary - Stone 800
        secondary: MasteryColors.secondaryDark,
        secondaryForeground: MasteryColors.secondaryForegroundDark,

        // Destructive - Red
        destructive: MasteryColors.destructiveDark,
        destructiveForeground: MasteryColors.destructiveForegroundDark,

        // Muted - Stone 800
        muted: MasteryColors.mutedDark,
        mutedForeground: MasteryColors.mutedForegroundDark,

        // Accent - Amber 400 (brand color)
        accent: MasteryColors.accentDark,
        accentForeground: MasteryColors.accentForegroundDark,

        // Foreground - Stone 50
        foreground: MasteryColors.foregroundDark,

        // Card - Stone 900
        card: MasteryColors.cardDark,
        cardForeground: MasteryColors.cardForegroundDark,

        // Popover - Stone 900
        popover: MasteryColors.popoverDark,
        popoverForeground: MasteryColors.popoverForegroundDark,

        // Border - Stone 800
        border: MasteryColors.borderDark,

        // Input - Stone 800
        input: MasteryColors.inputDark,

        // Ring - Amber 400 (focus indicator)
        ring: MasteryColors.ringDark,

        // Background - Stone 900
        background: MasteryColors.backgroundDark,

        // Selection - Amber 900
        selection: MasteryColors.selectionDark,
      ),
      textTheme: _buildTextTheme(),
    );
  }

  static ShadTextTheme _buildTextTheme() {
    return ShadTextTheme(
      h1: MasteryTextStyles.displayLarge,
      h2: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      h3: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      h4: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      p: MasteryTextStyles.body,
      blockquote: MasteryTextStyles.bodySmall,
      table: MasteryTextStyles.body,
      list: MasteryTextStyles.body,
      lead: MasteryTextStyles.bodyLarge,
      large: MasteryTextStyles.bodyLarge,
      small: MasteryTextStyles.bodySmall,
      muted: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF78716C), // Stone 500
      ),
    );
  }
}
