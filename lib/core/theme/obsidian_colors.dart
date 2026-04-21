import 'package:flutter/material.dart';

/// Dark palette — "Obsidian Bold": amplified indigo, brighter teal,
/// cyan accent, cooler/deeper surface ramp for stronger primary contrast.
///
/// These constants describe the *dark* mode brand colors. Light mode values
/// live alongside the dark presets in [ObsidianUiTokens.light].
abstract final class ObsidianColors {
  // Surface ramp (cool, deep navy — primary visibly advances off these).
  static const Color surface = Color(0xFF0B0E1A);
  static const Color surfaceContainerLowest = Color(0xFF050811);
  static const Color surfaceContainerLow = Color(0xFF11152A);
  static const Color surfaceContainer = Color(0xFF161B33);
  static const Color surfaceContainerHigh = Color(0xFF1E2440);
  static const Color surfaceBright = Color(0xFF252C4D);

  // Primary — indigo, amplified (Indigo-400).
  static const Color primary = Color(0xFF818CF8);
  static const Color primaryContainer = Color(0xFF3730A3);

  // Primary gradient endpoint (violet) for the indigo→violet hero gradient.
  static const Color primaryGradientEnd = Color(0xFFC084FC);

  // Secondary — brighter teal (Teal-400). Reads as "ready/positive".
  static const Color secondary = Color(0xFF2DD4BF);

  // Tertiary accent — cyan (Cyan-400). Highlights & data.
  static const Color tertiary = Color(0xFF22D3EE);

  // Status.
  static const Color warning = Color(0xFFFBBF24);
  static const Color onWarning = Color(0xFF1C1507);
  static const Color error = Color(0xFFFCA5A5);

  // Text & borders.
  static const Color onSurface = Color(0xFFF8FAFC);
  static const Color onSurfaceVariant = Color(0xFF94A3B8);

  /// Outline base — same value as surfaceContainerHigh so 1px borders sit
  /// flush with elevated surfaces. Opacity is applied via [ghostBorder].
  static const Color outlineVariant = Color(0xFF1E2440);

  static Color ghostBorder([double opacity = 0.15]) =>
      outlineVariant.withValues(alpha: opacity);
}

/// Raw color palette. Prefer over [ObsidianColors] in new code.
typedef AppColors = ObsidianColors;
