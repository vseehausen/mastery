import 'package:flutter/material.dart';
import 'typography_tokens.dart';

/// Typography scale for Mastery app
/// Based on Plus Jakarta Sans font family with specific weights and sizes
///
/// This class now uses the token-based system from [AppTypography].
/// All existing TextStyles are preserved for backward compatibility.
class MasteryTextStyles {
  MasteryTextStyles._();

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC TEXT STYLES (using tokens)
  // ═══════════════════════════════════════════════════════════════════════════

  // Display - 28px bold (main titles)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSize2xl,
    fontWeight: AppTypography.fontWeightBold,
    height: AppTypography.lineHeightTight,
  );

  static const TextStyle h1 = displayLarge;

  static const TextStyle h2 = TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSizeXl,
    fontWeight: AppTypography.fontWeightBold,
    height: AppTypography.lineHeightTight,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSizeLg,
    fontWeight: AppTypography.fontWeightBold,
    height: AppTypography.lineHeightTight,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSizeLg,
    fontWeight: AppTypography.fontWeightBold,
    height: AppTypography.lineHeightTight,
  );

  // Body Large - 18px (definitions, important content)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSizeLg,
    fontWeight: AppTypography.fontWeightNormal,
    height: AppTypography.lineHeightRelaxed,
  );

  // Body - 16px (labels, form fields)
  static const TextStyle body = TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSizeBase,
    fontWeight: AppTypography.fontWeightNormal,
    height: AppTypography.lineHeightRelaxed,
  );

  // Body Bold - 16px bold (emphasis)
  static const TextStyle bodyBold = TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSizeBase,
    fontWeight: AppTypography.fontWeightSemibold,
    height: AppTypography.lineHeightRelaxed,
  );

  // Body Small - 14px (descriptions, secondary text)
  static const TextStyle bodySmall = TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSizeSm,
    fontWeight: AppTypography.fontWeightNormal,
    height: AppTypography.lineHeightNormal,
  );

  // Caption - 11px (nav labels, hints)
  static const TextStyle caption = TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSizeXs,
    fontWeight: AppTypography.fontWeightNormal,
    height: AppTypography.lineHeightSnug,
  );

  // Button text
  static const TextStyle button = TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSizeBase,
    fontWeight: AppTypography.fontWeightSemibold,
    height: AppTypography.lineHeightRelaxed,
  );

  // Form label
  static const TextStyle formLabel = TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSizeSm,
    fontWeight: AppTypography.fontWeightMedium,
    height: AppTypography.lineHeightNormal,
  );

  // Muted text
  static const TextStyle muted = TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSizeSm,
    fontWeight: AppTypography.fontWeightNormal,
    height: AppTypography.lineHeightNormal,
  );
}
