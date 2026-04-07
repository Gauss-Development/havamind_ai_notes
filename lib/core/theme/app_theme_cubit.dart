import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeMode = 'app_theme_mode';

/// Persists user choice of [ThemeMode] (system / light / dark).
class AppThemeCubit extends Cubit<ThemeMode> {
  AppThemeCubit(this._prefs) : super(ThemeMode.system) {
    _restore();
  }

  final SharedPreferences _prefs;

  void _restore() {
    final raw = _prefs.getString(_kThemeMode);
    switch (raw) {
      case 'light':
        emit(ThemeMode.light);
      case 'dark':
        emit(ThemeMode.dark);
      default:
        emit(ThemeMode.system);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    await _prefs.setString(_kThemeMode, mode.name);
  }
}
