import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mictlan_client/theme/theme_controller.dart';
import 'package:mictlan_client/widgets/theme_mode_button.dart';

void main() {
  testWidgets('ThemeModeButton cycles through modes', (tester) async {
    //1.- Configuramos un ThemeController inicial en modo claro.
    final controller = ThemeController(initialMode: ThemeMode.light);

    await tester.pumpWidget(
      MaterialApp(
        home: ThemeScope(
          controller: controller,
          child: const Scaffold(
            body: Center(child: ThemeModeButton()),
          ),
        ),
      ),
    );

    //2.- Verificamos que el botón muestre el modo actual y cambie tras presionarlo.
    expect(find.text('Claro'), findsOneWidget);

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(controller.mode, ThemeMode.dark);
    expect(find.text('Oscuro'), findsOneWidget);
  });
}
