import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mictlan_client/theme/theme_controller.dart';

void main() {
  test('toggle alternates between light and dark modes', () {
    //1.- Preparamos el controlador en modo claro para validar el salto a oscuro.
    final controller = ThemeController(initialMode: ThemeMode.light);
    controller.toggle();
    expect(controller.mode, ThemeMode.dark);

    //2.- Volvemos a alternar para asegurar el retorno al modo claro.
    controller.toggle();
    expect(controller.mode, ThemeMode.light);
  });

  test('cycle advances through all theme modes', () {
    //1.- Iniciamos en claro y recorremos los tres modos disponibles.
    final controller = ThemeController(initialMode: ThemeMode.light);
    controller.cycle();
    expect(controller.mode, ThemeMode.dark);

    //2.- Validamos transición a sistema y de vuelta a claro.
    controller.cycle();
    expect(controller.mode, ThemeMode.system);

    controller.cycle();
    expect(controller.mode, ThemeMode.light);
  });
}
