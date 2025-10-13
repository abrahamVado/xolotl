import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mictlan_client/services/location_service.dart';

//1.- main agrupa las verificaciones del servicio de geoubicación.
void main() {
  test('regresa null cuando el servicio está deshabilitado', () async {
    //2.- Con el GPS apagado no se deben solicitar permisos ni coordenadas.
    var permissionChecks = 0;
    final service = LocationService(
      isServiceEnabled: () async => false,
      checkPermission: () async {
        permissionChecks++;
        return LocationPermission.denied;
      },
      requestPermission: () async {
        permissionChecks++;
        return LocationPermission.denied;
      },
      getCurrentPosition: (_) async => _buildPosition(),
    );

    final result = await service.currentLocation();

    expect(result, isNull);
    expect(permissionChecks, 0);
  });

  test('solicita permiso cuando está denegado y devuelve coordenadas', () async {
    //3.- Si la app no tiene permiso debe solicitarlo y retornar la LatLng.
    var requestCalls = 0;
    final service = LocationService(
      isServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.denied,
      requestPermission: () async {
        requestCalls++;
        return LocationPermission.whileInUse;
      },
      getCurrentPosition: (_) async => _buildPosition(latitude: 18.1, longitude: -94.5),
    );

    final result = await service.currentLocation();

    expect(requestCalls, 1);
    expect(result, const LatLng(18.1, -94.5));
  });

  test('propaga null cuando obtener la posición lanza una excepción', () async {
    //4.- Un error del plugin debe traducirse en una respuesta nula controlada.
    final service = LocationService(
      isServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.always,
      requestPermission: () async => LocationPermission.always,
      getCurrentPosition: (_) async => throw Exception('gps-error'),
    );

    final result = await service.currentLocation();

    expect(result, isNull);
  });
}

//5.- _buildPosition fabrica un objeto Position coherente para las pruebas.
Position _buildPosition({double latitude = 19.0, double longitude = -99.0}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    accuracy: 5,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  );
}
