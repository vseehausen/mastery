import 'package:flutter/material.dart';

/// Typography scale for Mastery app
/// Based on Inter font family with specific weights and sizes
class MasteryTextStyles {
  MasteryTextStyles._();

  // Display - 28px bold (main titles)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  // Body Large - 18px (definitions, important content)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Body - 16px (labels, form fields)
  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Body Bold - 16px bold (emphasis)
  static const TextStyle bodyBold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // Body Small - 14px (descriptions, secondary text)
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Caption - 11px (nav labels, hints)
  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  // Button text
  static const TextStyle button = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // Form label
  static const TextStyle formLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}
