import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

//1.- GoogleMapsAvailability centraliza la verificación del API key nativo.
class GoogleMapsAvailability {
  //2.- _channel define el canal de comunicación con el código Android.
  static const MethodChannel _channel = MethodChannel('com.example.mictlan_client/config');

  //3.- _shared mantiene la instancia reutilizada en toda la aplicación.
  static GoogleMapsAvailability _shared = GoogleMapsAvailability._(_defaultResolver);

  //4.- instance expone la instancia singleton y permite inyectar dobles en pruebas.
  static GoogleMapsAvailability get instance => _shared;

  //5.- debugOverride reemplaza temporalmente la instancia para escenarios controlados.
  @visibleForTesting
  static void debugOverride(Future<bool> Function() resolver) {
    _shared = GoogleMapsAvailability._(resolver);
  }

  //6.- debugReset restaura la implementación original tras una prueba.
  @visibleForTesting
  static void debugReset() {
    _shared = GoogleMapsAvailability._(_defaultResolver);
  }

  //7.- _resolver envuelve la consulta real o simulada según el contexto.
  final Future<bool> Function() _resolver;

  //8.- Constructor privado para evitar instancias externas sin control.
  GoogleMapsAvailability._(this._resolver);

  //9.- _defaultResolver consulta el canal nativo y confirma si existe API key válida.
  static Future<bool> _defaultResolver() async {
    try {
      final result = await _channel.invokeMethod<bool>('isGoogleMapsConfigured');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  //10.- isConfigured ejecuta el resolvedor activo para conocer el estado del API key.
  Future<bool> isConfigured() => _resolver();
}
