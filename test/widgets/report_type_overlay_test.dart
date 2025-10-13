import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:test/fake.dart';

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

    //5.- Integra la ruta image_url enviada por la API al directorio interno esperado.
    test('resolveReportTypeAsset remaps api image_url into internal assets', () {
      final asset = resolveReportTypeAsset({
        'id': 'bache',
        'image_url': 'assets/bache.jpeg',
      });
      expect(asset, 'internal/assets/bache.jpeg');
    });

    //6.- Asegura que las rutas con diagonales invertidas se normalicen correctamente.
    test('resolveReportTypeAsset normalizes windows style separators', () {
      final asset = resolveReportTypeAsset({
        'id': 'agua',
        'image_url': r'internal\\assets\\agua.png',
      });
      expect(asset, 'internal/assets/agua.png');
    });

    //7.- Prefija archivos sin carpeta con el directorio interno.
    test('resolveReportTypeAsset prefixes bare filenames into internal assets', () {
      final asset = resolveReportTypeAsset({
        'id': 'luz',
        'image_url': 'lampara.webp',
      });
      expect(asset, 'internal/assets/lampara.webp');
    });

    //8.- Mantiene las URLs absolutas provenientes del backend para carga remota.
    test('resolveReportTypeAsset keeps http urls untouched', () {
      final asset = resolveReportTypeAsset({
        'id': 'remoto',
        'image_url': 'https://cdn.example.com/reports/remoto.png',
      });
      expect(asset, 'https://cdn.example.com/reports/remoto.png');
    });
  });

  //9.- Documentamos la lógica responsiva del grid para mantener consistencia visual.
  group('resolveReportTypeCrossAxisCount', () {
    //10.- Usa un ancho pequeño para confirmar que siempre haya al menos una columna.
    test('resolveCrossAxisCount clamps to one column on narrow layouts', () {
      expect(resolveReportTypeCrossAxisCount(80), 1);
    });

    //11.- Evalúa un ancho mediano que debería producir dos columnas en teléfonos.
    test('resolveCrossAxisCount yields intermediate columns for phones', () {
      expect(resolveReportTypeCrossAxisCount(360), 2);
    });

    //12.- Garantiza que no supere el máximo configurado aun con pantallas amplias.
    test('resolveCrossAxisCount caps the number of columns', () {
      expect(resolveReportTypeCrossAxisCount(1600), 4);
    });
  });

  //13.- Conservamos las verificaciones de la UI para asegurar el menú overlay.
  group('ReportTypeOverlay', () {
    testWidgets('shows empty state when types list is empty', (tester) async {
      //14.- Pump the widget with an empty list to verify el estado vacío.
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

      //15.- The overlay should render the friendly empty state text.
      expect(find.text('Sin tipos disponibles'), findsOneWidget);
    });

    testWidgets('invokes callbacks for selection and dismiss', (tester) async {
      //16.- Prepare spies to capture selection and dismiss invocations.
      String? selectedId;
      var dismissed = false;

      //17.- Render the overlay with a single mock type entry.
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

      //18.- Tapping the tile should emit the item identifier.
      await tester.tap(find.byKey(const Key('report-type-pothole')));
      await tester.pump();
      expect(selectedId, 'pothole');

      //19.- Activating the close icon should call the dismiss callback.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(dismissed, isTrue);
    });

    testWidgets('renders expected asset image for each report type', (tester) async {
      //20.- Definimos una colección de tipos variados, incluyendo uno desconocido y uno sin id.
      const types = [
        {'id': 'pothole', 'name': 'Bache'},
        {'id': 'light', 'name': 'Alumbrado'},
        {'id': 'trash', 'name': 'Basura'},
        {'id': 'water', 'name': 'Fuga'},
        {'id': 'graffiti', 'name': 'Graffiti'},
        {'name': 'Sin Identificador'},
      ];

      //21.- Montamos el overlay para poder inspeccionar los widgets Image.asset generados.
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

      //22.- Verificamos que los ids conocidos usan rutas exactas a los placeholders preparados.
      final potholeImage = tester.widget<Image>(find.byKey(const Key('report-type-image-pothole')));
      expect((potholeImage.image as AssetImage).assetName, 'assets/icons/pothole.png');

      final lightImage = tester.widget<Image>(find.byKey(const Key('report-type-image-light')));
      expect((lightImage.image as AssetImage).assetName, 'assets/icons/light.png');

      final trashImage = tester.widget<Image>(find.byKey(const Key('report-type-image-trash')));
      expect((trashImage.image as AssetImage).assetName, 'assets/icons/trash.png');

      final waterImage = tester.widget<Image>(find.byKey(const Key('report-type-image-water')));
      expect((waterImage.image as AssetImage).assetName, 'assets/icons/water.png');

      //23.- Los ids nuevos generan rutas sanitizadas dentro de assets/icons automáticamente.
      final graffitiImage = tester.widget<Image>(find.byKey(const Key('report-type-image-graffiti')));
      expect((graffitiImage.image as AssetImage).assetName, 'assets/icons/graffiti.png');

      //24.- Cuando no existe id se recurre al placeholder default.
      final fallbackImage = tester.widget<Image>(find.byKey(const Key('report-type-image-Sin Identificador')));
      expect((fallbackImage.image as AssetImage).assetName, 'assets/icons/default.png');
    });

    testWidgets('renders network image when api supplies absolute url', (tester) async {
      //25.- Configuramos un HttpClient falso para que NetworkImage no haga solicitudes reales.
      painting.debugNetworkImageHttpClientProvider = () => _FakeHttpClient();
      addTearDown(() => painting.debugNetworkImageHttpClientProvider = null);

      //26.- Montamos el overlay con un tipo que contiene una URL remota.
      await tester.pumpWidget(
        _wrapWithThemes(
          Scaffold(
            body: ReportTypeOverlay(
              types: const [
                {
                  'id': 'remoto',
                  'name': 'Remoto',
                  'image_url': 'https://cdn.example.com/reports/remoto.png',
                },
              ],
              onSelected: _noopOnSelected,
              onDismiss: _noopOnDismiss,
            ),
          ),
        ),
      );

      await tester.pump();

      //27.- Validamos que la tarjeta use un NetworkImage apuntando a la ruta recibida.
      final remoteImage = tester.widget<Image>(find.byKey(const Key('report-type-image-remoto')));
      final provider = remoteImage.image as NetworkImage;
      expect(provider.url, 'https://cdn.example.com/reports/remoto.png');
    });

    testWidgets('adapts grid columns to available width', (tester) async {
      //28.- Configuramos múltiples escenarios de ancho para evaluar la retícula responsiva.
      const mockTypes = [
        {'id': 'pothole', 'name': 'Bache'},
        {'id': 'light', 'name': 'Alumbrado'},
        {'id': 'trash', 'name': 'Basura'},
        {'id': 'water', 'name': 'Fuga'},
      ];

      //29.- Validamos que en 320 px el grid utilice dos columnas ideales para móviles.
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

      //30.- Repite la verificación para un ancho de escritorio que debe saturar el máximo.
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

//31.- _noopOnSelected actúa como callback vacío para escenarios donde no importa.
void _noopOnSelected(String _) {}

//32.- _noopOnDismiss actúa como callback vacío para escenarios donde no importa.
void _noopOnDismiss() {}

//33.- _wrapWithThemes envuelve los tests con MaterialApp y el tema shadcn sincronizado.
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

//34.- _FakeHttpClient intercepta las cargas de NetworkImage en los tests.
class _FakeHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest(url);
}

//35.- _FakeHttpClientRequest implementa la interfaz requerida por NetworkImage.
class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  _FakeHttpClientRequest(this._uri);

  final Uri _uri;
  final _FakeHttpClientResponse _response = _FakeHttpClientResponse();
  Encoding _encoding = utf8;
  int _contentLength = 0;
  bool _bufferOutput = true;
  bool _followRedirects = true;
  int _maxRedirects = 5;
  bool _persistentConnection = false;

  @override
  Encoding get encoding => _encoding;

  @override
  set encoding(Encoding value) => _encoding = value;

  @override
  int get contentLength => _contentLength;

  @override
  set contentLength(int value) => _contentLength = value;

  @override
  bool get bufferOutput => _bufferOutput;

  @override
  set bufferOutput(bool value) => _bufferOutput = value;

  @override
  bool get followRedirects => _followRedirects;

  @override
  set followRedirects(bool value) => _followRedirects = value;

  @override
  int get maxRedirects => _maxRedirects;

  @override
  set maxRedirects(int value) => _maxRedirects = value;

  @override
  bool get persistentConnection => _persistentConnection;

  @override
  set persistentConnection(bool value) => _persistentConnection = value;

  @override
  String get method => 'GET';

  @override
  Uri get uri => _uri;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  Future<HttpClientResponse> close() => Future.value(_response);

  @override
  Future<HttpClientResponse> get done => Future.value(_response);

  @override
  Future<void> flush() async {}

  @override
  void write(Object? obj) {}

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? obj = '']) {}
}

//36.- _FakeHttpClientResponse simula una respuesta vacía satisfactoria.
class _FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  _FakeHttpClientResponse();

  final Stream<List<int>> _stream = Stream<List<int>>.fromIterable(const [<int>[]]);

  @override
  int get contentLength => 0;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  List<Cookie> get cookies => const [];

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  int get statusCode => 200;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  Future<Socket> detachSocket() async => throw UnimplementedError();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> data)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]) async => this;
}

//37.- _FakeHttpHeaders almacena los encabezados en memoria para las pruebas.
class _FakeHttpHeaders extends Fake implements HttpHeaders {
  final Map<String, List<String>> _headers = {};

  @override
  void add(String name, Object value, [bool preserveHeaderCase = false]) {
    final key = name.toLowerCase();
    _headers.putIfAbsent(key, () => <String>[]).add(value.toString());
  }

  @override
  void set(String name, Object value, [bool preserveHeaderCase = false]) {
    final key = name.toLowerCase();
    _headers[key] = [value.toString()];
  }

  @override
  List<String>? operator [](String name) => _headers[name.toLowerCase()];
}
