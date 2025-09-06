// providers/theme_provider.dart
import 'package:flutter/material.dart';

/// Provider for managing app theme (light/dark/system).
/// Exposes current [ThemeMode] and allows toggling.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  /// Current theme mode (system / light / dark).
  ThemeMode get mode => _mode;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Toggles between light and dark themes.
  /// If [isDark] is true → dark mode, else → light mode.
  void toggle(bool isDark) {
    _mode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Resets theme back to system default.
  void resetToSystem() {
    _mode = ThemeMode.system;
    notifyListeners();
  }
}
