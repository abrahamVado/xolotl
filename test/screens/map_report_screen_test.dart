import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:mictlan_client/screens/map_report_screen.dart';
import 'package:mictlan_client/providers/folio_providers.dart';
import 'package:mictlan_client/services/api.dart';
import 'package:mictlan_client/services/folio_repository.dart';
import 'package:mictlan_client/services/location_service.dart';
import 'package:mictlan_client/services/session_service.dart';
import 'package:mictlan_client/services/google_maps_availability.dart';
import 'package:mictlan_client/theme/shad_theme_builder.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

//1.- _FakeGoogleMapsPlatform neutraliza las dependencias de plataforma del mapa.
class _FakeGoogleMapsPlatform extends GoogleMapsFlutterPlatform {
  @override
  Future<void> init(int mapId) async {}

  @override
  Future<void> dispose({required int mapId}) async {}

  @override
  Future<void> updateMapOptions(
    Map<String, dynamic> optionsUpdate, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateMapConfiguration(
    MapConfiguration configuration, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateMarkers(
    MarkerUpdates markerUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updatePolygons(
    PolygonUpdates polygonUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updatePolylines(
    PolylineUpdates polylineUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateCircles(
    CircleUpdates circleUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateTileOverlays({
    required Set<TileOverlay> newTileOverlays,
    required int mapId,
  }) async {}

  @override
  Future<void> clearTileCache(
    TileOverlayId tileOverlayId, {
    required int mapId,
  }) async {}

  @override
  Future<void> animateCamera(
    CameraUpdate cameraUpdate, {
    required int mapId,
  }) async {}

  @override
  Future<void> moveCamera(
    CameraUpdate cameraUpdate, {
    required int mapId,
  }) async {}

  @override
  Future<void> setMapStyle(
    String? mapStyle, {
    required int mapId,
  }) async {}

  @override
  Future<LatLngBounds> getVisibleRegion({
    required int mapId,
  }) async => const LatLngBounds(
        southwest: LatLng(0, 0), northeast: LatLng(0, 0));

  @override
  Future<ScreenCoordinate> getScreenCoordinate(
    LatLng latLng, {
    required int mapId,
  }) async => const ScreenCoordinate(x: 0, y: 0);

  @override
  Future<LatLng> getLatLng(
    ScreenCoordinate screenCoordinate, {
    required int mapId,
  }) async => const LatLng(0, 0);

  @override
  Future<Uint8List?> takeSnapshot({
    required int mapId,
  }) async => Uint8List(0);

  @override
  Future<ScreenCoordinate> getMarkerScreenPosition(
    MarkerId markerId, {
    required int mapId,
  }) async => const ScreenCoordinate(x: 0, y: 0);

  @override
  Future<bool> isMarkerInfoWindowShown(
    MarkerId markerId, {
    required int mapId,
  }) async => false;

  @override
  Future<void> showMarkerInfoWindow(
    MarkerId markerId, {
    required int mapId,
  }) async {}

  @override
  Future<void> hideMarkerInfoWindow(
    MarkerId markerId, {
    required int mapId,
  }) async {}

  @override
  Stream<CameraMoveStartedEvent> onCameraMoveStarted({
    required int mapId,
  }) => const Stream.empty();

  @override
  Stream<CameraMoveEvent> onCameraMove({
    required int mapId,
  }) => const Stream.empty();

  @override
  Stream<CameraIdleEvent> onCameraIdle({
    required int mapId,
  }) => const Stream.empty();

  @override
  Stream<MarkerTapEvent> onMarkerTap({
    required int mapId,
  }) => const Stream.empty();

  @override
  Stream<MarkerDragStartEvent> onMarkerDragStart({
    required int mapId,
  }) => const Stream.empty();

  @override
  Stream<MarkerDragEvent> onMarkerDrag({
    required int mapId,
  }) => const Stream.empty();

  @override
  Stream<MarkerDragEndEvent> onMarkerDragEnd({
    required int mapId,
  }) => const Stream.empty();

  @override
  Stream<InfoWindowTapEvent> onInfoWindowTap({
    required int mapId,
  }) => const Stream.empty();

  @override
  Stream<InfoWindowLongPressEvent> onInfoWindowLongPress({
    required int mapId,
  }) => const Stream.empty();

  @override
  Stream<InfoWindowCloseEvent> onInfoWindowClose({
    required int mapId,
  }) => const Stream.empty();

  @override
  Stream<PolylineTapEvent> onPolylineTap({
    required int mapId,
  }) => const Stream.empty();

  @override
  Stream<PolygonTapEvent> onPolygonTap({
    required int mapId,
  }) => const Stream.empty();

  @override
  Stream<CircleTapEvent> onCircleTap({
    required int mapId,
  }) => const Stream.empty();

  @override
  Stream<MapTapEvent> onTap({
    required int mapId,
  }) => const Stream.empty();

  @override
  Stream<MapLongPressEvent> onLongPress({
    required int mapId,
  }) => const Stream.empty();

  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) {
    onPlatformViewCreated(creationId);
    return const SizedBox.shrink();
  }

  @override
  void enableDebugInspection() {}
}

//2.- _RecordingHttpClient responde con datos prefabricados y registra envíos.
class _RecordingHttpClient extends http.BaseClient {
  final List<Map<String, dynamic>> incidentTypes;
  String? lastIncidentType;

  _RecordingHttpClient({required this.incidentTypes});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'GET' && request.url.path.endsWith('/incident-types')) {
      final body = jsonEncode(incidentTypes);
      return http.StreamedResponse(
        Stream<List<int>>.fromIterable([utf8.encode(body)]),
        200,
        headers: const {'content-type': 'application/json'},
      );
    }
    if (request.method == 'POST' && request.url.path.endsWith('/reports')) {
      final bytes = await request.finalize().fold<List<int>>(
            <int>[],
            (previous, element) => previous..addAll(element),
          );
      final payload = utf8.decode(bytes);
      final data = jsonDecode(payload) as Map<String, dynamic>;
      lastIncidentType = data['incidentTypeId'] as String?;
      return http.StreamedResponse(
        Stream<List<int>>.fromIterable([
          utf8.encode(jsonEncode({'folio': 'abc123'})),
        ]),
        201,
        headers: const {'content-type': 'application/json'},
      );
    }
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable([utf8.encode('{}')]),
      404,
      headers: const {'content-type': 'application/json'},
    );
  }
}

//3.- _testIncidentTypes reproduce el catálogo por defecto para las pruebas.
const List<Map<String, dynamic>> _testIncidentTypes = [
  {
    'id': 'pothole',
    'name': 'Pothole',
    'emoji': '🕳️',
    'reportType': 'incident.pothole',
  },
  {
    'id': 'light',
    'name': 'Street Light',
    'emoji': '💡',
    'reportType': 'incident.light',
  },
  {
    'id': 'trash',
    'name': 'Trash',
    'emoji': '🗑️',
    'reportType': 'incident.trash',
  },
  {
    'id': 'water',
    'name': 'Water Leak',
    'emoji': '💧',
    'reportType': 'incident.water',
  },
];

//4.- _TestBundle agrupa cliente HTTP, sesión y servicio API para cada caso.
class _TestBundle {
  late final _RecordingHttpClient client;
  late final SessionService session;
  late final FolioRepository folios;
  late final ApiService api;

  _TestBundle() {
    client = _RecordingHttpClient(incidentTypes: _testIncidentTypes);
    session = SessionService(
      client: client,
      storage: InMemoryTokenStorage(
        SessionToken(
          token: 'token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          phone: '+521111111111',
        ),
      ),
      clock: () => DateTime.now(),
    );
    folios = FolioRepository(storage: InMemoryFolioStorage(), session: session);
    api = ApiService(client: client, session: session, folios: folios);
  }
}

//5.- _pumpReportScreen unifica la creación del árbol Material con dependencias falsas.
Future<void> _pumpReportScreen(
  WidgetTester tester,
  _TestBundle bundle, {
  ValueChanged<String>? onTypeSelected,
  ThemeMode mode = ThemeMode.light,
  LocationService? locationService,
}) async {
  final lightScheme = ColorScheme.fromSeed(seedColor: Colors.blueGrey);
  final darkScheme = ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.dark);
  final shadTheme = ShadThemeBuilder.fromMaterial(
    lightScheme: lightScheme,
    darkScheme: darkScheme,
    mode: mode,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        folioRepositoryProvider.overrideWithValue(bundle.folios),
      ],
      child: MaterialApp(
        themeMode: mode,
        theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
        darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
        home: shad.Theme(
          data: shadTheme,
          child: MapReportScreen(
            api: bundle.api,
            session: bundle.session,
            onReportTypeSelected: onTypeSelected,
            location: locationService,
          ),
        ),
      ),
    ),
  );
}

void main() {
  //6.- main agrupa y prepara las pruebas del flujo de introducción del mapa.
  setUpAll(() {
    GoogleMapsFlutterPlatform.instance = _FakeGoogleMapsPlatform();
  });

  setUp(() {
    //6.1.- Forzamos que la API key esté disponible por defecto en las pruebas.
    GoogleMapsAvailability.debugOverride(() async => true);
  });

  tearDown(() {
    //6.2.- Restauramos el resolvedor original tras cada caso de prueba.
    GoogleMapsAvailability.debugReset();
  });

  testWidgets('muestra la introducción por defecto', (tester) async {
    //7.- Validamos que el mensaje inicial aparezca al crear la pantalla.
    final bundle = _TestBundle();
    await _pumpReportScreen(tester, bundle);

    expect(find.text('Click to continue'), findsOneWidget);
    expect(find.byKey(const Key('map-intro-card')), findsOneWidget);
    expect(find.byType(shad.PrimaryButton), findsOneWidget);
    expect(find.byType(GoogleMap), findsNothing);
  });

  testWidgets('cambia al mapa después de continuar', (tester) async {
    //8.- Confirmamos que la pulsación del botón renderiza el mapa.
    final bundle = _TestBundle();
    await _pumpReportScreen(tester, bundle);

    await tester.tap(find.text('Click to continue'));
    await tester.pumpAndSettle();

    expect(find.byType(GoogleMap), findsOneWidget);
  });

  testWidgets('muestra la instrucción para iniciar un reporte', (tester) async {
    //9.- Verificamos que la superposición muestre el mensaje contextual del mapa.
    final bundle = _TestBundle();
    await _pumpReportScreen(tester, bundle);

    await tester.tap(find.text('Click to continue'));
    await tester.pumpAndSettle();

    expect(find.text('Haz clic en el mapa para iniciar un reporte'), findsOneWidget);
  });

  testWidgets('configura la cámara inicial sobre Minatitlán', (tester) async {
    //10.- Validamos que la cámara apunte a Minatitlán con el zoom adecuado.
    final bundle = _TestBundle();
    await _pumpReportScreen(tester, bundle);

    await tester.tap(find.text('Click to continue'));
    await tester.pumpAndSettle();

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    expect(map.initialCameraPosition.target.latitude, closeTo(18.0010, 0.0001));
    expect(map.initialCameraPosition.target.longitude, closeTo(-94.5597, 0.0001));
    expect(map.initialCameraPosition.zoom, closeTo(12.5, 0.01));
  });

  testWidgets('tocar el mapa permite abrir el selector mediante el botón flotante',
      (tester) async {
    //11.- Simulamos un toque y usamos el nuevo botón para mostrar el overlay.
    final bundle = _TestBundle();
    await _pumpReportScreen(tester, bundle);

    await tester.tap(find.text('Click to continue'));
    await tester.pumpAndSettle();

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    map.onTap?.call(const LatLng(20.0, -99.0));
    await tester.pump();

    expect(find.byKey(const Key('selected-marker-report-button')), findsOneWidget);
    expect(find.byKey(const Key('report-type-overlay')), findsNothing);

    await tester.tap(find.byKey(const Key('selected-marker-report-button')));
    await tester.pump();

    expect(find.byKey(const Key('report-type-overlay')), findsOneWidget);
    expect(
      () => tester.widget<shad.SurfaceCard>(find.byKey(const Key('report-type-overlay'))),
      returnsNormally,
    );
  });

  testWidgets('el marcador seleccionado expone un botón para iniciar reporte', (tester) async {
    //11.1.- Verificamos que el marcador incluya el CTA solicitado por la ciudadanía.
    final bundle = _TestBundle();
    await _pumpReportScreen(tester, bundle);

    await tester.tap(find.text('Click to continue'));
    await tester.pumpAndSettle();

    var map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    map.onTap?.call(const LatLng(21.17, -86.85));
    await tester.pump();

    map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    final marker = map.markers.firstWhere((m) => m.markerId == const MarkerId('selected'));

    expect(marker.infoWindow.title, 'Punto seleccionado');
    expect(marker.infoWindow.snippet, contains('Comenzar reporte'));
    expect(marker.infoWindow.onTap, isNotNull);
    expect(marker.onTap, isNotNull);
    expect(find.byKey(const Key('selected-marker-report-button')), findsOneWidget);
  });

  testWidgets('seleccionar un tipo envía el identificador correcto', (tester) async {
    //12.- Validamos que la selección dispare el flujo con el tipo esperado.
    final bundle = _TestBundle();
    String? reportedType;
    await _pumpReportScreen(tester, bundle, onTypeSelected: (value) => reportedType = value);

    await tester.tap(find.text('Click to continue'));
    await tester.pumpAndSettle();

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    map.onTap?.call(const LatLng(19.43, -99.13));
    await tester.pump();

    await tester.tap(find.byKey(const Key('selected-marker-report-button')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('report-type-pothole')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byLabelText('Descripción'), 'Bache grande');
    await tester.enterText(find.byLabelText('Correo de contacto'), 'ciudadano@example.com');
    await tester.enterText(find.byLabelText('Referencia de dirección'), 'Calle Principal 123');
    await tester.tap(find.text('Enviar reporte'));
    await tester.pumpAndSettle();

    expect(bundle.client.lastIncidentType, 'incident.pothole');
    expect(reportedType, 'incident.pothole');
    expect(find.byKey(const Key('report-type-overlay')), findsNothing);
  });

  testWidgets('ubica automáticamente al cargar después de la introducción', (tester) async {
    //11.1.- Corroboramos que el centrado inicial solicite la ubicación una vez.
    final bundle = _TestBundle();
    var permissionChecks = 0;
    var positionRequests = 0;
    final location = LocationService(
      isServiceEnabled: () async => true,
      checkPermission: () async {
        permissionChecks++;
        return LocationPermission.always;
      },
      requestPermission: () async => LocationPermission.always,
      getCurrentPosition: (_) async {
        positionRequests++;
        return Position(
          latitude: 19.0414,
          longitude: -98.2063,
          timestamp: DateTime.now(),
          accuracy: 5,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      },
    );
    await _pumpReportScreen(tester, bundle, locationService: location);

    await tester.tap(find.text('Click to continue'));
    await tester.pumpAndSettle();

    expect(permissionChecks, greaterThanOrEqualTo(1));
    expect(positionRequests, 1);

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    final selectedMarker =
        map.markers.firstWhere((marker) => marker.markerId == const MarkerId('selected'));
    expect(selectedMarker.position.latitude, closeTo(19.0414, 0.0001));
    expect(selectedMarker.position.longitude, closeTo(-98.2063, 0.0001));
  });

  testWidgets('centrar el mapa solicita la ubicación actual', (tester) async {
    //13.- Confirmamos que el botón de ubicación obtenga y marque la coordenada.
    final bundle = _TestBundle();
    var permissionChecks = 0;
    var positionRequests = 0;
    final location = LocationService(
      isServiceEnabled: () async => true,
      checkPermission: () async {
        permissionChecks++;
        return LocationPermission.always;
      },
      requestPermission: () async => LocationPermission.always,
      getCurrentPosition: (_) async {
        positionRequests++;
        return Position(
          latitude: 19.4326,
          longitude: -99.1332,
          timestamp: DateTime.now(),
          accuracy: 5,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      },
    );
    await _pumpReportScreen(tester, bundle, locationService: location);

    await tester.tap(find.text('Click to continue'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('map-location-card')), findsOneWidget);

    await tester.tap(find.byKey(const Key('map-current-location-button')));
    await tester.pumpAndSettle();

    expect(permissionChecks, greaterThanOrEqualTo(1));
    expect(positionRequests, 1);

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    final selectedMarker =
        map.markers.firstWhere((marker) => marker.markerId == const MarkerId('selected'));
    expect(selectedMarker.position.latitude, closeTo(19.4326, 0.0001));
    expect(selectedMarker.position.longitude, closeTo(-99.1332, 0.0001));
  });

  testWidgets('muestra instrucciones cuando falta el API key', (tester) async {
    //14.- Simulamos la ausencia del API key para validar el flujo de contingencia.
    GoogleMapsAvailability.debugOverride(() async => false);
    final bundle = _TestBundle();
    await _pumpReportScreen(tester, bundle);

    await tester.tap(find.text('Click to continue'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('map-unavailable-card')), findsOneWidget);
    expect(find.byType(GoogleMap), findsNothing);

    GoogleMapsAvailability.debugOverride(() async => true);
    await tester.tap(find.text('Reintentar detección'));
    await tester.pumpAndSettle();

    expect(find.byType(GoogleMap), findsOneWidget);
  });
}
