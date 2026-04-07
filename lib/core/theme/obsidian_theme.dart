import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';

TextTheme _buildTextTheme({
  required Color onSurface,
  required Color onSurfaceVariant,
}) {
  final m = GoogleFonts.manropeTextTheme();

  return m.copyWith(
    displayLarge: m.displayLarge?.copyWith(
      fontSize: 56,
      height: 1.1,
      letterSpacing: -0.02 * 56,
      fontWeight: FontWeight.w800,
      color: onSurface,
    ),
    displayMedium: m.displayMedium?.copyWith(
      letterSpacing: -0.02 * 45,
      fontWeight: FontWeight.w800,
      color: onSurface,
    ),
    displaySmall: m.displaySmall?.copyWith(
      letterSpacing: -0.02 * 36,
      fontWeight: FontWeight.w800,
      color: onSurface,
    ),
    headlineLarge: m.headlineLarge?.copyWith(
      fontSize: 28,
      height: 1.2,
      letterSpacing: -0.5,
      fontWeight: FontWeight.w800,
      color: onSurface,
    ),
    headlineMedium: m.headlineMedium?.copyWith(
      fontSize: 24,
      height: 1.25,
      letterSpacing: -0.4,
      fontWeight: FontWeight.w700,
      color: onSurface,
    ),
    headlineSmall: m.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: onSurface,
    ),
    titleLarge: m.titleLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: onSurface,
    ),
    titleMedium: m.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),
    titleSmall: m.titleSmall?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),
    bodyLarge: m.bodyLarge?.copyWith(
      fontSize: 16,
      height: 1.45,
      fontWeight: FontWeight.w500,
      color: onSurface,
    ),
    bodyMedium: m.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.45,
      fontWeight: FontWeight.w500,
      color: onSurface,
    ),
    bodySmall: m.bodySmall?.copyWith(
      fontSize: 12,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: onSurfaceVariant,
    ),
    labelLarge: m.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: onSurface,
    ),
    labelMedium: m.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: onSurfaceVariant,
    ),
    labelSmall: m.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
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
  final textTheme = _buildTextTheme(
    onSurface: tokens.onSurface,
    onSurfaceVariant: tokens.onSurfaceVariant,
  );

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: tokens.primary,
    onPrimary: tokens.onPrimaryButton,
    primaryContainer: tokens.primaryContainer,
    onPrimaryContainer: brightness == Brightness.dark
        ? const Color(0xFFE0E7FF)
        : const Color(0xFF1E1B4B),
    secondary: tokens.secondary,
    onSecondary: tokens.onPrimaryButton,
    secondaryContainer: brightness == Brightness.dark
        ? const Color(0xFF2D3548)
        : const Color(0xFFE0E7FF),
    onSecondaryContainer: brightness == Brightness.dark
        ? const Color(0xFFC7D2FE)
        : const Color(0xFF3730A3),
    tertiary: tokens.warning,
    onTertiary: const Color(0xFF1C1507),
    tertiaryContainer: brightness == Brightness.dark
        ? const Color(0xFF78350F)
        : const Color(0xFFFFFBEB),
    onTertiaryContainer: brightness == Brightness.dark
        ? const Color(0xFFFFE7C2)
        : const Color(0xFF78350F),
    error: brightness == Brightness.dark
        ? const Color(0xFFFFB4AB)
        : const Color(0xFFDC2626),
    onError: brightness == Brightness.dark
        ? const Color(0xFF690005)
        : Colors.white,
    errorContainer: brightness == Brightness.dark
        ? const Color(0xFF93000A)
        : const Color(0xFFFFDAD6),
    onErrorContainer: brightness == Brightness.dark
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
    shadow: Color.fromRGBO(
      79,
      70,
      229,
      brightness == Brightness.light ? 0.06 : 0.12,
    ),
    scrim: brightness == Brightness.dark ? Colors.black54 : Colors.black45,
    inverseSurface: brightness == Brightness.dark
        ? tokens.surfaceBright
        : const Color(0xFF1E1B4B),
    onInverseSurface: brightness == Brightness.dark
        ? tokens.onSurface
        : tokens.surfaceBright,
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
        alpha: brightness == Brightness.dark ? 0.92 : 0.98,
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
      contentTextStyle:
          textTheme.bodyMedium?.copyWith(color: tokens.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: tokens.onPrimaryButton,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: textTheme.titleSmall,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: BorderSide(color: tokens.ghostBorder(_kGhost)),
        shape: const StadiumBorder(),
        textStyle: textTheme.titleSmall,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tokens.secondary,
        textStyle:
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
        final base = textTheme.bodySmall ??
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
      labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: textTheme.titleSmall,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    checkboxTheme: CheckboxThemeData(
      shape: const CircleBorder(),
      side: BorderSide(color: tokens.ghostBorder(0.4), width: 2),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ObsidianUiTokens.radiusLg),
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
