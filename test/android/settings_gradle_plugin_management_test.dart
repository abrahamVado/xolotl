import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Verifica que settings.gradle centralice las versiones de los plugins requeridos.
  test('settings.gradle pins Android and Kotlin plugin versions', () {
    //1.- Lee el archivo settings.gradle para inspeccionar el bloque pluginManagement.
    final settings = File('android/settings.gradle').readAsStringSync();
    //2.- Comprueba que el plugin de aplicación Android utilice la versión 8.9.1.
    expect(
      settings.contains("id 'com.android.application' version '8.9.1'"),
      isTrue,
    );
    //3.- Comprueba que el plugin de Kotlin Android utilice la versión 2.1.0.
    expect(
      settings.contains("id 'org.jetbrains.kotlin.android' version '2.1.0'"),
      isTrue,
    );
  });
}
