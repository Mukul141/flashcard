import 'package:flutter/material.dart';

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
    return Row(
      children: [
        Icon(Icons.light_mode, color: Theme.of(context).colorScheme.onPrimary),
        Switch(
          value: isDark,
          onChanged: onToggle,
          activeColor: Theme.of(context).colorScheme.onPrimary,
          activeTrackColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
          inactiveThumbColor: Theme.of(context).colorScheme.onPrimary,
          inactiveTrackColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
        ),
        Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.onPrimary),
        const SizedBox(width: 12),
      ],
    );
  }
}
