import 'package:flutter/material.dart';
import 'package:sample/core/theme/obsidian_colors.dart';

/// Design tokens that follow the active [ThemeData] (light/dark).
@immutable
class ObsidianUiTokens extends ThemeExtension<ObsidianUiTokens> {
  const ObsidianUiTokens({
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceBright,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.warning,
    required this.outlineVariant,
    required this.onPrimaryButton,
  });

  // ── Radii ──────────────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  @Deprecated('Use radiusLg instead')
  static const double roundMd = radiusLg;
  @Deprecated('Use radiusXl instead')
  static const double roundXl = radiusXl;

  // ── Colors ─────────────────────────────────────────────────────────────
  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceBright;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color primary;
  final Color primaryContainer;
  final Color secondary;
  final Color warning;
  final Color outlineVariant;

  /// Text/icon on primary-colored buttons.
  final Color onPrimaryButton;

  Color ghostBorder([double opacity = 0.15]) =>
      outlineVariant.withValues(alpha: opacity);

  /// Subtle ambient shadow for floating UI (nav bar, elevated menus).
  List<BoxShadow> get ambientFloating {
    final isLight = surface.computeLuminance() > 0.5;
    return [
      BoxShadow(
        color: Color.fromRGBO(79, 70, 229, isLight ? 0.06 : 0.12),
        blurRadius: 40,
        offset: const Offset(0, 20),
      ),
    ];
  }

  // ── Presets ─────────────────────────────────────────────────────────────

  static const ObsidianUiTokens dark = ObsidianUiTokens(
    surface: ObsidianColors.surface,
    surfaceContainerLowest: ObsidianColors.surfaceContainerLowest,
    surfaceContainerLow: ObsidianColors.surfaceContainerLow,
    surfaceContainer: ObsidianColors.surfaceContainer,
    surfaceContainerHigh: ObsidianColors.surfaceContainerHigh,
    surfaceBright: ObsidianColors.surfaceBright,
    onSurface: ObsidianColors.onSurface,
    onSurfaceVariant: ObsidianColors.onSurfaceVariant,
    primary: ObsidianColors.primary,
    primaryContainer: ObsidianColors.primaryContainer,
    secondary: ObsidianColors.secondary,
    warning: ObsidianColors.warning,
    outlineVariant: ObsidianColors.outlineVariant,
    onPrimaryButton: Color(0xFFFFFFFF),
  );

  static const ObsidianUiTokens light = ObsidianUiTokens(
    surface: Color(0xFFFAFAFE),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF0F0F8),
    surfaceContainer: Color(0xFFE2E8F8),
    surfaceContainerHigh: Color(0xFFC7D2FE),
    surfaceBright: Color(0xFFFFFFFF),
    onSurface: Color(0xFF111827),
    onSurfaceVariant: Color(0xFF6B7280),
    primary: Color(0xFF4F46E5),
    primaryContainer: Color(0xFFEEF2FF),
    secondary: Color(0xFF0D9488),
    warning: Color(0xFFD97706),
    outlineVariant: Color(0xFF8B90A0),
    onPrimaryButton: Color(0xFFFFFFFF),
  );

  @override
  ObsidianUiTokens copyWith({
    Color? surface,
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceBright,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? primary,
    Color? primaryContainer,
    Color? secondary,
    Color? warning,
    Color? outlineVariant,
    Color? onPrimaryButton,
  }) {
    return ObsidianUiTokens(
      surface: surface ?? this.surface,
      surfaceContainerLowest:
          surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceBright: surfaceBright ?? this.surfaceBright,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      secondary: secondary ?? this.secondary,
      warning: warning ?? this.warning,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      onPrimaryButton: onPrimaryButton ?? this.onPrimaryButton,
    );
  }

  @override
  ObsidianUiTokens lerp(ThemeExtension<ObsidianUiTokens>? other, double t) {
    if (other is! ObsidianUiTokens) return this;
    return ObsidianUiTokens(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceContainerLowest: Color.lerp(
        surfaceContainerLowest,
        other.surfaceContainerLowest,
        t,
      )!,
      surfaceContainerLow: Color.lerp(
        surfaceContainerLow,
        other.surfaceContainerLow,
        t,
      )!,
      surfaceContainer: Color.lerp(
        surfaceContainer,
        other.surfaceContainer,
        t,
      )!,
      surfaceContainerHigh: Color.lerp(
        surfaceContainerHigh,
        other.surfaceContainerHigh,
        t,
      )!,
      surfaceBright: Color.lerp(surfaceBright, other.surfaceBright, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant: Color.lerp(
        onSurfaceVariant,
        other.onSurfaceVariant,
        t,
      )!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      onPrimaryButton: Color.lerp(onPrimaryButton, other.onPrimaryButton, t)!,
    );
  }
}

extension ObsidianUiTokensContext on BuildContext {
  ObsidianUiTokens get obsidian =>
      Theme.of(this).extension<ObsidianUiTokens>() ?? ObsidianUiTokens.dark;
}

/// Height of the dashboard bottom bar content (excluding safe area).
const double kObsidianNavBarHeight = 64;

/// Extra space so FABs clear the floating nav + home indicator.
double obsidianFabBottomPadding(BuildContext context) {
  final safe = MediaQuery.paddingOf(context).bottom;
  return kObsidianNavBarHeight + safe + 12;
}
