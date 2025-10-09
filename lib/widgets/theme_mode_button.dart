import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    //1.- build obtiene el controlador del tema y muestra un botón ligero para alternar.
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
    return TextButton.icon(
      //2.- TextButton.icon ofrece una acción ligera que combina ícono y texto.
      onPressed: controller.cycle,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
