/// 8pt-grid spacing scale used throughout the app.
///
/// Only these values should appear in padding / margin / gap arguments.
/// This prevents "magic-number" spacing and keeps layouts consistent.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double xxxxl = 64;

  /// Standard horizontal page padding (both sides).
  static const double pagePadding = lg;
}
