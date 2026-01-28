import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'color_tokens.dart';
import 'text_styles.dart';

/// Mastery app theme configuration using shadcn_ui
class MasteryTheme {
  MasteryTheme._();

  static ShadThemeData get light {
    return ShadThemeData(
      brightness: Brightness.light,
      colorScheme: const ShadColorScheme(
        // Primary - Dark gray/black for buttons, toggles, etc
        primary: MasteryColors.primaryLight,
        primaryForeground: MasteryColors.primaryForegroundLight,

        // Secondary - Light gray
        secondary: MasteryColors.secondaryLight,
        secondaryForeground: MasteryColors.secondaryForegroundLight,

        // Destructive
        destructive: Color(0xFFE7000B),
        destructiveForeground: Color(0xFFFFFFFF),

        // Muted
        muted: MasteryColors.mutedLight,
        mutedForeground: MasteryColors.mutedForegroundLight,

        // Accent - Now use learning color (amber) for accents only
        accent: MasteryColors.learningLight,
        accentForeground: MasteryColors.accentForegroundLight,

        // Foreground
        foreground: MasteryColors.foregroundLight,

        // Card
        card: MasteryColors.cardLight,
        cardForeground: MasteryColors.cardForegroundLight,

        // Popover
        popover: MasteryColors.cardLight,
        popoverForeground: MasteryColors.cardForegroundLight,

        // Border
        border: MasteryColors.borderLight,

        // Input
        input: MasteryColors.borderLight,

        // Ring (focus states)
        ring: MasteryColors.mutedForegroundLight,

        // Background
        background: MasteryColors.backgroundLight,

        // Selection - Use learning color (amber) for selection
        selection: MasteryColors.learningLight,
      ),
      textTheme: _buildTextTheme(),
    );
  }

  static ShadThemeData get dark {
    return ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: const ShadColorScheme(
        // Primary - Light gray text for buttons, toggles, etc
        primary: MasteryColors.primaryDark,
        primaryForeground: MasteryColors.primaryForegroundDark,

        // Secondary - Dark gray
        secondary: MasteryColors.secondaryDark,
        secondaryForeground: MasteryColors.secondaryForegroundDark,

        // Destructive
        destructive: Color(0xFFFF6666),
        destructiveForeground: Color(0xFF000000),

        // Muted
        muted: MasteryColors.mutedDark,
        mutedForeground: MasteryColors.mutedForegroundDark,

        // Accent - Now use learning color (amber) for accents only
        accent: MasteryColors.learningDark,
        accentForeground: MasteryColors.accentForegroundDark,

        // Foreground
        foreground: MasteryColors.foregroundDark,

        // Card
        card: MasteryColors.cardDark,
        cardForeground: MasteryColors.cardForegroundDark,

        // Popover
        popover: MasteryColors.cardDark,
        popoverForeground: MasteryColors.cardForegroundDark,

        // Border
        border: MasteryColors.borderDark,

        // Input
        input: MasteryColors.borderDark,

        // Ring (focus states)
        ring: MasteryColors.mutedForegroundDark,

        // Background
        background: MasteryColors.backgroundDark,

        // Selection - Use learning color (amber) for selection
        selection: MasteryColors.learningDark,
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
        color: Color(0xFF737373),
      ),
    );
  }
}
