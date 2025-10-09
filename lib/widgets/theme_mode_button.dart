import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../theme/theme_controller.dart';

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    //1.- build obtiene el controlador del tema y muestra un botón ghost para alternar.
    final controller = ThemeScope.of(context);
    final themeMode = controller.mode;
    final icon = switch (themeMode) {
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
      ThemeMode.system => Icons.brightness_auto,
    };
    final label = switch (themeMode) {
      ThemeMode.light => 'Claro',
      ThemeMode.dark => 'Oscuro',
      ThemeMode.system => 'Sistema',
    };
    return Button.ghost(
      onPressed: controller.cycle,
      leading: Icon(icon),
      child: Text(label),
    );
  }
}
