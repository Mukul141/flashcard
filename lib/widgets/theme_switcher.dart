// lib/widgets/theme_switcher.dart
import 'package:flutter/material.dart';

/// A row widget for toggling between light and dark mode.
///
/// - Shows light/dark icons with a [Switch] in between.
/// - [isDark] determines the current state.
/// - [onToggle] is called when the switch is flipped.
class ThemeSwitcher extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onToggle;

  const ThemeSwitcher({
    super.key,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;

    // -------------------------------------------------------------------------
    // UI
    // -------------------------------------------------------------------------
    return Row(
      children: [
        Icon(Icons.light_mode, color: color),
        Switch(
          value: isDark,
          onChanged: onToggle,
          activeColor: color,
          activeTrackColor: color.withOpacity(0.5),
          inactiveThumbColor: color,
          inactiveTrackColor: color.withOpacity(0.3),
        ),
        Icon(Icons.dark_mode, color: color),
        const SizedBox(width: 12),
      ],
    );
  }
}
