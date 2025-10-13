import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

//1.- LocationService encapsula la lógica para obtener la coordenada actual.
class LocationService {
  //2.- El constructor permite inyectar funciones para facilitar las pruebas.
  LocationService({
    Future<bool> Function()? isServiceEnabled,
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    Future<Position> Function(LocationAccuracy accuracy)? getCurrentPosition,
  })  : _isServiceEnabled = isServiceEnabled ?? Geolocator.isLocationServiceEnabled,
        _checkPermission = checkPermission ?? Geolocator.checkPermission,
        _requestPermission = requestPermission ?? Geolocator.requestPermission,
        _getCurrentPosition = getCurrentPosition ?? _defaultGetCurrentPosition;

  //3.- _isServiceEnabled referencia la verificación nativa del GPS.
  final Future<bool> Function() _isServiceEnabled;
  //4.- _checkPermission consulta el estado actual del permiso.
  final Future<LocationPermission> Function() _checkPermission;
  //5.- _requestPermission solicita acceso cuando la app no lo tiene.
  final Future<LocationPermission> Function() _requestPermission;
  //6.- _getCurrentPosition obtiene la coordenada con la precisión deseada.
  final Future<Position> Function(LocationAccuracy accuracy) _getCurrentPosition;

  //7.- _defaultGetCurrentPosition envuelve la llamada directa al plugin.
  static Future<Position> _defaultGetCurrentPosition(LocationAccuracy accuracy) {
    return Geolocator.getCurrentPosition(desiredAccuracy: accuracy);
  }

  //8.- currentLocation devuelve la LatLng si el GPS está disponible y autorizado.
  Future<LatLng?> currentLocation() async {
    final serviceEnabled = await _isServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await _checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      return null;
    }

    try {
      final position = await _getCurrentPosition(LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } on Exception {
      return null;
    }
  }
}
