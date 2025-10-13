import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xolotl/widgets/initialization_status_view.dart';

void main() {
  testWidgets('toggle button reveals details', (tester) async {
    //1.- pumpWidget monta la vista con detalles simulados y sin mostrarlos inicialmente.
    await tester.pumpWidget(const MaterialApp(
      home: InitializationStatusView(
        title: 'Estado',
        message: 'Inicializando',
        details: 'Detalle de prueba',
      ),
    ));

    expect(find.text('Detalle de prueba'), findsNothing);

    //2.- Al pulsar el botón se deben revelar los detalles para inspeccionarlos en pantalla.
    await tester.tap(find.text('Revisar errores'));
    await tester.pump();

    expect(find.text('Detalle de prueba'), findsOneWidget);
  });
}
