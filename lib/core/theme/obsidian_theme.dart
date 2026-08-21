import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';

/// "Obsidian Bold" Manrope expressive type scale.
///
/// Pushes Manrope's weight contrast (400 → 700 → 800/900) and tightens
/// tracking on display/headline so hero numerals and section titles read as
/// confidently bold. Body keeps a calm 400 for legibility.
TextTheme _buildTextTheme({
  required Color onSurface,
  required Color onSurfaceVariant,
}) {
  final m = GoogleFonts.manropeTextTheme();

  return m.copyWith(
    // ── Display — hero numerals, marquee text ────────────────────────────
    displayLarge: m.displayLarge?.copyWith(
      fontSize: 56,
      height: 1.05,
      letterSpacing: -1.6,
      fontWeight: FontWeight.w900,
      color: onSurface,
    ),
    displayMedium: m.displayMedium?.copyWith(
      fontSize: 44,
      height: 1.1,
      letterSpacing: -1.2,
      fontWeight: FontWeight.w800,
      color: onSurface,
    ),
    displaySmall: m.displaySmall?.copyWith(
      fontSize: 36,
      height: 1.15,
      letterSpacing: -1.0,
      fontWeight: FontWeight.w800,
      color: onSurface,
    ),
    // ── Headline — page + section ────────────────────────────────────────
    headlineLarge: m.headlineLarge?.copyWith(
      fontSize: 28,
      height: 1.2,
      letterSpacing: -0.6,
      fontWeight: FontWeight.w800,
      color: onSurface,
    ),
    headlineMedium: m.headlineMedium?.copyWith(
      fontSize: 22,
      height: 1.25,
      letterSpacing: -0.4,
      fontWeight: FontWeight.w700,
      color: onSurface,
    ),
    headlineSmall: m.headlineSmall?.copyWith(
      fontSize: 18,
      height: 1.3,
      letterSpacing: -0.2,
      fontWeight: FontWeight.w700,
      color: onSurface,
    ),
    // ── Title — sheet/card/dialog headings ───────────────────────────────
    titleLarge: m.titleLarge?.copyWith(
      fontSize: 18,
      height: 1.3,
      letterSpacing: -0.2,
      fontWeight: FontWeight.w700,
      color: onSurface,
    ),
    titleMedium: m.titleMedium?.copyWith(
      fontSize: 16,
      height: 1.35,
      letterSpacing: -0.1,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),
    titleSmall: m.titleSmall?.copyWith(
      fontSize: 14,
      height: 1.4,
      letterSpacing: 0,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),
    // ── Body — long-form reading ─────────────────────────────────────────
    bodyLarge: m.bodyLarge?.copyWith(
      fontSize: 16,
      height: 1.5,
      letterSpacing: 0,
      fontWeight: FontWeight.w400,
      color: onSurface,
    ),
    bodyMedium: m.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.5,
      letterSpacing: 0,
      fontWeight: FontWeight.w400,
      color: onSurface,
    ),
    bodySmall: m.bodySmall?.copyWith(
      fontSize: 13,
      height: 1.4,
      letterSpacing: 0,
      fontWeight: FontWeight.w400,
      color: onSurfaceVariant,
    ),
    // ── Label — buttons, tabs, micro CAPS ────────────────────────────────
    labelLarge: m.labelLarge?.copyWith(
      fontSize: 14,
      height: 1.2,
      letterSpacing: 0.2,
      fontWeight: FontWeight.w700,
      color: onSurface,
    ),
    labelMedium: m.labelMedium?.copyWith(
      fontSize: 12,
      height: 1.2,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w700,
      color: onSurfaceVariant,
    ),
    labelSmall: m.labelSmall?.copyWith(
      fontSize: 11,
      height: 1.2,
      letterSpacing: 0.8,
      fontWeight: FontWeight.w700,
      color: onSurfaceVariant,
    ),
  );
}

const _kCardRadius = ObsidianUiTokens.radiusMd;
const _kInputRadius = ObsidianUiTokens.radiusXl;
const _kGhost = 0.15;

ThemeData _buildTheme({
  required ObsidianUiTokens tokens,
  required Brightness brightness,
}) {
  final isDark = brightness == Brightness.dark;
  final textTheme = _buildTextTheme(
    onSurface: tokens.onSurface,
    onSurfaceVariant: tokens.onSurfaceVariant,
  );

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: tokens.primary,
    onPrimary: tokens.onPrimaryButton,
    primaryContainer: tokens.primaryContainer,
    onPrimaryContainer: isDark
        ? const Color(0xFFE0E7FF)
        : const Color(0xFF1E1B4B),
    secondary: tokens.secondary,
    onSecondary: isDark ? const Color(0xFF002B27) : Colors.white,
    secondaryContainer: isDark
        ? const Color(0xFF134E4A)
        : const Color(0xFFCCFBF1),
    onSecondaryContainer: isDark
        ? const Color(0xFFB2F5EA)
        : const Color(0xFF134E4A),
    // Tertiary = cyan accent (was previously warning).
    tertiary: tokens.tertiary,
    onTertiary: isDark ? const Color(0xFF00363D) : Colors.white,
    tertiaryContainer: isDark
        ? const Color(0xFF155E75)
        : const Color(0xFFCFFAFE),
    onTertiaryContainer: isDark
        ? const Color(0xFFA5F3FC)
        : const Color(0xFF155E75),
    error: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
    onError: isDark ? const Color(0xFF690005) : Colors.white,
    errorContainer: isDark ? const Color(0xFF93000A) : const Color(0xFFFFDAD6),
    onErrorContainer: isDark
        ? const Color(0xFFFFDAD6)
        : const Color(0xFF410002),
    surface: tokens.surface,
    onSurface: tokens.onSurface,
    surfaceContainerHighest: tokens.surfaceContainerHigh,
    surfaceContainerHigh: tokens.surfaceContainerHigh,
    surfaceContainer: tokens.surfaceContainer,
    surfaceContainerLow: tokens.surfaceContainerLow,
    surfaceContainerLowest: tokens.surfaceContainerLowest,
    onSurfaceVariant: tokens.onSurfaceVariant,
    outline: tokens.ghostBorder(_kGhost),
    outlineVariant: tokens.ghostBorder(_kGhost),
    shadow: tokens.primary.withValues(alpha: isDark ? 0.20 : 0.08),
    scrim: isDark ? Colors.black54 : Colors.black45,
    inverseSurface: isDark ? tokens.surfaceBright : const Color(0xFF1E1B4B),
    onInverseSurface: isDark ? tokens.onSurface : tokens.surfaceBright,
    inversePrimary: tokens.primaryContainer,
    surfaceTint: Colors.transparent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.surface,
    textTheme: textTheme,
    splashFactory: InkRipple.splashFactory,
    extensions: [tokens],
    dividerTheme: DividerThemeData(
      color: tokens.ghostBorder(0.08),
      thickness: 0,
      space: 0,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: tokens.onSurface,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: tokens.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.surfaceBright.withValues(
        alpha: isDark ? 0.92 : 0.98,
      ),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusLg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: tokens.surfaceContainer,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: tokens.onPrimaryButton,
        minimumSize: const Size(0, AppTapTarget.minSize),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.onSurface,
        minimumSize: const Size(0, AppTapTarget.minSize),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: BorderSide(color: tokens.ghostBorder(_kGhost)),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tokens.secondary,
        minimumSize: const Size(0, AppTapTarget.minSize),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kInputRadius),
        borderSide: BorderSide(color: tokens.ghostBorder(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kInputRadius),
        borderSide: BorderSide(color: tokens.ghostBorder(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kInputRadius),
        borderSide: BorderSide(
          color: tokens.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      labelStyle: textTheme.bodyLarge,
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
        final base =
            textTheme.bodySmall ??
            TextStyle(fontSize: 12, color: tokens.onSurfaceVariant);
        if (states.contains(WidgetState.focused)) {
          return base.copyWith(color: tokens.primary);
        }
        return base;
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: tokens.primary,
      unselectedLabelColor: tokens.onSurfaceVariant,
      labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: textTheme.labelLarge,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: tokens.primary, width: 2.5),
        borderRadius: BorderRadius.circular(2),
      ),
      indicatorSize: TabBarIndicatorSize.label,
      dividerHeight: 0,
      overlayColor: WidgetStateProperty.all(
        tokens.primary.withValues(alpha: 0.08),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: tokens.primary,
      linearTrackColor: tokens.surfaceContainerLow,
    ),
    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      minTileHeight: AppTapTarget.minSize,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: tokens.primary,
      foregroundColor: tokens.onPrimaryButton,
      elevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(AppTapTarget.minSize),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const CircleBorder(),
      side: BorderSide(color: tokens.ghostBorder(0.4), width: 2),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ObsidianUiTokens.radiusXxl),
        ),
      ),
    ),
  );
}

/// Dark theme.
ThemeData buildObsidianTheme() =>
    _buildTheme(tokens: ObsidianUiTokens.dark, brightness: Brightness.dark);

/// Light theme.
ThemeData buildObsidianLightTheme() =>
    _buildTheme(tokens: ObsidianUiTokens.light, brightness: Brightness.light);

// ── Forward-looking aliases (Obsidian* → AppTheme/AppColors/AppTokens) ────
//
// The existing `Obsidian*` symbols are being incrementally renamed to a neutral
// `App*` prefix per the approved Step-3 plan. Keep both names live during the
// migration so consumers can update at their own pace without churn.

/// Dark theme. Prefer over [buildObsidianTheme] in new code.
ThemeData buildAppTheme() => buildObsidianTheme();

/// Light theme. Prefer over [buildObsidianLightTheme] in new code.
ThemeData buildAppLightTheme() => buildObsidianLightTheme();
