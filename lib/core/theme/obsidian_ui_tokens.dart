import 'package:flutter/material.dart';
import 'package:sample/core/theme/obsidian_colors.dart';

/// Design tokens that follow the active [ThemeData] (light/dark).
///
/// "Obsidian Bold" — amplified indigo + violet/cyan gradient accents,
/// brighter teal secondary, expressive elevation system.
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
    required this.tertiary,
    required this.warning,
    required this.outlineVariant,
    required this.onPrimaryButton,
    required this.primaryGradient,
    required this.accentGradient,
    required this.heroBackdropGradient,
  });

  // ── Radii ──────────────────────────────────────────────────────────────
  /// Tightest radius — pill chips, dense badges.
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  /// Hero card radius — sheets, large feature surfaces.
  static const double radiusXxl = 32;
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

  /// Cyan accent — highlights, data viz, "fresh" surfaces.
  final Color tertiary;
  final Color warning;
  final Color outlineVariant;

  /// Text/icon on primary-colored buttons.
  final Color onPrimaryButton;

  // ── Gradients ──────────────────────────────────────────────────────────
  /// 135° indigo → violet. Primary brand gradient.
  final LinearGradient primaryGradient;

  /// 135° cyan → indigo. Accent CTAs and special chips.
  final LinearGradient accentGradient;

  /// Soft radial blob for hero backdrops (founder card, empty states).
  final RadialGradient heroBackdropGradient;

  Color ghostBorder([double opacity = 0.15]) =>
      outlineVariant.withValues(alpha: opacity);

  // ── Elevation presets ──────────────────────────────────────────────────
  /// 1dp — subtle separation (chip on card, list dividers).
  List<BoxShadow> get elevationSm => [
    BoxShadow(
      color: primary.withValues(alpha: 0.08),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  /// 4dp — cards lifted off scroll.
  List<BoxShadow> get elevationMd => [
    BoxShadow(
      color: primary.withValues(alpha: 0.12),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// 12dp — sheets, prominent floating menus, with soft brand glow.
  List<BoxShadow> get elevationLg => [
    BoxShadow(
      color: primary.withValues(alpha: 0.14),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: primary.withValues(alpha: 0.20),
      blurRadius: 24,
      offset: Offset.zero,
    ),
  ];

  /// Brand glow — primary CTA pressed/active state.
  List<BoxShadow> get vibrantGlow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.32),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Subtle ambient shadow for floating UI (nav bar, elevated menus).
  ///
  /// Kept for backwards compatibility; prefer [elevationLg] for new code.
  List<BoxShadow> get ambientFloating {
    final isLight = surface.computeLuminance() > 0.5;
    return [
      BoxShadow(
        color: primary.withValues(alpha: isLight ? 0.06 : 0.12),
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
    tertiary: ObsidianColors.tertiary,
    warning: ObsidianColors.warning,
    outlineVariant: ObsidianColors.outlineVariant,
    onPrimaryButton: Color(0xFF0B0E1A),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [ObsidianColors.primary, ObsidianColors.primaryGradientEnd],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [ObsidianColors.tertiary, ObsidianColors.primary],
    ),
    heroBackdropGradient: RadialGradient(
      center: Alignment(-0.4, -0.6),
      radius: 1.2,
      colors: [Color(0x66818CF8), Color(0x33C084FC), Color(0x0022D3EE)],
      stops: [0.0, 0.55, 1.0],
    ),
  );

  static const ObsidianUiTokens light = ObsidianUiTokens(
    surface: Color(0xFFFAFAFB),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF5F5F7),
    surfaceContainer: Color(0xFFEFEFF3),
    surfaceContainerHigh: Color(0xFFE8E8EE),
    surfaceBright: Color(0xFFE0E0E8),
    onSurface: Color(0xFF0F172A),
    onSurfaceVariant: Color(0xFF64748B),
    primary: Color(0xFF4338CA),
    primaryContainer: Color(0xFFE0E7FF),
    secondary: Color(0xFF0D9488),
    tertiary: Color(0xFF0891B2),
    warning: Color(0xFFD97706),
    outlineVariant: Color(0xFFE2E8F0),
    onPrimaryButton: Color(0xFFFFFFFF),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0891B2), Color(0xFF4338CA)],
    ),
    heroBackdropGradient: RadialGradient(
      center: Alignment(-0.4, -0.6),
      radius: 1.2,
      colors: [Color(0x33818CF8), Color(0x1FC084FC), Color(0x0022D3EE)],
      stops: [0.0, 0.55, 1.0],
    ),
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
    Color? tertiary,
    Color? warning,
    Color? outlineVariant,
    Color? onPrimaryButton,
    LinearGradient? primaryGradient,
    LinearGradient? accentGradient,
    RadialGradient? heroBackdropGradient,
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
      tertiary: tertiary ?? this.tertiary,
      warning: warning ?? this.warning,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      onPrimaryButton: onPrimaryButton ?? this.onPrimaryButton,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      accentGradient: accentGradient ?? this.accentGradient,
      heroBackdropGradient: heroBackdropGradient ?? this.heroBackdropGradient,
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
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      onPrimaryButton: Color.lerp(onPrimaryButton, other.onPrimaryButton, t)!,
      primaryGradient: LinearGradient.lerp(
        primaryGradient,
        other.primaryGradient,
        t,
      )!,
      accentGradient: LinearGradient.lerp(
        accentGradient,
        other.accentGradient,
        t,
      )!,
      heroBackdropGradient: RadialGradient.lerp(
        heroBackdropGradient,
        other.heroBackdropGradient,
        t,
      )!,
    );
  }
}

extension ObsidianUiTokensContext on BuildContext {
  ObsidianUiTokens get obsidian =>
      Theme.of(this).extension<ObsidianUiTokens>() ?? ObsidianUiTokens.dark;
}

/// Height of the dashboard bottom bar content (excluding safe area).
const double kObsidianNavBarHeight = 64;

/// System bottom inset (home indicator / gesture bar).
double appSystemBottomInset(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom;

/// Total height reserved above the physical screen bottom for the floating nav.
double appNavBarTotalHeight(BuildContext context) =>
    kObsidianNavBarHeight + appSystemBottomInset(context) + 8;

/// Extra space so scroll content and FABs clear the floating nav.
double obsidianFabBottomPadding(BuildContext context) =>
    appNavBarTotalHeight(context) + 12;

// ── Forward-looking aliases (Obsidian* → App*) ───────────────────────────
//
// Step-3 plan introduces neutral `App*` names for the design system. Both
// names live side-by-side during the migration so consumers can update
// incrementally without churn.

/// Design tokens. Prefer over [ObsidianUiTokens] in new code.
typedef AppTokens = ObsidianUiTokens;

extension AppTokensContext on BuildContext {
  /// Active design tokens for the current theme. Prefer over `obsidian`.
  AppTokens get appTokens => obsidian;
}

/// Tap-target sizing rules. Every interactive element must meet
/// [minSize] (48dp) — Material guideline + WCAG 2.5.5.
abstract final class AppTapTarget {
  /// Minimum width and height for any tappable surface.
  static const double minSize = 48;
}

/// Floating bottom-nav metrics. Re-exported under the `App*` prefix.
const double kAppNavBarHeight = kObsidianNavBarHeight;

/// Extra padding for FABs so they clear the floating nav + home indicator.
double appFabBottomPadding(BuildContext context) =>
    obsidianFabBottomPadding(context);
