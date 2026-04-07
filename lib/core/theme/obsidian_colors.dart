import 'package:flutter/material.dart';

/// Dark palette — indigo-forward, soft layers (no pure black).
abstract final class ObsidianColors {
  static const Color surface = Color(0xFF0F1220);
  static const Color surfaceContainerLowest = Color(0xFF080B14);
  static const Color surfaceContainerLow = Color(0xFF161B2E);
  static const Color surfaceContainer = Color(0xFF1E2438);
  static const Color surfaceContainerHigh = Color(0xFF2A3148);
  static const Color surfaceBright = Color(0xFF343C5C);

  static const Color primary = Color(0xFFA5B4FC);
  static const Color primaryContainer = Color(0xFF312E81);

  static const Color secondary = Color(0xFF5EEAD4);

  static const Color warning = Color(0xFFFCD34D);
  static const Color onWarning = Color(0xFF1C1507);

  static const Color outlineVariant = Color(0xFF6B7280);
  static const Color onSurface = Color(0xFFE8ECFF);
  static const Color onSurfaceVariant = Color(0xFF9CA3AF);

  static Color ghostBorder([double opacity = 0.15]) =>
      outlineVariant.withValues(alpha: opacity);
}
