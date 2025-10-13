import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:mictlan_client/theme/shad_theme_builder.dart';
import 'package:mictlan_client/widgets/report_type_overlay.dart';

void main() {
  //1.- Agrupamos los tests de la lógica de assets para asegurar rutas correctas.
  group('_ReportTypeAssets', () {
    //2.- Valida que ids conocidos usen los archivos predefinidos.
    test('resolveReportTypeAsset returns known asset for mapped ids', () {
      final asset = resolveReportTypeAsset({'id': 'pothole'});
      expect(asset, 'assets/icons/pothole.png');
    });

    //3.- Comprueba que ids con símbolos se limpien a nombres seguros.
    test('resolveReportTypeAsset sanitizes unknown ids to asset names', () {
      final asset = resolveReportTypeAsset({'id': 'Agua Potable?!'});
      expect(asset, 'assets/icons/agua_potable.png');
    });

    //4.- Garantiza que ids vacíos tengan un fallback consistente.
    test('resolveReportTypeAsset falls back to default asset for empty ids', () {
      final asset = resolveReportTypeAsset({'id': '***'});
      expect(asset, 'assets/icons/default.png');
    });
  });

  //5.- Documentamos la lógica responsiva del grid para mantener consistencia visual.
  group('resolveReportTypeCrossAxisCount', () {
    //6.- Usa un ancho pequeño para confirmar que siempre haya al menos una columna.
    test('resolveCrossAxisCount clamps to one column on narrow layouts', () {
      expect(resolveReportTypeCrossAxisCount(80), 1);
    });

    //7.- Evalúa un ancho mediano que debería producir dos columnas en teléfonos.
    test('resolveCrossAxisCount yields intermediate columns for phones', () {
      expect(resolveReportTypeCrossAxisCount(360), 2);
    });

    //8.- Garantiza que no supere el máximo configurado aun con pantallas amplias.
    test('resolveCrossAxisCount caps the number of columns', () {
      expect(resolveReportTypeCrossAxisCount(1600), 4);
    });
  });

  //9.- Conservamos las verificaciones de la UI para asegurar el menú overlay.
  group('ReportTypeOverlay', () {
    testWidgets('shows empty state when types list is empty', (tester) async {
      //10.- Pump the widget with an empty list to verify the placeholder message.
      await tester.pumpWidget(
        _wrapWithThemes(
          const Scaffold(
            body: ReportTypeOverlay(
              types: [],
              onSelected: _noopOnSelected,
              onDismiss: _noopOnDismiss,
            ),
          ),
        ),
      );

      //11.- The overlay should render the friendly empty state text.
      expect(find.text('Sin tipos disponibles'), findsOneWidget);
    });

    testWidgets('invokes callbacks for selection and dismiss', (tester) async {
      //12.- Prepare spies to capture selection and dismiss invocations.
      String? selectedId;
      var dismissed = false;

      //13.- Render the overlay with a single mock type entry.
      await tester.pumpWidget(
        _wrapWithThemes(
          Scaffold(
            body: ReportTypeOverlay(
              types: const [
                {'id': 'pothole', 'name': 'Bache', 'emoji': '🕳️'},
              ],
              onSelected: (value) => selectedId = value,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      //14.- Tapping the tile should emit the item identifier.
      await tester.tap(find.byKey(const Key('report-type-pothole')));
      await tester.pump();
      expect(selectedId, 'pothole');

      //15.- Activating the close icon should call the dismiss callback.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(dismissed, isTrue);
    });

    testWidgets('renders expected asset image for each report type', (tester) async {
      //16.- Definimos una colección de tipos variados, incluyendo uno desconocido y uno sin id.
      const types = [
        {'id': 'pothole', 'name': 'Bache'},
        {'id': 'light', 'name': 'Alumbrado'},
        {'id': 'trash', 'name': 'Basura'},
        {'id': 'water', 'name': 'Fuga'},
        {'id': 'graffiti', 'name': 'Graffiti'},
        {'name': 'Sin Identificador'},
      ];

      //17.- Montamos el overlay para poder inspeccionar los widgets Image.asset generados.
      await tester.pumpWidget(
        _wrapWithThemes(
          Scaffold(
            body: ReportTypeOverlay(
              types: types,
              onSelected: _noopOnSelected,
              onDismiss: _noopOnDismiss,
            ),
          ),
        ),
      );

      //18.- Verificamos que los ids conocidos usan rutas exactas a los placeholders preparados.
      final potholeImage = tester.widget<Image>(find.byKey(const Key('report-type-image-pothole')));
      expect((potholeImage.image as AssetImage).assetName, 'assets/icons/pothole.png');

      final lightImage = tester.widget<Image>(find.byKey(const Key('report-type-image-light')));
      expect((lightImage.image as AssetImage).assetName, 'assets/icons/light.png');

      final trashImage = tester.widget<Image>(find.byKey(const Key('report-type-image-trash')));
      expect((trashImage.image as AssetImage).assetName, 'assets/icons/trash.png');

      final waterImage = tester.widget<Image>(find.byKey(const Key('report-type-image-water')));
      expect((waterImage.image as AssetImage).assetName, 'assets/icons/water.png');

      //19.- Los ids nuevos generan rutas sanitizadas dentro de assets/icons automáticamente.
      final graffitiImage = tester.widget<Image>(find.byKey(const Key('report-type-image-graffiti')));
      expect((graffitiImage.image as AssetImage).assetName, 'assets/icons/graffiti.png');

      //20.- Cuando no existe id se recurre al placeholder default.
      final fallbackImage = tester.widget<Image>(find.byKey(const Key('report-type-image-Sin Identificador')));
      expect((fallbackImage.image as AssetImage).assetName, 'assets/icons/default.png');
    });

    testWidgets('adapts grid columns to available width', (tester) async {
      //21.- Configuramos múltiples escenarios de ancho para evaluar la retícula responsiva.
      const mockTypes = [
        {'id': 'pothole', 'name': 'Bache'},
        {'id': 'light', 'name': 'Alumbrado'},
        {'id': 'trash', 'name': 'Basura'},
        {'id': 'water', 'name': 'Fuga'},
      ];

      //22.- Validamos que en 320 px el grid utilice dos columnas ideales para móviles.
      await tester.pumpWidget(
        _wrapWithThemes(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: ReportTypeOverlay(
                  types: mockTypes,
                  onSelected: _noopOnSelected,
                  onDismiss: _noopOnDismiss,
                ),
              ),
            ),
          ),
        ),
      );

      final mobileGrid = tester.widget<GridView>(find.byType(GridView));
      final mobileDelegate =
          mobileGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(mobileDelegate.crossAxisCount, 2);

      //23.- Repite la verificación para un ancho de escritorio que debe saturar el máximo.
      await tester.pumpWidget(
        _wrapWithThemes(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 1024,
                child: ReportTypeOverlay(
                  types: mockTypes,
                  onSelected: _noopOnSelected,
                  onDismiss: _noopOnDismiss,
                ),
              ),
            ),
          ),
        ),
      );

      final desktopGrid = tester.widget<GridView>(find.byType(GridView));
      final desktopDelegate =
          desktopGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(desktopDelegate.crossAxisCount, 4);
    });
  });
}

//24.- _noopOnSelected actúa como callback vacío para escenarios donde no importa.
void _noopOnSelected(String _) {}

//25.- _noopOnDismiss actúa como callback vacío para escenarios donde no importa.
void _noopOnDismiss() {}

//26.- _wrapWithThemes envuelve los tests con MaterialApp y el tema shadcn sincronizado.
Widget _wrapWithThemes(Widget child, {ThemeMode mode = ThemeMode.light}) {
  final lightScheme = ColorScheme.fromSeed(seedColor: Colors.blueGrey);
  final darkScheme = ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.dark);
  final shadTheme = ShadThemeBuilder.fromMaterial(
    lightScheme: lightScheme,
    darkScheme: darkScheme,
    mode: mode,
  );
  return MaterialApp(
    themeMode: mode,
    theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
    darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
    home: shad.Theme(
      data: shadTheme,
      child: child,
    ),
  );
}
