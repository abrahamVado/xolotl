import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mictlan_client/theme/shad_theme_builder.dart';

void main() {
  group('ShadThemeBuilder', () {
    test('genera tema claro alineado con Material', () {
      //1.- Preparamos esquemas desde un color semilla para asegurar consistencia.
      final lightScheme = ColorScheme.fromSeed(seedColor: Colors.teal);
      final darkScheme = ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark);

      //2.- Invocamos el generador para modo claro y verificamos la conversión.
      final theme = ShadThemeBuilder.fromMaterial(
        lightScheme: lightScheme,
        darkScheme: darkScheme,
        mode: ThemeMode.light,
      );

      //3.- Confirmamos que los colores relevantes conserven brillo y primario.
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, lightScheme.primary);
      expect(theme.colorScheme.card, lightScheme.surface);
      expect(theme.surfaceOpacity, closeTo(0.08, 0.0001));
    });

    test('genera tema oscuro alineado con Material', () {
      //1.- Utilizamos los mismos esquemas pero solicitando modo oscuro.
      final lightScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
      final darkScheme = ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark);

      //2.- Creamos el tema oscuro y validamos color y opacidad.
      final theme = ShadThemeBuilder.fromMaterial(
        lightScheme: lightScheme,
        darkScheme: darkScheme,
        mode: ThemeMode.dark,
      );

      //3.- Verificamos brillo, mapeo de primario y opacidad para superficies.
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, darkScheme.primary);
      expect(theme.colorScheme.card, darkScheme.surface);
      expect(theme.surfaceOpacity, closeTo(0.18, 0.0001));
    });
  });
}
