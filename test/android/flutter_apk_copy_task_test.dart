import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Verifica que la configuración de Gradle duplique el APK del sabor por defecto para Flutter.
  test('build.gradle.kts copia el APK del sabor predeterminado a outputs/flutter-apk', () {
    //1.- Lee el archivo de configuración Kotlin para el módulo Android.
    final appGradle = File('android/app/build.gradle.kts').readAsStringSync();
    //2.- Confirma que se declara la constante con el sabor predeterminado esperado.
    expect(appGradle.contains('val defaultFlutterFlavor = "citizen"'), isTrue);
    //3.- Garantiza que exista la función auxiliar que copia el APK y usa el directorio de Flutter.
    expect(appGradle.contains('outputs/flutter-apk'), isTrue);
    //4.- Asegura que la función se registre para los tres tipos de compilación soportados.
    expect(
      appGradle.contains('listOf("debug", "profile", "release").forEach(::registerFlutterApkCopyTask)'),
      isTrue,
    );
  });
}
