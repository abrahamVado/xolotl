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

    //5.- Integra la ruta image_url enviada por la API preservando el árbol de assets declarado.
    test('resolveReportTypeAsset keeps api relative image_url inside assets directory', () {
      final asset = resolveReportTypeAsset({
        'id': 'bache',
        'image_url': 'assets/bache.jpeg',
      });
      expect(asset, 'assets/bache.jpeg');
    });

    //6.- Asegura que las rutas con diagonales invertidas se normalicen correctamente.
    test('resolveReportTypeAsset normalizes windows style separators', () {
      final asset = resolveReportTypeAsset({
        'id': 'agua',
        'image_url': r'internal\\assets\\agua.png',
      });
      expect(asset, 'internal/assets/agua.png');
    });

    //7.- Prefija archivos sin carpeta con el directorio principal de assets y respeta subcarpetas declaradas.
    test('resolveReportTypeAsset prefixes bare filenames into assets directory', () {
      final asset = resolveReportTypeAsset({
        'id': 'luz',
        'image_url': 'lampara.webp',
      });
      expect(asset, 'assets/lampara.webp');

      final nestedAsset = resolveReportTypeAsset({
        'id': 'farola',
        'image_url': 'report_images/farola.jpg',
      });
      expect(nestedAsset, 'assets/report_images/farola.jpg');
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

  //9.- Documentamos la lógica fija del grid para mantener el patrón 3x3 solicitado.
  group('resolveReportTypeCrossAxisCount', () {
    //10.- Incluso en anchos mínimos se conservan las tres columnas pedidas.
    test('resolveCrossAxisCount keeps three columns on narrow layouts', () {
      expect(resolveReportTypeCrossAxisCount(80), 3);
    });

    //11.- Los anchos medianos no modifican la cuadrícula fija.
    test('resolveCrossAxisCount keeps three columns on medium layouts', () {
      expect(resolveReportTypeCrossAxisCount(360), 3);
    });

    //12.- Las pantallas amplias también mantienen exactamente tres columnas.
    test('resolveCrossAxisCount keeps three columns on wide layouts', () {
      expect(resolveReportTypeCrossAxisCount(1600), 3);
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

    testWidgets('shows error indicator when network image fails to load', (tester) async {
      //28.- Forzamos un error de red para validar el mensaje de imagen no disponible.
      painting.debugNetworkImageHttpClientProvider = () => _FailingHttpClient();
      addTearDown(() => painting.debugNetworkImageHttpClientProvider = null);

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

      //29.- Avanzamos cuadros para que Flutter procese el error de carga asincrónico.
      await tester.pumpAndSettle();

      //30.- Debe mostrarse el contenedor con el aviso y el texto explicativo.
      expect(find.byKey(const Key('report-type-image-error-remoto')), findsOneWidget);
      expect(find.byKey(const Key('report-type-image-error-label-remoto')), findsOneWidget);
      expect(find.text('Imagen no disponible'), findsOneWidget);
    });

    testWidgets('constrains report type icons to a fixed square dimension', (tester) async {
      //31.- Montamos el overlay con un catálogo local para medir el tamaño del icono.
      await tester.pumpWidget(
        _wrapWithThemes(
          Scaffold(
            body: ReportTypeOverlay(
              types: const [
                {'id': 'pothole', 'name': 'Bache'},
              ],
              onSelected: _noopOnSelected,
              onDismiss: _noopOnDismiss,
            ),
          ),
        ),
      );

      //32.- Medimos el render del widget Image para asegurar el tamaño deseado.
      final imageSize = tester.getSize(find.byKey(const Key('report-type-image-pothole')));

      //33.- Confirmamos que el ancho y el alto coincidan con los 96 píxeles pedidos.
      expect(imageSize.width, 96);
      expect(imageSize.height, 96);
    });

    testWidgets('keeps grid columns fixed regardless of width', (tester) async {
      //34.- Configuramos múltiples escenarios de ancho para comprobar la cuadrícula fija.
      const mockTypes = [
        {'id': 'pothole', 'name': 'Bache'},
        {'id': 'light', 'name': 'Alumbrado'},
        {'id': 'trash', 'name': 'Basura'},
        {'id': 'water', 'name': 'Fuga'},
      ];

      //35.- Validamos que en 320 px el grid utilice tres columnas a pesar del ancho.
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
      expect(mobileDelegate.crossAxisCount, 3);

      //36.- Repetimos la verificación para un ancho de escritorio que mantiene tres columnas.
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
      expect(desktopDelegate.crossAxisCount, 3);
    });

    testWidgets('hides label text while preserving semantics', (tester) async {
      //37.- Renderizamos la tarjeta para asegurar que el texto visible se omite.
      final semanticsHandle = tester.ensureSemantics();
      addTearDown(semanticsHandle.dispose);

      await tester.pumpWidget(
        _wrapWithThemes(
          Scaffold(
            body: ReportTypeOverlay(
              types: const [
                {'id': 'pothole', 'name': 'Bache'},
              ],
              onSelected: _noopOnSelected,
              onDismiss: _noopOnDismiss,
            ),
          ),
        ),
      );

      //38.- No debe existir un widget Text con el nombre legible.
      expect(find.text('Bache'), findsNothing);

      //39.- La semántica conserva la etiqueta accesible del botón.
      final semantics = tester.getSemantics(find.byKey(const Key('report-type-pothole')));
      expect(semantics.label, contains('Bache'));
    });

    testWidgets('uses white material background for report type buttons', (tester) async {
      //40.- Montamos el overlay para inspeccionar el Material asociado a cada botón.
      await tester.pumpWidget(
        _wrapWithThemes(
          Scaffold(
            body: ReportTypeOverlay(
              types: const [
                {'id': 'pothole', 'name': 'Bache'},
              ],
              onSelected: _noopOnSelected,
              onDismiss: _noopOnDismiss,
            ),
          ),
        ),
      );

      //41.- Validamos que el Material inmediato tenga color blanco.
      final materialFinder = find.ancestor(
        of: find.byKey(const Key('report-type-pothole')),
        matching: find.byType(Material),
      );
      final material = tester.widget<Material>(materialFinder.first);
      expect(material.color, Colors.white);
    });
  });
}

//42.- _noopOnSelected actúa como callback vacío para escenarios donde no importa.
void _noopOnSelected(String _) {}

//43.- _noopOnDismiss actúa como callback vacío para escenarios donde no importa.
void _noopOnDismiss() {}

//44.- _wrapWithThemes envuelve los tests con MaterialApp y el tema shadcn sincronizado.
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

//45.- _FakeHttpClient intercepta las cargas de NetworkImage en los tests.
class _FakeHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest(url);
}

//46.- _FakeHttpClientRequest implementa la interfaz requerida por NetworkImage.
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

//47.- _FakeHttpClientResponse simula una respuesta vacía satisfactoria.
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

//48.- _FakeHttpHeaders almacena los encabezados en memoria para las pruebas.
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

//49.- _FailingHttpClient simula fallos para activar la ruta de error de imágenes.
class _FailingHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FailingHttpClientRequest(url);
}

//50.- _FailingHttpClientRequest produce un error al cerrar la conexión simulada.
class _FailingHttpClientRequest extends Fake implements HttpClientRequest {
  _FailingHttpClientRequest(this._uri);

  final Uri _uri;

  @override
  Uri get uri => _uri;

  @override
  String get method => 'GET';

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding value) {}

  @override
  int get contentLength => 0;

  @override
  set contentLength(int value) {}

  @override
  bool get bufferOutput => false;

  @override
  set bufferOutput(bool value) {}

  @override
  bool get followRedirects => false;

  @override
  set followRedirects(bool value) {}

  @override
  int get maxRedirects => 0;

  @override
  set maxRedirects(int value) {}

  @override
  bool get persistentConnection => false;

  @override
  set persistentConnection(bool value) {}

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

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

  @override
  Future<HttpClientResponse> close() =>
      Future<HttpClientResponse>.error(const SocketException('Simulated network failure'));

  @override
  Future<HttpClientResponse> get done =>
      Future<HttpClientResponse>.error(const SocketException('Simulated network failure'));
}
