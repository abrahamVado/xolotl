import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:mictlan_client/screens/map_report_screen.dart';

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

void main() {
  //2.- main agrupa y prepara las pruebas del flujo de introducción del mapa.
  setUpAll(() {
    GoogleMapsFlutterPlatform.instance = _FakeGoogleMapsPlatform();
  });

  testWidgets('muestra la introducción por defecto', (tester) async {
    //3.- Validamos que el mensaje inicial aparezca al crear la pantalla.
    await tester.pumpWidget(const MaterialApp(home: MapReportScreen()));

    expect(find.text('Click to continue'), findsOneWidget);
    expect(find.byType(GoogleMap), findsNothing);
  });

  testWidgets('cambia al mapa después de continuar', (tester) async {
    //4.- Confirmamos que la pulsación del botón renderiza el mapa.
    await tester.pumpWidget(const MaterialApp(home: MapReportScreen()));

    await tester.tap(find.text('Click to continue'));
    await tester.pumpAndSettle();

    expect(find.byType(GoogleMap), findsOneWidget);
  });
}
