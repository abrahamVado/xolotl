import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Verifica que settings.gradle centralice las versiones de los plugins requeridos.
  test('settings.gradle.kts pin Android and Kotlin plugin versions', () {
    //1.- Lee el archivo settings.gradle.kts para inspeccionar el bloque pluginManagement.
    final settings = File('android/settings.gradle.kts').readAsStringSync();
    //2.- Comprueba que el plugin de aplicación Android utilice la versión 8.9.1.
    expect(
      settings.contains('id("com.android.application") version "8.9.1" apply false'),
      isTrue,
    );
    //3.- Comprueba que el plugin de Kotlin Android utilice la versión 2.1.0.
    expect(
      settings.contains('id("org.jetbrains.kotlin.android") version "2.1.0" apply false'),
      isTrue,
    );
  });
}
