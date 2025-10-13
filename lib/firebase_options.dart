import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

//1.- DefaultFirebaseOptions entrega configuraciones por plataforma evitando depender de archivos nativos.
class DefaultFirebaseOptions {
  //2.- currentPlatform selecciona la configuración apropiada para cada plataforma soportada.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está configurado para ${defaultTargetPlatform.name}.',
        );
    }
  }

  //3.- Configuración genérica para Android usando valores de entorno sobrescribibles.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: 'YOUR_ANDROID_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: '1:000000000000:android:placeholder'),
    messagingSenderId: String.fromEnvironment('FIREBASE_ANDROID_SENDER_ID', defaultValue: '000000000000'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'your-project-id'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'your-project-id.appspot.com'),
  );

  //4.- Configuración para iOS, compatible con macOS cuando se usa el mismo proyecto.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY', defaultValue: 'YOUR_IOS_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: '1:000000000000:ios:placeholder'),
    messagingSenderId: String.fromEnvironment('FIREBASE_IOS_SENDER_ID', defaultValue: '000000000000'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'your-project-id'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'your-project-id.appspot.com'),
    iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: 'com.example.app'),
    iosClientId: String.fromEnvironment('FIREBASE_IOS_CLIENT_ID', defaultValue: '000000000000-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com'),
  );

  //5.- macos reutiliza la configuración iOS para simplificar la gestión multi-plataforma.
  static const FirebaseOptions macos = ios;

  //6.- La configuración web habilita el arranque en navegadores cuando existan builds web.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: 'YOUR_WEB_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: '1:000000000000:web:placeholder'),
    messagingSenderId: String.fromEnvironment('FIREBASE_WEB_SENDER_ID', defaultValue: '000000000000'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'your-project-id'),
    authDomain: String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN', defaultValue: 'your-project-id.firebaseapp.com'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'your-project-id.appspot.com'),
    measurementId: String.fromEnvironment('FIREBASE_MEASUREMENT_ID', defaultValue: 'G-XXXXXXXXXX'),
  );
}
