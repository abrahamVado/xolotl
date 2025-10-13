import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

//1.- FirebaseInitializeApp coincide con la firma de Firebase.initializeApp para poder inyectar stubs en pruebas.
typedef FirebaseInitializeApp = Future<void> Function({String? name, FirebaseOptions? options});

//2.- FirebaseAppProvider permite recuperar la instancia global cuando ya existe evitando recrear la aplicación.
typedef FirebaseAppProvider = FirebaseApp Function();

//3.- FirebaseInitializer centraliza la inicialización segura y reutilizable de Firebase.
class FirebaseInitializer {
  FirebaseInitializer({
    FirebaseInitializeApp? initializeApp,
    FirebaseAppProvider? appProvider,
  })  : _initializeApp = initializeApp ?? _defaultInitializeApp,
        _appProvider = appProvider ?? Firebase.app;

  final FirebaseInitializeApp _initializeApp;
  final FirebaseAppProvider _appProvider;

  //4.- ensureInitialized intenta arrancar Firebase con las opciones suministradas y maneja errores comunes.
  Future<void> ensureInitialized(FirebaseOptions options) async {
    try {
      await _initializeApp(options: options);
    } on FirebaseException catch (error) {
      if (error.code == 'duplicate-app') {
        _appProvider();
        return;
      }
      rethrow;
    } on PlatformException catch (error) {
      throw FirebaseException(
        plugin: 'firebase_core',
        code: error.code,
        message: 'Failed to initialize Firebase. ${error.message}',
        stackTrace: error.stacktrace,
      );
    }
  }

  //5.- initializeDefault usa los parámetros reales de Firebase.initializeApp cuando no se suministran stubs.
  static Future<void> initializeDefault({required FirebaseOptions options}) {
    final initializer = FirebaseInitializer();
    return initializer.ensureInitialized(options);
  }
}

//6.- _defaultInitializeApp conserva la firma original y delega en Firebase.initializeApp para facilitar pruebas.
Future<void> _defaultInitializeApp({String? name, FirebaseOptions? options}) async {
  await Firebase.initializeApp(name: name, options: options);
}
